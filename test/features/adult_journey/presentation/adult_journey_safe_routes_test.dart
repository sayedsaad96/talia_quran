import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_suggestion.dart';
import 'package:talia_quran/features/adult_journey/domain/services/adult_journey_suggestion_policy.dart';
import 'package:talia_quran/features/adult_journey/presentation/adult_journey_safe_routes.dart';

UnifiedJourneyAction _action(
  String route,
  UnifiedJourneyActionType type,
  JourneyIntent intent,
) => UnifiedJourneyAction(
  route: route,
  priority: UnifiedJourneyPriority.p1ActiveSession,
  source: 'test',
  actionType: type,
  intent: intent,
);

AdultJourneySuggestion _resume(AdultResumeDestination destination) =>
    AdultJourneySuggestion(
      launchKind: AdultJourneyLaunchKind.resume,
      reason: AdultJourneySuggestionReason.resume,
      action: _action(
        '/memorization-v2/session?surah=2&ayah=255&token=stored',
        UnifiedJourneyActionType.resumeSession,
        JourneyIntent.resume,
      ),
      resumeDestination: destination,
    );

void main() {
  test('resume opens the section constant, never the stored URL', () {
    expect(
      adultJourneySafeRoute(_resume(AdultResumeDestination.memorization)),
      AppRoutes.memorizationHub,
    );
    expect(
      adultJourneySafeRoute(_resume(AdultResumeDestination.quran)),
      AppRoutes.quran,
    );
    expect(
      adultJourneySafeRoute(_resume(AdultResumeDestination.azkar)),
      AppRoutes.azkar,
    );
  });

  test('unknown or missing resume destination is not tappable', () {
    expect(
      adultJourneySafeRoute(_resume(AdultResumeDestination.unknown)),
      isNull,
    );
    expect(
      adultJourneySafeRoute(
        const AdultJourneySuggestion(
          launchKind: AdultJourneyLaunchKind.resume,
          reason: AdultJourneySuggestionReason.resume,
        ),
      ),
      isNull,
    );
  });

  test('a kids resume location maps to unknown and so to null', () {
    final destination = AdultJourneySuggestionPolicy.resumeDestinationOf(
      '/memorization-plus/kids-home',
    );
    expect(destination, AdultResumeDestination.unknown);
    expect(adultJourneySafeRoute(_resume(destination)), isNull);
  });

  test('setupPlan opens the existing plan setup', () {
    expect(
      adultJourneySafeRoute(
        const AdultJourneySuggestion(
          launchKind: AdultJourneyLaunchKind.setupPlan,
          reason: AdultJourneySuggestionReason.needsPlan,
        ),
      ),
      AppRoutes.memorizationPlusCustomPlan,
    );
  });

  test('action-backed non-resume suggestions use the action route', () {
    final suggestion = AdultJourneySuggestion(
      launchKind: AdultJourneyLaunchKind.review,
      reason: AdultJourneySuggestionReason.ordinary,
      action: _action(
        '/memorization-v2/session?review=1',
        UnifiedJourneyActionType.smartPlan,
        JourneyIntent.review,
      ),
    );
    expect(
      adultJourneySafeRoute(suggestion),
      '/memorization-v2/session?review=1',
    );
  });

  test('synthetic suggestions use section constants', () {
    String? route(AdultJourneyLaunchKind kind) => adultJourneySafeRoute(
      AdultJourneySuggestion(
        launchKind: kind,
        reason: AdultJourneySuggestionReason.goalMatch,
      ),
    );
    expect(route(AdultJourneyLaunchKind.memorize), AppRoutes.memorizationHub);
    expect(route(AdultJourneyLaunchKind.review), AppRoutes.memorizationHub);
    expect(route(AdultJourneyLaunchKind.reading), AppRoutes.quran);
    expect(route(AdultJourneyLaunchKind.azkar), AppRoutes.azkar);
  });
}
