import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Circle Rush: orbit the planet, tap to switch orbit lanes, dodge asteroids.
class _Asteroid {
  double x, y, vx, vy, r;
  final List<double> wobble; // vertex radii multipliers
  double rot, spin;
  _Asteroid(this.x, this.y, this.vx, this.vy, this.r, this.wobble, this.rot, this.spin);
}

class _Spark {
  double x, y, vx, vy, life;
  _Spark(this.x, this.y, this.vx, this.vy, this.life);
}

class CircleRushScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const CircleRushScreen({super.key, required this.players, required this.callbacks});

  @override
  State<CircleRushScreen> createState() => _CircleRushScreenState();
}

class _CircleRushScreenState extends State<CircleRushScreen> with SingleTickerProviderStateMixin {
  late Ticker ticker;
  final rng = Random();
  double angle = 0;          // ship orbit angle
  double orbitR = 0.38;      // current orbit radius (arena units)
  double targetOrbit = 0.38;
  static const innerLane = 0.34, outerLane = 0.66;
  double angSpeed = 1.6;     // rad/sec, ramps up
  double elapsed = 0, lastSpawn = 0, spawnGap = 1.1;
  final asteroids = <_Asteroid>[];
  final sparks = <_Spark>[];
  bool over = false, started = false;
  double best = 0;
  Duration lastTick = Duration.zero;

  double get shipX => cos(angle) * orbitR;
  double get shipY => sin(angle) * orbitR;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => best = p.getDouble('circlerush_best') ?? 0);
    });
    ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    if (!mounted || over) return;
    if (ModalRoute.of(context)?.isCurrent != true) {
      lastTick = now;
      return;
    }
    final dt = lastTick == Duration.zero ? 0.016 : (now - lastTick).inMicroseconds / 1e6;
    lastTick = now;
    final step = dt.clamp(0.0, 0.05);
    if (!started) {
      setState(() => angle += angSpeed * step * 0.4);
      return;
    }
    setState(() {
      elapsed += step;
      // ramp difficulty
      angSpeed = 1.6 + elapsed * 0.022;
      angle += angSpeed * step;
      orbitR += (targetOrbit - orbitR) * min(1.0, step * 10);
      spawnGap = max(0.32, 1.1 - elapsed * 0.012);
      lastSpawn += step;
      if (lastSpawn >= spawnGap) {
        lastSpawn = 0;
        _spawnAsteroid();
      }
      final sx = shipX, sy = shipY;
      for (final a in asteroids) {
        a.x += a.vx * step; a.y += a.vy * step; a.rot += a.spin * step;
        final dx = a.x - sx, dy = a.y - sy;
        if (dx * dx + dy * dy < (a.r + 0.045) * (a.r + 0.045)) {
          _crash();
          return;
        }
      }
      asteroids.removeWhere((a) => a.x * a.x + a.y * a.y > 1.9);
      // ship trail
      if (rng.nextDouble() < 0.5) {
        sparks.add(_Spark(sx, sy, (rng.nextDouble() - .5) * .2, (rng.nextDouble() - .5) * .2, 0.5));
      }
      for (final s in sparks) {
        s.x += s.vx * step; s.y += s.vy * step; s.life -= step;
      }
      sparks.removeWhere((s) => s.life <= 0);
    });
  }

  void _spawnAsteroid() {
    final th = rng.nextDouble() * 2 * pi;
    final tx = (rng.nextDouble() - .5) * 1.0, ty = (rng.nextDouble() - .5) * 1.0;
    final sx = cos(th) * 1.25, sy = sin(th) * 1.25;
    final dx = tx - sx, dy = ty - sy;
    final len = sqrt(dx * dx + dy * dy);
    final sp = 0.45 + rng.nextDouble() * 0.35 + elapsed * 0.004;
    asteroids.add(_Asteroid(
      sx, sy, dx / len * sp, dy / len * sp,
      0.05 + rng.nextDouble() * 0.055,
      List.generate(8, (_) => 0.75 + rng.nextDouble() * 0.5),
      rng.nextDouble() * 2 * pi, (rng.nextDouble() - .5) * 3,
    ));
  }

  void _onTap() {
    if (over) return;
    Sfx.tap();
    if (!started) {
      setState(() => started = true);
      return;
    }
    setState(() => targetOrbit = targetOrbit == innerLane ? outerLane : innerLane);
  }

  void _crash() {
    over = true;
    Sfx.lose();
    // explosion sparks
    for (int i = 0; i < 26; i++) {
      final th = rng.nextDouble() * 2 * pi;
      sparks.add(_Spark(shipX, shipY, cos(th) * (0.3 + rng.nextDouble() * .6),
          sin(th) * (0.3 + rng.nextDouble() * .6), 0.9));
    }
    final isBest = elapsed > best;
    if (isBest) {
      best = elapsed;
      SharedPreferences.getInstance().then((p) => p.setDouble('circlerush_best', best));
    }
    widget.players[0].score = elapsed.round();
    widget.callbacks.refreshHud();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      widget.callbacks.finish(
        headline: '💥 You survived ${elapsed.toStringAsFixed(1)}s!',
        subline: isBest ? '🏆 NEW BEST! The planet salutes you!' : 'Best: ${best.toStringAsFixed(1)}s — one more orbit?',
      );
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          TurnBanner(player: widget.players[0], action: over ? 'crashed!' : (started ? 'is dodging!' : 'tap to launch!')),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('⏱️ ${elapsed.toStringAsFixed(1)}s',
                    style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(width: 16),
                Text('🏆 ${best.toStringAsFixed(1)}s', style: TextStyle(color: t.muted, fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: _ArenaPainter(
                angle: angle, orbitR: orbitR, asteroids: asteroids, sparks: sparks,
                over: over, started: started, elapsed: elapsed,
                primary: t.primary, accent: t.accent, secondary: t.secondary,
                text: t.text, muted: t.muted, dark: t.dark,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text('👆 TAP to hop between the inner & outer orbit lanes!',
                style: TextStyle(color: t.muted, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ArenaPainter extends CustomPainter {
  final double angle, orbitR, elapsed;
  final List<_Asteroid> asteroids;
  final List<_Spark> sparks;
  final bool over, started;
  final Color primary, accent, secondary, text, muted;
  final bool dark;
  _ArenaPainter({required this.angle, required this.orbitR, required this.asteroids,
    required this.sparks, required this.over, required this.started, required this.elapsed,
    required this.primary, required this.accent, required this.secondary,
    required this.text, required this.muted, required this.dark});

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2;
    final u = min(s.width, s.height) / 2 * 0.96; // arena unit in px
    Offset pt(double x, double y) => Offset(cx + x * u, cy + y * u);

    // starfield
    final starPaint = Paint()..color = muted.withValues(alpha: .5);
    for (int i = 0; i < 40; i++) {
      final th = i * 2.39996, rr = (i * 37 % 100) / 100 * 1.2;
      c.drawCircle(pt(cos(th) * rr, sin(th) * rr), 1.4, starPaint);
    }
    // orbit lanes
    for (final lane in [_CircleRushScreenState.innerLane, _CircleRushScreenState.outerLane]) {
      c.drawCircle(Offset(cx, cy), lane * u,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 2
            ..color = primary.withValues(alpha: .35));
    }
    // planet with pulse
    final pulse = 1 + 0.04 * sin(elapsed * 3);
    final planetR = 0.20 * u * pulse;
    final pg = RadialGradient(colors: [accent, primary.withValues(alpha: .7)]);
    c.drawCircle(Offset(cx, cy), planetR,
        Paint()..shader = pg.createShader(Rect.fromCircle(center: Offset(cx, cy), radius: planetR)));
    // asteroids
    for (final a in asteroids) {
      final p = pt(a.x, a.y), r = a.r * u;
      final path = Path();
      for (int i = 0; i < 8; i++) {
        final th = a.rot + i / 8 * 2 * pi;
        final rr = r * a.wobble[i];
        final v = Offset(p.dx + cos(th) * rr, p.dy + sin(th) * rr);
        if (i == 0) {
          path.moveTo(v.dx, v.dy);
        } else {
          path.lineTo(v.dx, v.dy);
        }
      }
      path.close();
      c.drawPath(path, Paint()..color = dark ? const Color(0xFF6B5B4A) : const Color(0xFF8A7A66));
      c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = text.withValues(alpha: .4));
    }
    // sparks
    for (final sp in sparks) {
      c.drawCircle(pt(sp.x, sp.y), 3 * sp.life.clamp(0.0, 1.0),
          Paint()..color = secondary.withValues(alpha: sp.life.clamp(0.0, 1.0)));
    }
    // ship (triangle pointing tangentially)
    if (!over) {
      final p = pt(cos(angle) * orbitR, sin(angle) * orbitR);
      final dir = angle + pi / 2; // tangent
      const sz = 13.0;
      final nose = Offset(p.dx + cos(dir) * sz, p.dy + sin(dir) * sz);
      final l = Offset(p.dx + cos(dir + 2.5) * sz * 0.8, p.dy + sin(dir + 2.5) * sz * 0.8);
      final rr2 = Offset(p.dx + cos(dir - 2.5) * sz * 0.8, p.dy + sin(dir - 2.5) * sz * 0.8);
      final ship = Path()..moveTo(nose.dx, nose.dy)..lineTo(l.dx, l.dy)..lineTo(rr2.dx, rr2.dy)..close();
      c.drawPath(ship, Paint()..color = accent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      c.drawPath(ship, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = text);
      // flame
      final flame = 6 + 4 * sin(elapsed * 30);
      c.drawCircle(Offset(p.dx - cos(dir) * sz * 0.9, p.dy - sin(dir) * sz * 0.9),
          flame * 0.5, Paint()..color = secondary.withValues(alpha: .8));
    }
    if (!started && !over) {
      final tp = TextPainter(
        text: TextSpan(text: '👆 tap to launch!', style: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(c, Offset(cx - tp.width / 2, cy - planetR - 44));
    }
  }

  @override
  bool shouldRepaint(covariant _ArenaPainter o) => true;
}
