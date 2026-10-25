import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/services/kids_map_celebration.dart';
import '../../domain/services/kids_surah_house_summary_builder.dart';

/// Remembers, per account, which surahs the child had already seen
/// completed on the whole-Quran journey map. Display state only, never
/// learning data. Any storage error means no glow (decoration fails closed).
class KidsQuranMapCelebrationStore {
  KidsQuranMapCelebrationStore(this._prefs, this._owner);

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  /// Followed by the owner id. Cleared with the account data and backed up
  /// as an owner-suffixed family.
  static const keyPrefix = 'kids_quran_map_seen_completed_';

  String get _key => '$keyPrefix${_owner.currentOwnerId}';

  /// The surahs completed since the last visit; records this visit.
  ///
  /// The record only grows: a load that misses progress (a transient read
  /// failure shows every house as not started) must not erase it, or the
  /// next good load would celebrate every finished surah at once. An
  /// unreadable record counts as a first visit: nothing glows now, and the
  /// rewrite lets later completions glow again.
  Future<Set<int>> takeNewlyCompleted(List<KidsSurahHouse> houses) async {
    try {
      final key = _key;
      final stored = _prefs.getStringList(key);
      final parsed = stored?.map(int.tryParse).toList();
      final seen = parsed == null || parsed.contains(null)
          ? null
          : parsed.whereType<int>().toSet();
      final celebrate = kidsSurahsToCelebrate(
        seenCompleted: seen,
        houses: houses,
      );
      final record = {...?seen, ...kidsCompletedSurahs(houses)};
      await _prefs.setStringList(key, [for (final id in record) '$id']);
      return celebrate;
    } catch (_) {
      return const {};
    }
  }
}
