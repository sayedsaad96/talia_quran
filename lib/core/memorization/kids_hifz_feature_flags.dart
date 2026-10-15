import 'package:shared_preferences/shared_preferences.dart';

/// Gradual rollout switch for the rebuilt kids memorization journey.
abstract final class KidsHifzFeatureFlags {
  static const enabledKey = 'kids_hifz_v2_enabled';

  /// Existing installations remain on their selected experience until the
  /// rollout explicitly enables V2. Safety and privacy fixes are shared.
  static bool isEnabled(SharedPreferences prefs) =>
      prefs.getBool(enabledKey) ?? false;

  /// Switch for the selectable Quran-wide kids journey; off keeps the
  /// Juz Amma adventure.
  static const quranJourneyKey = 'kids_quran_journey_enabled';

  static bool isQuranJourneyEnabled(SharedPreferences prefs) =>
      prefs.getBool(quranJourneyKey) ?? false;
}
