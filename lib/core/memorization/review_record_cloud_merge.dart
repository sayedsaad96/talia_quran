import '../../features/memorization_plus/domain/entities/memorization_entities.dart';

/// Field-level merge for local ↔ cloud [AyahReviewRecord] rows (B6/B9).
class ReviewRecordCloudMerge {
  ReviewRecordCloudMerge._();

  /// Merges [local] with [remote]. When [local] is null, returns [remote].
  static AyahReviewRecord merge({
    AyahReviewRecord? local,
    required AyahReviewRecord remote,
  }) {
    if (local == null) return remote;

    final latest = _latestByReviewTime(local, remote);

    return AyahReviewRecord(
      surahId: local.surahId,
      ayahNumber: local.ayahNumber,
      strengthLevel: _max(local.strengthLevel, remote.strengthLevel),
      intervalDays: _max(local.intervalDays, remote.intervalDays),
      totalReviews: _max(local.totalReviews, remote.totalReviews),
      lapses: _max(local.lapses, remote.lapses),
      easeFactor: _maxDouble(local.easeFactor, remote.easeFactor),
      lastReviewedAt: _maxDate(local.lastReviewedAt, remote.lastReviewedAt),
      nextReviewDate: latest.nextReviewDate,
      lastRating: latest.lastRating,
      reviewState: latest.reviewState,
      createdByMode: _mergeMode(local.createdByMode, remote.createdByMode),
      difficulty: latest.difficulty,
      stability: latest.stability,
      predictedRetrievability: latest.predictedRetrievability,
      predictedFsrsIntervalDays: latest.predictedFsrsIntervalDays,
      predictedFsrsDueDate: latest.predictedFsrsDueDate,
      predictedRecallProbability: latest.predictedRecallProbability,
      schedulerVsFsrsGapDays: latest.schedulerVsFsrsGapDays,
      schedulerVsFsrsRatio: latest.schedulerVsFsrsRatio,
      schedulerEarlierThanFsrs: latest.schedulerEarlierThanFsrs,
    );
  }

  static AyahReviewRecord _latestByReviewTime(
    AyahReviewRecord local,
    AyahReviewRecord remote,
  ) {
    if (remote.lastReviewedAt.isAfter(local.lastReviewedAt)) return remote;
    if (local.lastReviewedAt.isAfter(remote.lastReviewedAt)) return local;
    return remote;
  }

  static int _max(int a, int b) => a > b ? a : b;

  static double _maxDouble(double a, double b) => a > b ? a : b;

  static DateTime _maxDate(DateTime a, DateTime b) =>
      a.isAfter(b) ? a : b;

  static ReviewRecordCreatedByMode _mergeMode(
    ReviewRecordCreatedByMode local,
    ReviewRecordCreatedByMode remote,
  ) {
    if (_isProductionMode(local) && !_isProductionMode(remote)) return local;
    if (_isProductionMode(remote) && !_isProductionMode(local)) return remote;
    return remote;
  }

  static bool _isProductionMode(ReviewRecordCreatedByMode mode) {
    return switch (mode) {
      ReviewRecordCreatedByMode.v2Session ||
      ReviewRecordCreatedByMode.kidsMode ||
      ReviewRecordCreatedByMode.hifz => true,
      _ => false,
    };
  }
}
