import 'dart:math';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/circle_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/orrery_themes.dart';
import '../theme/orrery_widgets.dart';

const _storeUrl =
    'https://play.google.com/store/apps/details?id=com.gameswajiha.circlerush';

/// Game screen: renders engine state. The engine owns all phases; this
/// screen only paints, forwards taps, and plays audio for engine events.
class GameScreen extends StatefulWidget {
  final RushAudio audio;
  final RushSettings settings;
  const GameScreen({super.key, required this.audio, required this.settings});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver {
  late final RushEngine engine;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    engine = RushEngine(
        mode: widget.settings.mode,
        difficulty: widget.settings.difficulty);
    engine.onEvent = _onEvent;
    engine.onRecord = _onRecord;
    widget.audio.startGameMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    engine.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Auto-pause the run (engine watchdog respects paused); audio pauses
      // so it resumes exactly where it left off.
      if (engine.phase == RushPhase.playing ||
          engine.phase == RushPhase.countdown) {
        engine.setPaused(true);
      }
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  void _onEvent(RushEvent e) {
    final a = widget.audio;
    switch (e) {
      case RushEvent.hop:
        a.hop();
        break;
      case RushEvent.nearMiss:
        a.nearMiss();
        break;
      case RushEvent.crash:
        a.crash();
        break;
      case RushEvent.countdownBeep:
        a.beep();
        break;
      case RushEvent.go:
        a.go();
        break;
      case RushEvent.milestone:
        a.milestone();
        break;
      case RushEvent.tickWarn:
        a.beep();
        break;
      case RushEvent.win:
        a.win();
        break;
      case RushEvent.lose:
        a.lose();
        break;
      case RushEvent.newBest:
        a.newBest();
        break;
    }
  }

  /// Persist the run; returns whether it was a new best. Never throws —
  /// a failed record can never wedge the engine.
  Future<bool> _onRecord(RunResult r) async {
    if (_recorded) return false;
    _recorded = true;
    try {
      final best = await widget.settings.recordRun(
        m: engine.mode,
        seconds: r.seconds,
        score: r.score,
        won: r.won,
      );
      // Sensible review moment: after enough real games, occasionally.
      final gp = widget.settings.gamesPlayed;
      if (gp >= 3 && (gp % 4 == 0 || best)) {
        try {
          final review = InAppReview.instance;
          if (await review.isAvailable()) {
            await review.requestReview();
          }
        } catch (_) {}
      }
      return best;
    } catch (_) {
      return false;
    }
  }

  void _togglePause() {
    widget.audio.click();
    engine.setPaused(!engine.paused);
  }

  void _quit() {
    widget.audio.click();
    engine.setPaused(false);
    Navigator.of(context).pop();
  }

  void _retry() {
    widget.audio.click();
    _recorded = false;
    engine.restart();
  }

  void _share() {
    widget.audio.click();
    final msg = engine.mode == RushMode.endless
        ? 'I survived ${engine.elapsed.toStringAsFixed(1)}s in Circle Rush! Can you beat my orbit? 🪐\n$_storeUrl'
        : 'I scored ${engine.score} pts in Circle Rush! Can you beat my orbit? 🪐\n$_storeUrl';
    SharePlus.instance.share(ShareParams(text: msg));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Back button pauses the run instead of quitting mid-dodge.
        if (engine.phase == RushPhase.playing ||
            engine.phase == RushPhase.countdown) {
          engine.setPaused(true);
        } else {
          Navigator.of(context).pop();
        }
      },
      child: ListenableBuilder(
        listenable: engine,
        builder: (_, _) => _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final t = widget.settings.theme;
    return Scaffold(
      backgroundColor: t.deskDark,
      body: DeskBackdrop(
        theme: t,
        child: SafeArea(
          child: GestureDetector(
            onTap: engine.primaryTap,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                Column(
                  children: [
                    _Hud(
                      engine: engine,
                      settings: widget.settings,
                      onPause: _togglePause,
                    ),
                    Expanded(
                      child: CustomPaint(
                        painter: _ArenaPainter(
                          engine: engine,
                          theme: t,
                          orb: widget.settings.orb,
                          shipStyleId: widget.settings.shipStyleId,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        engine.phase == RushPhase.playing
                            ? '👆 TAP to hop between the inner & outer lanes!'
                            : engine.banner,
                        style: Orrery.body(13,
                            theme: t, color: t.muted),
                      ),
                    ),
                  ],
                ),
                if (engine.phase == RushPhase.countdown)
                  _CountdownOverlay(
                      step: engine.countdownStep, theme: t),
                if (engine.paused &&
                    engine.phase != RushPhase.over)
                  _PauseOverlay(
                    theme: widget.settings.theme,
                    audio: widget.audio,
                    settings: widget.settings,
                    onResume: _togglePause,
                    onRestart: _retry,
                    onQuit: _quit,
                  ),
                if (engine.phase == RushPhase.over && !engine.paused)
                  _GameOverOverlay(
                    theme: t,
                    engine: engine,
                    settings: widget.settings,
                    onRetry: _retry,
                    onMenu: _quit,
                    onShare: _share,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  final RushEngine engine;
  final RushSettings settings;
  final VoidCallback onPause;
  const _Hud(
      {required this.engine,
      required this.settings,
      required this.onPause});

  @override
  Widget build(BuildContext context) {
    final t = settings.theme;
    final isTimed = engine.timeLimit != null;
    final main = isTimed
        ? '${engine.score} pts · ${engine.secondsLeft}s left'
        : '⏱️ ${engine.elapsed.toStringAsFixed(1)}s';
    final best = settings.bestFor(engine.mode);
    final bestLine = engine.mode == RushMode.endless
        ? '🏆 ${best == 0 ? '—' : '${best.toStringAsFixed(1)}s'}'
        : '🏆 ${best == 0 ? '—' : '$best pts'}';
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(main,
                    style: Orrery.display(24, theme: t)),
                Text('$bestLine · ${settings.playerName}',
                    style: Orrery.body(12,
                        theme: t, color: t.muted)),
              ],
            ),
          ),
          if (engine.mode != RushMode.endless)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.35),
                border: Border.all(color: t.panelEdge),
              ),
              child: Text('⚡ ${engine.nearMisses}',
                  style: Orrery.body(13, theme: t)),
            ),
          DialButton(theme: t, icon: Icons.pause, onTap: onPause),
        ],
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  final int step;
  final OrreryThemeDef theme;
  const _CountdownOverlay({required this.step, required this.theme});

  @override
  Widget build(BuildContext context) {
    final label = switch (step) {
      0 => 'READY',
      1 => 'SET',
      _ => 'RUSH!',
    };
    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 40, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black.withValues(alpha: 0.55),
            border: Border.all(color: theme.brass, width: 3),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  offset: const Offset(0, 8),
                  blurRadius: 20),
            ],
          ),
          child: Text(label,
              style: Orrery.display(52, theme: theme)),
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  final OrreryThemeDef theme;
  final RushAudio audio;
  final RushSettings settings;
  final VoidCallback onResume, onRestart, onQuit;
  const _PauseOverlay({
    required this.theme,
    required this.audio,
    required this.settings,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: BrassPanel(
            theme: t,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PAUSED', style: Orrery.display(30, theme: t)),
                const SizedBox(height: 14),
                BrassButton(
                    theme: t, text: '▶  RESUME', onTap: onResume),
                const SizedBox(height: 10),
                BrassButton(
                    theme: t, text: '↻  RESTART', onTap: onRestart),
                const SizedBox(height: 10),
                BrassButton(
                    theme: t, text: '✕  QUIT', onTap: onQuit),
                const SizedBox(height: 14),
                ListenableBuilder(
                  listenable: settings,
                  builder: (_, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _QuickToggle(
                        theme: t,
                        icon: Icons.music_note,
                        on: settings.musicOn,
                        onTap: () {
                          audio.click();
                          settings.setMusic(!settings.musicOn);
                          audio.configure(
                              musicOn: settings.musicOn,
                              sfxOn: settings.sfxOn,
                              volume: settings.volume);
                          if (settings.musicOn) {
                            audio.startGameMusic();
                          }
                        },
                      ),
                      _QuickToggle(
                        theme: t,
                        icon: Icons.volume_up,
                        on: settings.sfxOn,
                        onTap: () {
                          audio.click();
                          settings.setSfx(!settings.sfxOn);
                          audio.configure(
                              musicOn: settings.musicOn,
                              sfxOn: settings.sfxOn,
                              volume: settings.volume);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickToggle extends StatelessWidget {
  final OrreryThemeDef theme;
  final IconData icon;
  final bool on;
  final VoidCallback onTap;
  const _QuickToggle(
      {required this.theme,
      required this.icon,
      required this.on,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: on
              ? t.brass.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
              color: on ? t.brassLight : t.panelEdge, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: on ? t.brassLight : t.muted, size: 20),
            const SizedBox(width: 6),
            Text(on ? 'ON' : 'OFF',
                style: Orrery.label(13, theme: t)),
          ],
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final OrreryThemeDef theme;
  final RushEngine engine;
  final RushSettings settings;
  final VoidCallback onRetry, onMenu, onShare;
  const _GameOverOverlay({
    required this.theme,
    required this.engine,
    required this.settings,
    required this.onRetry,
    required this.onMenu,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final headline = engine.isNewBest
        ? '🏆 NEW BEST!'
        : engine.won
            ? '🎉 VICTORY!'
            : '💥 CRASHED!';
    final detail = engine.mode == RushMode.endless
        ? 'You survived ${engine.elapsed.toStringAsFixed(1)}s'
        : '${engine.score} pts · ${engine.elapsed.toStringAsFixed(0)}s · ${engine.nearMisses} near misses';
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: BrassPanel(
            theme: t,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(headline,
                    style: Orrery.display(30, theme: t),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(detail,
                    style: Orrery.body(15, theme: t),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  engine.mode == RushMode.endless
                      ? 'Best: ${settings.bestEndless.toStringAsFixed(1)}s'
                      : 'Best: ${settings.bestFor(engine.mode)} pts',
                  style: Orrery.body(13, theme: t, color: t.muted),
                ),
                const SizedBox(height: 16),
                BrassButton(
                    theme: t, text: '↻  FLY AGAIN', onTap: onRetry),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: BrassButton(
                          theme: t,
                          text: 'MENU',
                          fontSize: 15,
                          onTap: onMenu),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BrassButton(
                          theme: t,
                          text: 'SHARE',
                          fontSize: 15,
                          onTap: onShare),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- painter
class _ArenaPainter extends CustomPainter {
  final RushEngine engine;
  final OrreryThemeDef theme;
  final OrbStyleDef orb;
  final String shipStyleId;
  _ArenaPainter(
      {required this.engine,
      required this.theme,
      required this.orb,
      required this.shipStyleId});

  @override
  void paint(Canvas c, Size s) {
    final t = theme;
    final cx = s.width / 2, cy = s.height / 2;
    final u = min(s.width, s.height) / 2 * 0.96;
    Offset pt(double x, double y) => Offset(cx + x * u, cy + y * u);

    // Starfield (deterministic positions).
    final starPaint = Paint()..color = t.star.withValues(alpha: .55);
    for (int i = 0; i < 46; i++) {
      final th = i * 2.39996;
      final rr = ((i * 37) % 100) / 100 * 1.25;
      final tw = 0.7 + 0.3 * sin(engine.elapsed * 2 + i);
      c.drawCircle(
          pt(cos(th) * rr, sin(th) * rr), 1.5 * tw, starPaint);
    }

    // Orbit lanes — brass rings, active lane highlighted.
    for (int i = 0; i < 2; i++) {
      final lane = i == 0 ? 0.34 : 0.66;
      final active = engine.laneIndex == i &&
          engine.phase == RushPhase.playing;
      c.drawCircle(
          Offset(cx, cy),
          lane * u,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = active ? 5 : 2.5
            ..color = active
                ? t.brassLight
                : t.brass.withValues(alpha: .38));
    }

    // Planet with pulse + 3D shading.
    final pulse = 1 + 0.035 * sin(engine.elapsed * 3);
    final pr = 0.20 * u * pulse;
    final center = Offset(cx, cy);
    final pg = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 1.1,
      colors: [
        Color.lerp(orb.pole, Colors.white, 0.25)!,
        orb.base,
        Color.lerp(orb.base, Colors.black, 0.45)!,
      ],
      stops: const [0.0, 0.45, 1.0],
    );
    c.drawCircle(center, pr,
        Paint()..shader = pg.createShader(Rect.fromCircle(center: center, radius: pr)));
    // Marble bands.
    for (int i = 0; i < 4; i++) {
      final yy = cy - pr * 0.55 + i * pr * 0.35;
      final half =
          sqrt(max(0.0, pr * pr - (yy - cy) * (yy - cy)));
      c.drawLine(
          Offset(cx - half * 0.9, yy),
          Offset(cx + half * 0.9, yy),
          Paint()
            ..strokeWidth = 3
            ..color = orb.band.withValues(alpha: 0.5));
    }
    // Saturn-style rings for ringed orbs.
    if (orb.hasRings) {
      c.drawOval(
          Rect.fromCenter(
              center: center, width: pr * 3.4, height: pr * 1.0),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = t.brass.withValues(alpha: 0.75));
      c.drawOval(
          Rect.fromCenter(
              center: center, width: pr * 2.6, height: pr * 0.75),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = t.brassLight.withValues(alpha: 0.6));
    }
    // Rim shadow for depth.
    c.drawCircle(
        center,
        pr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.black.withValues(alpha: 0.35));

    // Asteroids — chunky faceted rock.
    for (final a in engine.asteroids) {
      final p = pt(a.x, a.y), r = a.r * u;
      final path = Path();
      for (int i = 0; i < 8; i++) {
        final th = a.rot + i / 8 * 2 * pi;
        final rr = r * a.wobble[i];
        final v =
            Offset(p.dx + cos(th) * rr, p.dy + sin(th) * rr);
        if (i == 0) {
          path.moveTo(v.dx, v.dy);
        } else {
          path.lineTo(v.dx, v.dy);
        }
      }
      path.close();
      final g = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        radius: 1.2,
        colors: [t.rock, t.rockDark],
      );
      c.drawPath(
          path,
          Paint()
            ..shader = g.createShader(
                Rect.fromCircle(center: p, radius: r)));
      c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.black.withValues(alpha: 0.45));
      // Grazed rocks glow faintly — telegraphs the near-miss bonus.
      if (a.grazed) {
        c.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..color = t.brassLight.withValues(alpha: 0.7));
      }
    }

    // Engine sparks.
    for (final sp in engine.sparks) {
      final a = (sp.life / sp.maxLife).clamp(0.0, 1.0);
      c.drawCircle(pt(sp.x, sp.y), 3.2 * a,
          Paint()..color = t.flameCore.withValues(alpha: a));
    }

    // Floaters (+10, milestones).
    for (final f in engine.floaters) {
      final a = f.life.clamp(0.0, 1.0);
      final tp = TextPainter(
          text: TextSpan(
              text: f.text,
              style: TextStyle(
                  color: t.brassLight.withValues(alpha: a),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        offset: const Offset(0, 2),
                        blurRadius: 4)
                  ])),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(c, pt(f.x, f.y) - Offset(tp.width / 2, tp.height / 2));
    }

    // Ship.
    if (engine.phase != RushPhase.crashing &&
        engine.phase != RushPhase.over) {
      final p = pt(cos(engine.angle) * engine.orbitR,
          sin(engine.angle) * engine.orbitR);
      // Hop bounce: ship squashes outward mid-hop.
      final bounce =
          engine.hopT < 0.35 ? sin(engine.hopT / 0.35 * pi) : 0.0;
      _paintShip(c, p, engine.angle + pi / 2, 15 + bounce * 4,
          shipStyleId, t);
      // Flame.
      final dir = engine.angle + pi / 2;
      final flame = 5 + 4 * sin(engine.elapsed * 30) + bounce * 6;
      c.drawCircle(
          Offset(p.dx - cos(dir) * 16, p.dy - sin(dir) * 16),
          flame * 0.5,
          Paint()..color = t.flame.withValues(alpha: .85));
      c.drawCircle(
          Offset(p.dx - cos(dir) * 16, p.dy - sin(dir) * 16),
          flame * 0.25,
          Paint()..color = t.flameCore.withValues(alpha: .95));
    }

    // Idle hint.
    if (engine.phase == RushPhase.idle) {
      final tp = TextPainter(
          text: TextSpan(
              text: '👆 tap to launch!',
              style: TextStyle(
                  color: t.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        offset: const Offset(0, 2),
                        blurRadius: 6)
                  ])),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(c, Offset(cx - tp.width / 2, cy - pr - 46));
    }
  }

  void _paintShip(Canvas c, Offset p, double dir, double sz,
      String styleId, OrreryThemeDef t) {
    final body = Paint()..color = t.ivory;
    final trim = Paint()..color = t.brass;
    final dark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black.withValues(alpha: 0.5);
    final glow = Paint()
      ..color = t.ivory.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    Offset at(double ang, double r) =>
        Offset(p.dx + cos(ang) * r, p.dy + sin(ang) * r);

    void poly(List<Offset> pts, Paint fill) {
      final path = Path()
        ..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      path.close();
      c.drawPath(path, glow);
      c.drawPath(path, fill);
      c.drawPath(path, dark);
    }

    switch (styleId) {
      case 'dart':
        poly([at(dir, sz), at(dir + 2.9, sz * .55), at(dir - 2.9, sz * .55)],
            body);
        break;
      case 'comet':
        c.drawCircle(p, sz * .55, glow);
        c.drawCircle(p, sz * .55, body);
        c.drawCircle(p, sz * .55, dark);
        poly(
            [at(dir + pi, sz * .5), at(dir + 2.6, sz * 1.3), at(dir - 2.6, sz * 1.3)],
            trim);
        break;
      case 'saucer':
        c.drawOval(Rect.fromCenter(center: p, width: sz * 1.9, height: sz * .8),
            glow);
        c.drawOval(Rect.fromCenter(center: p, width: sz * 1.9, height: sz * .8),
            body);
        c.drawOval(Rect.fromCenter(center: p, width: sz * 1.9, height: sz * .8),
            dark);
        c.drawCircle(Offset(p.dx, p.dy - sz * .3), sz * .38, trim);
        c.drawCircle(Offset(p.dx, p.dy - sz * .3), sz * .38, dark);
        break;
      case 'ring':
        c.drawCircle(p, sz * .75, glow);
        c.drawCircle(
            p,
            sz * .75,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = t.brass);
        c.drawCircle(p, sz * .22, body);
        c.drawCircle(p, sz * .22, dark);
        break;
      case 'teardrop':
        final path = Path()
          ..moveTo(at(dir, sz).dx, at(dir, sz).dy)
          ..quadraticBezierTo(
              at(dir + 1.4, sz * 1.1).dx,
              at(dir + 1.4, sz * 1.1).dy,
              at(dir + pi, sz * .6).dx,
              at(dir + pi, sz * .6).dy)
          ..quadraticBezierTo(
              at(dir - 1.4, sz * 1.1).dx,
              at(dir - 1.4, sz * 1.1).dy,
              at(dir, sz).dx,
              at(dir, sz).dy)
          ..close();
        c.drawPath(path, glow);
        c.drawPath(path, body);
        c.drawPath(path, dark);
        break;
      case 'gem':
        poly(
            [at(dir, sz), at(dir + 1.7, sz * .55), at(dir + pi, sz * .7), at(dir - 1.7, sz * .55)],
            trim);
        poly(
            [at(dir, sz * .7), at(dir + 1.7, sz * .38), at(dir + pi, sz * .5), at(dir - 1.7, sz * .38)],
            body);
        break;
      case 'top':
        poly([at(dir, sz), at(dir + 2.6, sz * .6), at(dir - 2.6, sz * .6)],
            body);
        poly(
            [at(dir + pi, sz * .8), at(dir + pi + 0.6, sz * .4), at(dir + pi - 0.6, sz * .4)],
            trim);
        c.drawCircle(p, sz * .3, trim);
        c.drawCircle(p, sz * .3, dark);
        break;
      case 'orrery':
        c.drawCircle(p, sz * .45, glow);
        c.drawCircle(p, sz * .45, body);
        c.drawCircle(p, sz * .45, dark);
        c.drawCircle(
            p,
            sz * .85,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.5
              ..color = t.brass);
        break;
      case 'dragonfly':
        poly([at(dir, sz * .8), at(dir + 2.8, sz * .3), at(dir - 2.8, sz * .3)],
            body);
        for (final w in [0.9, -0.9]) {
          c.drawOval(
              Rect.fromCenter(
                  center: at(dir + w, sz * .5), width: sz * 1.2, height: sz * .45),
              Paint()..color = t.brassLight.withValues(alpha: 0.85));
        }
        break;
      case 'saturnship':
        c.drawCircle(p, sz * .55, glow);
        c.drawCircle(p, sz * .55, body);
        c.drawCircle(p, sz * .55, dark);
        c.drawOval(
            Rect.fromCenter(center: p, width: sz * 2.1, height: sz * .6),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = t.brass);
        break;
      case 'kestrel':
        poly(
            [at(dir, sz), at(dir + 2.2, sz * .9), at(dir + pi, sz * .2), at(dir - 2.2, sz * .9)],
            body);
        poly([at(dir + pi, sz * .15), at(dir + 2.7, sz * .5), at(dir - 2.7, sz * .5)],
            trim);
        break;
      case 'arrow':
      default:
        poly(
            [at(dir, sz), at(dir + 2.5, sz * .8), at(dir - 2.5, sz * .8)],
            body);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ArenaPainter o) => true;
}
