import '../../../../core/journey/unified_journey_action.dart';

/// What the adult-journey overlay may read about the current Home load. Built
/// by a presentation adapter from the existing Home state; the domain never
/// sees Home types or storage.
class AdultJourneyContext {
  const AdultJourneyContext({
    required this.ownerId,
    required this.isAdult,
    required this.now,
    required this.actions,
    required this.hasActiveAdultPlan,
    required this.hasAdultReviewRecords,
    required this.hasDueAdultReview,
  });

  final String ownerId;

  /// True only for a confirmed adult (adult track chosen, not a child). An
  /// unresolved identity is not an adult (spec §5).
  final bool isAdult;

  final DateTime now;

  /// The unified journey's actions in `evaluateAll` order.
  final List<UnifiedJourneyAction> actions;

  final bool hasActiveAdultPlan;
  final bool hasAdultReviewRecords;
  final bool hasDueAdultReview;
}
