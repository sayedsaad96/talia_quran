import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/prayer_companion/domain/entities/prayer_companion.dart';
import '../identity/account_data_barrier.dart';

/// Account-owned upper bounds; changing them never rewrites frozen selections.
final class PrayerReviewLengths {
  const PrayerReviewLengths(this._prefs, this._barrier);
  final SharedPreferences _prefs;
  final AccountDataBarrier _barrier;
  static const baseKey = 'prayer_review_lengths';
  static const validLengths = {3, 7, 15};

  int read(String ownerId, PrayerKey prayer) {
    try {
      return decode(
            _prefs.getString('$baseKey|$ownerId') ?? '{}',
          )[prayer.name] ??
          7;
    } on FormatException {
      return 7;
    }
  }

  Future<void> write(
    String ownerId,
    PrayerKey prayer,
    int length,
    AccountDataLease authority,
  ) async {
    authority.checkOwner(ownerId);
    if (!validLengths.contains(length)) {
      throw const FormatException('Invalid review length');
    }
    await _barrier.run((lease) async {
      lease.checkOwner(ownerId);
      final key = '$baseKey|$ownerId';
      Map<String, int> values;
      try {
        values = decode(_prefs.getString(key) ?? '{}');
      } on FormatException {
        values = {};
      }
      values[prayer.name] = length;
      if (!await _prefs.setString(key, jsonEncode(values))) {
        throw StateError('Prayer review settings could not be saved');
      }
      lease.checkOwner(ownerId);
    }, authority: authority);
  }

  static Map<String, int> decode(String raw) {
    final Object? parsed = jsonDecode(raw);
    if (parsed is! Map<String, dynamic> ||
        parsed.length > PrayerKey.values.length) {
      throw const FormatException('Invalid prayer review settings');
    }
    final validKeys = PrayerKey.values.map((p) => p.name).toSet();
    final result = <String, int>{};
    for (final entry in parsed.entries) {
      if (!validKeys.contains(entry.key) ||
          entry.value is! int ||
          !validLengths.contains(entry.value)) {
        throw const FormatException('Invalid prayer review setting');
      }
      result[entry.key] = entry.value as int;
    }
    return result;
  }
}
