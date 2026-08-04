import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/memorization/progress_metrics_service.dart';
import '../../../../../core/memorization/remote_child_production_summary_builder.dart';
import '../../../domain/entities/memorization_entities.dart';

/// Pure cloud-row → domain-entity mappings shared by the kids-cloud-sync and
/// production-sync collaborators. No I/O, no shared state.
class MemorizationCloudMappers {
  MemorizationCloudMappers(this._metrics);

  final ProgressMetricsService _metrics;

  KidsProgress progressFromCloud(Map<String, dynamic>? row) {
    if (row == null) return const KidsProgress.initial();
    return KidsProgress(
      totalPoints: row['total_points'] as int? ?? 0,
      currentLevel: row['current_level'] as int? ?? 1,
      currentStreak: row['current_streak'] as int? ?? 0,
      starsEarned: row['stars_earned'] as int? ?? 0,
      ayahsCompleted: row['ayahs_completed'] as int? ?? 0,
      lastSessionAt: row['last_session_at'] == null
          ? null
          : DateTime.parse(row['last_session_at'] as String),
    );
  }

  KidsSessionLog logFromCloud(Map<String, dynamic> row) => KidsSessionLog(
    id: row['local_id'] as String? ?? row['id'].toString(),
    surahId: row['surah_id'] as int,
    ayahNumber: row['ayah_number'] as int,
    repeatsCompleted: row['repeats_completed'] as int? ?? 0,
    pointsEarned: row['points_earned'] as int? ?? 0,
    completedAt: DateTime.parse(row['completed_at'] as String),
    syncedAt: DateTime.now(),
  );

  ParentReward rewardFromCloud(Map<String, dynamic> row) => ParentReward(
    id: row['id'].toString(),
    title: row['title'] as String,
    status: ParentRewardStatus.values.firstWhere(
      (status) => status.name == (row['status'] as String? ?? 'locked'),
      orElse: () => ParentRewardStatus.locked,
    ),
    createdAt: DateTime.parse(row['created_at'] as String),
    unlockedAt: row['unlocked_at'] == null
        ? null
        : DateTime.parse(row['unlocked_at'] as String),
    claimedAt: row['claimed_at'] == null
        ? null
        : DateTime.parse(row['claimed_at'] as String),
  );

  AyahReviewRecord reviewRecordFromCloud(Map<String, dynamic> row) =>
      RemoteChildProductionSummaryBuilder.reviewRecordFromCloud(row);

  List<RemoteChildSummary> parseRemoteChildrenDashboard(dynamic raw) {
    final items = raw as List<dynamic>? ?? const [];
    return items
        .map(
          (item) => remoteChildSummaryFromDashboardJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  RemoteChildSummary remoteChildSummaryFromDashboardJson(
    Map<String, dynamic> row,
  ) {
    final childId = row['child_user_id'] as String;
    final progressRaw = row['progress'];
    final logsRaw = row['logs'] as List<dynamic>? ?? const [];
    final rewardsRaw = row['rewards'] as List<dynamic>? ?? const [];

    RemoteChildProductionSummary? production;
    try {
      final reviewSummaryRaw = row['review_summary'];
      final reviewRows = (row['review_rows'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final dailyPlanRaw = row['daily_plan'];
      final dailyPlanRow = dailyPlanRaw == null
          ? null
          : Map<String, dynamic>.from(dailyPlanRaw as Map);
      final certRows = (row['certificates'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final streakRaw = row['streak'];
      final streakRow = streakRaw == null
          ? null
          : Map<String, dynamic>.from(streakRaw as Map);
      final activityRows = (row['activities'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (reviewSummaryRaw is Map) {
        production = buildProductionSummaryFromAggregates(
          reviewSummary: Map<String, dynamic>.from(reviewSummaryRaw),
          dailyPlanRow: dailyPlanRow,
          certRows: certRows,
          streakRow: streakRow,
          activityRows: activityRows,
        );
      } else {
        production = buildProductionSummary(
          reviewRows: reviewRows,
          dailyPlanRow: dailyPlanRow,
          certRows: certRows,
          streakRow: streakRow,
          activityRows: activityRows,
        );
      }
    } catch (_) {
      production = null;
    }

    return RemoteChildSummary(
      childUserId: childId,
      displayName: row['display_name'] as String? ?? 'طفل تالية',
      progress: progressFromCloud(
        progressRaw == null ? null : Map<String, dynamic>.from(progressRaw as Map),
      ),
      logs: logsRaw
          .map((item) => logFromCloud(Map<String, dynamic>.from(item as Map)))
          .toList(),
      rewards: rewardsRaw
          .map(
            (item) => rewardFromCloud(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      production: production,
    );
  }

  /// Reconstructs the parent-facing production summary from cloud rows.
  ///
  /// Reuses existing pure logic only: [AyahReviewRecord.reviewClassification]
  /// (SRS due/near/far/memorized classification) and [SmartCoachEngine] (next
  /// recommendation) — no second engine is introduced for the parent side.
  RemoteChildProductionSummary buildProductionSummary({
    required List<Map<String, dynamic>> reviewRows,
    required Map<String, dynamic>? dailyPlanRow,
    required List<Map<String, dynamic>> certRows,
    required Map<String, dynamic>? streakRow,
    required List<Map<String, dynamic>> activityRows,
  }) {
    return RemoteChildProductionSummaryBuilder(metrics: _metrics).build(
      reviewRows: reviewRows,
      dailyPlanRow: dailyPlanRow,
      certRows: certRows,
      streakRow: streakRow,
      activityRows: activityRows,
    );
  }

  RemoteChildProductionSummary buildProductionSummaryFromAggregates({
    required Map<String, dynamic> reviewSummary,
    required Map<String, dynamic>? dailyPlanRow,
    required List<Map<String, dynamic>> certRows,
    required Map<String, dynamic>? streakRow,
    required List<Map<String, dynamic>> activityRows,
  }) {
    final reviewCount = reviewSummary['review_count'] as int? ?? 0;
    final memorizedCount = reviewSummary['memorized_count'] as int? ?? 0;
    final overdueCount = reviewSummary['overdue_count'] as int? ?? 0;
    final nextReviewRaw = reviewSummary['next_review_at'] as String?;
    final latestReviewRaw = reviewSummary['latest_review_at'] as String?;
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
    final planSurahId = dailyPlanRow?['surah_id'] as int?;
    final planTotal = dailyPlanRow?['total_items'] as int? ?? 0;
    final planCompleted = dailyPlanRow?['completed_count'] as int? ?? 0;
    final completionPercent = reviewCount == 0
        ? 0.0
        : ((memorizedCount / AppConstants.totalAyahs) * 100).clamp(0.0, 100.0);

    return RemoteChildProductionSummary(
      totalMemorizedAyahs: memorizedCount,
      totalAyahsTracked: reviewCount,
      completionPercent: completionPercent,
      currentSurahId: planSurahId ?? reviewSummary['last_surah_id'] as int?,
      lastMemorizedSurahId: reviewSummary['last_surah_id'] as int?,
      lastMemorizedAyahNumber: reviewSummary['last_ayah_number'] as int?,
      lastMemorizedAt: latestReviewRaw == null
          ? null
          : DateTime.tryParse(latestReviewRaw)?.toUtc(),
      reviewsCompleted: reviewCount,
      reviewsOverdue: overdueCount,
      nextReviewAt: nextReviewRaw == null
          ? null
          : DateTime.tryParse(nextReviewRaw)?.toUtc(),
      dailyPlanSurahId: planSurahId,
      dailyPlanTotal: planTotal,
      dailyPlanCompleted: planCompleted,
      currentStreak: streakRow?['current_streak'] as int?,
      longestStreak: streakRow?['longest_streak'] as int?,
      activeDaysLast30: activeDays,
      certificates: certificates,
      smartCoachKind: null,
    );
  }
}
