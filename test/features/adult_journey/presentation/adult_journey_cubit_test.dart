import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/adult_journey/adult_journey_feature_flags.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/adult_journey/application/adult_journey_launch_resolver.dart';
import 'package:talia_quran/features/adult_journey/application/adult_journey_usecases.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_suggestion.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_context.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_update.dart';
import 'package:talia_quran/features/adult_journey/presentation/cubits/adult_journey_cubit.dart';
import 'package:talia_quran/features/adult_journey/presentation/cubits/adult_journey_state.dart';

class _MockLoad extends Mock implements LoadAdultJourney {}

class _MockUpdate extends Mock implements UpdateAdultJourney {}

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => true;
}

const _readingProfile = AdultJourneyPreferences(
  goal: AdultJourneyGoal.reading,
  profileCompleted: true,
);

void main() {
  late _MockLoad load;
  late _MockUpdate update;
  late _MutableOwner owner;
  late StreamController<void> changes;
  final now = DateTime(2026, 10, 13, 10);

  setUpAll(() => registerFallbackValue(const ClearAdultToday()));

  setUp(() {
    load = _MockLoad();
    update = _MockUpdate();
    owner = _MutableOwner('a');
    changes = StreamController<void>.broadcast(sync: true);
  });

  tearDown(() => changes.close());

  AdultJourneyCubit build({
    bool personalization = true,
    bool budget = true,
    AdultJourneyLaunchResolver? launchResolver,
  }) {
    final flags = AdultJourneyFlags(
      (key) => key == AdultJourneyFeature.personalization.storageKey
          ? personalization
          : key == AdultJourneyFeature.todayBudget.storageKey
          ? budget
          : false,
    );
    final cubit = AdultJourneyCubit(
      loadAdultJourney: load,
      updateAdultJourney: update,
      flags: flags,
      owner: owner,
      accountChanges: changes.stream,
      now: () => now,
      launchResolver: launchResolver,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  AdultJourneyContext ctx(String ownerId, {bool isAdult = true}) =>
      AdultJourneyContext(
        ownerId: ownerId,
        isAdult: isAdult,
        now: now,
        actions: const [],
        hasActiveAdultPlan: false,
        hasAdultReviewRecords: false,
        hasDueAdultReview: false,
      );

  void loads(String ownerId, AdultJourneyLoadResult result) {
    when(() => load(ownerId)).thenAnswer((_) async => result);
  }

  test('starts hidden and shows a confirmed adult after loading', () async {
    loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
    final cubit = build();
    expect(cubit.state.isVisible, isFalse);

    await cubit.refreshContext(ctx('a'));

    expect(cubit.state.isVisible, isTrue);
    expect(cubit.state.preferences, _readingProfile);
    expect(cubit.state.setupInviteDue, isFalse);
  });

  test('missing record shows the invite until snoozed or completed', () async {
    loads('a', AdultJourneyLoadResult.missing);
    final cubit = build();
    await cubit.refreshContext(ctx('a'));
    expect(cubit.state.setupInviteDue, isTrue);
  });

  test('a child or unconfirmed adult stays hidden and never loads', () async {
    final cubit = build();
    await cubit.refreshContext(ctx('a', isAdult: false));
    expect(cubit.state.isVisible, isFalse);
    verifyNever(() => load(any()));
  });

  test('context for another owner stays hidden', () async {
    final cubit = build();
    await cubit.refreshContext(ctx('b'));
    expect(cubit.state.isVisible, isFalse);
    verifyNever(() => load(any()));
  });

  test('personalization flag off keeps everything hidden', () async {
    final cubit = build(personalization: false);
    await cubit.refreshContext(ctx('a'));
    await cubit.loadPreferences();
    expect(cubit.state.isVisible, isFalse);
    verifyNever(() => load(any()));
  });

  test('loadPreferences works without a Home context', () async {
    loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
    final cubit = build();
    await cubit.loadPreferences();
    expect(cubit.state.isVisible, isTrue);
    expect(cubit.state.suggestions, isEmpty);
  });

  test('unavailable identity hides instead of showing defaults', () async {
    loads('a', AdultJourneyLoadResult.unavailable);
    final cubit = build();
    await cubit.loadPreferences();
    expect(cubit.state.isVisible, isFalse);
  });

  test('A -> B -> A discards the first A result', () async {
    final firstA = Completer<AdultJourneyLoadResult>();
    final secondA = Completer<AdultJourneyLoadResult>();
    var calls = 0;
    when(
      () => load('a'),
    ).thenAnswer((_) => ++calls == 1 ? firstA.future : secondA.future);
    final cubit = build();

    final pending = cubit.refreshContext(ctx('a'));
    owner.currentOwnerId = 'b';
    changes.add(null);
    owner.currentOwnerId = 'a';
    changes.add(null);
    expect(cubit.state.isVisible, isFalse);
    final second = cubit.refreshContext(ctx('a'));

    firstA.complete(
      const AdultJourneyLoadResult.ready(
        AdultJourneyPreferences(
          goal: AdultJourneyGoal.azkar,
          profileCompleted: true,
        ),
      ),
    );
    await pending;
    expect(cubit.state.isVisible, isFalse, reason: 'stale result dropped');

    secondA.complete(const AdultJourneyLoadResult.ready(_readingProfile));
    await second;
    expect(cubit.state.preferences, _readingProfile);
  });

  test('an owner change without an event drops old results', () async {
    final slow = Completer<AdultJourneyLoadResult>();
    when(() => load('a')).thenAnswer((_) => slow.future);
    final cubit = build();

    final pending = cubit.refreshContext(ctx('a'));
    owner.currentOwnerId = 'b';
    slow.complete(const AdultJourneyLoadResult.ready(_readingProfile));
    await pending;

    expect(cubit.state.isVisible, isFalse);
  });

  test('an owner change event clears visible state immediately', () async {
    loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
    final cubit = build();
    await cubit.refreshContext(ctx('a'));
    owner.currentOwnerId = 'b';
    changes.add(null);
    expect(cubit.state, AdultJourneyState.hidden);
  });

  test(
    'a same-owner event (e.g. a Khatmah write) re-reads, not hides',
    () async {
      loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
      final cubit = build();
      await cubit.refreshContext(ctx('a'));
      loads('a', AdultJourneyLoadResult.unavailable);

      changes.add(null);
      expect(cubit.state.isVisible, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(
        cubit.state.isVisible,
        isFalse,
        reason: 'a blocked barrier makes the re-read unavailable',
      );
    },
  );

  test('a same-owner event keeps the overlay when storage is ready', () async {
    loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
    final cubit = build();
    await cubit.refreshContext(ctx('a'));
    changes.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isVisible, isTrue);
    expect(cubit.state.preferences, _readingProfile);
  });

  test('a newer-schema record hides the overlay', () async {
    loads('a', AdultJourneyLoadResult.unsupported);
    final cubit = build();
    await cubit.refreshContext(ctx('a'));
    expect(cubit.state.isVisible, isFalse);
  });

  test('a save finishing after a non-adult refresh stays hidden', () async {
    loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
    final slow = Completer<AdultJourneySaveResult>();
    when(() => update('a', any())).thenAnswer((_) => slow.future);
    final cubit = build();
    await cubit.refreshContext(ctx('a'));

    final saving = cubit.setTodayMinutes(10);
    await cubit.refreshContext(ctx('a', isAdult: false));
    slow.complete(const AdultJourneySaveResult.saved(_readingProfile));
    await saving;

    expect(cubit.state.isVisible, isFalse);
  });

  test('an owner change without an event hides visible state on the next '
      'result', () async {
    loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
    final slow = Completer<AdultJourneySaveResult>();
    when(() => update('a', any())).thenAnswer((_) => slow.future);
    final cubit = build();
    await cubit.refreshContext(ctx('a'));

    final saving = cubit.setTodayMinutes(5);
    owner.currentOwnerId = 'b';
    slow.complete(const AdultJourneySaveResult.saved(_readingProfile));

    expect(await saving, isFalse);
    expect(cubit.state, AdultJourneyState.hidden);
  });

  test('saveProfile success updates the state', () async {
    loads('a', AdultJourneyLoadResult.missing);
    when(() => update('a', any())).thenAnswer(
      (_) async => const AdultJourneySaveResult.saved(_readingProfile),
    );
    final cubit = build();
    await cubit.loadPreferences();

    final ok = await cubit.saveProfile(AdultJourneyGoal.reading, null);

    expect(ok, isTrue);
    expect(cubit.state.preferences, _readingProfile);
    expect(cubit.state.setupInviteDue, isFalse);
    expect(cubit.state.error, isNull);
    final command =
        verify(() => update('a', captureAny())).captured.single
            as SaveAdultProfile;
    expect(command.goal, AdultJourneyGoal.reading);
  });

  test('failed save keeps the previous preferences and sets a code', () async {
    loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
    when(() => update('a', any())).thenAnswer(
      (_) async =>
          const AdultJourneySaveResult.failed(AdultJourneySaveFailure.storage),
    );
    final cubit = build();
    await cubit.loadPreferences();

    final ok = await cubit.saveProfile(AdultJourneyGoal.azkar, null);

    expect(ok, isFalse);
    expect(cubit.state.preferences, _readingProfile);
    expect(cubit.state.error, AdultJourneyErrorCode.saveFailed);
    expect(cubit.state.isSaving, isFalse);
  });

  test('a throwing save is a failure, not an exception', () async {
    loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
    when(() => update('a', any())).thenThrow(StateError('disk'));
    final cubit = build();
    await cubit.loadPreferences();

    expect(await cubit.saveProfile(AdultJourneyGoal.azkar, null), isFalse);
    expect(cubit.state.error, AdultJourneyErrorCode.saveFailed);
  });

  test('a retry after failure clears the error on success', () async {
    loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
    var attempt = 0;
    when(() => update('a', any())).thenAnswer(
      (_) async => ++attempt == 1
          ? const AdultJourneySaveResult.failed(AdultJourneySaveFailure.storage)
          : const AdultJourneySaveResult.saved(_readingProfile),
    );
    final cubit = build();
    await cubit.loadPreferences();

    expect(await cubit.saveProfile(AdultJourneyGoal.reading, null), isFalse);
    expect(await cubit.saveProfile(AdultJourneyGoal.reading, null), isTrue);
    expect(cubit.state.error, isNull);
  });

  test('a save finished after an account switch is not applied', () async {
    loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
    final slow = Completer<AdultJourneySaveResult>();
    when(() => update('a', any())).thenAnswer((_) => slow.future);
    final cubit = build();
    await cubit.loadPreferences();

    final saving = cubit.saveProfile(AdultJourneyGoal.azkar, null);
    owner.currentOwnerId = 'b';
    changes.add(null);
    slow.complete(const AdultJourneySaveResult.saved(_readingProfile));

    expect(await saving, isFalse);
    expect(cubit.state, AdultJourneyState.hidden);
  });

  test('setTodayMinutes accepts only 5/10/20 and needs the flag', () async {
    loads('a', AdultJourneyLoadResult.missing);
    when(() => update('a', any())).thenAnswer(
      (_) async => const AdultJourneySaveResult.saved(
        AdultJourneyPreferences(todayLocalDate: '2026-10-13', todayMinutes: 10),
      ),
    );
    final cubit = build();
    await cubit.loadPreferences();

    expect(await cubit.setTodayMinutes(7), isFalse);
    expect(await cubit.setTodayMinutes(10), isTrue);
    expect(cubit.state.todayMinutes, 10);

    final off = build(budget: false);
    await off.loadPreferences();
    expect(await off.setTodayMinutes(10), isFalse);
  });

  test('clearToday drops only the day choice', () async {
    const withToday = AdultJourneyPreferences(
      goal: AdultJourneyGoal.reading,
      profileCompleted: true,
      todayLocalDate: '2026-10-13',
      todayMinutes: 5,
    );
    loads('a', const AdultJourneyLoadResult.ready(withToday));
    when(() => update('a', any())).thenAnswer(
      (_) async => const AdultJourneySaveResult.saved(_readingProfile),
    );
    final cubit = build();
    await cubit.loadPreferences();
    expect(cubit.state.todayMinutes, 5);

    expect(await cubit.clearToday(), isTrue);
    expect(cubit.state.todayMinutes, isNull);
    expect(cubit.state.preferences.goal, AdultJourneyGoal.reading);
  });

  group('resolveLaunch', () {
    const review = AdultJourneySuggestion(
      launchKind: AdultJourneyLaunchKind.review,
      reason: AdultJourneySuggestionReason.goalMatch,
    );
    const fresh = '/memorization-plus/v2/session?surahId=36&intent=review';

    late AccountDataBarrier barrier;
    late int lookups;
    Completer<void>? hold;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      barrier = AccountDataBarrier.forPreferences(
        await SharedPreferences.getInstance(),
      );
      lookups = 0;
      hold = null;
    });

    AdultJourneyLaunchResolver resolver() => AdultJourneyLaunchResolver(
      owner: owner,
      captureLease: barrier.capture,
      memorizationDestinations: () async {
        lookups++;
        await hold?.future;
        return const AdultMemorizationDestinations(
          isChild: false,
          todayPlanLocation: '/memorization-plus/v2/session?surahId=2',
          reviewQuizLocation: fresh,
        );
      },
    );

    test('returns the freshly resolved route', () async {
      loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
      final cubit = build(launchResolver: resolver());
      await cubit.refreshContext(ctx('a'));
      expect(await cubit.resolveLaunch(review), fresh);
    });

    test('nothing while hidden', () async {
      final cubit = build(launchResolver: resolver());
      expect(await cubit.resolveLaunch(review), isNull);
      expect(lookups, 0);
    });

    test('a second tap during a launch resolves nothing', () async {
      loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
      final cubit = build(launchResolver: resolver());
      await cubit.refreshContext(ctx('a'));
      hold = Completer<void>();
      final first = cubit.resolveLaunch(review);
      expect(await cubit.resolveLaunch(review), isNull);
      hold!.complete();
      expect(await first, fresh);
      expect(lookups, 1);
    });

    test('an account switch during the launch opens nothing', () async {
      loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
      final cubit = build(launchResolver: resolver());
      await cubit.refreshContext(ctx('a'));
      hold = Completer<void>();
      final pending = cubit.resolveLaunch(review);
      owner.currentOwnerId = 'b';
      changes.add(null);
      hold!.complete();
      expect(await pending, isNull);
    });

    test('without a resolver the Phase A safe route is used', () async {
      loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
      final cubit = build();
      await cubit.refreshContext(ctx('a'));
      expect(await cubit.resolveLaunch(review), AppRoutes.memorizationHub);
    });
  });

  test('no emission after close', () async {
    final slow = Completer<AdultJourneyLoadResult>();
    when(() => load('a')).thenAnswer((_) => slow.future);
    final cubit = build();
    final emitted = <AdultJourneyState>[];
    cubit.stream.listen(emitted.add);

    final pending = cubit.refreshContext(ctx('a'));
    await cubit.close();
    slow.complete(const AdultJourneyLoadResult.ready(_readingProfile));
    await pending;
    changes.add(null);

    expect(emitted, isEmpty);
  });
}
