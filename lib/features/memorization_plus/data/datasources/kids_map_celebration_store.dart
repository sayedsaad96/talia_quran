import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/services/kids_map_celebration.dart';

/// K37 — remembers, per account and surah, which houses the child had
/// already seen completed on the map. Display state only, never learning
/// data. Any storage error means no glow (decoration fails closed).
class KidsMapCelebrationStore {
  KidsMapCelebrationStore(this._prefs, this._owner);

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  String _key(int surahId) =>
      'kids_map_seen_completed_${_owner.currentOwnerId}_$surahId';

  /// The houses completed since the last visit; records this visit.
  Future<Set<int>> takeNewlyCompleted(
    int surahId,
    List<KidsJourneyStage> stages,
  ) async {
    try {
      final key = _key(surahId);
      final stored = _prefs.getStringList(key);
      final seen = stored?.map(int.parse).toSet();
      final celebrate = kidsHousesToCelebrate(
        seenCompleted: seen,
        stages: stages,
      );
      await _prefs.setStringList(key, [
        for (final number in kidsCompletedHouses(stages)) '$number',
      ]);
      return celebrate;
    } catch (_) {
      return const {};
    }
  }
}
