import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/adult_journey/application/adult_journey_launch_resolver.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_suggestion.dart';

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => true;
}

const _todayPlan =
    '/memorization-plus/v2/session?surahId=2&intent=continueDailyPlan';
const _reviewQuiz = '/memorization-plus/v2/session?surahId=67&intent=review';

AdultJourneySuggestion _suggestion(
  AdultJourneyLaunchKind kind, {
  UnifiedJourneyAction? action,
  AdultResumeDestination? resume,
}) => AdultJourneySuggestion(
  launchKind: kind,
  reason: AdultJourneySuggestionReason.ordinary,
  action: action,
  resumeDestination: resume,
);

UnifiedJourneyAction _action(String route, JourneyIntent intent) =>
    UnifiedJourneyAction(
      route: route,
      priority: UnifiedJourneyPriority.p4SmartPlan,
      source: 'test',
      actionType: UnifiedJourneyActionType.smartPlan,
      intent: intent,
    );

void main() {
  late _MutableOwner owner;
  late AccountDataBarrier barrier;
  late AdultMemorizationDestinations destinations;
  late int lookups;
  Completer<void>? holdLookup;
  late AdultJourneyLaunchResolver resolver;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    barrier = AccountDataBarrier.forPreferences(
      await SharedPreferences.getInstance(),
    );
    owner = _MutableOwner('owner-a');
    destinations = const AdultMemorizationDestinations(
      isChild: false,
      todayPlanLocation: _todayPlan,
      reviewQuizLocation: _reviewQuiz,
    );
    lookups = 0;
    holdLookup = null;
    resolver = AdultJourneyLaunchResolver(
      owner: owner,
      captureLease: barrier.capture,
      memorizationDestinations: () async {
        lookups++;
        await holdLookup?.future;
        return destinations;
      },
    );
  });

  Future<String?> resolve(AdultJourneySuggestion s, {String? ownerId}) =>
      resolver.resolve(suggestion: s, expectedOwnerId: ownerId ?? 'owner-a');

  group('memorization is resolved at tap time', () {
    test(
      'review uses the latest review location, not the card route',
      () async {
        final card = _suggestion(
          AdultJourneyLaunchKind.review,
          action: _action(
            '/memorization-plus/v2/session?stale=1',
            JourneyIntent.review,
          ),
        );
        destinations = const AdultMemorizationDestinations(
          isChild: false,
          todayPlanLocation: _todayPlan,
          reviewQuizLocation:
              '/memorization-plus/v2/session?surahId=36&intent=review',
        );
        expect(
          await resolve(card),
          '/memorization-plus/v2/session?surahId=36&intent=review',
        );
        expect(lookups, 1);
      },
    );

    test('memorize uses today\'s plan location exactly as resolved', () async {
      final route = await resolve(_suggestion(AdultJourneyLaunchKind.memorize));
      expect(route, _todayPlan);
      final uri = Uri.parse(route!);
      expect(uri.queryParameters.containsKey('blockSize'), isFalse);
      expect(uri.queryParameters['intent'], 'continueDailyPlan');
      expect(uri.queryParameters.containsKey('origin'), isFalse);
    });

    test(
      'an ended plan follows the resolver to plan setup, not a session',
      () async {
        destinations = const AdultMemorizationDestinations(
          isChild: false,
          todayPlanLocation: AppRoutes.memorizationPlusCustomPlan,
          reviewQuizLocation: _reviewQuiz,
        );
        expect(
          await resolve(_suggestion(AdultJourneyLaunchKind.memorize)),
          AppRoutes.memorizationPlusCustomPlan,
        );
      },
    );

    test(
      'review with nothing memorized opens the hub, which explains',
      () async {
        destinations = const AdultMemorizationDestinations(
          isChild: false,
          todayPlanLocation: AppRoutes.memorizationPlusCustomPlan,
          reviewQuizLocation: AppRoutes.memorizationPlusCustomPlan,
        );
        expect(
          await resolve(_suggestion(AdultJourneyLaunchKind.review)),
          AppRoutes.memorizationHub,
        );
      },
    );

    test('plan setup opens the existing custom plan screen', () async {
      expect(
        await resolve(_suggestion(AdultJourneyLaunchKind.setupPlan)),
        AppRoutes.memorizationPlusCustomPlan,
      );
    });

    test('a child profile gets no destination', () async {
      destinations = const AdultMemorizationDestinations(
        isChild: true,
        todayPlanLocation: _todayPlan,
        reviewQuizLocation: _reviewQuiz,
      );
      for (final kind in [
        AdultJourneyLaunchKind.memorize,
        AdultJourneyLaunchKind.review,
        AdultJourneyLaunchKind.setupPlan,
      ]) {
        expect(await resolve(_suggestion(kind)), isNull, reason: kind.name);
      }
    });

    test('a failed lookup falls back to the hub', () async {
      resolver = AdultJourneyLaunchResolver(
        owner: owner,
        captureLease: barrier.capture,
        memorizationDestinations: () async => throw StateError('isar'),
      );
      expect(
        await resolve(_suggestion(AdultJourneyLaunchKind.review)),
        AppRoutes.memorizationHub,
      );
    });
  });

  group('account changes', () {
    test('a different current owner opens nothing', () async {
      expect(
        await resolve(
          _suggestion(AdultJourneyLaunchKind.review),
          ownerId: 'owner-b',
        ),
        isNull,
      );
      expect(lookups, 0);
    });

    test('an owner switch during the lookup opens nothing', () async {
      holdLookup = Completer<void>();
      final pending = resolve(_suggestion(AdultJourneyLaunchKind.memorize));
      await Future<void>.delayed(Duration.zero);
      owner.currentOwnerId = 'owner-b';
      holdLookup!.complete();
      expect(await pending, isNull);
    });

    test(
      'a barrier invalidation during the lookup opens nothing (A→B→A)',
      () async {
        holdLookup = Completer<void>();
        final pending = resolve(_suggestion(AdultJourneyLaunchKind.review));
        await Future<void>.delayed(Duration.zero);
        barrier.invalidate(); // owner id unchanged, generation moved
        holdLookup!.complete();
        expect(await pending, isNull);
      },
    );

    test('a blocked barrier opens nothing and skips the lookup', () async {
      barrier.invalidate();
      expect(
        await resolve(_suggestion(AdultJourneyLaunchKind.memorize)),
        isNull,
      );
      expect(lookups, 0);
    });
  });

  group('resume and fixed sections', () {
    test('resume opens its section, never the stored session URL', () async {
      final stored = _action(
        '/memorization-plus/v2/session?surahId=2&startAyah=40',
        JourneyIntent.resume,
      );
      final route = await resolve(
        _suggestion(
          AdultJourneyLaunchKind.resume,
          action: stored,
          resume: AdultResumeDestination.memorization,
        ),
      );
      expect(route, AppRoutes.memorizationHub);
      expect(lookups, 0);
    });

    test('a kids or unknown resume path opens nothing', () async {
      expect(
        await resolve(
          _suggestion(
            AdultJourneyLaunchKind.resume,
            resume: AdultResumeDestination.unknown,
          ),
        ),
        isNull,
      );
    });

    test(
      'reading keeps the current Home load route; azkar its section',
      () async {
        expect(
          await resolve(
            _suggestion(
              AdultJourneyLaunchKind.reading,
              action: _action('/quran/page/12', JourneyIntent.reading),
            ),
          ),
          '/quran/page/12',
        );
        expect(
          await resolve(_suggestion(AdultJourneyLaunchKind.azkar)),
          AppRoutes.azkar,
        );
        expect(lookups, 0);
      },
    );
  });
}
