import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/orrery_themes.dart';
import '../theme/orrery_widgets.dart';

/// Settings: renameable pilot profile, music/SFX toggles, volume,
/// best-score reset, about.
class SettingsScreen extends StatefulWidget {
  final RushAudio audio;
  final RushSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameCtrl;
  late final FocusNode _nameFocus;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.settings.playerName);
    _nameFocus = FocusNode();
    // Commit the pending name whenever the field loses focus — a typed
    // name is never lost even if the user navigates away without pressing
    // the check button or keyboard-done.
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && mounted) {
        widget.settings.setPlayerName(_nameCtrl.text);
      }
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    // Final commit in case the field still had focus.
    widget.settings.setPlayerName(_nameCtrl.text);
    _nameCtrl.dispose();
    super.dispose();
  }

  void _applyAudio() {
    widget.audio.configure(
      musicOn: widget.settings.musicOn,
      sfxOn: widget.settings.sfxOn,
      volume: widget.settings.volume,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final t = widget.settings.theme;
        final s = widget.settings;
        return Scaffold(
          backgroundColor: t.deskDark,
          body: DeskBackdrop(
            theme: t,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DialButton(
                          theme: t,
                          icon: Icons.arrow_back,
                          onTap: () {
                            widget.audio.click();
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 12),
                        Text('SETTINGS',
                            style: Orrery.display(26, theme: t)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    BrassPanel(
                      theme: t,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PILOT PROFILE',
                              style: Orrery.label(12, theme: t)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameCtrl,
                            focusNode: _nameFocus,
                            maxLength: 18,
                            style: Orrery.body(17, theme: t),
                            // Save on EVERY keystroke — never wait for
                            // keyboard-done or the check button.
                            onChanged: (v) => s.setPlayerName(v),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'Your pilot name',
                              hintStyle: Orrery.body(15,
                                  theme: t, color: t.muted),
                              filled: true,
                              fillColor:
                                  Colors.black.withValues(alpha: 0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: t.panelEdge),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: t.panelEdge),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.check,
                                    color: t.brassLight),
                                onPressed: () {
                                  widget.audio.click();
                                  s.setPlayerName(_nameCtrl.text);
                                  FocusScope.of(context).unfocus();
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'Pilot name saved!',
                                        style: Orrery.body(14,
                                            theme: t)),
                                    backgroundColor: t.panel,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(
                                        milliseconds: 900),
                                  ));
                                },
                              ),
                            ),
                            onSubmitted: (v) {
                              widget.audio.click();
                              s.setPlayerName(v);
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
                          Text('AUDIO',
                              style: Orrery.label(12, theme: t)),
                          _ToggleRow(
                            theme: t,
                            label: 'Music',
                            value: s.musicOn,
                            onChanged: (v) {
                              s.setMusic(v);
                              _applyAudio();
                            },
                          ),
                          _ToggleRow(
                            theme: t,
                            label: 'Sound effects',
                            value: s.sfxOn,
                            onChanged: (v) {
                              s.setSfx(v);
                              _applyAudio();
                            },
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.volume_up,
                                  color: t.brassLight),
                              Expanded(
                                child: Slider(
                                  value: s.volume,
                                  activeColor: t.brass,
                                  inactiveColor: t.panelEdge
                                      .withValues(alpha: 0.4),
                                  onChanged: (v) {
                                    s.setVolume(v);
                                    _applyAudio();
                                  },
                                ),
                              ),
                            ],
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
                          Text('RECORDS',
                              style: Orrery.label(12, theme: t)),
                          const SizedBox(height: 8),
                          Text(
                            'Games flown: ${s.gamesPlayed}   ·   Victories: ${s.wins}',
                            style: Orrery.body(14, theme: t),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Best Endless: ${s.bestEndless.toStringAsFixed(1)}s   ·   '
                            'Best Rush 60: ${s.bestRush60} pts   ·   '
                            'Best Blitz 30: ${s.bestBlitz30} pts',
                            style: Orrery.body(13,
                                theme: t, color: t.muted),
                          ),
                          const SizedBox(height: 10),
                          BrassButton(
                            theme: t,
                            text: 'RESET ALL RECORDS',
                            fontSize: 15,
                            onTap: () async {
                              widget.audio.click();
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: t.panel,
                                  title: Text('Reset records?',
                                      style: Orrery.display(20,
                                          theme: t)),
                                  content: Text(
                                      'All best scores and stats will be erased.',
                                      style: Orrery.body(14,
                                          theme: t)),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context)
                                              .pop(false),
                                      child: Text('CANCEL',
                                          style: Orrery.label(13,
                                              theme: t)),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context)
                                              .pop(true),
                                      child: Text('RESET',
                                          style: Orrery.label(13,
                                              theme: t,
                                              color: Colors
                                                  .redAccent)),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) s.resetBests();
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
                          Text('ABOUT',
                              style: Orrery.label(12, theme: t)),
                          const SizedBox(height: 8),
                          Text(
                            'Circle Rush — dodge the asteroid storm and ride the brass rings of the celestial orrery.\n\n'
                            'Tap to hop between the inner and outer orbit lanes. Graze a rock for +10. One hit and you\'re stardust.',
                            style: Orrery.body(14, theme: t),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('assets/wajiha_logo.png',
                                  width: 26,
                                  height: 26,
                                  fit: BoxFit.contain),
                              const SizedBox(width: 8),
                              Text('Credits: WAJIHA',
                                  style:
                                      Orrery.label(12, theme: t)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final OrreryThemeDef theme;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.theme,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Row(
      children: [
        Expanded(
            child: Text(label, style: Orrery.body(16, theme: t))),
        Switch(
          value: value,
          activeThumbColor: t.brassLight,
          activeTrackColor: t.brassDark,
          inactiveTrackColor:
              Colors.black.withValues(alpha: 0.4),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
