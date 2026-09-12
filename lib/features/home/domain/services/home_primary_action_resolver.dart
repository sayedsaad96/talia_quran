import '../../../../core/journey/unified_journey_action.dart';

/// The resolved primary slot of the home screen (spec 2026-09-12, 3.2).
enum HomePrimaryActionKind { khatmahContinue, journeyHero, startKhatmah }

/// Pure decision for the home primary slot - no BuildContext, no DI.
///
/// Contract (spec 3.2 as amended):
/// 1. An active khatmah always wins: the recitation card is strictly
///    khatmah-gated.
/// 2. With the unified journey on, a learning-critical hero action
///    (p1ActiveSession..p4SmartPlan) keeps the journey hero.
/// 3. Otherwise the invitation to start a khatmah takes the slot.
class HomePrimaryActionResolver {
  const HomePrimaryActionResolver();

  /// [heroPriority] must be null only when there is no hero action.
  HomePrimaryActionKind resolve({
    required bool unifiedJourneyEnabled,
    required bool hasContinueRecitation,
    required UnifiedJourneyPriority? heroPriority,
  }) {
    if (hasContinueRecitation) return HomePrimaryActionKind.khatmahContinue;
    final isLearningCritical =
        heroPriority != null &&
        heroPriority.index <= UnifiedJourneyPriority.p4SmartPlan.index;
    if (unifiedJourneyEnabled && isLearningCritical) {
      return HomePrimaryActionKind.journeyHero;
    }
    return HomePrimaryActionKind.startKhatmah;
  }
}
