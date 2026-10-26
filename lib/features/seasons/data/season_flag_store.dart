import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/identity/record_owner_provider.dart';

/// Per-owner boolean marks behind the season cards (a fasted day, a read
/// Friday, a dismissed card, an earned badge). One key per mark:
/// `season_flag_<name>|<owner>`. A cleared mark removes its key, so nothing
/// false is stored. Local only; covered by backup and account reset through
/// the `season_flag_` prefix.
class SeasonFlagStore {
  SeasonFlagStore(this._prefs, this._owner);

  static const keyPrefix = 'season_flag_';

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  static String keyFor(String name, String ownerId) =>
      '$keyPrefix$name|$ownerId';

  bool isSet(String name) {
    try {
      return _prefs.getBool(keyFor(name, _owner.currentOwnerId)) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> set(String name, bool value) {
    // Owner captured once so an account switch mid-call cannot misfile it.
    final key = keyFor(name, _owner.currentOwnerId);
    return value ? _prefs.setBool(key, true) : _prefs.remove(key);
  }

  /// Names (without prefix and owner) of this owner's set marks that start
  /// with [namePrefix].
  List<String> namesWithPrefix(String namePrefix) {
    final head = '$keyPrefix$namePrefix';
    final suffix = '|${_owner.currentOwnerId}';
    return [
      for (final key in _prefs.getKeys())
        if (key.startsWith(head) &&
            key.endsWith(suffix) &&
            _prefs.getBool(key) == true)
          key.substring(keyPrefix.length, key.length - suffix.length),
    ];
  }
}

/// `yyyy-mm-dd` of a civil date, for per-date marks.
String seasonDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
