import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/identity/record_owner_provider.dart';
import '../../../core/seasons/season_calendar.dart';

/// Remembers which Ramadan home cards the user hid, per phase and Hijri year,
/// scoped to the signed-in account.
class RamadanCardDismissStore {
  RamadanCardDismissStore(this._prefs, this._owner);

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  static String keyFor(RamadanPhase phase, int hijriYear, String ownerId) =>
      'ramadan_card_dismissed_${phase.name}_$hijriYear|$ownerId';

  bool isDismissed(RamadanPhase phase, int hijriYear) =>
      _prefs.getBool(keyFor(phase, hijriYear, _owner.currentOwnerId)) ?? false;

  Future<void> dismiss(RamadanPhase phase, int hijriYear) {
    // Owner captured once so an account switch mid-call cannot misfile it.
    final key = keyFor(phase, hijriYear, _owner.currentOwnerId);
    return _prefs.setBool(key, true);
  }
}
