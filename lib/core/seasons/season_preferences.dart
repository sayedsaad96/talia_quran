import 'package:shared_preferences/shared_preferences.dart';

import '../identity/record_owner_provider.dart';
import 'season_calendar.dart';

/// Per-owner on/off choices for the seasons engine: one master switch
/// («رافقني في المواسم»), one switch per [SeasonId], a shared seasonal
/// reminders opt-in (off by default), and the guardian's single
/// «مواسم الطفل» switch. The master switch hides every season without
/// touching the per-season choices, so turning it back on restores them.
/// Nothing here deletes data.
class SeasonPreferences {
  SeasonPreferences(this._prefs, this._owner);

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  static const keyPrefix = 'season_pref_';
  static const _master = 'master';
  static const _reminders = 'reminders';
  static const _kids = 'kids';

  static String keyFor(String name, String ownerId) =>
      '$keyPrefix$name|$ownerId';

  static String seasonKeyFor(SeasonId id, String ownerId) =>
      keyFor(id.name, ownerId);

  /// A stored value of the wrong type counts as absent, so the default wins.
  bool? _stored(String key) {
    try {
      return _prefs.getBool(key);
    } catch (_) {
      return null;
    }
  }

  bool _read(String name) =>
      _stored(keyFor(name, _owner.currentOwnerId)) ?? true;

  /// Owner captured once so an account switch mid-call cannot misfile it.
  Future<void> _write(String name, bool value) =>
      _prefs.setBool(keyFor(name, _owner.currentOwnerId), value);

  bool get masterEnabled => _read(_master);

  Future<void> setMasterEnabled(bool value) => _write(_master, value);

  /// Quiet default: every season shows, except the Monday/Thursday fasting
  /// reminder which stays off until the user opts in.
  static bool defaultEnabled(SeasonId id) => id != SeasonId.monThu;

  bool isSeasonEnabled(SeasonId id) =>
      _stored(seasonKeyFor(id, _owner.currentOwnerId)) ?? defaultEnabled(id);

  Future<void> setSeasonEnabled(SeasonId id, bool value) =>
      _prefs.setBool(seasonKeyFor(id, _owner.currentOwnerId), value);

  /// The season's card, challenge and badge may show.
  bool isSeasonVisible(SeasonId id) => masterEnabled && isSeasonEnabled(id);

  /// The shared seasonal reminders switch: off until the user explicitly turns
  /// it on. The Ramadan last-ten reminder has its own opt-in and is not
  /// governed by this switch.
  bool get remindersEnabled =>
      _stored(keyFor(_reminders, _owner.currentOwnerId)) ?? false;

  Future<void> setRemindersEnabled(bool value) => _write(_reminders, value);

  /// The guardian's one switch for the child's seasonal content.
  bool get kidsSeasonsEnabled => _read(_kids);

  Future<void> setKidsSeasonsEnabled(bool value) => _write(_kids, value);

  /// Removes this owner's stored choices, so every switch falls back to its
  /// default. Used by the page's «restore defaults» button. The kids key is
  /// kept: the guardian's choice lives on another page.
  Future<void> resetToDefaults() async {
    final ownerId = _owner.currentOwnerId;
    final suffix = '|$ownerId';
    final kidsKey = keyFor(_kids, ownerId);
    final keys = _prefs
        .getKeys()
        .where(
          (k) => k.startsWith(keyPrefix) && k.endsWith(suffix) && k != kidsKey,
        )
        .toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
