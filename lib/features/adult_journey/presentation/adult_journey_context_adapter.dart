import '../../../core/journey/unified_journey_action.dart';
import '../../home/presentation/cubits/home_cubit.dart';
import '../../memorization_plus/domain/entities/memorization_entities.dart';
import '../domain/entities/adult_journey_context.dart';

/// Builds the overlay's [AdultJourneyContext] from the current [HomeLoaded].
/// Uses only fields Home already loads; `HomeCubit` and `home_state` are not
/// touched (spec §6).
///
/// Derivations (kept conservative, none reads storage):
/// - `isAdult`: adult track chosen AND not a child. `HomeCubit` treats a
///   missing profile as an adult (`isKids == false`, `selectedTrack == null`),
///   so `!isKids` alone is not enough (spec §5).
/// - `actions`: [HomeLoaded.alternativeActions], the full `evaluateAll`
///   list, order kept.
/// - `hasActiveAdultPlan`: same rule as the navigation resolver: an active
///   custom plan that targets an adult.
/// - `hasAdultReviewRecords`: Home's micro-review pick comes from adult-scoped
///   review records, so a non-null pick proves records exist; otherwise only
///   `progress.memorizedAyahs > 0` is trusted.
/// - `hasDueAdultReview`: overdue count above zero, or the journey itself
///   lists a review-backlog action.
AdultJourneyContext buildAdultJourneyContext({
  required HomeLoaded state,
  required String ownerId,
  required DateTime now,
}) {
  final plan = state.customPlan;
  return AdultJourneyContext(
    ownerId: ownerId,
    isAdult: state.selectedTrack == MemorizationTrack.adults && !state.isKids,
    now: now,
    actions: List.unmodifiable(state.alternativeActions),
    hasActiveAdultPlan:
        plan != null &&
        plan.isActive &&
        plan.targetUser == PlanTargetUser.adult,
    hasAdultReviewRecords:
        state.microReview != null || state.progress.memorizedAyahs > 0,
    hasDueAdultReview:
        state.progress.overdueReviews > 0 ||
        state.alternativeActions.any(
          (a) => a.actionType == UnifiedJourneyActionType.reviewBacklog,
        ),
  );
}
