import 'package:shared_preferences/shared_preferences.dart';

import '../experience/rollout_manifest.dart';

/// Gradual rollout switch for the rebuilt kids memorization journey.
abstract final class KidsHifzFeatureFlags {
  static const enabledKey = 'kids_hifz_v2_enabled';

  /// A stored value wins; otherwise the shipped default in [RolloutManifest].
  static bool isEnabled(SharedPreferences prefs) =>
      prefs.getBool(enabledKey) ?? RolloutManifest.defaultFor(enabledKey);

  /// Switch for the selectable Quran-wide kids journey. On by default
  /// (owner decision 2026-10-18, recorded in [RolloutManifest]); the Juz Amma
  /// adventure stays the default path until a guardian picks the Quran
  /// journey. Off hides the choice and keeps every child on the adventure.
  static const quranJourneyKey = 'kids_quran_journey_enabled';

  static bool isQuranJourneyEnabled(SharedPreferences prefs) =>
      prefs.getBool(quranJourneyKey) ??
      RolloutManifest.defaultFor(quranJourneyKey);
}
