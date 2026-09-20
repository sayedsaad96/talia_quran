import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/prayer_companion.dart';

/// SharedPreferences-backed store for the opt-in Companion settings.
///
/// Every key uses the `prayer_companion_` prefix, which
/// `AccountDataReset.clearedPreferencePrefixes` clears on account reset.
class PrayerCompanionPreferences {
  const PrayerCompanionPreferences(this._prefs);

  static const enabledKey = 'prayer_companion_enabled';
  static const preparationMinutesKey = 'prayer_companion_preparation_minutes';
  static const checkInEnabledKey = 'prayer_companion_check_in_enabled';
  static const followUpEnabledKey = 'prayer_companion_follow_up_enabled';

  /// Minutes before the prayer that are allowed for the preparation
  /// reminder. 0 disables it and is the default.
  static const allowedPreparationMinutes = {0, 5, 10, 15};

  final SharedPreferences _prefs;

  PrayerCompanionSettings read() => PrayerCompanionSettings(
    enabled: _prefs.getBool(enabledKey) ?? false,
    preparationMinutes: _readPreparationMinutes(),
    checkInEnabled: _prefs.getBool(checkInEnabledKey) ?? true,
    followUpEnabled: _prefs.getBool(followUpEnabledKey) ?? true,
  );

  int _readPreparationMinutes() {
    final value = _prefs.getInt(preparationMinutesKey) ?? 0;
    // A stale or corrupted value falls back to disabled rather than
    // tripping the PrayerCompanionSettings assertion.
    return allowedPreparationMinutes.contains(value) ? value : 0;
  }

  Future<void> write(PrayerCompanionSettings settings) async {
    await _prefs.setBool(enabledKey, settings.enabled);
    await _prefs.setInt(preparationMinutesKey, settings.preparationMinutes);
    await _prefs.setBool(checkInEnabledKey, settings.checkInEnabled);
    await _prefs.setBool(followUpEnabledKey, settings.followUpEnabled);
  }
}
