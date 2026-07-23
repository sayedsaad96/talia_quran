import '../../features/memorization_plus/data/models/memorization_models.dart';
import '../../features/memorization_plus/domain/entities/memorization_entities.dart';
import '../constants/app_constants.dart';
import 'memorization_snapshot.dart';
import 'progress_metrics.dart';
import 'progress_metrics_service.dart';
import 'review_record_filters.dart';
import 'smart_coach_engine.dart';
import 'smart_coach_recommendation.dart';

/// Reconstructs the parent-facing production summary from child cloud rows.
///
/// Parent remote rows describe a child account, so SRS metrics must use the
/// kids audience bucket. Adult-compatible filtering would hide `kidsMode`
/// records and make parent memorization totals look empty.
class RemoteChildProductionSummaryBuilder {
  const RemoteChildProductionSummaryBuilder({
    this.metrics = const ProgressMetricsService(),
  });

  final ProgressMetricsService metrics;

  RemoteChildProductionSummary build({
    required List<Map<String, dynamic>> reviewRows,
    required Map<String, dynamic>? dailyPlanRow,
    required List<Map<String, dynamic>> certRows,
    required Map<String, dynamic>? streakRow,
    required List<Map<String, dynamic>> activityRows,
  }) {
    final records = reviewRows.map(reviewRecordFromCloud).toList();
    final now = DateTime.now().toUtc();
    final currentStreak = streakRow?['current_streak'] as int?;
    final longestStreak = streakRow?['longest_streak'] as int?;

    final childMetrics = metrics.calculate(
      records: records,
      now: now,
      audience: ProgressAudience.kids,
      totalAyahs: AppConstants.totalAyahs,
      totalSurahs: AppConstants.totalSurahs,
      totalJuz: AppConstants.totalJuz,
      streakDays: currentStreak ?? 0,
    );

    DateTime? nextReviewAt;
    for (final record in records.where(ReviewRecordFilters.isKidsSource)) {
      if (!ReviewRecordFilters.isStarted(record)) continue;
      if (nextReviewAt == null ||
          record.nextReviewDate.isBefore(nextReviewAt)) {
        nextReviewAt = record.nextReviewDate;
      }
    }

    final completionPercent = (childMetrics.memorizationCompletionPercent * 100)
        .clamp(0.0, 100.0);

    final planData = _parseDailyPlan(dailyPlanRow);
    final certificates = certRows
        .map(
          (row) => RemoteCertificateAward(
            certId: row['cert_id'] as String,
            titleAr: row['title_ar'] as String,
            certType: row['cert_type'] as String,
            earnedAt: DateTime.parse(row['earned_at'] as String),
          ),
        )
        .toList();

    final activeDays = activityRows
        .where((row) => (row['activity_count'] as int? ?? 0) > 0)
        .length;

    return RemoteChildProductionSummary(
      totalMemorizedAyahs: childMetrics.memorizedAyahs,
      totalAyahsTracked: childMetrics.startedAyahs,
      completionPercent: completionPercent,
      currentSurahId: planData.surahId ?? childMetrics.lastMemorizedSurahId,
      lastMemorizedSurahId: childMetrics.lastMemorizedSurahId,
      lastMemorizedAyahNumber: childMetrics.lastMemorizedAyahNumber,
      lastMemorizedAt: childMetrics.lastReviewedAt,
      reviewsCompleted: childMetrics.startedAyahs,
      reviewsOverdue: childMetrics.overdueReviews,
      nextReviewAt: nextReviewAt,
      dailyPlanSurahId: planData.surahId,
      dailyPlanTotal: planData.total,
      dailyPlanCompleted: planData.completed,
      currentStreak: streakRow == null ? null : currentStreak,
      longestStreak: streakRow == null ? null : longestStreak,
      activeDaysLast30: activeDays,
      certificates: certificates,
      smartCoachKind: _smartCoachKind(records, planData.cachedPlan),
    );
  }

  static AyahReviewRecord reviewRecordFromCloud(Map<String, dynamic> row) {
    PerformanceRating? lastRating;
    final ratingRaw = row['last_rating'] as String?;
    if (ratingRaw != null) {
      for (final value in PerformanceRating.values) {
        if (value.name == ratingRaw) {
          lastRating = value;
          break;
        }
      }
    }

    var reviewState = ReviewState.newCard;
    final reviewStateRaw = row['review_state'] as String?;
    if (reviewStateRaw != null) {
      for (final value in ReviewState.values) {
        if (value.name == reviewStateRaw) {
          reviewState = value;
          break;
        }
      }
    }

    var createdByMode = ReviewRecordCreatedByMode.unknown;
    final modeRaw = row['created_by_mode'] as String?;
    if (modeRaw != null) {
      for (final value in ReviewRecordCreatedByMode.values) {
        if (value.name == modeRaw) {
          createdByMode = value;
          break;
        }
      }
    }

    return AyahReviewRecord(
      surahId: row['surah_id'] as int,
      ayahNumber: row['ayah_number'] as int,
      strengthLevel: row['strength_level'] as int? ?? 0,
      intervalDays: row['interval_days'] as int? ?? 0,
      lastReviewedAt: DateTime.parse(row['last_reviewed_at'] as String),
      nextReviewDate: DateTime.parse(row['next_review_date'] as String),
      totalReviews: row['total_reviews'] as int? ?? 0,
      lastRating: lastRating,
      easeFactor: (row['ease_factor'] as num?)?.toDouble() ?? 2.5,
      lapses: row['lapses'] as int? ?? 0,
      reviewState: reviewState,
      createdByMode: createdByMode,
      difficulty: (row['difficulty'] as num?)?.toDouble() ?? 5.0,
      stability: (row['stability'] as num?)?.toDouble() ?? 0.0,
    );
  }

  _RemoteDailyPlanData _parseDailyPlan(Map<String, dynamic>? row) {
    if (row == null) return const _RemoteDailyPlanData();

    DailyPlan? cachedPlan;
    final payload = row['payload'];
    if (payload is Map<String, dynamic>) {
      try {
        cachedPlan = DailyPlanModel.fromJson(payload);
      } catch (_) {
        cachedPlan = null;
      }
    }

    return _RemoteDailyPlanData(
      surahId: row['surah_id'] as int?,
      total: row['total_items'] as int? ?? 0,
      completed: row['completed_count'] as int? ?? 0,
      cachedPlan: cachedPlan,
    );
  }

  SmartCoachRecommendationKind? _smartCoachKind(
    List<AyahReviewRecord> records,
    DailyPlan? cachedPlan,
  ) {
    try {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: MemorizationProfile(
          schemaVersion: 1,
          selectedPath: MemorizationPath.child,
          guardianLinkStatus: GuardianLinkStatus.linked,
          guardianOnboardingStatus: GuardianOnboardingStatus.completed,
          isParentGuardian: false,
          createdAt: now,
          updatedAt: now,
        ),
        reviewRecords: records,
        cachedDailyPlan: cachedPlan,
      );
      return const SmartCoachEngine().recommend(snapshot)?.kind;
    } catch (_) {
      return null;
    }
  }
}

class _RemoteDailyPlanData {
  const _RemoteDailyPlanData({
    this.surahId,
    this.total = 0,
    this.completed = 0,
    this.cachedPlan,
  });

  final int? surahId;
  final int total;
  final int completed;
  final DailyPlan? cachedPlan;
}
