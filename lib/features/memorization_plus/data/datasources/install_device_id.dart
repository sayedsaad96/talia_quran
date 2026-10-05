import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Stable per-install identifier (UUID v4), shared by every server call that
/// must tell this device apart from the child's other devices.
abstract final class InstallDeviceId {
  static const key = 'family_activity_device_id';

  static Future<String> read(SharedPreferences prefs, {Random? random}) async {
    final existing = prefs.getString(key);
    if (existing != null) return existing;
    final rng = random ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final id =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
    await prefs.setString(key, id);
    return id;
  }
}
