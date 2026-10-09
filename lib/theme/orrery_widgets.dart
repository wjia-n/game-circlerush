import 'package:flutter/material.dart';
import 'orrery_themes.dart';

/// Shared text + pseudo-3D physical UI components for the Celestial Orrery
/// art direction: chunky panels, brass trim, soft drop shadows, beveled
/// buttons that look like real machined controls.
class Orrery {
  static TextStyle display(double size,
      {required OrreryThemeDef theme, Color? color}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color ?? theme.text,
      letterSpacing: 1.2,
      shadows: [
        Shadow(
            color: Colors.black.withValues(alpha: 0.55),
            offset: const Offset(0, 3),
            blurRadius: 6),
      ],
    );
  }

  static TextStyle label(double size,
      {required OrreryThemeDef theme, Color? color}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color ?? theme.brassLight,
      letterSpacing: 2.0,
    );
  }

  static TextStyle body(double size,
      {required OrreryThemeDef theme, Color? color}) {
    return TextStyle(
      fontSize: size,
      color: color ?? theme.text,
      height: 1.35,
    );
  }
}

/// Desk backdrop: dark gradient + vignette, like a craftsman's desk.
class DeskBackdrop extends StatelessWidget {
  final OrreryThemeDef theme;
  final Widget child;
  const DeskBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.25),
          radius: 1.4,
          colors: [theme.deskMid, theme.deskDark],
        ),
      ),
      child: child,
    );
  }
}

/// A chunky wooden panel with a brass edge and a soft drop shadow.
class BrassPanel extends StatelessWidget {
  final OrreryThemeDef theme;
  final Widget child;
  final EdgeInsets padding;
  const BrassPanel({
    super.key,
    required this.theme,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.panel,
            Color.lerp(theme.panel, Colors.black, 0.18)!,
          ],
        ),
        border: Border.all(color: theme.panelEdge, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
          BoxShadow(
            color: theme.brassLight.withValues(alpha: 0.12),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A chunky machined-brass button with press feedback.
class BrassButton extends StatefulWidget {
  final OrreryThemeDef theme;
  final String text;
  final VoidCallback? onTap;
  final double fontSize;
  final bool wide;
  const BrassButton({
    super.key,
    required this.theme,
    required this.text,
    required this.onTap,
    this.fontSize = 20,
    this.wide = true,
  });

  @override
  State<BrassButton> createState() => _BrassButtonState();
}

class _BrassButtonState extends State<BrassButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.wide ? double.infinity : null,
        padding: EdgeInsets.symmetric(
            horizontal: 26, vertical: _down ? 12 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _down
                ? [t.brassDark, t.brass]
                : [t.brassLight, t.brass, t.brassDark],
          ),
          border: Border.all(color: t.brassDark, width: 2),
          boxShadow: _down
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      offset: const Offset(0, 2),
                      blurRadius: 6)
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      offset: const Offset(0, 6),
                      blurRadius: 12),
                  BoxShadow(
                      color: t.brassLight.withValues(alpha: 0.35),
                      offset: const Offset(0, 1),
                      blurRadius: 2),
                ],
        ),
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: const Color(0xFF241309),
            shadows: [
              Shadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  offset: const Offset(0, 1),
                  blurRadius: 1),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round brass icon button (machined dial look).
class DialButton extends StatelessWidget {
  final OrreryThemeDef theme;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  const DialButton({
    super.key,
    required this.theme,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.panel, Color.lerp(t.panel, Colors.black, 0.25)!],
              ),
              border: Border.all(color: t.panelEdge, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 5),
                    blurRadius: 10),
              ],
            ),
            child: Icon(icon, color: t.brassLight, size: 26),
          ),
          if (badge != null)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: t.brass,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.brassDark),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF241309))),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small "PRO" lock badge shown on locked premium content.
class ProLock extends StatelessWidget {
  final OrreryThemeDef theme;
  const ProLock({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.brass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.brassDark),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 2),
              blurRadius: 4),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 12, color: Color(0xFF241309)),
          SizedBox(width: 3),
          Text('PRO',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF241309))),
        ],
      ),
    );
  }
}
