import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/orrery_themes.dart';

/// Game modes.
enum RushMode { endless, rush60, blitz30 }

/// Difficulty tiers. Drifter + Voyager are free; Cometchaser + Nova are Pro.
enum Difficulty { drifter, voyager, cometchaser, nova }

/// Persisted settings + stats for Circle Rush. Survives app restarts.
///
/// The player profile (name) is stored as ONE JSON string. Android's
/// SharedPreferences stores StringLists as an unordered StringSet, so ordered
/// data must NEVER use setStringList — the JSON-string approach preserves
/// exact order and content.
class RushSettings extends ChangeNotifier {
  static const _kMusic = 'circlerush_music_on';
  static const _kSfx = 'circlerush_sfx_on';
  static const _kVolume = 'circlerush_volume';
  /// Player names: ONE order-preserving JSON string. NEVER use
  /// setStringList — Android stores StringLists as an unordered StringSet,
  /// which scrambles names across slots on every restart.
  static const _kProfileJson = 'circlerush_player_names_json';
  // Legacy keys (one-time migration, then removed):
  static const _kLegacyProfileJson = 'circlerush_profile_json';
  static const _kLegacyName = 'circlerush_player_name';
  static const _kLegacyBest = 'circlerush_best';
  static const _kTheme = 'circlerush_theme_id';
  static const _kOrb = 'circlerush_orb_style';
  static const _kShip = 'circlerush_ship_style';
  static const _kDifficulty = 'circlerush_difficulty';
  static const _kMode = 'circlerush_mode';
  static const _kCustomTheme = 'circlerush_custom_theme_json';
  static const _kCustomOrb = 'circlerush_custom_orb_json';
  static const _kIsPro = 'circlerush_is_pro';
  static const _kGames = 'circlerush_games_played';
  static const _kWins = 'circlerush_wins';
  static const _kBestEndless = 'circlerush_best_endless';
  static const _kBestRush60 = 'circlerush_best_rush60';
  static const _kBestBlitz30 = 'circlerush_best_blitz30';

  static const defaultName = 'Star Pilot';

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String playerName = defaultName;
  String themeId = 'classic';
  String orbStyleId = 'marble';
  String shipStyleId = 'arrow';
  Difficulty difficulty = Difficulty.drifter;
  RushMode mode = RushMode.endless;
  bool isPro = false;
  int gamesPlayed = 0;
  int wins = 0;
  double bestEndless = 0; // seconds
  int bestRush60 = 0; // score
  int bestBlitz30 = 0; // score

  /// Custom theme colors (ARGB ints).
  Map<String, int> customThemeColors = Map.of(OrreryThemes.defaultCustomColors);

  /// Custom orb colors (ARGB ints).
  Map<String, int> customOrbColors = Map.of(OrbStyles.defaultCustomOrb);

  OrreryThemeDef get customTheme => OrreryThemes.buildCustom(customThemeColors);
  OrbStyleDef get customOrb => OrbStyles.buildCustom(customOrbColors);

  OrreryThemeDef get theme =>
      OrreryThemes.byId(themeId, custom: isPro ? customTheme : null);
  OrbStyleDef get orb =>
      OrbStyles.byId(orbStyleId, custom: isPro ? customOrb : null);
  ShipStyleDef get ship => ShipStyles.byId(shipStyleId);

  SharedPreferences? _prefs;

  /// Encode the player profile as an order-preserving JSON list string.
  /// A single-entry list today keeps the slot ordering model safe if a
  /// pass-and-play multi-pilot profile is added later.
  static String encodeProfile(String name) =>
      jsonEncode({'names': [name], 'v': 1});

  static String decodeProfileName(String? raw) {
    if (raw == null) return defaultName;
    try {
      final d = jsonDecode(raw);
      if (d is Map) {
        // New format: {'names': [...]}.
        final names = d['names'];
        if (names is List && names.isNotEmpty) {
          final n = (names.first as String? ?? '').trim();
          if (n.isNotEmpty) return n;
        }
        // Fallback: older single-name format {'name': ...}.
        final n = (d['name'] as String? ?? '').trim();
        if (n.isNotEmpty) return n;
      }
    } catch (_) {}
    return defaultName;
  }

  static Map<String, int> _decodeColorMap(
      String? raw, Map<String, int> fallback) {
    if (raw == null) return Map.of(fallback);
    try {
      final d = jsonDecode(raw);
      if (d is Map) {
        final out = Map.of(fallback);
        for (final e in d.entries) {
          final v = e.value;
          if (v is int && out.containsKey(e.key)) out[e.key] = v;
        }
        return out;
      }
    } catch (_) {}
    return Map.of(fallback);
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;

    // Profile: prefer the order-safe JSON key; migrate legacy keys once.
    var raw = p.getString(_kProfileJson);
    if (raw == null) {
      final legacyJson = p.getString(_kLegacyProfileJson);
      if (legacyJson != null) {
        final migrated = decodeProfileName(legacyJson);
        if (migrated != defaultName) playerName = migrated;
        raw = encodeProfile(playerName);
        await p.setString(_kProfileJson, raw);
      } else {
        final legacy = p.getString(_kLegacyName);
        if (legacy != null && legacy.trim().isNotEmpty) {
          playerName = legacy.trim();
          raw = encodeProfile(playerName);
          await p.setString(_kProfileJson, raw);
        }
      }
      await p.remove(_kLegacyProfileJson);
      await p.remove(_kLegacyName);
    }
    playerName = decodeProfileName(raw ?? p.getString(_kProfileJson));

    themeId = p.getString(_kTheme) ?? 'classic';
    orbStyleId = p.getString(_kOrb) ?? 'marble';
    shipStyleId = p.getString(_kShip) ?? 'arrow';
    difficulty =
        Difficulty.values[(p.getInt(_kDifficulty) ?? 0).clamp(0, 3)];
    mode = RushMode.values[(p.getInt(_kMode) ?? 0).clamp(0, 2)];
    isPro = p.getBool(_kIsPro) ?? false;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    wins = p.getInt(_kWins) ?? 0;
    // Migrate the old v1 single "best" key into best_endless if empty.
    final legacyBest = p.getDouble(_kLegacyBest);
    bestEndless = p.getDouble(_kBestEndless) ?? 0;
    if (bestEndless == 0 && legacyBest != null && legacyBest > 0) {
      bestEndless = legacyBest;
    }
    await p.remove(_kLegacyBest);
    bestRush60 = p.getInt(_kBestRush60) ?? 0;
    bestBlitz30 = p.getInt(_kBestBlitz30) ?? 0;
    customThemeColors = _decodeColorMap(
        p.getString(_kCustomTheme), OrreryThemes.defaultCustomColors);
    customOrbColors =
        _decodeColorMap(p.getString(_kCustomOrb), OrbStyles.defaultCustomOrb);
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kProfileJson, encodeProfile(playerName));
    await p.setString(_kTheme, themeId);
    await p.setString(_kOrb, orbStyleId);
    await p.setString(_kShip, shipStyleId);
    await p.setInt(_kDifficulty, difficulty.index);
    await p.setInt(_kMode, mode.index);
    await p.setBool(_kIsPro, isPro);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kWins, wins);
    await p.setDouble(_kBestEndless, bestEndless);
    await p.setInt(_kBestRush60, bestRush60);
    await p.setInt(_kBestBlitz30, bestBlitz30);
    await p.setString(_kCustomTheme, jsonEncode(customThemeColors));
    await p.setString(_kCustomOrb, jsonEncode(customOrbColors));
  }

  /// Free-tier limits: clamp Pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || OrreryThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (orbStyleId == 'custom' ||
        OrbStyles.byId(orbStyleId).pro) {
      orbStyleId = 'marble';
      changed = true;
    }
    if (ShipStyles.isPro(shipStyleId)) {
      shipStyleId = 'arrow';
      changed = true;
    }
    if (difficulty.index > 1) {
      difficulty = Difficulty.voyager;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(String name) async {
    final clean = name.trim();
    playerName = clean.isEmpty ? defaultName : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || OrreryThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setOrbStyle(String id) async {
    if (!isPro && (id == 'custom' || OrbStyles.byId(id).pro)) return;
    orbStyleId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setShipStyle(String id) async {
    if (!isPro && ShipStyles.isPro(id)) return;
    shipStyleId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(Difficulty d) async {
    if (!isPro && d.index > 1) return; // hard tiers are Pro
    difficulty = d;
    notifyListeners();
    await _save();
  }

  Future<void> setMode(RushMode m) async {
    mode = m;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomThemeColor(String key, int argb) async {
    if (!isPro) return;
    if (!OrreryThemes.customKeys.contains(key)) return;
    customThemeColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomTheme() async {
    customThemeColors = Map.of(OrreryThemes.defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setCustomOrbColor(String key, int argb) async {
    if (!isPro) return;
    if (!OrbStyles.customKeys.contains(key)) return;
    customOrbColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomOrb() async {
    customOrbColors = Map.of(OrbStyles.defaultCustomOrb);
    notifyListeners();
    await _save();
  }

  /// Best score for a mode: endless = seconds (double), others = int score.
  num bestFor(RushMode m) => switch (m) {
        RushMode.endless => bestEndless,
        RushMode.rush60 => bestRush60,
        RushMode.blitz30 => bestBlitz30,
      };

  /// Record a finished run. Returns true if it was a new best.
  Future<bool> recordRun({
    required RushMode m,
    required double seconds,
    required int score,
    required bool won,
  }) async {
    gamesPlayed++;
    if (won) wins++;
    var isBest = false;
    switch (m) {
      case RushMode.endless:
        if (seconds > bestEndless) {
          bestEndless = seconds;
          isBest = true;
        }
      case RushMode.rush60:
        if (score > bestRush60) {
          bestRush60 = score;
          isBest = true;
        }
      case RushMode.blitz30:
        if (score > bestBlitz30) {
          bestBlitz30 = score;
          isBest = true;
        }
    }
    notifyListeners();
    await _save();
    return isBest;
  }

  Future<void> resetBests() async {
    bestEndless = 0;
    bestRush60 = 0;
    bestBlitz30 = 0;
    gamesPlayed = 0;
    wins = 0;
    notifyListeners();
    await _save();
  }
}
