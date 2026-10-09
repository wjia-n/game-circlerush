import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/orrery_themes.dart';
import '../theme/orrery_widgets.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'themes_screen.dart';

const _storeUrl =
    'https://play.google.com/store/apps/details?id=com.gameswajiha.circlerush';

/// Main menu: profile chip, mode + difficulty selection, best chips,
/// big brass PLAY button, dial buttons for themes/settings/pro/share.
class MenuScreen extends StatefulWidget {
  final RushAudio audio;
  final RushSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  RushSettings get s => widget.settings;
  OrreryThemeDef get _t => s.theme;
  final StoreService _store = StoreService();

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _store.init();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  void _play() {
    widget.audio.click();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(audio: widget.audio, settings: s),
      ),
    );
  }

  void _share() {
    widget.audio.click();
    SharePlus.instance.share(
        ShareParams(
            text: 'I\'m dodging asteroids in Circle Rush! Can you beat my orbit? 🪐\n$_storeUrl'));
  }

  String _modeName(RushMode m) => switch (m) {
        RushMode.endless => 'Endless Orbit',
        RushMode.rush60 => 'Rush 60',
        RushMode.blitz30 => 'Blitz 30',
      };

  String _modeDesc(RushMode m) => switch (m) {
        RushMode.endless => 'Survive as long as you can. One hit ends it.',
        RushMode.rush60 =>
          '60 seconds. Near misses +10. Survive it all for +100!',
        RushMode.blitz30 =>
          '30 seconds of pure chaos. Faster rocks, denser storm.',
      };

  String _bestLine(RushMode m) {
    final b = s.bestFor(m);
    if (m == RushMode.endless) {
      return b == 0 ? 'No best yet' : 'Best: ${b.toStringAsFixed(1)}s';
    }
    return b == 0 ? 'No best yet' : 'Best: $b pts';
  }

  String _diffName(Difficulty d) => switch (d) {
        Difficulty.drifter => 'Drifter',
        Difficulty.voyager => 'Voyager',
        Difficulty.cometchaser => 'Cometchaser',
        Difficulty.nova => 'Nova',
      };

  String _diffDesc(Difficulty d) => switch (d) {
        Difficulty.drifter => 'Gentle — learn the lanes',
        Difficulty.voyager => 'Brisk — the classic rush',
        Difficulty.cometchaser => 'Fierce — Pro tier',
        Difficulty.nova => 'Relentless — Pro tier',
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: s,
      builder: (_, _) {
        final t = _t;
        return Scaffold(
          backgroundColor: t.deskDark,
          body: DeskBackdrop(
            theme: t,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Column(
                  children: [
                    // Profile chip.
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          widget.audio.click();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                  audio: widget.audio, settings: s),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.black.withValues(alpha: 0.35),
                            border: Border.all(color: t.panelEdge),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person,
                                  size: 15, color: t.brassLight),
                              const SizedBox(width: 6),
                              Text(s.playerName,
                                  style: Orrery.body(14,
                                      theme: t, color: t.ivory)),
                              const SizedBox(width: 4),
                              Icon(Icons.edit,
                                  size: 13, color: t.muted),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: t.brass, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            offset: const Offset(0, 8),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset('assets/circlerush_logo.png',
                          fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                    Text('CIRCLE RUSH',
                        style: Orrery.display(40, theme: t)),
                    Text('DODGE THE STORM, RIDE THE RING',
                        style: Orrery.label(11, theme: t)),
                    const SizedBox(height: 16),
                    BrassPanel(
                      theme: t,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MODE',
                              style: Orrery.label(12, theme: t)),
                          const SizedBox(height: 8),
                          for (final m in RushMode.values)
                            _ModeCard(
                              theme: t,
                              selected: s.mode == m,
                              name: _modeName(m),
                              desc: _modeDesc(m),
                              best: _bestLine(m),
                              onTap: () {
                                widget.audio.click();
                                s.setMode(m);
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    BrassPanel(
                      theme: t,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DIFFICULTY',
                              style: Orrery.label(12, theme: t)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final d in Difficulty.values)
                                _DiffChip(
                                  theme: t,
                                  selected: s.difficulty == d,
                                  name: _diffName(d),
                                  desc: _diffDesc(d),
                                  locked:
                                      !s.isPro && d.index > 1,
                                  onTap: () {
                                    widget.audio.click();
                                    if (!s.isPro && d.index > 1) {
                                      _proNudge();
                                      return;
                                    }
                                    s.setDifficulty(d);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    BrassButton(
                        theme: t, text: '▶  PLAY', onTap: _play),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        DialButton(
                          theme: t,
                          icon: Icons.palette,
                          onTap: () {
                            widget.audio.click();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ThemesScreen(
                                    audio: widget.audio,
                                    settings: s,
                                    store: _store),
                              ),
                            );
                          },
                        ),
                        DialButton(
                          theme: t,
                          icon: Icons.settings,
                          onTap: () {
                            widget.audio.click();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SettingsScreen(
                                    audio: widget.audio, settings: s),
                              ),
                            );
                          },
                        ),
                        DialButton(
                          theme: t,
                          icon: Icons.workspace_premium,
                          badge: s.isPro ? null : 'PRO',
                          onTap: () {
                            widget.audio.click();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProScreen(
                                    audio: widget.audio,
                                    settings: s,
                                    store: _store),
                              ),
                            );
                          },
                        ),
                        DialButton(
                          theme: t,
                          icon: Icons.share,
                          onTap: _share,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/wajiha_logo.png',
                            width: 22, height: 22, fit: BoxFit.contain),
                        const SizedBox(width: 8),
                        Text('Credits: WAJIHA',
                            style: Orrery.label(11, theme: t)),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _proNudge() {
    final t = _t;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('That tier is Pro-only — take a look!',
            style: Orrery.body(15, theme: t)),
        backgroundColor: t.panel,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'PRO',
          textColor: t.brassLight,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProScreen(
                    audio: widget.audio,
                    settings: s,
                    store: _store),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final OrreryThemeDef theme;
  final bool selected;
  final String name, desc, best;
  final VoidCallback onTap;
  const _ModeCard({
    required this.theme,
    required this.selected,
    required this.name,
    required this.desc,
    required this.best,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? t.brass.withValues(alpha: 0.22)
              : Colors.black.withValues(alpha: 0.25),
          border: Border.all(
            color: selected ? t.brassLight : t.panelEdge.withValues(alpha: 0.4),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: t.brass.withValues(alpha: 0.25),
                      offset: const Offset(0, 3),
                      blurRadius: 10)
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Orrery.body(16, theme: t)
                          .copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style:
                          Orrery.body(12, theme: t, color: t.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(best,
                style: Orrery.label(11, theme: t)),
          ],
        ),
      ),
    );
  }
}

class _DiffChip extends StatelessWidget {
  final OrreryThemeDef theme;
  final bool selected;
  final String name, desc;
  final bool locked;
  final VoidCallback onTap;
  const _DiffChip({
    required this.theme,
    required this.selected,
    required this.name,
    required this.desc,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: desc,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? t.brass
                : Colors.black.withValues(alpha: 0.3),
            border: Border.all(
                color: selected ? t.brassDark : t.panelEdge, width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 3),
                  blurRadius: 6),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locked)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.lock,
                      size: 13, color: Color(0xFF241309)),
                ),
              Text(name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? const Color(0xFF241309)
                        : t.ivory,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
