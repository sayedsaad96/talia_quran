import 'package:shared_preferences/shared_preferences.dart';

/// A pending encrypted checkpoint must survive ordinary sign-out/account reset.
/// Actual account deletion always clears this marker and the encrypted record.
abstract final class PendingCheckpointRecoveryMarker {
  static String keyFor(String ownerId) =>
      'pending_checkpoint_recovery_owner_$ownerId';
  static bool contains(SharedPreferences prefs, String ownerId) =>
      prefs.getBool(keyFor(ownerId)) == true;
  static Future<void> mark(SharedPreferences prefs, String ownerId) async {
    if (contains(prefs, ownerId)) return;
    if (!await prefs.setBool(keyFor(ownerId), true)) {
      throw StateError('Checkpoint recovery marker could not be saved');
    }
  }

  static Future<void> clear(SharedPreferences prefs, String ownerId) async {
    if (prefs.containsKey(keyFor(ownerId)) &&
        !await prefs.remove(keyFor(ownerId))) {
      throw StateError('Checkpoint recovery marker could not be cleared');
    }
  }
}
