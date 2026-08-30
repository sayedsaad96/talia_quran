import 'package:shared_preferences/shared_preferences.dart';

/// Durable owner marker used only while an unsynced bookmark must survive an
/// account switch after forced sign-out.
abstract final class PendingBookmarkRecoveryMarker {
  static const _keyPrefix = 'pending_bookmark_recovery_owner_';

  static bool contains(SharedPreferences prefs, String ownerId) =>
      prefs.getBool('$_keyPrefix$ownerId') == true;

  static Future<void> mark(SharedPreferences prefs, String ownerId) =>
      prefs.setBool('$_keyPrefix$ownerId', true);

  static Future<void> clear(SharedPreferences prefs, String ownerId) =>
      prefs.remove('$_keyPrefix$ownerId');

  static Set<String> ownerIds(SharedPreferences prefs) => prefs
      .getKeys()
      .where((key) => key.startsWith(_keyPrefix))
      .where((key) => prefs.getBool(key) == true)
      .map((key) => key.substring(_keyPrefix.length))
      .where((ownerId) => ownerId.isNotEmpty)
      .toSet();
}
