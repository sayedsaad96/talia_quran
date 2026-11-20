import 'package:shared_preferences/shared_preferences.dart';

/// Which home-widget sections to draw. Device chrome, not account data:
/// switching accounts clears the snapshot, then the next refresh copies these
/// same choices onto the new owner's snapshot.
final class WidgetSectionPreferences {
  WidgetSectionPreferences(this._prefs);

  static const prayerKey = 'talia_widget_show_prayer';
  static const reviewsKey = 'talia_widget_show_reviews';
  static const wirdKey = 'talia_widget_show_wird';
  static const hijriKey = 'talia_widget_show_hijri';

  final SharedPreferences _prefs;

  bool get showPrayer => _prefs.getBool(prayerKey) ?? true;
  bool get showReviews => _prefs.getBool(reviewsKey) ?? true;
  bool get showWird => _prefs.getBool(wirdKey) ?? true;
  bool get showHijri => _prefs.getBool(hijriKey) ?? true;

  int get visibleCount =>
      (showPrayer ? 1 : 0) +
      (showReviews ? 1 : 0) +
      (showWird ? 1 : 0) +
      (showHijri ? 1 : 0);

  bool get hasAnyVisible => visibleCount > 0;

  Future<void> setShowPrayer(bool value) => _prefs.setBool(prayerKey, value);
  Future<void> setShowReviews(bool value) => _prefs.setBool(reviewsKey, value);
  Future<void> setShowWird(bool value) => _prefs.setBool(wirdKey, value);
  Future<void> setShowHijri(bool value) => _prefs.setBool(hijriKey, value);

  Future<void> resetToDefaults() async {
    await _prefs.remove(prayerKey);
    await _prefs.remove(reviewsKey);
    await _prefs.remove(wirdKey);
    await _prefs.remove(hijriKey);
  }
}
