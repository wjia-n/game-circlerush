import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/orrery_themes.dart';
import '../theme/orrery_widgets.dart';
import 'pro_screen.dart';

/// Customization: 13 orrery themes, 10 orb styles + custom orb creator,
/// 12 ship styles. Pro content is locked with a clear upsell path.
class ThemesScreen extends StatefulWidget {
  final RushAudio audio;
  final RushSettings settings;
  final StoreService store;
  const ThemesScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.store});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  RushSettings get s => widget.settings;

  // A craftsman's palette for the custom creators.
  static const _palette = [
    0xFF1A0F08,
    0xFF3B2416,
    0xFF5C3A21,
    0xFFC9A227,
    0xFFE8CE7A,
    0xFF8A6D1A,
    0xFFF5EFE0,
    0xFF4A7FA5,
    0xFF8FB8D8,
    0xFF3E7A52,
    0xFF7FB069,
    0xFFA5512F,
    0xFFD98E5F,
    0xFF6E5FA3,
    0xFF9A8BD0,
    0xFF5DA9E9,
    0xFFBDE0FE,
    0xFFE07B39,
    0xFFFFD166,
    0xFF2B2B33,
    0xFF9AA3B5,
    0xFFB97A2A,
    0xFFE0A83C,
    0xFF4E7676,
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: s,
      builder: (_, _) {
        final t = s.theme;
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: t.deskDark,
            body: DeskBackdrop(
              theme: t,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
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
                          Text('WORKSHOP',
                              style: Orrery.display(26, theme: t)),
                        ],
                      ),
                    ),
                    TabBar(
                      labelColor: t.brassLight,
                      unselectedLabelColor: t.muted,
                      indicatorColor: t.brass,
                      labelStyle: Orrery.label(13, theme: t),
                      tabs: const [
                        Tab(text: 'THEMES'),
                        Tab(text: 'ORB'),
                        Tab(text: 'SHIP'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _themesTab(t),
                          _orbTab(t),
                          _shipTab(t),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------- themes
  Widget _themesTab(OrreryThemeDef t) {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.05,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: OrreryThemes.all.length + 1, // + custom
            itemBuilder: (_, i) {
              if (i < OrreryThemes.all.length) {
                final th = OrreryThemes.all[i];
                final locked = OrreryThemes.isProTheme(th.id) &&
                    !s.isPro;
                return _ThemeCard(
                  theme: th,
                  selected: s.themeId == th.id,
                  locked: locked,
                  onTap: () => _pickTheme(th.id, locked),
                );
              }
              return _ThemeCard(
                theme: s.customTheme,
                selected: s.themeId == 'custom',
                locked: !s.isPro,
                custom: true,
                onTap: () => _pickTheme('custom', !s.isPro),
              );
            },
          ),
          if (s.themeId == 'custom' && s.isPro) ...[
            const SizedBox(height: 16),
            Text('MY CREATION — COLORS',
                style: Orrery.label(12, theme: t)),
            const SizedBox(height: 8),
            BrassPanel(
              theme: t,
              child: Column(
                children: [
                  for (final key in OrreryThemes.customKeys)
                    _colorRow(
                      theme: t,
                      label: _pretty(key),
                      current:
                          s.customThemeColors[key] ?? 0xFF000000,
                      onPick: (c) =>
                          s.setCustomThemeColor(key, c),
                    ),
                  const SizedBox(height: 8),
                  BrassButton(
                    theme: t,
                    text: 'RESET COLORS',
                    fontSize: 14,
                    onTap: () {
                      widget.audio.click();
                      s.resetCustomTheme();
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  void _pickTheme(String id, bool locked) {
    widget.audio.click();
    if (locked) {
      _proNudge('That theme is Pro-only');
      return;
    }
    s.setTheme(id);
  }

  // ------------------------------------------------------------------- orb
  Widget _orbTab(OrreryThemeDef t) {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: OrbStyles.all.length + 1, // + custom
            itemBuilder: (_, i) {
              if (i < OrbStyles.all.length) {
                final o = OrbStyles.all[i];
                final locked = o.pro && !s.isPro;
                return _OrbCard(
                  theme: t,
                  orb: o,
                  selected: s.orbStyleId == o.id,
                  locked: locked,
                  onTap: () {
                    widget.audio.click();
                    if (locked) {
                      _proNudge('That orb is Pro-only');
                      return;
                    }
                    s.setOrbStyle(o.id);
                  },
                );
              }
              return _OrbCard(
                theme: t,
                orb: s.customOrb,
                selected: s.orbStyleId == 'custom',
                locked: !s.isPro,
                custom: true,
                onTap: () {
                  widget.audio.click();
                  if (!s.isPro) {
                    _proNudge('The orb creator is Pro-only');
                    return;
                  }
                  s.setOrbStyle('custom');
                },
              );
            },
          ),
          if (s.orbStyleId == 'custom' && s.isPro) ...[
            const SizedBox(height: 16),
            Text('MY ORB — COLORS',
                style: Orrery.label(12, theme: t)),
            const SizedBox(height: 8),
            BrassPanel(
              theme: t,
              child: Column(
                children: [
                  for (final key in OrbStyles.customKeys)
                    _colorRow(
                      theme: t,
                      label: _pretty(key),
                      current:
                          s.customOrbColors[key] ?? 0xFF000000,
                      onPick: (c) =>
                          s.setCustomOrbColor(key, c),
                    ),
                  const SizedBox(height: 8),
                  BrassButton(
                    theme: t,
                    text: 'RESET COLORS',
                    fontSize: 14,
                    onTap: () {
                      widget.audio.click();
                      s.resetCustomOrb();
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ ship
  Widget _shipTab(OrreryThemeDef t) {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.92,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: ShipStyles.all.length,
        itemBuilder: (_, i) {
          final sh = ShipStyles.all[i];
          final locked = sh.pro && !s.isPro;
          final selected = s.shipStyleId == sh.id;
          return GestureDetector(
            onTap: () {
              widget.audio.click();
              if (locked) {
                _proNudge('That ship is Pro-only');
                return;
              }
              s.setShipStyle(sh.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: selected
                    ? t.brass.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.3),
                border: Border.all(
                  color: selected
                      ? t.brassLight
                      : t.panelEdge.withValues(alpha: 0.4),
                  width: selected ? 2.5 : 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(52, 52),
                        painter: _ShipMini(
                            styleId: sh.id,
                            ivory: t.ivory,
                            brass: t.brass),
                      ),
                      const SizedBox(height: 6),
                      Text(sh.name,
                          textAlign: TextAlign.center,
                          style: Orrery.body(12, theme: t)
                              .copyWith(
                                  fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (locked)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(Icons.lock,
                          size: 15, color: t.brassLight),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _proNudge(String msg) {
    final t = s.theme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: Orrery.body(15, theme: t)),
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
                    store: widget.store),
              ),
            );
          },
        ),
      ),
    );
  }

  String _pretty(String key) {
    const names = {
      'deskDark': 'Desk shadow',
      'deskMid': 'Desk wood',
      'panel': 'Panel wood',
      'panelEdge': 'Panel trim',
      'brass': 'Brass',
      'brassLight': 'Brass highlight',
      'brassDark': 'Brass shadow',
      'text': 'Text',
      'ivory': 'Ivory',
      'rock': 'Rock',
      'rockDark': 'Rock shadow',
      'flame': 'Flame',
      'base': 'Orb base',
      'band': 'Orb bands',
      'pole': 'Orb pole',
    };
    return names[key] ?? key;
  }

  Widget _colorRow({
    required OrreryThemeDef theme,
    required String label,
    required int current,
    required ValueChanged<int> onPick,
  }) {
    final t = theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child:
                      Text(label, style: Orrery.body(14, theme: t))),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(current),
                  border: Border.all(
                      color: t.brassLight, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color:
                            Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 2),
                        blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final c in _palette)
                GestureDetector(
                  onTap: () {
                    widget.audio.click();
                    onPick(c);
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(c),
                      border: Border.all(
                        color: c == current
                            ? t.brassLight
                            : Colors.black.withValues(alpha: 0.3),
                        width: c == current ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final OrreryThemeDef theme;
  final bool selected;
  final bool locked;
  final bool custom;
  final VoidCallback onTap;
  const _ThemeCard({
    required this.theme,
    required this.selected,
    required this.locked,
    required this.onTap,
    this.custom = false,
  });

  @override
  Widget build(BuildContext context) {
    final th = theme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [th.panel, th.deskDark],
          ),
          border: Border.all(
            color: selected ? th.brassLight : th.panelEdge,
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: const Offset(0, 4),
                blurRadius: 8),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mini orrery preview.
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: th.brass, width: 3),
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                th.ivory,
                                Color.lerp(th.ivory, Colors.black, 0.35)!
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  custom ? 'My Creation' : th.name,
                  style: Orrery.body(13, theme: th).copyWith(
                      fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (locked)
              Positioned(
                top: 0,
                right: 0,
                child: ProLock(theme: th),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrbCard extends StatelessWidget {
  final OrreryThemeDef theme;
  final OrbStyleDef orb;
  final bool selected;
  final bool locked;
  final bool custom;
  final VoidCallback onTap;
  const _OrbCard({
    required this.theme,
    required this.orb,
    required this.selected,
    required this.locked,
    required this.onTap,
    this.custom = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: selected ? t.brassLight : t.panelEdge,
            width: selected ? 3 : 1.5,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center:
                              const Alignment(-0.35, -0.35),
                          colors: [
                            orb.pole,
                            orb.base,
                            Color.lerp(orb.base, Colors.black, 0.4)!
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.5),
                              offset: const Offset(0, 4),
                              blurRadius: 8),
                        ],
                      ),
                      child: orb.hasRings
                          ? CustomPaint(
                              painter: _RingMini(brass: t.brass))
                          : null,
                    ),
                  ),
                ),
                Text(
                  custom ? 'My Orb' : orb.name,
                  style: Orrery.body(13, theme: t).copyWith(
                      fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (locked)
              Positioned(
                top: 0,
                right: 0,
                child: ProLock(theme: t),
              ),
          ],
        ),
      ),
    );
  }
}

class _RingMini extends CustomPainter {
  final Color brass;
  _RingMini({required this.brass});
  @override
  void paint(Canvas c, Size s) {
    c.drawOval(
        Rect.fromCenter(
            center: Offset(s.width / 2, s.height / 2),
            width: s.width * 1.5,
            height: s.height * 0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = brass.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

/// Simplified ship preview for the picker.
class _ShipMini extends CustomPainter {
  final String styleId;
  final Color ivory, brass;
  _ShipMini(
      {required this.styleId, required this.ivory, required this.brass});

  @override
  void paint(Canvas c, Size s) {
    final p = Offset(s.width / 2, s.height / 2 + 4);
    const dir = -1.5708; // up
    Offset at(double ang, double r) =>
        Offset(p.dx + cos(ang) * r, p.dy + sin(ang) * r);
    final body = Paint()..color = ivory;
    final trim = Paint()..color = brass;
    final dark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.black.withValues(alpha: 0.5);
    void poly(List<Offset> pts, Paint fill) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      path.close();
      c.drawPath(path, fill);
      c.drawPath(path, dark);
    }

    const sz = 20.0;
    switch (styleId) {
      case 'dart':
        poly([at(dir, sz), at(dir + 2.9, sz * .55), at(dir - 2.9, sz * .55)], body);
      case 'comet':
        c.drawCircle(p, sz * .5, body);
        c.drawCircle(p, sz * .5, dark);
        poly([at(dir + pi, sz * .5), at(dir + 2.6, sz * 1.2), at(dir - 2.6, sz * 1.2)], trim);
      case 'saucer':
        c.drawOval(Rect.fromCenter(center: p, width: sz * 1.7, height: sz * .7), body);
        c.drawOval(Rect.fromCenter(center: p, width: sz * 1.7, height: sz * .7), dark);
        c.drawCircle(Offset(p.dx, p.dy - sz * .25), sz * .32, trim);
      case 'ring':
        c.drawCircle(p, sz * .7, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = brass);
        c.drawCircle(p, sz * .2, body);
      case 'teardrop':
        poly([at(dir, sz), at(dir + 1.6, sz * .6), at(dir + pi, sz * .5), at(dir - 1.6, sz * .6)], body);
      case 'gem':
        poly([at(dir, sz), at(dir + 1.7, sz * .5), at(dir + pi, sz * .65), at(dir - 1.7, sz * .5)], trim);
      case 'top':
        poly([at(dir, sz), at(dir + 2.6, sz * .55), at(dir - 2.6, sz * .55)], body);
        c.drawCircle(p, sz * .28, trim);
      case 'orrery':
        c.drawCircle(p, sz * .4, body);
        c.drawCircle(p, sz * .75, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = brass);
      case 'dragonfly':
        poly([at(dir, sz * .75), at(dir + 2.8, sz * .3), at(dir - 2.8, sz * .3)], body);
        for (final w in [0.9, -0.9]) {
          c.drawOval(Rect.fromCenter(center: at(dir + w, sz * .45), width: sz * 1.1, height: sz * .4), trim);
        }
      case 'saturnship':
        c.drawCircle(p, sz * .5, body);
        c.drawCircle(p, sz * .5, dark);
        c.drawOval(Rect.fromCenter(center: p, width: sz * 1.9, height: sz * .55),
            Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = brass);
      case 'kestrel':
        poly([at(dir, sz), at(dir + 2.2, sz * .85), at(dir + pi, sz * .2), at(dir - 2.2, sz * .85)], body);
        poly([at(dir + pi, sz * .15), at(dir + 2.7, sz * .45), at(dir - 2.7, sz * .45)], trim);
      case 'arrow':
      default:
        poly([at(dir, sz), at(dir + 2.5, sz * .75), at(dir - 2.5, sz * .75)], body);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
