import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/memorization/progress_metrics_service.dart';
import '../../../../../core/memorization/remote_child_production_summary_builder.dart';
import '../../../domain/entities/kids_home_mission.dart';
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

  KidsSessionLog logFromCloud(Map<String, dynamic> row) {
    final rawAyahNumbers = row['ayah_numbers'];
    final ayahNumbers = rawAyahNumbers is List
        ? rawAyahNumbers
              .whereType<num>()
              .map((number) => number.toInt())
              .toList(growable: false)
        : const <int>[];

    return KidsSessionLog(
      id: row['local_id'] as String? ?? row['id'].toString(),
      surahId: (row['surah_id'] as num).toInt(),
      ayahNumber: (row['ayah_number'] as num).toInt(),
      repeatsCompleted: _boundedInt(row['repeats_completed'], fallback: 0),
      pointsEarned: _boundedInt(row['points_earned'], fallback: 0),
      completedAt: DateTime.parse(row['completed_at'] as String),
      syncedAt: DateTime.now(),
      missionType: _enumByName(
        KidsMissionType.values,
        row['mission_type'],
        KidsMissionType.newMemorization,
      ),
      ayahNumbers: ayahNumbers,
      durationSeconds: _boundedInt(row['duration_seconds'], fallback: 0),
      attemptCount: _boundedInt(row['attempt_count'], fallback: 1, minimum: 1),
      hintCount: _boundedInt(row['hint_count'], fallback: 0),
      masteryRating: _enumByName(
        PerformanceRating.values,
        row['mastery_rating'],
        PerformanceRating.excellent,
      ),
    );
  }

  static int _boundedInt(
    dynamic value, {
    required int fallback,
    int minimum = 0,
  }) {
    if (value is! num) return fallback;
    final parsed = value.toInt();
    return parsed < minimum ? fallback : parsed;
  }

  static T _enumByName<T extends Enum>(
    Iterable<T> values,
    dynamic raw,
    T fallback,
  ) {
    if (raw is! String) return fallback;
    return values.firstWhere(
      (value) => value.name == raw,
      orElse: () => fallback,
    );
  }

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
    requestedAt: row['requested_at'] == null
        ? null
        : DateTime.parse(row['requested_at'] as String),
    claimedAt: row['claimed_at'] == null
        ? null
        : DateTime.parse(row['claimed_at'] as String),
  );

  KidsHomeMission homeMissionFromCloud(Map<String, dynamic> row) =>
      KidsHomeMission(
        id: row['id'].toString(),
        title: row['title'] as String,
        status: KidsHomeMissionStatus.values.firstWhere(
          (status) => status.name == row['status'],
          orElse: () => KidsHomeMissionStatus.assigned,
        ),
        createdAt: DateTime.parse(row['created_at'] as String),
        reportedAt: row['reported_at'] == null
            ? null
            : DateTime.parse(row['reported_at'] as String),
        acknowledgedAt: row['acknowledged_at'] == null
            ? null
            : DateTime.parse(row['acknowledged_at'] as String),
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
    final activity = activityFromDashboardJson(row['activity_snapshot']);

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
          activity: activity,
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
      // Blank means unnamed; the UI shows its localized default.
      displayName: (row['display_name'] as String? ?? '').trim(),
      progress: progressFromCloud(
        progressRaw == null
            ? null
            : Map<String, dynamic>.from(progressRaw as Map),
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
      childAge: (row['age'] as num?)?.toInt(),
      activity: activity,
    );
  }

  /// Parses the dashboard's `activity_snapshot` envelope
  /// (`{updated_at, snapshot: {...}}`). Returns null when absent or malformed
  /// so a missing snapshot is never shown as zero activity.
  RemoteChildActivity? activityFromDashboardJson(dynamic raw) {
    if (raw is! Map) return null;
    final updatedAt = raw['updated_at'] is String
        ? DateTime.tryParse(raw['updated_at'] as String)?.toUtc()
        : null;
    final snapshot = raw['snapshot'];
    if (updatedAt == null || snapshot is! Map) return null;
    int? count(String key) {
      final value = snapshot[key];
      return value is num && value >= 0 ? value.toInt() : null;
    }

    final dayKey = snapshot['day_key'];
    final currentStreak = count('current_streak');
    final longestStreak = count('longest_streak');
    final activeDays = count('active_days_last_30');
    final totalXp = count('total_xp');
    final readPages = count('read_pages_count');
    final todayActivity = count('today_activity_count');
    final todayReadPages = count('today_read_pages_count');
    if (dayKey is! String ||
        currentStreak == null ||
        longestStreak == null ||
        activeDays == null ||
        totalXp == null ||
        readPages == null ||
        todayActivity == null ||
        todayReadPages == null) {
      return null;
    }
    return RemoteChildActivity(
      updatedAt: updatedAt,
      dayKey: dayKey,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      activeDaysLast30: activeDays,
      totalXp: totalXp,
      readPagesCount: readPages,
      todayActivityCount: todayActivity,
      todayReadPagesCount: todayReadPages,
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
    RemoteChildActivity? activity,
  }) {
    final reviewCount = reviewSummary['review_count'] as int? ?? 0;
    // Servers before `tracked_count` returned one row per ayah as
    // `review_count`; newer ones return the review-event total there.
    final trackedCount = reviewSummary['tracked_count'] as int? ?? reviewCount;
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
    final activeDays =
        activity?.activeDaysLast30 ??
        activityRows
            .where((row) => (row['activity_count'] as int? ?? 0) > 0)
            .length;
    final planSurahId = dailyPlanRow?['surah_id'] as int?;
    final planTotal = dailyPlanRow?['total_items'] as int? ?? 0;
    final planCompleted = dailyPlanRow?['completed_count'] as int? ?? 0;
    final completionPercent = trackedCount == 0
        ? 0.0
        : ((memorizedCount / AppConstants.totalAyahs) * 100).clamp(0.0, 100.0);

    return RemoteChildProductionSummary(
      totalMemorizedAyahs: memorizedCount,
      totalAyahsTracked: trackedCount,
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
      currentStreak:
          streakRow?['current_streak'] as int? ?? activity?.currentStreak,
      longestStreak:
          streakRow?['longest_streak'] as int? ?? activity?.longestStreak,
      activeDaysLast30: activeDays,
      certificates: certificates,
      smartCoachKind: null,
    );
  }
}
