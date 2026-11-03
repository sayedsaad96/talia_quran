import 'dart:convert';
import '../../../../core/journey/unified_journey_action.dart';
import '../../../../core/journey/unified_journey_engine.dart';
import '../entities/adult_journey_context.dart';
import '../entities/adult_journey_preferences.dart';
import '../entities/adult_journey_suggestion.dart';
import '../entities/daily_review_task.dart';
import 'adult_journey_suggestion_policy.dart';
import 'adult_local_date.dart';

class DailyReviewTaskPolicy {
  const DailyReviewTaskPolicy();

  DailyReviewTaskDecision select({
    required AdultJourneyContext context,
    required AdultJourneyPreferences preferences,
  }) {
    final date = AdultLocalDate.format(context.now.toLocal());
    DailyReviewTaskDecision empty(DailyReviewTaskStatus status) =>
        DailyReviewTaskDecision(
          status: status,
          ownerId: context.ownerId,
          localDate: date,
        );
    if (!context.isAdult || context.ownerId.trim().isEmpty) {
      return empty(DailyReviewTaskStatus.unavailable);
    }
    UnifiedJourneyAction? action;
    var blocked = false;
    for (final item in context.actions) {
      if (item.priority == UnifiedJourneyPriority.p1ActiveSession &&
          AdultJourneySuggestionPolicy.launchKindOf(item) ==
              AdultJourneyLaunchKind.resume) {
        action = item;
        break;
      }
    }
    if (action == null) {
      for (final item in context.actions) {
        if (item.priority == UnifiedJourneyPriority.p2CriticalAlert) {
          blocked = item.intent != JourneyIntent.review;
          action = item;
          break;
        }
      }
    }
    if (action == null) {
      for (final item in context.actions) {
        if (item.intent == JourneyIntent.review) {
          action = item;
          break;
        }
      }
    }
    if (action == null) {
      if (!context.hasAdultReviewRecords) {
        return empty(DailyReviewTaskStatus.noReviews);
      }
      return empty(
        context.hasDueAdultReview
            ? DailyReviewTaskStatus.unavailable
            : DailyReviewTaskStatus.noDueReview,
      );
    }
    final kind = AdultJourneySuggestionPolicy.launchKindOf(action);
    final minutes = journeyActionMinutes(action);
    final budget = preferences.minutesFor(date);
    final exceeds = budget != null && minutes > budget;
    final suggestion = AdultJourneySuggestion(
      action: action,
      launchKind: kind,
      estimatedMinutes: minutes,
      exceedsBudget: exceeds,
      reason: kind == AdultJourneyLaunchKind.resume
          ? AdultJourneySuggestionReason.resume
          : action.priority.index <=
                UnifiedJourneyPriority.p3ReviewBacklog.index
          ? AdultJourneySuggestionReason.urgent
          : budget != null && !exceeds
          ? AdultJourneySuggestionReason.timeFit
          : AdultJourneySuggestionReason.ordinary,
      resumeDestination: kind == AdultJourneyLaunchKind.resume
          ? AdultJourneySuggestionPolicy.resumeDestinationOf(action.route)
          : null,
    );
    return DailyReviewTaskDecision(
      status: blocked
          ? DailyReviewTaskStatus.blockedByPriority
          : DailyReviewTaskStatus.ready,
      ownerId: context.ownerId,
      localDate: date,
      suggestion: suggestion,
      decisionKey: blocked
          ? null
          : jsonEncode([
              context.ownerId,
              date,
              action.actionType.name,
              action.route,
              action.priority.name,
            ]),
    );
  }
}
