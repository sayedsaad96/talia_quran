import 'unified_journey_action.dart';
import 'unified_journey_input.dart';

class UnifiedJourneyEngine {
  const UnifiedJourneyEngine();

  UnifiedJourneyAction evaluate(UnifiedJourneyInput input) {
    final all = evaluateAll(input);
    return all.first;
  }

  List<UnifiedJourneyAction> evaluateAll(UnifiedJourneyInput input) {
    final actions = <UnifiedJourneyAction>[];

    if (input.lastRestorableLocation != null) {
      actions.add(
        UnifiedJourneyAction(
          route: input.lastRestorableLocation!,
          priority: UnifiedJourneyPriority.p1ActiveSession,
          source: 'AppSessionService',
          actionType: UnifiedJourneyActionType.resumeSession,
          intent: JourneyIntent.resume,
          metadata: _parseResumeMetadata(input.lastRestorableLocation!),
        ),
      );
    }

    if (input.hasCriticalLearningAlert || input.hasHighPriorityLearningAlert) {
      actions.add(
        UnifiedJourneyAction(
          route: input.learningAlertRoute ?? '/memorization',
          priority: UnifiedJourneyPriority.p2CriticalAlert,
          source: 'AdaptiveRecommendations',
          actionType: UnifiedJourneyActionType.criticalAlert,
          intent: JourneyIntent.review,
          metadata: {
            if (input.learningAlertType != null)
              'learningAlertType': input.learningAlertType!.name,
          },
        ),
      );
    }

    if (input.hasReviewBacklog && input.overdueAyahs > 0) {
      actions.add(
        UnifiedJourneyAction(
          route: '/memorization',
          priority: UnifiedJourneyPriority.p3ReviewBacklog,
          source: 'AdaptiveRecommendations',
          actionType: UnifiedJourneyActionType.reviewBacklog,
          intent: JourneyIntent.review,
          metadata: {'overdueAyahs': input.overdueAyahs.toString()},
        ),
      );
    }

    if (input.hasSmartPlan) {
      actions.add(
        UnifiedJourneyAction(
          route: input.smartPlanRoute ?? '/memorization',
          priority: UnifiedJourneyPriority.p4SmartPlan,
          source: 'SmartCoach',
          actionType: UnifiedJourneyActionType.smartPlan,
          intent: input.isSmartPlanReview
              ? JourneyIntent.review
              : JourneyIntent.memorize,
          metadata: {
            if (input.smartPlanType != null)
              'smartPlanType': input.smartPlanType!.name,
          },
        ),
      );
    }

    if (input.hasActiveKhatmah && input.khatmahRoute != null) {
      actions.add(
        UnifiedJourneyAction(
          route: input.khatmahRoute!,
          priority: UnifiedJourneyPriority.p5DailyGoal,
          source: 'Khatmah',
          actionType: UnifiedJourneyActionType.dailyReading,
          intent: JourneyIntent.reading,
        ),
      );
    } else if (input.hasDailyWird && input.dailyWirdPageNumber != null) {
      actions.add(
        UnifiedJourneyAction(
          route: '/quran/page/${input.dailyWirdPageNumber}',
          priority: UnifiedJourneyPriority.p5DailyGoal,
          source: 'DailyWird',
          actionType: UnifiedJourneyActionType.dailyReading,
          intent: JourneyIntent.reading,
        ),
      );
    }

    if (input.hasActiveKhatmah &&
        input.hasDailyWird &&
        input.dailyWirdPageNumber != null &&
        input.khatmahRoute != '/quran/page/${input.dailyWirdPageNumber}') {
      actions.add(
        UnifiedJourneyAction(
          route: '/quran/page/${input.dailyWirdPageNumber}',
          priority: UnifiedJourneyPriority.p5DailyGoal,
          source: 'DailyWird',
          actionType: UnifiedJourneyActionType.dailyReading,
          intent: JourneyIntent.reading,
        ),
      );
    }

    actions.add(_explore(input));
    return actions;
  }

  UnifiedJourneyAction _explore(UnifiedJourneyInput input) {
    if (input.isKids) {
      return const UnifiedJourneyAction(
        route: '/memorization',
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
        route: '/memorization',
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

int journeyActionMinutes(UnifiedJourneyAction action) {
  return switch (action.intent) {
    JourneyIntent.reading => 4,
    JourneyIntent.memorize => 8,
    JourneyIntent.review => 6,
    JourneyIntent.azkar => 5,
    JourneyIntent.resume => 3,
    JourneyIntent.explore => 2,
  };
}
