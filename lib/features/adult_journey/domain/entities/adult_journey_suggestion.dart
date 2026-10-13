import 'package:equatable/equatable.dart';

import '../../../../core/journey/unified_journey_action.dart';

enum AdultJourneyLaunchKind {
  resume,
  reading,
  khatmah,
  memorize,
  review,
  azkar,
  explore,

  /// No memorization plan yet: open the existing plan setup.
  setupPlan,
}

enum AdultJourneySuggestionReason {
  /// p1 resume: kept first whatever the goal or time.
  resume,

  /// p2/p3 critical alert or review backlog: never reordered.
  urgent,
  goalMatch,
  timeFit,

  /// An ordinary optional suggestion in its original order.
  ordinary,

  /// Memorization goal without a plan.
  needsPlan,

  /// Review goal without anything memorized to review.
  noReview,
  estimateUnavailable,
}

/// Where a resume reminder may safely lead. The stored session URL itself is
/// never reopened from the new card (spec §6).
enum AdultResumeDestination { memorization, quran, azkar, unknown }

class AdultJourneySuggestion extends Equatable {
  const AdultJourneySuggestion({
    required this.launchKind,
    required this.reason,
    this.action,
    this.estimatedMinutes,
    this.exceedsBudget = false,
    this.resumeDestination,
  });

  /// The existing journey action, or null for an explained destination
  /// (plan setup / nothing to review).
  final UnifiedJourneyAction? action;
  final AdultJourneyLaunchKind launchKind;

  /// Approximate minutes from `journeyActionMinutes`; null when unknown.
  final int? estimatedMinutes;

  /// The estimate is longer than today's choice. The item stays shown.
  final bool exceedsBudget;
  final AdultJourneySuggestionReason reason;
  final AdultResumeDestination? resumeDestination;

  @override
  List<Object?> get props => [
    action?.route,
    launchKind,
    estimatedMinutes,
    exceedsBudget,
    reason,
    resumeDestination,
  ];
}
