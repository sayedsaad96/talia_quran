import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Typed snapshot of a set of preference keys, including keys that were
/// absent, and the matching rollback.
///
/// Unlike a best-effort rollback, [rollback] throws as soon as a key cannot be
/// put back, so a journal keeps the restore recoverable instead of reporting
/// a half-restored state as safe.
class RestorePreferencesSnapshot {
  const RestorePreferencesSnapshot(this._prefs);

  final SharedPreferences _prefs;

  String capture(Iterable<String> keys) {
    final values = <String, Object?>{};
    for (final key in keys) {
      final value = _prefs.get(key);
      values[key] = switch (value) {
        null => null,
        final String v => {'t': 's', 'v': v},
        final int v => {'t': 'i', 'v': v},
        final double v => {'t': 'd', 'v': v},
        final bool v => {'t': 'b', 'v': v},
        final List<dynamic> v => {'t': 'l', 'v': List<String>.of(v.cast())},
        _ => throw StateError('Unsupported preference type for $key'),
      };
    }
    return jsonEncode(values);
  }

  Future<void> rollback(String snapshot) async {
    final decoded = jsonDecode(snapshot);
    if (decoded is! Map) {
      throw const FormatException('Preference snapshot is not an object');
    }
    for (final entry in decoded.entries) {
      final key = entry.key as String;
      final value = entry.value;
      if (value == null) {
        if (_prefs.containsKey(key) && !await _prefs.remove(key)) {
          throw StateError('Failed to remove $key');
        }
        continue;
      }
      if (!await _write(key, value as Map)) {
        throw StateError('Failed to restore $key');
      }
    }
  }

  Future<bool> _write(String key, Map<dynamic, dynamic> typed) {
    final value = typed['v'];
    return switch (typed['t']) {
      's' => _prefs.setString(key, value as String),
      'i' => _prefs.setInt(key, value as int),
      'd' => _prefs.setDouble(key, (value as num).toDouble()),
      'b' => _prefs.setBool(key, value as bool),
      'l' => _prefs.setStringList(key, (value as List).cast<String>()),
      _ => throw FormatException('Unknown preference type for $key'),
    };
  }
}
