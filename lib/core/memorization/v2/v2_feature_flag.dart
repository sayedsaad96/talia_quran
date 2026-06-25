// lib/core/memorization/v2/v2_feature_flag.dart

import 'package:shared_preferences/shared_preferences.dart';

/// V2 feature flags — Product Rules §7 (backward compatibility).
///
/// When a flag is OFF, the legacy flow runs unchanged.
/// Flags are stored in [SharedPreferences] (default: false).
abstract final class V2FeatureFlag {
  static const _keyAdult = 'enable_memorization_v2';
  static const _keyKids = 'enable_memorization_v2_kids';

  /// Whether the adult Memorization V2 flow is enabled.
  static Future<bool> isAdultEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAdult) ?? false;
  }

  /// Whether the kids Memorization V2 flow is enabled (Phase G).
  static Future<bool> isKidsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyKids) ?? false;
  }

  /// For testing / developer tools: toggle V2 adult flag.
  static Future<void> setAdultEnabled({required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdult, enabled);
  }

  /// For testing / developer tools: toggle V2 kids flag.
  static Future<void> setKidsEnabled({required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyKids, enabled);
  }
}
