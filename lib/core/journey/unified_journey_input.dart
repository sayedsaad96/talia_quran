import '../../features/memorization_plus/domain/entities/memorization_recommendation.dart';
import '../memorization/smart_coach_recommendation.dart';

enum SmartPlanType {
  continueMemorization,
  reviewPlan,
  customPlan,
}

class UnifiedJourneyInput {
  const UnifiedJourneyInput({
    this.lastRestorableLocation,
    this.hasCriticalLearningAlert = false,
    this.hasHighPriorityLearningAlert = false,
    this.learningAlertType,
    this.learningAlertRoute,
    this.coachRecommendation,
    this.hasReviewBacklog = false,
    this.overdueAyahs = 0,
    this.reviewBacklogRoute,
    this.hasSmartPlan = false,
    this.isSmartPlanReview = false,
    this.smartPlanType,
    this.smartPlanRoute,
    this.hasDailyWird = false,
    this.dailyWirdPageNumber,
    this.dailyWirdSurahNameAr,
    this.dailyWirdSurahNameEn,
    this.hasActiveKhatmah = false,
    this.khatmahRoute,
    this.isKids = false,
    this.userGoal,
  });

  final String? lastRestorableLocation;

  // Adaptive/Critical Alerts (Priority 2)
  final bool hasCriticalLearningAlert;
  final bool hasHighPriorityLearningAlert;
  final RecommendationType? learningAlertType;
  final String? learningAlertRoute;
  final SmartCoachRecommendation? coachRecommendation;

  // Review Backlog (Priority 3)
  final bool hasReviewBacklog;
  final int overdueAyahs;
  final String? reviewBacklogRoute;

  // Smart Plan / Coach (Priority 4)
  final bool hasSmartPlan;
  final bool isSmartPlanReview;
  final SmartPlanType? smartPlanType;
  final String? smartPlanRoute;

  // Daily Goal / Wird (Priority 5)
  final bool hasDailyWird;
  final int? dailyWirdPageNumber;
  final String? dailyWirdSurahNameAr;
  final String? dailyWirdSurahNameEn;
  final bool hasActiveKhatmah;
  final String? khatmahRoute;

  // Fallbacks / Context (Priority 6)
  final bool isKids;
  final String? userGoal;
}
