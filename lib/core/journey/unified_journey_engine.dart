import 'unified_journey_action.dart';
import 'unified_journey_input.dart';

class UnifiedJourneyEngine {
  const UnifiedJourneyEngine();

  UnifiedJourneyAction evaluate(UnifiedJourneyInput input) {
    // Priority 1: Active Session
    if (input.lastRestorableLocation != null) {
      return UnifiedJourneyAction(
        route: input.lastRestorableLocation!,
        priority: UnifiedJourneyPriority.p1ActiveSession,
        source: 'AppSessionService',
        actionType: UnifiedJourneyActionType.resumeSession,
        intent: JourneyIntent.resume,
        metadata: _parseResumeMetadata(input.lastRestorableLocation!),
      );
    }

    // Priority 2: Critical / High Priority Learning Alerts (e.g. Overload / Leech)
    if (input.hasCriticalLearningAlert || input.hasHighPriorityLearningAlert) {
      return UnifiedJourneyAction(
        route: input.learningAlertRoute ?? '/memorization_hub',
        priority: UnifiedJourneyPriority.p2CriticalAlert,
        source: 'AdaptiveRecommendations',
        actionType: UnifiedJourneyActionType.criticalAlert,
        intent: JourneyIntent.review,
        metadata: {
          if (input.learningAlertType != null)
            'learningAlertType': input.learningAlertType!.name,
        },
      );
    }

    // Priority 3: Review Backlog
    if (input.hasReviewBacklog && input.overdueAyahs > 0) {
      return UnifiedJourneyAction(
        route: '/memorization_hub',
        priority: UnifiedJourneyPriority.p3ReviewBacklog,
        source: 'AdaptiveRecommendations',
        actionType: UnifiedJourneyActionType.reviewBacklog,
        intent: JourneyIntent.review,
        metadata: {
          'overdueAyahs': input.overdueAyahs.toString(),
        },
      );
    }

    // Priority 4: Smart Plan (Coach / Custom)
    if (input.hasSmartPlan) {
      return UnifiedJourneyAction(
        route: input.smartPlanRoute ?? '/memorization_hub',
        priority: UnifiedJourneyPriority.p4SmartPlan,
        source: 'SmartCoach',
        actionType: UnifiedJourneyActionType.smartPlan,
        intent: input.isSmartPlanReview ? JourneyIntent.review : JourneyIntent.memorize,
        metadata: {
          if (input.smartPlanType != null)
            'smartPlanType': input.smartPlanType!.name,
        },
      );
    }

    // Priority 5: Daily Goal (Wird)
    if (input.hasDailyWird && input.dailyWirdPageNumber != null) {
      return UnifiedJourneyAction(
        route: '/quran/page/${input.dailyWirdPageNumber}',
        priority: UnifiedJourneyPriority.p5DailyGoal,
        source: 'DailyWird',
        actionType: UnifiedJourneyActionType.dailyReading,
        intent: JourneyIntent.reading,
      );
    }

    // Priority 6: Free Exploration / Contextual Fallbacks
    if (input.isKids) {
      return const UnifiedJourneyAction(
        route: '/memorization_hub',
        priority: UnifiedJourneyPriority.p6FreeExploration,
        source: 'KidsMode',
        actionType: UnifiedJourneyActionType.explore,
        intent: JourneyIntent.explore,
      );
    }

    if (input.userGoal == 'azkar') {
      return const UnifiedJourneyAction(
        route: '/azkar',
        priority: UnifiedJourneyPriority.p6FreeExploration,
        source: 'UserGoal',
        actionType: UnifiedJourneyActionType.explore,
        intent: JourneyIntent.azkar,
      );
    }
    
    if (input.userGoal == 'child') {
      return const UnifiedJourneyAction(
        route: '/memorization_hub',
        priority: UnifiedJourneyPriority.p6FreeExploration,
        source: 'UserGoal',
        actionType: UnifiedJourneyActionType.explore,
        intent: JourneyIntent.explore,
      );
    }

    return const UnifiedJourneyAction(
      route: '/quran',
      priority: UnifiedJourneyPriority.p6FreeExploration,
      source: 'Default',
      actionType: UnifiedJourneyActionType.explore,
      intent: JourneyIntent.explore,
    );
  }

  Map<String, String> _parseResumeMetadata(String location) {
    final uri = Uri.tryParse(location);
    if (uri == null) return {};
    
    final metadata = <String, String>{};
    if (uri.queryParameters.containsKey('surahId')) {
      metadata['surahId'] = uri.queryParameters['surahId']!;
    }
    if (uri.queryParameters.containsKey('startAyah')) {
      metadata['startAyah'] = uri.queryParameters['startAyah']!;
    }
    if (uri.queryParameters.containsKey('ayahNumber')) {
      metadata['ayahNumber'] = uri.queryParameters['ayahNumber']!;
    }
    if (uri.pathSegments.length >= 3) {
      metadata['pathSegment2'] = uri.pathSegments[2];
    }
    return metadata;
  }
}
