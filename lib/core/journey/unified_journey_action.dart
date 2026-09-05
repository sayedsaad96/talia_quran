enum JourneyIntent { resume, review, memorize, reading, azkar, explore }

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
  khatmahReading,
  dailyReading,
  explore,
}

class UnifiedJourneyAction {
  const UnifiedJourneyAction({
    required this.route,
    required this.priority,
    required this.source,
    required this.actionType,
    required this.intent,
    this.metadata = const {},
  });

  final String route;
  final UnifiedJourneyPriority priority;
  final String source;
  final UnifiedJourneyActionType actionType;
  final JourneyIntent intent;
  final Map<String, String> metadata;
}

/// The calm, ordered journey actions exposed to Home.
class JourneyResolution {
  const JourneyResolution({required this.primaryAction, this.secondaryAction});

  final UnifiedJourneyAction primaryAction;
  final UnifiedJourneyAction? secondaryAction;

  /// Short aliases keep the resolution comfortable to consume in UI code.
  UnifiedJourneyAction get primary => primaryAction;
  UnifiedJourneyAction? get secondary => secondaryAction;
}

/// Temporary compatibility name while Home migrates to [JourneyResolution].
typedef UnifiedJourneyResolution = JourneyResolution;
