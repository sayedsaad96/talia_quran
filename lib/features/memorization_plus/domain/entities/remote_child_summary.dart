import 'package:equatable/equatable.dart';

import '../../../../core/memorization/smart_coach_recommendation.dart';
import 'kids_progress.dart';
import 'kids_session_log.dart';
import 'parent_dashboard.dart';

class RemoteChildSummary extends Equatable {
  const RemoteChildSummary({
    required this.childUserId,
    required this.displayName,
    required this.progress,
    required this.logs,
    required this.rewards,
    this.production,
  });

  final String childUserId;
  final String displayName;
  final KidsProgress progress;
  final List<KidsSessionLog> logs;
  final List<ParentReward> rewards;

  /// Additive Phase 7 production-sync summary (V2 SRS, daily plan,
  /// certificates, streak, heatmap, Smart Coach). Null when the cloud rows
  /// could not be read (e.g. RLS not yet applied, or child never synced).
  final RemoteChildProductionSummary? production;

  @override
  List<Object?> get props => [
    childUserId,
    displayName,
    progress,
    logs,
    rewards,
    production,
  ];
}

/// A single certificate earned by a linked child, as mirrored to
/// `certificate_awards_cloud`.
class RemoteCertificateAward extends Equatable {
  const RemoteCertificateAward({
    required this.certId,
    required this.titleAr,
    required this.certType,
    required this.earnedAt,
  });

  final String certId;
  final String titleAr;
  final String certType;
  final DateTime earnedAt;

  @override
  List<Object?> get props => [certId, titleAr, certType, earnedAt];
}

/// Aggregated production-state summary for a linked child, reconstructed on
/// the parent device from the Phase 7 cloud sync tables
/// (`ayah_review_records_cloud`, `daily_plans_cloud`,
/// `certificate_awards_cloud`, `streaks`, `daily_activities`).
///
/// This is purely a read-side reconstruction: the underlying classification
/// (`ReviewClassification`) and recommendation (`SmartCoachEngine`) logic is
/// reused as-is, fed by these synced rows — no second engine is introduced.
class RemoteChildProductionSummary extends Equatable {
  const RemoteChildProductionSummary({
    required this.totalMemorizedAyahs,
    required this.totalAyahsTracked,
    required this.completionPercent,
    this.currentSurahId,
    this.lastMemorizedSurahId,
    this.lastMemorizedAyahNumber,
    this.lastMemorizedAt,
    required this.reviewsCompleted,
    required this.reviewsOverdue,
    this.nextReviewAt,
    this.dailyPlanSurahId,
    required this.dailyPlanTotal,
    required this.dailyPlanCompleted,
    this.currentStreak,
    this.longestStreak,
    required this.activeDaysLast30,
    this.certificates = const [],
    this.smartCoachKind,
  });

  final int totalMemorizedAyahs;
  final int totalAyahsTracked;
  final double completionPercent;
  final int? currentSurahId;
  final int? lastMemorizedSurahId;
  final int? lastMemorizedAyahNumber;
  final DateTime? lastMemorizedAt;
  final int reviewsCompleted;
  final int reviewsOverdue;
  final DateTime? nextReviewAt;
  final int? dailyPlanSurahId;
  final int dailyPlanTotal;
  final int dailyPlanCompleted;
  final int? currentStreak;
  final int? longestStreak;

  /// Number of distinct UTC calendar days with recorded activity in the
  /// trailing 30-day window (lightweight heatmap summary).
  final int activeDaysLast30;
  final List<RemoteCertificateAward> certificates;

  /// Learning-status label source; `null` when no recommendation applies.
  final SmartCoachRecommendationKind? smartCoachKind;

  int get dailyPlanRemaining =>
      (dailyPlanTotal - dailyPlanCompleted).clamp(0, dailyPlanTotal);

  @override
  List<Object?> get props => [
    totalMemorizedAyahs,
    totalAyahsTracked,
    completionPercent,
    currentSurahId,
    lastMemorizedSurahId,
    lastMemorizedAyahNumber,
    lastMemorizedAt,
    reviewsCompleted,
    reviewsOverdue,
    nextReviewAt,
    dailyPlanSurahId,
    dailyPlanTotal,
    dailyPlanCompleted,
    currentStreak,
    longestStreak,
    activeDaysLast30,
    certificates,
    smartCoachKind,
  ];
}
