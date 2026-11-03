import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// No backup, path, PIN or other user data is staged across process restarts.
class RestoreRequestStore {
  const RestoreRequestStore(this._prefs);
  final SharedPreferences _prefs;
  static const key = 'restore_cold_request_v1';

  Future<String?> pendingId() async {
    await _prefs.reload();
    final value = _prefs.get(key);
    if (value == null) return null;
    if (value is! String || !RegExp(r'^[a-f0-9-]{36}$').hasMatch(value)) {
      throw const FormatException('Invalid maintenance request');
    }
    return value;
  }

  Future<String> schedule() async {
    final id = const Uuid().v4();
    if (!await _prefs.setString(key, id) || await pendingId() != id) {
      throw StateError('Maintenance request was not stored');
    }
    return id;
  }

  Future<bool> consume(String expectedId) async {
    if (await pendingId() != expectedId) return false;
    await clearForCancellation();
    return true;
  }

  Future<void> clearForCancellation() async {
    if (!await _prefs.remove(key)) {
      throw StateError('Maintenance request removal failed');
    }
    await _prefs.reload();
    if (_prefs.containsKey(key)) {
      throw StateError('Request removal unconfirmed');
    }
  }
}
