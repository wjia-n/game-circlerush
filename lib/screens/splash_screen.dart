import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/orrery_themes.dart';
import '../theme/orrery_widgets.dart';
import 'menu_screen.dart';

/// Launch splash: a WAJIHA company moment, then the game splash
/// (game logo + name + animated loading line + "Credits: WAJIHA").
class SplashScreen extends StatefulWidget {
  final RushAudio audio;
  final RushSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyShown = false;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the splash shows, then start menu music.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    // Company moment: the official WAJIHA mark, briefly and reverently.
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _companyShown = true);
    // Game splash: logo + name + animated loading line.
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.theme;
    return Scaffold(
      backgroundColor: theme.deskDark,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        // Company moment first, then the game splash.
        child: _companyShown
            ? _GameSplash(theme: theme, loader: _loader)
            : _CompanySplash(theme: theme),
      ),
    );
  }
}

/// Company moment: the official WAJIHA winged-W mark, centered, with a
/// gentle fade-in. The logo asset is copied unchanged — never redrawn.
class _CompanySplash extends StatefulWidget {
  final OrreryThemeDef theme;
  const _CompanySplash({required this.theme});

  @override
  State<_CompanySplash> createState() => _CompanySplashState();
}

class _CompanySplashState extends State<_CompanySplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DeskBackdrop(
      theme: widget.theme,
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/wajiha_logo.png',
                width: 130,
                height: 130,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 18),
              Text('WAJIHA', style: Orrery.display(34, theme: widget.theme)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final OrreryThemeDef theme;
  final AnimationController loader;
  const _GameSplash({required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return DeskBackdrop(
      theme: theme,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.brass, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/circlerush_logo.png',
                  fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text('CIRCLE RUSH', style: Orrery.display(46, theme: theme)),
            const SizedBox(height: 6),
            Text(
              'THE CELESTIAL ORRERY',
              style: Orrery.label(13, theme: theme),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                            color: theme.brass.withValues(alpha: 0.5)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: [
                                theme.brassLight,
                                theme.brass,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loader.value < 1
                          ? 'Winding the orrery…'
                          : 'Ready!',
                      style: Orrery.body(13,
                          theme: theme,
                          color: theme.muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: Orrery.label(14, theme: theme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
