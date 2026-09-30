import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'azkar_alias_registry.dart';

/// Centralized persistence and state notification for Azkar and Duas user preferences.
class AzkarPreferencesStore {
  AzkarPreferencesStore([this._prefs, this._aliases]) {
    final savedFavorites = _prefs?.getStringList(_keyFavoriteDuas) ?? const [];
    _favoritesNotifier = ValueNotifier<Set<String>>(Set<String>.from(savedFavorites));

    final savedAutoAdvance = _prefs?.getBool(_keyAutoAdvance) ?? true;
    _autoAdvanceNotifier = ValueNotifier<bool>(savedAutoAdvance);

    final savedFontScale = _prefs?.getDouble(_keyFontScale) ?? 1.0;
    _fontScaleNotifier = ValueNotifier<double>(savedFontScale);

    _quietNightNotifier = ValueNotifier<bool>(_prefs?.getBool(_keyQuietNight) ?? false);
  }

  static const _keyFavoriteDuas = 'azkar_favorite_duas';
  static const _keyAutoAdvance = 'azkar_auto_advance';
  static const _keyFontScale = 'azkar_font_scale';
  static const _keyTasbeehTarget = 'azkar_tasbeeh_target';
  static const _keyQuietNight = 'azkar_quiet_night';

  final SharedPreferences? _prefs;
  final AzkarAliasRegistry? _aliases;
  int _inMemoryTasbeehTarget = 33;

  late final ValueNotifier<Set<String>> _favoritesNotifier;
  late final ValueNotifier<bool> _autoAdvanceNotifier;
  late final ValueNotifier<double> _fontScaleNotifier;
  late final ValueNotifier<bool> _quietNightNotifier;

  // ─── Favorites ─────────────────────────────────────────────────────────────
  ValueListenable<Set<String>> get favoritesListenable => _favoritesNotifier;

  Set<String> getFavoriteDuaIds() => Set.unmodifiable(_favoritesNotifier.value);

  bool isFavorite(String id) {
    final favorites = _favoritesNotifier.value;
    if (favorites.contains(id)) return true;
    final aliases = _aliases?.aliasesOf(id) ?? const <String>{};
    return aliases.any(favorites.contains);
  }

  /// Toggles [id]. A record with hidden duplicate copies is one favorite: the
  /// visible id is written and every copy id is cleared on removal.
  Future<bool> toggleFavorite(String id) async {
    final aliases = _aliases?.aliasesOf(id) ?? const <String>{};
    final updated = Set<String>.from(_favoritesNotifier.value);
    final wasFavorite = updated.contains(id) || aliases.any(updated.contains);
    updated
      ..remove(id)
      ..removeAll(aliases);
    if (!wasFavorite) updated.add(id);
    _favoritesNotifier.value = updated;

    await _prefs?.setStringList(_keyFavoriteDuas, updated.toList());
    return !wasFavorite;
  }

  // ─── Auto-Advance ──────────────────────────────────────────────────────
  ValueListenable<bool> get autoAdvanceListenable => _autoAdvanceNotifier;

  bool getAutoAdvance() => _autoAdvanceNotifier.value;

  Future<void> setAutoAdvance(bool enabled) async {
    await _prefs?.setBool(_keyAutoAdvance, enabled);
    _autoAdvanceNotifier.value = enabled;
  }

  // ─── Font Scale ────────────────────────────────────────────────────
  ValueListenable<double> get fontScaleListenable => _fontScaleNotifier;

  double getFontScale() => _fontScaleNotifier.value;

  Future<void> setFontScale(double scale) async {
    await _prefs?.setDouble(_keyFontScale, scale);
    _fontScaleNotifier.value = scale;
  }

  // ─── Free Tasbeeh Target ───────────────────────────────────────────
  int getLastTasbeehTarget() =>
      _prefs?.getInt(_keyTasbeehTarget) ?? _inMemoryTasbeehTarget;

  Future<void> setLastTasbeehTarget(int target) async {
    _inMemoryTasbeehTarget = target;
    await _prefs?.setInt(_keyTasbeehTarget, target);
  }

  // ─── Quiet Night Mode ──────────────────────────────────────────────
  ValueListenable<bool> get quietNightListenable => _quietNightNotifier;

  bool getQuietNight() => _quietNightNotifier.value;

  Future<void> setQuietNight(bool enabled) async {
    await _prefs?.setBool(_keyQuietNight, enabled);
    _quietNightNotifier.value = enabled;
  }

  // ─── Daily Tasbeeh Tally ───────────────────────────────────────────
  String _tasbeehDayKey(DateTime now) => '${now.year}-${now.month}-${now.day}';

  int getTasbeehTally([DateTime? now]) {
    if (_prefs == null) return 0;
    final day = _tasbeehDayKey(now ?? DateTime.now());
    return _prefs.getInt('$_keyTasbeehPrefix$day') ?? 0;
  }

  Future<void> bumpTasbeehTally([DateTime? now]) async {
    if (_prefs == null) return;
    final day = _tasbeehDayKey(now ?? DateTime.now());
    final current = _prefs.getInt('$_keyTasbeehPrefix$day') ?? 0;
    await _prefs.setInt('$_keyTasbeehPrefix$day', current + 1);
  }

  static const _keyTasbeehPrefix = 'azkar_tasbeeh_tally_';
}
