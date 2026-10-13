import '../../../core/router/app_router.dart';
import '../domain/entities/adult_journey_suggestion.dart';

/// Phase A destinations for the overlay's suggestions. Only `AppRoutes`
/// constants or an existing action's own route are returned; a stored session
/// URL is never reopened from the new card (spec §6). A null result means the
/// suggestion is shown but not tappable.
String? adultJourneySafeRoute(AdultJourneySuggestion suggestion) {
  switch (suggestion.launchKind) {
    case AdultJourneyLaunchKind.resume:
      return switch (suggestion.resumeDestination) {
        AdultResumeDestination.memorization => AppRoutes.memorizationHub,
        AdultResumeDestination.quran => AppRoutes.quran,
        AdultResumeDestination.azkar => AppRoutes.azkar,
        AdultResumeDestination.unknown || null => null,
      };
    case AdultJourneyLaunchKind.setupPlan:
      return AppRoutes.memorizationPlusCustomPlan;
    case AdultJourneyLaunchKind.reading:
    case AdultJourneyLaunchKind.khatmah:
    case AdultJourneyLaunchKind.memorize:
    case AdultJourneyLaunchKind.review:
    case AdultJourneyLaunchKind.azkar:
    case AdultJourneyLaunchKind.explore:
      return suggestion.action?.route ?? _syntheticRoute(suggestion.launchKind);
  }
}

String? _syntheticRoute(AdultJourneyLaunchKind kind) {
  return switch (kind) {
    AdultJourneyLaunchKind.memorize ||
    AdultJourneyLaunchKind.review => AppRoutes.memorizationHub,
    AdultJourneyLaunchKind.reading ||
    AdultJourneyLaunchKind.khatmah ||
    AdultJourneyLaunchKind.explore => AppRoutes.quran,
    AdultJourneyLaunchKind.azkar => AppRoutes.azkar,
    _ => null,
  };
}
