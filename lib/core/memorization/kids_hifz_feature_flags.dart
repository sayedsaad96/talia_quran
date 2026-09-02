import 'package:shared_preferences/shared_preferences.dart';

/// Gradual rollout switch for the rebuilt kids memorization journey.
abstract final class KidsHifzFeatureFlags {
  static const enabledKey = 'kids_hifz_v2_enabled';

  /// Existing installations remain on their selected experience until the
  /// rollout explicitly enables V2. Safety and privacy fixes are shared.
  static bool isEnabled(SharedPreferences prefs) =>
      prefs.getBool(enabledKey) ?? false;
}
