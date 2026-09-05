import '../../features/memorization_plus/domain/entities/memorization_recommendation.dart';

enum SmartPlanType { continueMemorization, reviewPlan, customPlan }

class UnifiedJourneyInput {
  const UnifiedJourneyInput({
    this.lastRestorableLocation,
    this.hasCriticalLearningAlert = false,
    this.hasHighPriorityLearningAlert = false,
    this.learningAlertType,
    this.learningAlertRoute,
    this.hasReviewBacklog = false,
    this.overdueAyahs = 0,
    this.hasSmartPlan = false,
    this.isSmartPlanReview = false,
    this.khatmahCandidate,
    this.smartPlanType,
    this.smartPlanRoute,
    this.hasDailyWird = false,
    this.dailyWirdPageNumber,
    this.isKids = false,
    this.userGoal,
  });

  final String? lastRestorableLocation;

  // Adaptive/Critical Alerts (Priority 2)
  final bool hasCriticalLearningAlert;
  final bool hasHighPriorityLearningAlert;
  final RecommendationType? learningAlertType;
  final String? learningAlertRoute;

  // Review Backlog (Priority 3)
  final bool hasReviewBacklog;
  final int overdueAyahs;

  // Smart Plan / Coach (Priority 4)
  final bool hasSmartPlan;
  final bool isSmartPlanReview;

  /// Active reader destination supplied by the Khatmah feature.
  final KhatmahJourneyCandidate? khatmahCandidate;

  final SmartPlanType? smartPlanType;
  final String? smartPlanRoute;

  // Daily Goal / Wird (Priority 5)
  final bool hasDailyWird;
  final int? dailyWirdPageNumber;

  // Fallbacks / Context (Priority 6)
  final bool isKids;
  final String? userGoal;
}

/// Immutable, feature-neutral Khatmah reader candidate.
///
/// Its presence means the Khatmah feature has already established that the
/// current plan is active and safe to continue. The journey engine never
/// controls Khatmah state transitions.
class KhatmahJourneyCandidate {
  const KhatmahJourneyCandidate({required this.route});

  final String route;
}
