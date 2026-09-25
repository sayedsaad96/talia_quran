import 'package:shared_preferences/shared_preferences.dart';

/// Internal migration state for the prayer delivery pipeline (V2 §21/§22).
///
/// This is NOT a user-facing feature flag. It records which delivery owner
/// currently holds the prayer alarms:
///
///   1 = legacy FLN (`flutter_local_notifications`, IDs 2000–2039)
///   2 = native Android delivery (AlarmManager, IDs 2200–2499)
///
/// V2 is persisted ONLY after a verified successful native scheduling
/// round-trip; any failure keeps the value at 1 so the legacy fallback
/// remains the active owner.
abstract final class PrayerDeliveryVersion {
  /// Legacy FLN delivery (current production behavior).
  static const int legacy = 1;

  /// Native Android delivery via PrayerDeliveryScheduler.
  static const int nativeAndroidV2 = 2;

  /// SharedPreferences key. New installs default to [legacy] until the
  /// migration flow explicitly promotes them.
  static const String prefsKey = 'prayer_delivery_version';

  /// Reads the persisted version, defaulting to [legacy].
  static int read(SharedPreferences prefs) =>
      prefs.getInt(prefsKey) ?? legacy;

  /// Persists a new version. Callers must only write [nativeAndroidV2]
  /// after verifying native scheduling succeeded (§22 step 5–6).
  static Future<void> save(SharedPreferences prefs, int version) =>
      prefs.setInt(prefsKey, version);
}