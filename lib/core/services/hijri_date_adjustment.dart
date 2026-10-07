import 'package:shared_preferences/shared_preferences.dart';

/// The user's Hijri date adjustment, in days.
///
/// The `hijri` package computes the tabular Umm al-Qura calendar, while many
/// countries start months on a local sighting that can differ by a day or
/// two. Only Hijri-derived labels and occasions shift; Gregorian dates,
/// weekdays and prayer times never do.
class HijriDateAdjustment {
  HijriDateAdjustment(this._prefs);

  static const preferenceKey = 'hijri_day_offset';
  static const minDays = -2;
  static const maxDays = 2;

  final SharedPreferences _prefs;

  int get days =>
      (_prefs.getInt(preferenceKey) ?? 0).clamp(minDays, maxDays).toInt();

  Future<void> setDays(int days) =>
      _prefs.setInt(preferenceKey, days.clamp(minDays, maxDays).toInt());
}
