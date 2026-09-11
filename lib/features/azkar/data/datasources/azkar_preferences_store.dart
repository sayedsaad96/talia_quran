import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized persistence and state notification for Azkar and Duas user preferences.
class AzkarPreferencesStore {
  AzkarPreferencesStore([this._prefs]) {
    final savedFavorites = _prefs?.getStringList(_keyFavoriteDuas) ?? const [];
    _favoritesNotifier = ValueNotifier<Set<String>>(Set<String>.from(savedFavorites));

    final savedAutoAdvance = _prefs?.getBool(_keyAutoAdvance) ?? true;
    _autoAdvanceNotifier = ValueNotifier<bool>(savedAutoAdvance);

    final savedFontScale = _prefs?.getDouble(_keyFontScale) ?? 1.0;
    _fontScaleNotifier = ValueNotifier<double>(savedFontScale);
  }

  static const _keyFavoriteDuas = 'azkar_favorite_duas';
  static const _keyAutoAdvance = 'azkar_auto_advance';
  static const _keyFontScale = 'azkar_font_scale';
  static const _keyTasbeehTarget = 'azkar_tasbeeh_target';

  final SharedPreferences? _prefs;
  int _inMemoryTasbeehTarget = 33;

  late final ValueNotifier<Set<String>> _favoritesNotifier;
  late final ValueNotifier<bool> _autoAdvanceNotifier;
  late final ValueNotifier<double> _fontScaleNotifier;

  // ─── Favorites ─────────────────────────────────────────────────────────────
  ValueListenable<Set<String>> get favoritesListenable => _favoritesNotifier;

  Set<String> getFavoriteDuaIds() => Set.unmodifiable(_favoritesNotifier.value);

  bool isFavorite(String id) => _favoritesNotifier.value.contains(id);

  Future<bool> toggleFavorite(String id) async {
    final updated = Set<String>.from(_favoritesNotifier.value);
    final isNowFavorite = updated.contains(id) ? !updated.remove(id) : updated.add(id);
    _favoritesNotifier.value = updated;

    await _prefs?.setStringList(_keyFavoriteDuas, updated.toList());
    return isNowFavorite;
  }

  // ─── Auto-Advance ──────────────────────────────────────────────────────────
  ValueListenable<bool> get autoAdvanceListenable => _autoAdvanceNotifier;

  bool getAutoAdvance() => _autoAdvanceNotifier.value;

  Future<void> setAutoAdvance(bool enabled) async {
    await _prefs?.setBool(_keyAutoAdvance, enabled);
    _autoAdvanceNotifier.value = enabled;
  }

  // ─── Font Scale ────────────────────────────────────────────────────────────
  ValueListenable<double> get fontScaleListenable => _fontScaleNotifier;

  double getFontScale() => _fontScaleNotifier.value;

  Future<void> setFontScale(double scale) async {
    await _prefs?.setDouble(_keyFontScale, scale);
    _fontScaleNotifier.value = scale;
  }

  // ─── Free Tasbeeh Target ───────────────────────────────────────────────────
  int getLastTasbeehTarget() =>
      _prefs?.getInt(_keyTasbeehTarget) ?? _inMemoryTasbeehTarget;

  Future<void> setLastTasbeehTarget(int target) async {
    _inMemoryTasbeehTarget = target;
    await _prefs?.setInt(_keyTasbeehTarget, target);
  }
}
