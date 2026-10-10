import '../../../../core/memorization/kids_progress_cloud_merge.dart';
import '../entities/memorization_entities.dart';

abstract final class KidsHouseReviewPolicy {
  static String proofId(int surahId, int ayah, String sessionId) =>
      'kids_house_review_${surahId}_${ayah}_$sessionId';

  static bool isVerifiedReview(KidsSessionLog log) =>
      log.id.startsWith(
        'kids_house_review_${log.surahId}_${log.ayahNumber}_',
      ) &&
      log.missionType == KidsMissionType.linkedReview &&
      log.pointsEarned > 0 &&
      log.masteryRating != PerformanceRating.weak;

  static List<int> pendingAyahs(
    List<KidsSessionLog> logs,
    int surahId,
    List<int> range,
  ) {
    if (range.isEmpty) return const [];
    final firstPasses = <int, DateTime>{};
    for (final log in logs) {
      if (log.surahId != surahId ||
          !range.contains(log.ayahNumber) ||
          !KidsSessionLogsCloudMerge.isCanonicalRewardLog(log)) {
        continue;
      }
      final previous = firstPasses[log.ayahNumber];
      if (previous == null || log.completedAt.isAfter(previous)) {
        firstPasses[log.ayahNumber] = log.completedAt;
      }
    }
    if (firstPasses.length != range.length) return const [];
    final completedAt = firstPasses.values.reduce(
      (a, b) => a.isAfter(b) ? a : b,
    );
    return range
        .where(
          (ayah) => !logs.any(
            (log) =>
                log.surahId == surahId &&
                log.ayahNumber == ayah &&
                isVerifiedReview(log) &&
                log.completedAt.isAfter(completedAt),
          ),
        )
        .toList(growable: false);
  }
}
