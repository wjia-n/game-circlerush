import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';

/// Turn phases owned entirely by the engine. The UI only renders.
/// [crashing] = crash animation in flight: input locked, the run will end
/// shortly. This is what makes stuck states impossible by construction.
enum RushPhase { idle, countdown, playing, crashing, over }

/// One-shot events the engine emits so the UI can play audio + toasts.
/// Every scored action emits an event — no silent scoring.
enum RushEvent {
  hop, // lane hop
  nearMiss, // grazed an asteroid: +10
  crash, // hit an asteroid
  countdownBeep, // "Ready… Set…"
  go, // "RUSH!" — run starts
  milestone, // endless: every 15s survived
  tickWarn, // timed modes: 3s left
  win, // survived the full time attack
  lose, // crashed
  newBest, // new personal best
}

class RunResult {
  final double seconds;
  final int score;
  final bool won;
  const RunResult(
      {required this.seconds, required this.score, required this.won});
}

class Asteroid {
  double x, y, vx, vy, r;
  final List<double> wobble;
  double rot, spin;
  bool grazed = false; // flew close without hitting: near-miss candidate
  Asteroid(this.x, this.y, this.vx, this.vy, this.r, this.wobble, this.rot,
      this.spin);
}

class Spark {
  double x, y, vx, vy, life, maxLife;
  Spark(this.x, this.y, this.vx, this.vy, this.life) : maxLife = life;
}

class Floater {
  double x, y;
  final String text;
  double life;
  Floater(this.x, this.y, this.text, this.life);
}

/// Difficulty tuning. Clear progression: speed + density + rock size all
/// scale up. Cometchaser and Nova are Pro tiers.
class DiffTune {
  final double angSpeed, ramp;
  final double gap, gapMin, gapRamp;
  final double rockSpeed, rockRamp;
  final double rockRMin, rockRMax;
  const DiffTune({
    required this.angSpeed,
    required this.ramp,
    required this.gap,
    required this.gapMin,
    required this.gapRamp,
    required this.rockSpeed,
    required this.rockRamp,
    required this.rockRMin,
    required this.rockRMax,
  });
}

const _tunes = {
  Difficulty.drifter: DiffTune(
      angSpeed: 1.5,
      ramp: 0.016,
      gap: 1.15,
      gapMin: 0.55,
      gapRamp: 0.008,
      rockSpeed: 0.42,
      rockRamp: 0.0025,
      rockRMin: 0.050,
      rockRMax: 0.095),
  Difficulty.voyager: DiffTune(
      angSpeed: 1.8,
      ramp: 0.022,
      gap: 1.00,
      gapMin: 0.42,
      gapRamp: 0.010,
      rockSpeed: 0.50,
      rockRamp: 0.0035,
      rockRMin: 0.055,
      rockRMax: 0.105),
  Difficulty.cometchaser: DiffTune(
      angSpeed: 2.2,
      ramp: 0.030,
      gap: 0.85,
      gapMin: 0.32,
      gapRamp: 0.013,
      rockSpeed: 0.58,
      rockRamp: 0.0045,
      rockRMin: 0.060,
      rockRMax: 0.110),
  Difficulty.nova: DiffTune(
      angSpeed: 2.7,
      ramp: 0.040,
      gap: 0.70,
      gapMin: 0.24,
      gapRamp: 0.017,
      rockSpeed: 0.66,
      rockRamp: 0.0060,
      rockRMin: 0.065,
      rockRMax: 0.115),
};

/// Circle Rush engine: deterministic sim, engine-owned phases, watchdog.
///
/// The UI never drives game flow — it renders engine state and forwards
/// taps. A watchdog timer recovers any phase found without a live tick or
/// transition timer, so stuck states are impossible by construction.
class RushEngine extends ChangeNotifier {
  final RushMode mode;
  final Difficulty difficulty;
  void Function(RushEvent)? onEvent;

  /// Called when the run ends (crash or time-up). Must return whether the
  /// result was a new best; the engine awaits it before showing the
  /// game-over state. Any error is swallowed — a failed record can never
  /// wedge the engine.
  Future<bool> Function(RunResult result)? onRecord;

  RushPhase phase = RushPhase.idle;

  // Ship state (arena units; arena is a unit circle of radius ~1).
  double angle = 0;
  double orbitR = _innerLane;
  double targetOrbit = _innerLane;
  int laneIndex = 0;
  double hopT = 99; // seconds since last hop (drives the hop bounce)

  // Run state.
  double elapsed = 0;
  int nearMisses = 0;
  int score = 0;
  int get secondsLeft =>
      timeLimit == null ? 0 : (timeLimit! - elapsed).ceil().clamp(0, 999);
  double? get timeLimit => switch (mode) {
        RushMode.endless => null,
        RushMode.rush60 => 60.0,
        RushMode.blitz30 => 30.0,
      };

  int countdownStep = 0; // 0 Ready, 1 Set, 2 RUSH!
  bool isNewBest = false;
  bool won = false;
  int _milestone = 0;
  int _lastWarnSec = -1;

  final List<Asteroid> asteroids = [];
  final List<Spark> sparks = [];
  final List<Floater> floaters = [];

  final _rand = Random();
  Timer? _tick; // the sim loop
  Timer? _trans; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  DateTime _lastFrame = DateTime.now();
  bool _disposed = false;
  bool paused = false;

  static const double _innerLane = 0.34;
  static const double _outerLane = 0.66;
  static const double _shipR = 0.045;
  static const double _nearMargin = 0.14;
  static const int _frameMs = 16;

  double get shipX => cos(angle) * orbitR;
  double get shipY => sin(angle) * orbitR;
  double get angSpeedNow =>
      _tunes[difficulty]!.angSpeed + elapsed * _tunes[difficulty]!.ramp;

  String get banner => switch (phase) {
        RushPhase.idle => 'Tap to launch!',
        RushPhase.countdown => 'Get ready…',
        RushPhase.playing => switch (mode) {
            RushMode.endless => 'Dodge the rocks!',
            RushMode.rush60 => 'Survive 60 seconds!',
            RushMode.blitz30 => 'Survive 30 seconds!',
          },
        RushPhase.crashing => '💥',
        RushPhase.over => won ? 'Victory!' : 'Run over',
      };

  RushEngine({required this.mode, required this.difficulty}) {
    _startTick();
    _watchdog =
        Timer.periodic(const Duration(seconds: 2), (_) => _recover());
  }

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    _trans?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------ main loop
  void _startTick() {
    if (_disposed || paused || _tick != null) return;
    _lastFrame = DateTime.now();
    _tick = Timer.periodic(
        const Duration(milliseconds: _frameMs), (_) => _frame());
  }

  void _frame() {
    if (_disposed || paused) return;
    final now = DateTime.now();
    final dt = (now.difference(_lastFrame).inMicroseconds / 1e6)
        .clamp(0.0, 0.05);
    _lastFrame = now;
    switch (phase) {
      case RushPhase.idle:
        // Slow showcase orbit; sparks twinkle so the arena feels alive.
        angle += 0.7 * dt;
        _updateSparks(dt);
        _updateFloaters(dt);
        break;
      case RushPhase.playing:
        _step(dt);
        break;
      case RushPhase.countdown:
      case RushPhase.crashing:
        // Transitions are timer-driven; still animate debris/floaters.
        _updateSparks(dt);
        _updateFloaters(dt);
        break;
      case RushPhase.over:
        _updateSparks(dt);
        _updateFloaters(dt);
        break;
    }
    notifyListeners();
  }

  void _step(double dt) {
    final tune = _tunes[difficulty]!;
    elapsed += dt;
    hopT += dt;
    final limit = timeLimit;

    // Ship orbit + lane hop spring.
    angle += (tune.angSpeed + elapsed * tune.ramp) * dt;
    orbitR += (targetOrbit - orbitR) * (1 - pow(0.0001, dt));

    // Timed-mode countdown warnings.
    if (limit != null) {
      final left = (limit - elapsed).ceil();
      if (left <= 3 && left > 0 && left != _lastWarnSec) {
        _lastWarnSec = left;
        onEvent?.call(RushEvent.tickWarn);
      }
      if (elapsed >= limit) {
        _win();
        return;
      }
    }

    // Spawning.
    final blitz = mode == RushMode.blitz30 ? 0.75 : 1.0;
    final rush = mode == RushMode.rush60 ? 0.9 : 1.0;
    final gapNow = max(
        tune.gapMin,
        (tune.gap - elapsed * tune.gapRamp) * blitz * rush);
    _spawnIn += dt;
    if (_spawnIn >= gapNow) {
      _spawnIn = 0;
      _spawnAsteroid(tune);
    }

    // Asteroids.
    final sx = shipX, sy = shipY;
    for (final a in asteroids) {
      a.x += a.vx * dt;
      a.y += a.vy * dt;
      a.rot += a.spin * dt;
      final dx = a.x - sx, dy = a.y - sy;
      final d2 = dx * dx + dy * dy;
      final hitR = a.r + _shipR;
      if (d2 < hitR * hitR) {
        _crash();
        return;
      }
      if (!a.grazed && d2 < (hitR + _nearMargin) * (hitR + _nearMargin)) {
        a.grazed = true;
      }
    }
    // Rocks that leave the arena: score grazes, drop the rest.
    asteroids.removeWhere((a) {
      final out = a.x * a.x + a.y * a.y > 1.9;
      if (out && a.grazed && phase == RushPhase.playing) {
        nearMisses++;
        if (mode != RushMode.endless) score += 10;
        floaters.add(Floater(shipX, shipY - 0.12, '+10', 0.9));
        onEvent?.call(RushEvent.nearMiss);
      }
      return out;
    });

    // Endless score = seconds survived; timed modes = seconds + near-miss pts.
    score = mode == RushMode.endless
        ? elapsed.floor()
        : elapsed.floor() + nearMisses * 10;

    // Milestones every 15s in endless.
    if (mode == RushMode.endless && elapsed >= (_milestone + 1) * 15) {
      _milestone++;
      floaters.add(Floater(0, -0.35, '${_milestone * 15}s!', 1.1));
      onEvent?.call(RushEvent.milestone);
    }

    // Engine exhaust sparks.
    if (_rand.nextDouble() < 0.6) {
      sparks.add(Spark(sx, sy, (_rand.nextDouble() - .5) * .25,
          (_rand.nextDouble() - .5) * .25, 0.45));
    }
    _updateSparks(dt);
    _updateFloaters(dt);
  }

  double _spawnIn = 0;

  void _spawnAsteroid(DiffTune tune) {
    final th = _rand.nextDouble() * 2 * pi;
    final tx = (_rand.nextDouble() - .5) * 1.1;
    final ty = (_rand.nextDouble() - .5) * 1.1;
    final px = cos(th) * 1.25, py = sin(th) * 1.25;
    final dx = tx - px, dy = ty - py;
    final len = sqrt(dx * dx + dy * dy);
    final blitz = mode == RushMode.blitz30 ? 1.3 : 1.0;
    final rush = mode == RushMode.rush60 ? 1.1 : 1.0;
    final sp =
        (tune.rockSpeed + _rand.nextDouble() * 0.35 + elapsed * tune.rockRamp) *
            blitz *
            rush;
    asteroids.add(Asteroid(
      px,
      py,
      dx / len * sp,
      dy / len * sp,
      tune.rockRMin + _rand.nextDouble() * (tune.rockRMax - tune.rockRMin),
      List.generate(8, (_) => 0.75 + _rand.nextDouble() * 0.5),
      _rand.nextDouble() * 2 * pi,
      (_rand.nextDouble() - .5) * 3,
    ));
  }

  void _updateSparks(double dt) {
    for (final s in sparks) {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.life -= dt;
    }
    sparks.removeWhere((s) => s.life <= 0);
  }

  void _updateFloaters(double dt) {
    for (final f in floaters) {
      f.y -= dt * 0.35;
      f.life -= dt;
    }
    floaters.removeWhere((f) => f.life <= 0);
  }

  // ------------------------------------------------------------- input
  /// The single tap the game cares about: launch from idle, hop lanes while
  /// playing. Everything else is ignored by construction.
  void primaryTap() {
    if (_disposed || paused) return;
    switch (phase) {
      case RushPhase.idle:
        _beginCountdown();
        break;
      case RushPhase.playing:
        _hop();
        break;
      case RushPhase.countdown:
      case RushPhase.crashing:
      case RushPhase.over:
        break;
    }
  }

  void _hop() {
    laneIndex = 1 - laneIndex;
    targetOrbit = laneIndex == 0 ? _innerLane : _outerLane;
    hopT = 0;
    onEvent?.call(RushEvent.hop);
    notifyListeners();
  }

  // -------------------------------------------------------- phase flow
  void _armTrans(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _trans?.cancel();
    _trans = Timer(d, () {
      _trans = null;
      if (!_disposed && !paused) fn();
    });
  }

  void _beginCountdown() {
    phase = RushPhase.countdown;
    countdownStep = 0;
    onEvent?.call(RushEvent.countdownBeep);
    notifyListeners();
    _armTrans(const Duration(milliseconds: 500), _countdownNext);
  }

  void _countdownNext() {
    if (phase != RushPhase.countdown) return;
    countdownStep++;
    if (countdownStep < 2) {
      onEvent?.call(RushEvent.countdownBeep);
      notifyListeners();
      _armTrans(const Duration(milliseconds: 500), _countdownNext);
    } else {
      // "RUSH!" — the run starts.
      phase = RushPhase.playing;
      elapsed = 0;
      _spawnIn = 0;
      _milestone = 0;
      _lastWarnSec = -1;
      onEvent?.call(RushEvent.go);
      notifyListeners();
    }
  }

  void _crash() {
    phase = RushPhase.crashing;
    // Explosion at the ship.
    for (int i = 0; i < 30; i++) {
      final th = _rand.nextDouble() * 2 * pi;
      final sp = 0.3 + _rand.nextDouble() * .7;
      sparks.add(Spark(shipX, shipY, cos(th) * sp, sin(th) * sp,
          0.7 + _rand.nextDouble() * .5));
    }
    onEvent?.call(RushEvent.crash);
    notifyListeners();
    _armTrans(const Duration(milliseconds: 900), _finish);
  }

  void _win() {
    // Timed modes only: survived the full limit.
    phase = RushPhase.crashing; // reuse the settle path
    score += 100;
    floaters.add(Floater(0, -0.2, '+100 SURVIVED!', 1.4));
    won = true;
    onEvent?.call(RushEvent.win);
    notifyListeners();
    _armTrans(const Duration(milliseconds: 1100), _finish);
  }

  Future<void> _finish() async {
    if (_disposed || phase == RushPhase.over) return;
    final result = RunResult(
        seconds: elapsed, score: score, won: won);
    var best = false;
    try {
      best = await onRecord?.call(result) ?? false;
    } catch (_) {}
    if (_disposed) return;
    isNewBest = best;
    phase = RushPhase.over;
    if (best) {
      onEvent?.call(RushEvent.newBest);
    } else if (won) {
      onEvent?.call(RushEvent.win);
    } else {
      onEvent?.call(RushEvent.lose);
    }
    notifyListeners();
  }

  /// Restart the engine for another run (back to idle).
  void restart() {
    _trans?.cancel();
    _trans = null;
    phase = RushPhase.idle;
    angle = 0;
    orbitR = _innerLane;
    targetOrbit = _innerLane;
    laneIndex = 0;
    hopT = 99;
    elapsed = 0;
    nearMisses = 0;
    score = 0;
    countdownStep = 0;
    isNewBest = false;
    won = false;
    _milestone = 0;
    _lastWarnSec = -1;
    _spawnIn = 0;
    asteroids.clear();
    sparks.clear();
    floaters.clear();
    paused = false;
    _startTick();
    notifyListeners();
  }

  // ----------------------------------------------------------- pause
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _tick?.cancel();
      _tick = null;
      _trans?.cancel();
      _trans = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  // -------------------------------------------------------- watchdog
  /// Stuck-state recovery: if any phase is found without a live tick or
  /// transition timer, repair it. Makes stuck states impossible by
  /// construction. Respects [paused].
  void _recover() {
    if (_disposed || paused) return;
    final stale = DateTime.now().difference(_lastFrame).inMilliseconds > 600;
    if ((phase == RushPhase.playing || phase == RushPhase.idle) &&
        (_tick == null || stale)) {
      _tick?.cancel();
      _tick = null;
      _startTick();
      return;
    }
    if (phase == RushPhase.countdown && _trans == null) {
      _countdownNext();
    } else if (phase == RushPhase.crashing && _trans == null) {
      _finish();
    }
  }
}
