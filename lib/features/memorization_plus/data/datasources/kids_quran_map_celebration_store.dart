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

  String get _key => 'kids_quran_map_seen_completed_${_owner.currentOwnerId}';

  /// The surahs completed since the last visit; records this visit.
  Future<Set<int>> takeNewlyCompleted(List<KidsSurahHouse> houses) async {
    try {
      final key = _key;
      final stored = _prefs.getStringList(key);
      final seen = stored?.map(int.parse).toSet();
      final celebrate = kidsSurahsToCelebrate(
        seenCompleted: seen,
        houses: houses,
      );
      await _prefs.setStringList(key, [
        for (final id in kidsCompletedSurahs(houses)) '$id',
      ]);
      return celebrate;
    } catch (_) {
      return const {};
    }
  }
}
