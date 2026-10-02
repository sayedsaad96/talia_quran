import 'package:equatable/equatable.dart';

import '../../../../core/memorization/kids_progress_cloud_merge.dart';
import '../entities/kids_session_log.dart';

/// The five regions of the kids Adventure map. Names are UI copy only.
enum KidsRegionId { beginning, palmOasis, flowerValley, starMountain, pearlSea }

/// A contiguous slice of the kids journey path.
final class KidsAdventureRegion {
  const KidsAdventureRegion(this.id, this.surahIds);

  final KidsRegionId id;
  final List<int> surahIds;
}

/// Regions group `KidsJourneyPath.surahIds` in path order, without changing it.
const List<KidsAdventureRegion> kKidsAdventureRegions = [
  KidsAdventureRegion(KidsRegionId.beginning, [1]),
  KidsAdventureRegion(KidsRegionId.palmOasis, [114, 113, 112, 111, 110, 109]),
  KidsAdventureRegion(KidsRegionId.flowerValley, [
    108,
    107,
    106,
    105,
    104,
    103,
    102,
    101,
    100,
  ]),
  KidsAdventureRegion(KidsRegionId.starMountain, [
    99,
    98,
    97,
    96,
    95,
    94,
    93,
    92,
    91,
    90,
  ]),
  KidsAdventureRegion(KidsRegionId.pearlSea, [
    89,
    88,
    87,
    86,
    85,
    84,
    83,
    82,
    81,
    80,
    79,
    78,
  ]),
];

/// Surahs whose every ayah (1..count) is covered by canonical reward logs.
///
/// Review-only logs never count. Surahs missing from [ayahCountBySurah] are
/// never memorized.
Set<int> kidsMemorizedSurahIds(
  List<KidsSessionLog> logs,
  Map<int, int> ayahCountBySurah,
) {
  final covered = <int, Set<int>>{};
  for (final log in logs) {
    if (!KidsSessionLogsCloudMerge.isCanonicalRewardLog(log)) continue;
    final set = covered.putIfAbsent(log.surahId, () => <int>{});
    set.add(log.ayahNumber);
    set.addAll(log.ayahNumbers);
  }
  final memorized = <int>{};
  for (final entry in covered.entries) {
    final count = ayahCountBySurah[entry.key];
    if (count == null || count <= 0) continue;
    var all = true;
    for (var a = 1; a <= count; a++) {
      if (!entry.value.contains(a)) {
        all = false;
        break;
      }
    }
    if (all) memorized.add(entry.key);
  }
  return memorized;
}

final class KidsRegionProgress extends Equatable {
  const KidsRegionProgress(this.region, this.memorized);

  final KidsAdventureRegion region;

  /// How many of the region's surahs are memorized.
  final int memorized;

  int get total => region.surahIds.length;
  bool get isComplete => memorized == total;

  @override
  List<Object?> get props => [region.id, memorized];
}

List<KidsRegionProgress> kidsRegionProgress(Set<int> memorizedSurahIds) => [
  for (final region in kKidsAdventureRegions)
    KidsRegionProgress(
      region,
      region.surahIds.where(memorizedSurahIds.contains).length,
    ),
];

/// The region holding [surahId]; throws [StateError] off the kids path.
KidsAdventureRegion kidsRegionOf(int surahId) {
  for (final region in kKidsAdventureRegions) {
    if (region.surahIds.contains(surahId)) return region;
  }
  throw StateError('Surah $surahId is not on the kids journey path');
}
