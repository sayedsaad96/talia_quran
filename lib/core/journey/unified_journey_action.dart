enum JourneyIntent {
  resume,
  review,
  memorize,
  reading,
  azkar,
  explore,
}

enum UnifiedJourneyPriority {
  p1ActiveSession,
  p2CriticalAlert,
  p3ReviewBacklog,
  p4SmartPlan,
  p5DailyGoal,
  p6FreeExploration,
}

enum UnifiedJourneyActionType {
  resumeSession,
  criticalAlert,
  reviewBacklog,
  smartPlan,
  dailyReading,
  explore,
}

class UnifiedJourneyAction {
  const UnifiedJourneyAction({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.priority,
    required this.source,
    required this.actionType,
    required this.intent,
    this.metadata = const {},
  });

  final String title;
  final String subtitle;
  final String route;
  final UnifiedJourneyPriority priority;
  final String source;
  final UnifiedJourneyActionType actionType;
  final JourneyIntent intent;
  final Map<String, String> metadata;
}
