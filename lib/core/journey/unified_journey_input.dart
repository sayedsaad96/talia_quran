class UnifiedJourneyInput {
  const UnifiedJourneyInput({
    this.lastRestorableLocation,
    this.hasCriticalLearningAlert = false,
    this.hasHighPriorityLearningAlert = false,
    this.learningAlertTitle,
    this.learningAlertDescription,
    this.learningAlertRoute,
    this.hasReviewBacklog = false,
    this.overdueAyahs = 0,
    this.hasSmartPlan = false,
    this.isSmartPlanReview = false,
    this.smartPlanTitle,
    this.smartPlanDescription,
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
  final String? learningAlertTitle;
  final String? learningAlertDescription;
  final String? learningAlertRoute;

  // Review Backlog (Priority 3)
  final bool hasReviewBacklog;
  final int overdueAyahs;

  // Smart Plan / Coach (Priority 4)
  final bool hasSmartPlan;
  final bool isSmartPlanReview;
  final String? smartPlanTitle;
  final String? smartPlanDescription;
  final String? smartPlanRoute;

  // Daily Goal / Wird (Priority 5)
  final bool hasDailyWird;
  final int? dailyWirdPageNumber;

  // Fallbacks / Context (Priority 6)
  final bool isKids;
  final String? userGoal;
}
