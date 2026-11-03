import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/features/adult_journey/adult_journey_feature_flags.dart';
import 'package:talia_quran/features/adult_journey/application/adult_journey_usecases.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_context.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/presentation/cubits/adult_journey_cubit.dart';

class Load extends Mock implements LoadAdultJourney {}

class Update extends Mock implements UpdateAdultJourney {}

class Owner implements RecordOwnerProvider {
  @override
  String currentOwnerId = 'a';
  @override
  bool get isSignedIn => true;
}

const action = UnifiedJourneyAction(
  route: '/memorization/review',
  priority: UnifiedJourneyPriority.p3ReviewBacklog,
  source: 'test',
  actionType: UnifiedJourneyActionType.reviewBacklog,
  intent: JourneyIntent.review,
);
AdultJourneyContext snapshot(
  DateTime now, {
  bool adult = true,
  bool due = true,
  bool hasRecords = true,
}) => AdultJourneyContext(
  ownerId: 'a',
  isAdult: adult,
  now: now,
  actions: due ? [action] : [],
  hasActiveAdultPlan: true,
  hasAdultReviewRecords: hasRecords,
  hasDueAdultReview: due,
);
void main() {
  test('child switch during fresh load hides task and aborts', () async {
    final now = DateTime(2026, 10, 31);
    final load = Load();
    when(
      () => load('a'),
    ).thenAnswer((_) async => AdultJourneyLoadResult.missing);
    final cubit = AdultJourneyCubit(
      loadAdultJourney: load,
      updateAdultJourney: Update(),
      flags: AdultJourneyFlags((_) => true),
      owner: Owner(),
      accountChanges: const Stream.empty(),
      now: () => now,
      loadFreshContext: () async => snapshot(now, adult: false),
    );
    addTearDown(cubit.close);
    await cubit.refreshContext(snapshot(now));
    final key = cubit.state.dailyReviewTask!.decisionKey!;
    expect(
      await cubit.resolveDailyReviewLaunch(expectedDecisionKey: key),
      isNull,
    );
    expect(cubit.state.isVisible, isFalse);
  });

  test('account switch during fresh load aborts', () async {
    final now = DateTime(2026, 10, 31);
    final gate = Completer<AdultJourneyContext>();
    final owner = Owner();
    final load = Load();
    when(
      () => load('a'),
    ).thenAnswer((_) async => AdultJourneyLoadResult.missing);
    final cubit = AdultJourneyCubit(
      loadAdultJourney: load,
      updateAdultJourney: Update(),
      flags: AdultJourneyFlags((_) => true),
      owner: owner,
      accountChanges: const Stream.empty(),
      now: () => now,
      loadFreshContext: () => gate.future,
    );
    addTearDown(cubit.close);
    await cubit.refreshContext(snapshot(now));
    final key = cubit.state.dailyReviewTask!.decisionKey!;
    final result = cubit.resolveDailyReviewLaunch(expectedDecisionKey: key);
    owner.currentOwnerId = 'b';
    gate.complete(snapshot(now));
    expect(await result, isNull);
    expect(cubit.canNavigateDailyReview(key), isFalse);
  });
  test('fresh snapshot removes completed task instead of navigating', () async {
    final now = DateTime(2026, 10, 31);
    final load = Load();
    when(
      () => load('a'),
    ).thenAnswer((_) async => AdultJourneyLoadResult.missing);
    final cubit = AdultJourneyCubit(
      loadAdultJourney: load,
      updateAdultJourney: Update(),
      flags: AdultJourneyFlags((_) => true),
      owner: Owner(),
      accountChanges: const Stream.empty(),
      now: () => now,
      loadFreshContext: () async => snapshot(now, due: false),
    );
    addTearDown(cubit.close);
    await cubit.refreshContext(snapshot(now));
    final key = cubit.state.dailyReviewTask!.decisionKey!;
    expect(
      await cubit.resolveDailyReviewLaunch(expectedDecisionKey: key),
      isNull,
    );
    expect(cubit.state.dailyReviewTask!.decisionKey, isNull);
  });
  test('concurrent tap and day change abort stale launches', () async {
    var now = DateTime(2026, 10, 31, 23, 59);
    final pending = Completer<AdultJourneyContext>();
    final load = Load();
    when(
      () => load('a'),
    ).thenAnswer((_) async => AdultJourneyLoadResult.missing);
    final cubit = AdultJourneyCubit(
      loadAdultJourney: load,
      updateAdultJourney: Update(),
      flags: AdultJourneyFlags((_) => true),
      owner: Owner(),
      accountChanges: const Stream.empty(),
      now: () => now,
      loadFreshContext: () => pending.future,
    );
    addTearDown(cubit.close);
    await cubit.refreshContext(snapshot(now));
    final key = cubit.state.dailyReviewTask!.decisionKey!;
    final first = cubit.resolveDailyReviewLaunch(expectedDecisionKey: key);
    expect(
      await cubit.resolveDailyReviewLaunch(expectedDecisionKey: key),
      isNull,
    );
    now = DateTime(2026, 11, 1);
    pending.complete(snapshot(now));
    expect(await first, isNull);
  });
  test('empty decision rechecks new reviews before setup', () async {
    final now = DateTime(2026, 10, 31);
    final load = Load();
    when(
      () => load('a'),
    ).thenAnswer((_) async => AdultJourneyLoadResult.missing);
    final cubit = AdultJourneyCubit(
      loadAdultJourney: load,
      updateAdultJourney: Update(),
      flags: AdultJourneyFlags((_) => true),
      owner: Owner(),
      accountChanges: const Stream.empty(),
      now: () => now,
      loadFreshContext: () async => snapshot(now),
    );
    addTearDown(cubit.close);
    await cubit.refreshContext(snapshot(now, due: false, hasRecords: false));
    final day = cubit.state.dailyReviewTask!.localDate;
    expect(await cubit.resolveNoReviewsLaunch(expectedLocalDate: day), isNull);
    expect(cubit.canNavigateNoReviews(day), isFalse);
  });
  test('empty decision rejects a new day before or during lookup', () async {
    var now = DateTime(2026, 10, 31, 23, 59);
    final gate = Completer<AdultJourneyContext>();
    final load = Load();
    when(
      () => load('a'),
    ).thenAnswer((_) async => AdultJourneyLoadResult.missing);
    final cubit = AdultJourneyCubit(
      loadAdultJourney: load,
      updateAdultJourney: Update(),
      flags: AdultJourneyFlags((_) => true),
      owner: Owner(),
      accountChanges: const Stream.empty(),
      now: () => now,
      loadFreshContext: () => gate.future,
    );
    addTearDown(cubit.close);
    await cubit.refreshContext(snapshot(now, due: false, hasRecords: false));
    final day = cubit.state.dailyReviewTask!.localDate;
    final result = cubit.resolveNoReviewsLaunch(expectedLocalDate: day);
    now = DateTime(2026, 11, 1);
    gate.complete(snapshot(now, due: false, hasRecords: false));
    expect(await result, isNull);
    expect(cubit.canNavigateNoReviews(day), isFalse);
    expect(await cubit.resolveNoReviewsLaunch(expectedLocalDate: day), isNull);
  });
  test('empty decision rejects account change during fresh load', () async {
    final now = DateTime(2026, 10, 31);
    final gate = Completer<AdultJourneyContext>();
    final owner = Owner();
    final load = Load();
    when(
      () => load('a'),
    ).thenAnswer((_) async => AdultJourneyLoadResult.missing);
    final cubit = AdultJourneyCubit(
      loadAdultJourney: load,
      updateAdultJourney: Update(),
      flags: AdultJourneyFlags((_) => true),
      owner: owner,
      accountChanges: const Stream.empty(),
      now: () => now,
      loadFreshContext: () => gate.future,
    );
    addTearDown(cubit.close);
    await cubit.refreshContext(snapshot(now, due: false, hasRecords: false));
    final day = cubit.state.dailyReviewTask!.localDate;
    final result = cubit.resolveNoReviewsLaunch(expectedLocalDate: day);
    owner.currentOwnerId = 'b';
    gate.complete(snapshot(now, due: false, hasRecords: false));
    expect(await result, isNull);
    expect(cubit.canNavigateNoReviews(day), isFalse);
  });
  test('unchanged empty decision resolves plan setup', () async {
    final now = DateTime(2026, 10, 31);
    final load = Load();
    when(
      () => load('a'),
    ).thenAnswer((_) async => AdultJourneyLoadResult.missing);
    final cubit = AdultJourneyCubit(
      loadAdultJourney: load,
      updateAdultJourney: Update(),
      flags: AdultJourneyFlags((_) => true),
      owner: Owner(),
      accountChanges: const Stream.empty(),
      now: () => now,
      loadFreshContext: () async =>
          snapshot(now, due: false, hasRecords: false),
    );
    addTearDown(cubit.close);
    await cubit.refreshContext(snapshot(now, due: false, hasRecords: false));
    final day = cubit.state.dailyReviewTask!.localDate;
    expect(
      await cubit.resolveNoReviewsLaunch(expectedLocalDate: day),
      isNotNull,
    );
    expect(cubit.canNavigateNoReviews(day), isTrue);
  });
  test(
    'empty decision refuses setup after switching to a child profile',
    () async {
      final now = DateTime(2026, 10, 31);
      final load = Load();
      when(
        () => load('a'),
      ).thenAnswer((_) async => AdultJourneyLoadResult.missing);
      final cubit = AdultJourneyCubit(
        loadAdultJourney: load,
        updateAdultJourney: Update(),
        flags: AdultJourneyFlags((_) => true),
        owner: Owner(),
        accountChanges: const Stream.empty(),
        now: () => now,
        loadFreshContext: () async =>
            snapshot(now, adult: false, due: false, hasRecords: false),
      );
      addTearDown(cubit.close);
      await cubit.refreshContext(snapshot(now, due: false, hasRecords: false));
      final day = cubit.state.dailyReviewTask!.localDate;
      expect(
        await cubit.resolveNoReviewsLaunch(expectedLocalDate: day),
        isNull,
      );
      expect(cubit.state.isVisible, isFalse);
      expect(cubit.canNavigateNoReviews(day), isFalse);
    },
  );
}
