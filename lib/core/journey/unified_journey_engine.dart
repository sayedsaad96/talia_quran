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
        route: input.learningAlertRoute ?? '/memorization',
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
        route: '/memorization',
        priority: UnifiedJourneyPriority.p3ReviewBacklog,
        source: 'AdaptiveRecommendations',
        actionType: UnifiedJourneyActionType.reviewBacklog,
        intent: JourneyIntent.review,
        metadata: {'overdueAyahs': input.overdueAyahs.toString()},
      );
    }

    // Priority 4: Smart Plan (Coach / Custom)
    if (input.hasSmartPlan) {
      return UnifiedJourneyAction(
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

  /// Resolves the focused destination and one distinct follow-up. P1–P3
  /// continue to use [evaluate], preserving their existing behavior exactly.
  UnifiedJourneyResolution resolve(UnifiedJourneyInput input) {
    final candidates = _goalCandidates(input);
    final hasUrgentAction =
        input.lastRestorableLocation != null ||
        input.hasCriticalLearningAlert ||
        input.hasHighPriorityLearningAlert ||
        (input.hasReviewBacklog && input.overdueAyahs > 0);

    if (hasUrgentAction) {
      return _resolution(evaluate(input), candidates);
    }

    return _resolution(candidates.first, candidates.skip(1));
  }

  List<UnifiedJourneyAction> _goalCandidates(UnifiedJourneyInput input) {
    final smartPlan = input.hasSmartPlan
        ? UnifiedJourneyAction(
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
          )
        : null;
    final khatmah = input.khatmahCandidate == null
        ? null
        : UnifiedJourneyAction(
            route: input.khatmahCandidate!.route,
            priority: UnifiedJourneyPriority.p4SmartPlan,
            source: 'Khatmah',
            actionType: UnifiedJourneyActionType.khatmahReading,
            intent: JourneyIntent.reading,
          );
    final dailyWird = input.hasDailyWird && input.dailyWirdPageNumber != null
        ? UnifiedJourneyAction(
            route: '/quran/page/${input.dailyWirdPageNumber}',
            priority: UnifiedJourneyPriority.p5DailyGoal,
            source: 'DailyWird',
            actionType: UnifiedJourneyActionType.dailyReading,
            intent: JourneyIntent.reading,
          )
        : null;

    if (input.isKids || input.userGoal == 'child') {
      return const [
        UnifiedJourneyAction(
          route: '/memorization',
          priority: UnifiedJourneyPriority.p6FreeExploration,
          source: 'KidsMode',
          actionType: UnifiedJourneyActionType.explore,
          intent: JourneyIntent.explore,
        ),
      ];
    }

    if (input.userGoal == 'azkar') {
      return [
        const UnifiedJourneyAction(
          route: '/azkar',
          priority: UnifiedJourneyPriority.p6FreeExploration,
          source: 'UserGoal',
          actionType: UnifiedJourneyActionType.explore,
          intent: JourneyIntent.azkar,
        ),
        ?khatmah,
        ?dailyWird,
        ?smartPlan,
        _defaultAction,
      ];
    }

    final readingGoal = input.userGoal == 'reading';
    final memorizationGoal = input.userGoal == 'memorization';
    return [
      if (readingGoal) ?khatmah,
      if (memorizationGoal) ?smartPlan,
      if (readingGoal) ?dailyWird,
      if (!readingGoal && !memorizationGoal) ?smartPlan,
      ?khatmah,
      ?dailyWird,
      _defaultAction,
    ];
  }

  UnifiedJourneyResolution _resolution(
    UnifiedJourneyAction primary,
    Iterable<UnifiedJourneyAction> candidates,
  ) {
    UnifiedJourneyAction? secondary;
    for (final candidate in candidates) {
      if (candidate.route != primary.route) {
        secondary = candidate;
        break;
      }
    }
    return UnifiedJourneyResolution(
      primaryAction: primary,
      secondaryAction: secondary,
    );
  }

  static const _defaultAction = UnifiedJourneyAction(
    route: '/quran',
    priority: UnifiedJourneyPriority.p6FreeExploration,
    source: 'Default',
    actionType: UnifiedJourneyActionType.explore,
    intent: JourneyIntent.explore,
  );

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
