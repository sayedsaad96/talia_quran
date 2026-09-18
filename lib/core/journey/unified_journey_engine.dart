import '../memorization/smart_coach_recommendation.dart';
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
    final coach = input.coachRecommendation;

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
          route: coach?.route ?? input.learningAlertRoute ?? '/memorization',
          priority: UnifiedJourneyPriority.p2CriticalAlert,
          source: coach == null ? 'AdaptiveRecommendations' : 'SmartCoach',
          actionType: UnifiedJourneyActionType.criticalAlert,
          intent: coach == null ? JourneyIntent.review : _coachIntent(coach),
          metadata: {
            if (input.learningAlertType != null)
              'learningAlertType': input.learningAlertType!.name,
            ..._coachMetadata(coach),
          },
          coachRecommendation: coach,
        ),
      );
    }

    if (input.hasReviewBacklog && input.overdueAyahs > 0) {
      actions.add(
        UnifiedJourneyAction(
          route: coach?.route ?? input.reviewBacklogRoute ?? '/memorization',
          priority: UnifiedJourneyPriority.p3ReviewBacklog,
          source: coach == null ? 'AdaptiveRecommendations' : 'SmartCoach',
          actionType: UnifiedJourneyActionType.reviewBacklog,
          intent: coach == null ? JourneyIntent.review : _coachIntent(coach),
          metadata: {
            'overdueAyahs': input.overdueAyahs.toString(),
            ..._coachMetadata(coach),
          },
          coachRecommendation: coach,
        ),
      );
    }

    if (input.hasSmartPlan) {
      actions.add(
        UnifiedJourneyAction(
          route: coach?.route ?? input.smartPlanRoute ?? '/memorization',
          priority: UnifiedJourneyPriority.p4SmartPlan,
          source: coach == null ? 'CustomMemorizationPlan' : 'SmartCoach',
          actionType: UnifiedJourneyActionType.smartPlan,
          intent: coach == null
              ? (input.isSmartPlanReview
                    ? JourneyIntent.review
                    : JourneyIntent.memorize)
              : _coachIntent(coach),
          metadata: {
            if (input.smartPlanType != null)
              'smartPlanType': input.smartPlanType!.name,
            ..._coachMetadata(coach),
          },
          coachRecommendation: coach,
        ),
      );
    }

    // Khatmah and daily wird are independent tracks — both are added when present.
    if (input.hasActiveKhatmah && input.khatmahRoute != null) {
      actions.add(
        UnifiedJourneyAction(
          route: input.khatmahRoute!,
          priority: UnifiedJourneyPriority.p5DailyGoal,
          source: 'Khatmah',
          actionType: UnifiedJourneyActionType.khatmah,
          intent: JourneyIntent.reading,
        ),
      );
    }

    if (input.hasDailyWird && input.dailyWirdPageNumber != null) {
      actions.add(
        UnifiedJourneyAction(
          route: '/quran/page/${input.dailyWirdPageNumber}',
          priority: UnifiedJourneyPriority.p5DailyGoal,
          source: 'DailyWird',
          actionType: UnifiedJourneyActionType.dailyReading,
          intent: JourneyIntent.reading,
          metadata: {
            'pageNumber': '${input.dailyWirdPageNumber}',
            if (input.dailyWirdSurahNameAr != null)
              'surahNameAr': input.dailyWirdSurahNameAr!,
            if (input.dailyWirdSurahNameEn != null)
              'surahNameEn': input.dailyWirdSurahNameEn!,
          },
        ),
      );
    }

    actions.add(_explore(input));
    return _deduplicateRoutes(actions);
  }

  List<UnifiedJourneyAction> _deduplicateRoutes(
    List<UnifiedJourneyAction> actions,
  ) {
    final routes = <String>{};
    return actions.where((action) => routes.add(action.route)).toList();
  }

  JourneyIntent _coachIntent(SmartCoachRecommendation coach) {
    return switch (coach.kind) {
      SmartCoachRecommendationKind.reviewDueNear ||
      SmartCoachRecommendationKind.reviewDueFar ||
      SmartCoachRecommendationKind.memorizedReviewDue ||
      SmartCoachRecommendationKind.reviewWeakAyah => JourneyIntent.review,
      SmartCoachRecommendationKind.continueDailyPlan ||
      SmartCoachRecommendationKind.memorizeNewAyahs ||
      SmartCoachRecommendationKind.kidsCurrentMission ||
      SmartCoachRecommendationKind.continueV2Session => JourneyIntent.memorize,
    };
  }

  Map<String, String> _coachMetadata(SmartCoachRecommendation? coach) => {
    if (coach != null) 'smartCoachKind': coach.kind.name,
    if (coach?.explanationCode != null)
      'smartCoachExplanation': coach!.explanationCode!.name,
  };

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
