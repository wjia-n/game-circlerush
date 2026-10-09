import 'package:flutter/material.dart';

/// Art direction: "The Celestial Orrery" — a hand-built brass orrery on a
/// craftsman's desk. Pseudo-3D physical materials: walnut panels, polished
/// brass rings, marble/ivory celestial bodies, soft shadows. No neon, no
/// cyberpunk, no holographic or AI-dashboard looks — everything must feel
/// like a real physical object you could touch.
///
/// 13 themes: 4 free starters, 9 Pro (incl. the custom theme creator).
class OrreryThemeDef {
  final String id;
  final String name;
  final Color deskDark;
  final Color deskMid;
  final Color panel;
  final Color panelEdge;
  final Color brass;
  final Color brassLight;
  final Color brassDark;
  final Color text;
  final Color muted;
  final Color ivory;
  final Color rock;
  final Color rockDark;
  final Color flame;
  final Color flameCore;
  final Color star;

  const OrreryThemeDef({
    required this.id,
    required this.name,
    required this.deskDark,
    required this.deskMid,
    required this.panel,
    required this.panelEdge,
    required this.brass,
    required this.brassLight,
    required this.brassDark,
    required this.text,
    required this.muted,
    required this.ivory,
    required this.rock,
    required this.rockDark,
    required this.flame,
    required this.flameCore,
    required this.star,
  });
}

class OrreryThemes {
  /// Free starter themes. Everything else (incl. 'custom') is Pro.
  static const List<String> freeThemeIds = [
    'classic',
    'walnut',
    'observatory',
    'emerald',
  ];

  static bool isProTheme(String id) => !freeThemeIds.contains(id);

  static const List<OrreryThemeDef> all = [
    OrreryThemeDef(
      id: 'classic',
      name: 'Classic Orrery',
      deskDark: Color(0xFF1A0F08),
      deskMid: Color(0xFF3B2416),
      panel: Color(0xFF4A2F1B),
      panelEdge: Color(0xFFC9A227),
      brass: Color(0xFFC9A227),
      brassLight: Color(0xFFE8CE7A),
      brassDark: Color(0xFF8A6D1A),
      text: Color(0xFFF5EFE0),
      muted: Color(0xFFB8A88E),
      ivory: Color(0xFFF5EFE0),
      rock: Color(0xFF8A7A66),
      rockDark: Color(0xFF4A4036),
      flame: Color(0xFFE07B39),
      flameCore: Color(0xFFFFD166),
      star: Color(0xFFFFF6DC),
    ),
    OrreryThemeDef(
      id: 'walnut',
      name: 'Dark Walnut Study',
      deskDark: Color(0xFF0D0805),
      deskMid: Color(0xFF2A1A10),
      panel: Color(0xFF33200F),
      panelEdge: Color(0xFFD4AF37),
      brass: Color(0xFFD4AF37),
      brassLight: Color(0xFFF3DC8E),
      brassDark: Color(0xFF96702A),
      text: Color(0xFFF8F1E2),
      muted: Color(0xFFA89880),
      ivory: Color(0xFFF8F1E2),
      rock: Color(0xFF7A6A58),
      rockDark: Color(0xFF3D352B),
      flame: Color(0xFFD95D39),
      flameCore: Color(0xFFFFC53D),
      star: Color(0xFFFDEBC8),
    ),
    OrreryThemeDef(
      id: 'observatory',
      name: 'Midnight Observatory',
      deskDark: Color(0xFF0A0E1C),
      deskMid: Color(0xFF1C2438),
      panel: Color(0xFF232C44),
      panelEdge: Color(0xFFC0C6D4),
      brass: Color(0xFFC0C6D4),
      brassLight: Color(0xFFE8ECF5),
      brassDark: Color(0xFF7E8698),
      text: Color(0xFFF2EEE4),
      muted: Color(0xFF9AA3B5),
      ivory: Color(0xFFF2EEE4),
      rock: Color(0xFF6E7688),
      rockDark: Color(0xFF3A3F4D),
      flame: Color(0xFF5DA9E9),
      flameCore: Color(0xFFBDE0FE),
      star: Color(0xFFFFFFFF),
    ),
    OrreryThemeDef(
      id: 'emerald',
      name: 'Emerald Reading Room',
      deskDark: Color(0xFF0E1A12),
      deskMid: Color(0xFF2E3B22),
      panel: Color(0xFF3A4A2C),
      panelEdge: Color(0xFFB9975B),
      brass: Color(0xFFB9975B),
      brassLight: Color(0xFFE3C888),
      brassDark: Color(0xFF7E5F33),
      text: Color(0xFFF4F0E4),
      muted: Color(0xFFA9AE98),
      ivory: Color(0xFFF4F0E4),
      rock: Color(0xFF7C8474),
      rockDark: Color(0xFF454A40),
      flame: Color(0xFF7FB069),
      flameCore: Color(0xFFD8F3A2),
      star: Color(0xFFF2F5DF),
    ),
    OrreryThemeDef(
      id: 'ivory',
      name: 'Ivory Salon',
      deskDark: Color(0xFF4A4238),
      deskMid: Color(0xFFEFE6D4),
      panel: Color(0xFFF8F1E2),
      panelEdge: Color(0xFF8A6D1A),
      brass: Color(0xFF8A6D1A),
      brassLight: Color(0xFFC9A227),
      brassDark: Color(0xFF5C4A12),
      text: Color(0xFF2B2118),
      muted: Color(0xFF7A6C5C),
      ivory: Color(0xFF2B2118),
      rock: Color(0xFF9A8A76),
      rockDark: Color(0xFF5C5346),
      flame: Color(0xFFD95D39),
      flameCore: Color(0xFFFFC53D),
      star: Color(0xFF8A7A5C),
    ),
    OrreryThemeDef(
      id: 'copper',
      name: 'Copper Foundry',
      deskDark: Color(0xFF170B06),
      deskMid: Color(0xFF4A2413),
      panel: Color(0xFF5A2C16),
      panelEdge: Color(0xFFD98E5F),
      brass: Color(0xFFD98E5F),
      brassLight: Color(0xFFF2B88F),
      brassDark: Color(0xFF8A4E2E),
      text: Color(0xFFF9EFE4),
      muted: Color(0xFFC4A68C),
      ivory: Color(0xFFF9EFE4),
      rock: Color(0xFF8C6E5A),
      rockDark: Color(0xFF4C3B30),
      flame: Color(0xFFE07B39),
      flameCore: Color(0xFFFFE08A),
      star: Color(0xFFFFE8CC),
    ),
    OrreryThemeDef(
      id: 'ocean',
      name: "Cartographer's Ocean",
      deskDark: Color(0xFF08141A),
      deskMid: Color(0xFF17323E),
      panel: Color(0xFF1E3E4C),
      panelEdge: Color(0xFF7FB5B5),
      brass: Color(0xFF7FB5B5),
      brassLight: Color(0xFFB8D8D8),
      brassDark: Color(0xFF4E7676),
      text: Color(0xFFF0F6F2),
      muted: Color(0xFF9AB8B8),
      ivory: Color(0xFFF0F6F2),
      rock: Color(0xFF6E7F86),
      rockDark: Color(0xFF3C474C),
      flame: Color(0xFF5DA9E9),
      flameCore: Color(0xFFBDE0FE),
      star: Color(0xFFE8F4F4),
    ),
    OrreryThemeDef(
      id: 'wine',
      name: 'Wine Cellar',
      deskDark: Color(0xFF150809),
      deskMid: Color(0xFF3D1F2E),
      panel: Color(0xFF4C2638),
      panelEdge: Color(0xFFC9A227),
      brass: Color(0xFFC9A227),
      brassLight: Color(0xFFE8CE7A),
      brassDark: Color(0xFF8A6D1A),
      text: Color(0xFFF5ECE4),
      muted: Color(0xFFB89E9E),
      ivory: Color(0xFFF5ECE4),
      rock: Color(0xFF7C6468),
      rockDark: Color(0xFF45363A),
      flame: Color(0xFFE07B39),
      flameCore: Color(0xFFFFD166),
      star: Color(0xFFFFEBDC),
    ),
    OrreryThemeDef(
      id: 'dune',
      name: 'Desert Surveyor',
      deskDark: Color(0xFF1A1006),
      deskMid: Color(0xFF4A3A1E),
      panel: Color(0xFF5A4826),
      panelEdge: Color(0xFFE0A83C),
      brass: Color(0xFFE0A83C),
      brassLight: Color(0xFFF3CE7A),
      brassDark: Color(0xFF96702A),
      text: Color(0xFFF9F2E2),
      muted: Color(0xFFC4B28A),
      ivory: Color(0xFFF9F2E2),
      rock: Color(0xFF9A8264),
      rockDark: Color(0xFF5C4E38),
      flame: Color(0xFFD95D39),
      flameCore: Color(0xFFFFE08A),
      star: Color(0xFFFFF2D8),
    ),
    OrreryThemeDef(
      id: 'slate',
      name: 'Slate Laboratory',
      deskDark: Color(0xFF0C0D10),
      deskMid: Color(0xFF2A2D33),
      panel: Color(0xFF34383F),
      panelEdge: Color(0xFF9AA3B5),
      brass: Color(0xFF9AA3B5),
      brassLight: Color(0xFFC6CDD9),
      brassDark: Color(0xFF5E6470),
      text: Color(0xFFF2F4F6),
      muted: Color(0xFFA6ACB8),
      ivory: Color(0xFFF2F4F6),
      rock: Color(0xFF757B86),
      rockDark: Color(0xFF41454D),
      flame: Color(0xFF7FB069),
      flameCore: Color(0xFFD8F3A2),
      star: Color(0xFFF4F6FA),
    ),
    OrreryThemeDef(
      id: 'autumn',
      name: 'Autumn Workshop',
      deskDark: Color(0xFF170D06),
      deskMid: Color(0xFF4A2A14),
      panel: Color(0xFF5A3418),
      panelEdge: Color(0xFFD99A2B),
      brass: Color(0xFFD99A2B),
      brassLight: Color(0xFFF2C66E),
      brassDark: Color(0xFF8A5F1A),
      text: Color(0xFFF9F0E0),
      muted: Color(0xFFC4A87E),
      ivory: Color(0xFFF9F0E0),
      rock: Color(0xFF8C6E52),
      rockDark: Color(0xFF4C3D2E),
      flame: Color(0xFFE07B39),
      flameCore: Color(0xFFFFE08A),
      star: Color(0xFFFFEBD0),
    ),
    OrreryThemeDef(
      id: 'rosewood',
      name: 'Rosewood Chamber',
      deskDark: Color(0xFF120608),
      deskMid: Color(0xFF331419),
      panel: Color(0xFF421A21),
      panelEdge: Color(0xFFE3A68A),
      brass: Color(0xFFE3A68A),
      brassLight: Color(0xFFF5CBB5),
      brassDark: Color(0xFF8A5F4C),
      text: Color(0xFFF9EDE6),
      muted: Color(0xFFC4A294),
      ivory: Color(0xFFF9EDE6),
      rock: Color(0xFF7E645F),
      rockDark: Color(0xFF463835),
      flame: Color(0xFFE07B39),
      flameCore: Color(0xFFFFD166),
      star: Color(0xFFFFE6DA),
    ),
    OrreryThemeDef(
      id: 'porcelain',
      name: 'Porcelain Cabinet',
      deskDark: Color(0xFF2E3436),
      deskMid: Color(0xFFDDE3E0),
      panel: Color(0xFFEDEFF0),
      panelEdge: Color(0xFF4E7676),
      brass: Color(0xFF4E7676),
      brassLight: Color(0xFF7FB5B5),
      brassDark: Color(0xFF2E4A4A),
      text: Color(0xFF1E2A28),
      muted: Color(0xFF6E7A78),
      ivory: Color(0xFF1E2A28),
      rock: Color(0xFF8C9694),
      rockDark: Color(0xFF525C5A),
      flame: Color(0xFFD95D39),
      flameCore: Color(0xFFFFC53D),
      star: Color(0xFF5E6A68),
    ),
  ];

  /// Look up a theme by id; 'custom' resolves to the user-built theme.
  static OrreryThemeDef byId(String id, {OrreryThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static List<OrreryThemeDef> get catalog => all;

  /// Keys editable in the custom theme creator (Pro).
  static const List<String> customKeys = [
    'deskDark',
    'deskMid',
    'panel',
    'panelEdge',
    'brass',
    'brassLight',
    'brassDark',
    'text',
    'ivory',
    'rock',
    'rockDark',
    'flame',
  ];

  static Map<String, int> get defaultCustomColors => {
        'deskDark': 0xFF1A0F08,
        'deskMid': 0xFF3B2416,
        'panel': 0xFF4A2F1B,
        'panelEdge': 0xFFC9A227,
        'brass': 0xFFC9A227,
        'brassLight': 0xFFE8CE7A,
        'brassDark': 0xFF8A6D1A,
        'text': 0xFFF5EFE0,
        'ivory': 0xFFF5EFE0,
        'rock': 0xFF8A7A66,
        'rockDark': 0xFF4A4036,
        'flame': 0xFFE07B39,
      };

  /// Build the user-designed custom theme from stored ARGB ints.
  static OrreryThemeDef buildCustom(Map<String, int> colors) {
    Color c(String k) => Color(colors[k] ?? 0xFF000000);
    final base = all.first;
    return OrreryThemeDef(
      id: 'custom',
      name: 'My Creation',
      deskDark: c('deskDark'),
      deskMid: c('deskMid'),
      panel: c('panel'),
      panelEdge: c('panelEdge'),
      brass: c('brass'),
      brassLight: c('brassLight'),
      brassDark: c('brassDark'),
      text: c('text'),
      muted: c('text').withValues(alpha: 0.65),
      ivory: c('ivory'),
      rock: c('rock'),
      rockDark: c('rockDark'),
      flame: c('flame'),
      flameCore: base.flameCore,
      star: c('ivory'),
    );
  }
}

/// Orb styles: the planet at the center of the arena. 10 styles — 4 free,
/// 6 Pro — plus a custom orb creator (Pro).
class OrbStyleDef {
  final String id;
  final String name;
  final Color base;
  final Color band;
  final Color pole;
  final bool hasRings;
  final bool pro;

  const OrbStyleDef({
    required this.id,
    required this.name,
    required this.base,
    required this.band,
    required this.pole,
    this.hasRings = false,
    this.pro = false,
  });
}

class OrbStyles {
  static const List<OrbStyleDef> all = [
    OrbStyleDef(
        id: 'marble',
        name: 'Blue Marble',
        base: Color(0xFF4A7FA5),
        band: Color(0xFF8FB8D1),
        pole: Color(0xFFDDEAF2)),
    OrbStyleDef(
        id: 'rust',
        name: 'Rust Mars',
        base: Color(0xFFA5512F),
        band: Color(0xFFD98E5F),
        pole: Color(0xFFF2D5B8)),
    OrbStyleDef(
        id: 'jade',
        name: 'Jade Orb',
        base: Color(0xFF3E7A52),
        band: Color(0xFF7FB069),
        pole: Color(0xFFD8EFD0)),
    OrbStyleDef(
        id: 'amber',
        name: 'Amber Eye',
        base: Color(0xFFB97A2A),
        band: Color(0xFFE0A83C),
        pole: Color(0xFFF7E3B5)),
    OrbStyleDef(
        id: 'onyx',
        name: 'Onyx Pearl',
        base: Color(0xFF2B2B33),
        band: Color(0xFF5E6470),
        pole: Color(0xFFC6CDD9),
        pro: true),
    OrbStyleDef(
        id: 'opal',
        name: 'Opal Dream',
        base: Color(0xFF7FB5B5),
        band: Color(0xFFB8D8D8),
        pole: Color(0xFFF0FAF8),
        pro: true),
    OrbStyleDef(
        id: 'lava',
        name: 'Lava Heart',
        base: Color(0xFF8A2E1B),
        band: Color(0xFFE07B39),
        pole: Color(0xFFFFD166),
        pro: true),
    OrbStyleDef(
        id: 'ice',
        name: 'Ice Comet',
        base: Color(0xFF5DA9E9),
        band: Color(0xFFBDE0FE),
        pole: Color(0xFFFFFFFF),
        pro: true),
    OrbStyleDef(
        id: 'saturn',
        name: 'Ringed Giant',
        base: Color(0xFFB9975B),
        band: Color(0xFFE3C888),
        pole: Color(0xFFF7ECD2),
        hasRings: true,
        pro: true),
    OrbStyleDef(
        id: 'comet',
        name: 'Comet Crown',
        base: Color(0xFF6E5FA3),
        band: Color(0xFF9A8BD0),
        pole: Color(0xFFE8E2FA),
        hasRings: true,
        pro: true),
  ];

  static OrbStyleDef byId(String id, {OrbStyleDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final s in all) {
      if (s.id == id) return s;
    }
    return all.first;
  }

  /// Keys editable in the custom orb creator (Pro).
  static const List<String> customKeys = ['base', 'band', 'pole'];

  static Map<String, int> get defaultCustomOrb => {
        'base': 0xFF4A7FA5,
        'band': 0xFF8FB8D1,
        'pole': 0xFFDDEAF2,
      };

  static OrbStyleDef buildCustom(Map<String, int> colors) {
    Color c(String k) => Color(colors[k] ?? 0xFF000000);
    return OrbStyleDef(
      id: 'custom',
      name: 'My Orb',
      base: c('base'),
      band: c('band'),
      pole: c('pole'),
    );
  }
}

/// Ship styles: how the player's craft is drawn. 12 styles — 8 free, 4 Pro.
class ShipStyleDef {
  final String id;
  final String name;
  final bool pro;

  const ShipStyleDef({required this.id, required this.name, this.pro = false});
}

class ShipStyles {
  static const List<ShipStyleDef> all = [
    ShipStyleDef(id: 'arrow', name: 'Arrow'),
    ShipStyleDef(id: 'dart', name: 'Dart'),
    ShipStyleDef(id: 'comet', name: 'Comet'),
    ShipStyleDef(id: 'saucer', name: 'Saucer'),
    ShipStyleDef(id: 'ring', name: 'Ring Runner'),
    ShipStyleDef(id: 'teardrop', name: 'Teardrop'),
    ShipStyleDef(id: 'gem', name: 'Gem Cutter'),
    ShipStyleDef(id: 'top', name: 'Spinning Top'),
    ShipStyleDef(id: 'orrery', name: 'Brass Orrery', pro: true),
    ShipStyleDef(id: 'dragonfly', name: 'Dragonfly', pro: true),
    ShipStyleDef(id: 'saturnship', name: 'Saturn Class', pro: true),
    ShipStyleDef(id: 'kestrel', name: 'Kestrel', pro: true),
  ];

  static ShipStyleDef byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return all.first;
  }

  static bool isPro(String id) => byId(id).pro;
}
