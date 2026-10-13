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
import 'package:talia_quran/features/adult_journey/domain/services/adult_return_policy.dart';
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
  late StreamController<String> prefChanges;
  final now = DateTime(2026, 10, 13, 10);

  setUpAll(() => registerFallbackValue(const ClearAdultToday()));

  setUp(() {
    load = _MockLoad();
    update = _MockUpdate();
    owner = _MutableOwner('a');
    changes = StreamController<void>.broadcast(sync: true);
    prefChanges = StreamController<String>.broadcast(sync: true);
  });

  tearDown(() async {
    await changes.close();
    await prefChanges.close();
  });

  AdultJourneyCubit build({
    bool personalization = true,
    bool budget = true,
    bool gentle = false,
    AdultJourneyLaunchResolver? launchResolver,
  }) {
    final flags = AdultJourneyFlags(
      (key) => key == AdultJourneyFeature.personalization.storageKey
          ? personalization
          : key == AdultJourneyFeature.todayBudget.storageKey
          ? budget
          : key == AdultJourneyFeature.gentleReturn.storageKey
          ? gentle
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
      preferenceChanges: prefChanges.stream,
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

  group('whole-branch review fixes', () {
    test('a same-owner event during a save still reports the save', () async {
      loads('a', AdultJourneyLoadResult.missing);
      final slow = Completer<AdultJourneySaveResult>();
      when(() => update('a', any())).thenAnswer((_) => slow.future);
      final cubit = build();
      await cubit.refreshContext(ctx('a'));

      final saving = cubit.saveProfile(AdultJourneyGoal.reading, null);
      // e.g. a Khatmah write fires the barrier for the same owner; its
      // re-read sees the saved record.
      loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
      changes.add(null);
      slow.complete(const AdultJourneySaveResult.saved(_readingProfile));

      expect(await saving, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.preferences, _readingProfile);
      expect(cubit.state.isSaving, isFalse);
      expect(cubit.state.error, isNull);
    });

    test('a failure is tagged with the action that caused it', () async {
      loads('a', AdultJourneyLoadResult.missing);
      when(() => update('a', any())).thenAnswer(
        (_) async => const AdultJourneySaveResult.failed(
          AdultJourneySaveFailure.storage,
        ),
      );
      final cubit = build();
      await cubit.refreshContext(ctx('a'));

      await cubit.snoozeSetup();
      expect(
        cubit.state.errorFor(AdultJourneyErrorSource.snooze),
        AdultJourneyErrorCode.saveFailed,
      );
      expect(cubit.state.errorFor(AdultJourneyErrorSource.today), isNull);
      expect(cubit.state.errorFor(AdultJourneyErrorSource.profile), isNull);

      await cubit.setTodayMinutes(5);
      expect(cubit.state.errorFor(AdultJourneyErrorSource.snooze), isNull);
      expect(
        cubit.state.errorFor(AdultJourneyErrorSource.today),
        AdultJourneyErrorCode.saveFailed,
      );
    });

    test('a pending error survives a Home re-read', () async {
      loads('a', AdultJourneyLoadResult.missing);
      when(() => update('a', any())).thenAnswer(
        (_) async => const AdultJourneySaveResult.failed(
          AdultJourneySaveFailure.storage,
        ),
      );
      final cubit = build();
      await cubit.refreshContext(ctx('a'));
      await cubit.snoozeSetup();
      await cubit.refreshContext(ctx('a'));
      expect(
        cubit.state.errorFor(AdultJourneyErrorSource.snooze),
        AdultJourneyErrorCode.saveFailed,
      );
    });

    test('a save from another screen (Settings) refreshes this one', () async {
      loads('a', AdultJourneyLoadResult.missing);
      final cubit = build();
      await cubit.refreshContext(ctx('a'));
      expect(cubit.state.setupInviteDue, isTrue);

      loads('a', const AdultJourneyLoadResult.ready(_readingProfile));
      prefChanges.add('a');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.preferences, _readingProfile);
      expect(cubit.state.setupInviteDue, isFalse);
    });

    test(
      'a visit finishing during a user save keeps the save in charge',
      () async {
        loads('a', AdultJourneyLoadResult.missing);
        final saveDone = Completer<AdultJourneySaveResult>();
        when(() => update('a', any())).thenAnswer((invocation) {
          final command = invocation.positionalArguments[1];
          if (command is RecordAdultHomeVisit) {
            return Future.value(
              AdultJourneySaveResult.saved(
                AdultJourneyPreferences(lastHomeSeenAtUtc: now.toUtc()),
              ),
            );
          }
          return saveDone.future;
        });
        final cubit = AdultJourneyCubit(
          loadAdultJourney: load,
          updateAdultJourney: update,
          flags: AdultJourneyFlags((_) => true),
          owner: owner,
          accountChanges: changes.stream,
          now: () => now,
        );
        addTearDown(cubit.close);
        await cubit.refreshContext(ctx('a'));

        final saving = cubit.saveProfile(AdultJourneyGoal.reading, null);
        expect(cubit.state.isSaving, isTrue);
        await cubit.recordHomeVisit();
        expect(cubit.state.isSaving, isTrue, reason: 'buttons stay disabled');

        saveDone.complete(const AdultJourneySaveResult.saved(_readingProfile));
        expect(await saving, isTrue);
        expect(cubit.state.isSaving, isFalse);
        expect(cubit.state.preferences, _readingProfile);
      },
    );

    test('refreshDay waits while a save is in flight', () async {
      var clock = DateTime(2026, 10, 13, 23, 59);
      loads('a', AdultJourneyLoadResult.missing);
      final slow = Completer<AdultJourneySaveResult>();
      when(() => update('a', any())).thenAnswer((_) => slow.future);
      final cubit = AdultJourneyCubit(
        loadAdultJourney: load,
        updateAdultJourney: update,
        flags: AdultJourneyFlags((_) => true),
        owner: owner,
        accountChanges: changes.stream,
        now: () => clock,
      );
      addTearDown(cubit.close);
      await cubit.refreshContext(ctx('a'));

      final saving = cubit.setTodayMinutes(5);
      clock = DateTime(2026, 10, 14, 0, 1);
      cubit.refreshDay();
      expect(cubit.state.isSaving, isTrue, reason: 'buttons stay disabled');

      slow.complete(const AdultJourneySaveResult.saved(_readingProfile));
      expect(await saving, isTrue);
      expect(cubit.state.isSaving, isFalse);
    });

    test('a change for another owner is ignored', () async {
      loads('a', AdultJourneyLoadResult.missing);
      final cubit = build();
      await cubit.refreshContext(ctx('a'));
      clearInteractions(load);
      prefChanges.add('b');
      await Future<void>.delayed(Duration.zero);
      verifyNever(() => load(any()));
    });

    test('refreshDay drops yesterday\'s time choice', () async {
      var clock = DateTime(2026, 10, 13, 23, 50);
      const yesterday = AdultJourneyPreferences(
        todayLocalDate: '2026-10-13',
        todayMinutes: 10,
      );
      loads('a', const AdultJourneyLoadResult.ready(yesterday));
      final cubit = AdultJourneyCubit(
        loadAdultJourney: load,
        updateAdultJourney: update,
        flags: AdultJourneyFlags((_) => true),
        owner: owner,
        accountChanges: changes.stream,
        now: () => clock,
      );
      addTearDown(cubit.close);
      await cubit.refreshContext(ctx('a'));
      expect(cubit.state.todayMinutes, 10);

      cubit.refreshDay();
      expect(cubit.state.todayMinutes, 10, reason: 'same day: no change');

      clock = DateTime(2026, 10, 14, 0, 10);
      cubit.refreshDay();
      expect(cubit.state.localDate, '2026-10-14');
      expect(cubit.state.todayMinutes, isNull);
    });
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

  group('gentle return', () {
    // `now` is 2026-10-13 10:00 local; nine days earlier is an absence.
    final nineDaysAgo = DateTime(2026, 10, 4, 10).toUtc();
    const today = '2026-10-13';

    AdultJourneyPreferences away({
      AdultJourneyExperience? experience,
      String? dismissed,
    }) => AdultJourneyPreferences(
      goal: AdultJourneyGoal.review,
      experience: experience,
      profileCompleted: true,
      lastHomeSeenAtUtc: nineDaysAgo,
      returnDismissedLocalDate: dismissed,
    );

    test('flag off: no offer and no visit write', () async {
      loads('a', AdultJourneyLoadResult.ready(away()));
      final cubit = build();
      await cubit.refreshContext(ctx('a'));
      expect(cubit.state.returnOffer, isNull);
      await cubit.recordHomeVisit();
      verifyNever(() => update(any(), any()));
    });

    test('after seven or more days the absence offer shows on Home', () async {
      loads('a', AdultJourneyLoadResult.ready(away()));
      final cubit = build(gentle: true);
      await cubit.refreshContext(ctx('a'));
      expect(cubit.state.returnOffer?.reason, AdultReturnReason.absence);
      expect(cubit.state.returnOffer?.eligibleLocalDate, today);
    });

    test('Settings (no Home context) never shows or records it', () async {
      loads('a', AdultJourneyLoadResult.ready(away()));
      final cubit = build(gentle: true);
      await cubit.loadPreferences();
      expect(cubit.state.returnOffer, isNull);
      await cubit.recordHomeVisit();
      verifyNever(() => update(any(), any()));
    });

    test(
      'a visit writes RecordAdultHomeVisit with the current instant',
      () async {
        loads('a', AdultJourneyLoadResult.ready(away()));
        when(() => update('a', any())).thenAnswer(
          (_) async => AdultJourneySaveResult.saved(
            away().copyWith(
              lastHomeSeenAtUtc: now.toUtc(),
              returnOfferLocalDate: today,
            ),
          ),
        );
        final cubit = build(gentle: true);
        await cubit.refreshContext(ctx('a'));
        await cubit.recordHomeVisit();

        final command =
            verify(() => update('a', captureAny())).captured.single
                as RecordAdultHomeVisit;
        expect(command.nowUtc, now.toUtc());
        expect(
          cubit.state.returnOffer?.reason,
          AdultReturnReason.absence,
          reason: 'the stored offer keeps it for the rest of the day',
        );
        expect(cubit.state.isSaving, isFalse, reason: 'visits are silent');
      },
    );

    test('a same-day visit (unchanged) emits nothing', () async {
      loads('a', AdultJourneyLoadResult.ready(away()));
      when(
        () => update('a', any()),
      ).thenAnswer((_) async => AdultJourneySaveResult.unchanged(away()));
      final cubit = build(gentle: true);
      await cubit.refreshContext(ctx('a'));
      final emitted = <AdultJourneyState>[];
      final sub = cubit.stream.listen(emitted.add);
      await cubit.recordHomeVisit();
      await sub.cancel();
      expect(emitted, isEmpty);
    });

    test('a visit finishing after a non-adult refresh shows nothing', () async {
      loads('a', AdultJourneyLoadResult.ready(away()));
      final slow = Completer<AdultJourneySaveResult>();
      when(() => update('a', any())).thenAnswer((_) => slow.future);
      final cubit = build(gentle: true);
      await cubit.refreshContext(ctx('a'));
      final visit = cubit.recordHomeVisit();
      await cubit.refreshContext(ctx('a', isAdult: false));
      slow.complete(AdultJourneySaveResult.saved(away()));
      await visit;
      expect(cubit.state.isVisible, isFalse);
    });

    test('a visit for A finishing after a switch to B shows nothing', () async {
      loads('a', AdultJourneyLoadResult.ready(away()));
      final slow = Completer<AdultJourneySaveResult>();
      when(() => update('a', any())).thenAnswer((_) => slow.future);
      final cubit = build(gentle: true);
      await cubit.refreshContext(ctx('a'));

      final visit = cubit.recordHomeVisit();
      owner.currentOwnerId = 'b';
      changes.add(null);
      slow.complete(
        AdultJourneySaveResult.saved(
          away().copyWith(returnOfferLocalDate: today),
        ),
      );
      await visit;
      expect(cubit.state, AdultJourneyState.hidden);
      verifyNever(() => update('b', any()));
    });

    test('becoming «عائد» after an old dismissal shows the options', () async {
      final dismissedLongAgo = AdultJourneyPreferences(
        goal: AdultJourneyGoal.reading,
        experience: AdultJourneyExperience.continuing,
        profileCompleted: true,
        lastHomeSeenAtUtc: now.toUtc(),
        returnDismissedLocalDate: '2026-09-01',
      );
      loads('a', AdultJourneyLoadResult.ready(dismissedLongAgo));
      when(() => update('a', any())).thenAnswer(
        (_) async => AdultJourneySaveResult.saved(
          AdultJourneyPreferences(
            goal: AdultJourneyGoal.reading,
            experience: AdultJourneyExperience.returning,
            profileCompleted: true,
            lastHomeSeenAtUtc: now.toUtc(),
          ),
        ),
      );
      final cubit = build(gentle: true);
      await cubit.refreshContext(ctx('a'));
      expect(cubit.state.returnOffer, isNull);

      await cubit.saveProfile(
        AdultJourneyGoal.reading,
        AdultJourneyExperience.returning,
      );
      expect(cubit.state.returnOffer?.reason, AdultReturnReason.selfDescribed);
    });

    test('light start writes one command and needs the budget flag', () async {
      loads('a', AdultJourneyLoadResult.ready(away()));
      when(() => update('a', any())).thenAnswer(
        (_) async => AdultJourneySaveResult.saved(
          away(dismissed: today).copyWith(
            todayLocalDate: today,
            todayMinutes: 5,
            lightReturnToday: true,
          ),
        ),
      );
      final noBudget = build(gentle: true, budget: false);
      await noBudget.refreshContext(ctx('a'));
      expect(noBudget.state.returnTimeActionsEnabled, isFalse);
      expect(await noBudget.startLightReturn(), isFalse);
      expect(await noBudget.chooseReturnTime(), isFalse);
      verifyNever(() => update(any(), any()));

      final cubit = build(gentle: true);
      await cubit.refreshContext(ctx('a'));
      expect(await cubit.startLightReturn(), isTrue);
      final command =
          verify(() => update('a', captureAny())).captured.single
              as StartAdultLightReturn;
      expect(command.localDate, today);
      expect(cubit.state.returnOffer, isNull);
      expect(cubit.state.todayMinutes, 5);
    });

    test('continue as usual works without the budget flag', () async {
      loads('a', AdultJourneyLoadResult.ready(away()));
      when(() => update('a', any())).thenAnswer(
        (_) async => AdultJourneySaveResult.saved(away(dismissed: today)),
      );
      final cubit = build(gentle: true, budget: false);
      await cubit.refreshContext(ctx('a'));
      expect(await cubit.continueAsUsual(), isTrue);
      expect(
        verify(() => update('a', captureAny())).captured.single,
        isA<ContinueAdultAsUsual>(),
      );
      expect(cubit.state.returnOffer, isNull);
      expect(cubit.state.preferences.goal, AdultJourneyGoal.review);
    });

    test(
      'self-described returning shows options until the first dismissal',
      () async {
        final recent = AdultJourneyPreferences(
          goal: AdultJourneyGoal.reading,
          experience: AdultJourneyExperience.returning,
          profileCompleted: true,
          lastHomeSeenAtUtc: now.toUtc(),
        );
        loads('a', AdultJourneyLoadResult.ready(recent));
        final cubit = build(gentle: true);
        await cubit.refreshContext(ctx('a'));
        expect(
          cubit.state.returnOffer?.reason,
          AdultReturnReason.selfDescribed,
        );

        loads(
          'a',
          AdultJourneyLoadResult.ready(
            recent.copyWith(returnDismissedLocalDate: '2026-10-10'),
          ),
        );
        await cubit.refreshContext(ctx('a'));
        expect(
          cubit.state.returnOffer,
          isNull,
          reason: 'no daily repeat once dismissed',
        );
      },
    );
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
