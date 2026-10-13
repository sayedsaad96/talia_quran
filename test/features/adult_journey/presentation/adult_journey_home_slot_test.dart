import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/features/adult_journey/adult_journey_feature_flags.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_update.dart';
import 'package:talia_quran/features/adult_journey/presentation/cubits/adult_journey_cubit.dart';
import 'package:talia_quran/features/adult_journey/presentation/widgets/adult_journey_home_slot.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';

import 'adult_journey_test_harness.dart';

class _FakeHomeCubit extends Cubit<HomeState> implements HomeCubit {
  _FakeHomeCubit(super.initialState);

  void push(HomeState next) => emit(next);

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _progress = OverallProgress(
  memorizedAyahs: 0,
  totalAyahs: 6236,
  memorizedSurahs: 0,
  totalSurahs: 114,
  memorizedJuz: 0,
  totalJuz: 30,
  readAyahs: 0,
  readSurahs: 0,
  readJuz: 0,
  streakDays: 0,
  lastActiveDate: null,
  achievements: [],
  readPagesCount: 0,
  totalQuranPages: 604,
  learningAyahs: 0,
  reviewAyahs: 0,
  kidsPoints: 0,
  kidsStars: 0,
);

const _explore = UnifiedJourneyAction(
  route: '/quran',
  priority: UnifiedJourneyPriority.p6FreeExploration,
  source: 'test',
  actionType: UnifiedJourneyActionType.explore,
  intent: JourneyIntent.explore,
);

/// [firstRun] true leaves every field empty so `HomeLoaded.isFirstRun` holds.
HomeLoaded _home({
  MemorizationTrack? track = MemorizationTrack.adults,
  bool isKids = false,
  bool firstRun = false,
}) => HomeLoaded(
  progress: _progress,
  greeting: 'morning',
  activityStartDate: DateTime.utc(2026, 1, 1),
  selectedTrack: track,
  isKids: isKids,
  heroAction: firstRun ? null : _explore,
  alternativeActions: firstRun ? const [] : const [_explore],
);

const _inviteTitle = 'Make your journey fit you';
const _todayTitle = 'How much time do you have today?';

void main() {
  late MockLoadAdultJourney load;
  late MockUpdateAdultJourney update;
  late Map<String, bool> flagValues;
  late int cubitsBuilt;

  setUpAll(() => registerFallbackValue(const ClearAdultToday()));

  setUp(() async {
    await getIt.reset();
    load = MockLoadAdultJourney();
    update = MockUpdateAdultJourney();
    cubitsBuilt = 0;
    flagValues = {
      AdultJourneyFeature.personalization.storageKey: true,
      AdultJourneyFeature.todayBudget.storageKey: false,
    };
    when(
      () => load(any()),
    ).thenAnswer((_) async => AdultJourneyLoadResult.missing);
    const owner = FixedRecordOwnerProvider('owner-a');
    getIt.registerSingleton<RecordOwnerProvider>(owner);
    getIt.registerSingleton<AdultJourneyFlags>(
      AdultJourneyFlags((key) => flagValues[key]),
    );
    getIt.registerFactory<AdultJourneyCubit>(() {
      cubitsBuilt++;
      return AdultJourneyCubit(
        loadAdultJourney: load,
        updateAdultJourney: update,
        flags: getIt<AdultJourneyFlags>(),
        owner: owner,
        accountChanges: const Stream<void>.empty(),
        now: () => adultTestNow,
      );
    });
  });

  tearDown(() => getIt.reset());

  Future<_FakeHomeCubit> pumpSlot(
    WidgetTester tester,
    HomeState home, {
    Brightness brightness = Brightness.light,
    String locale = 'en',
    bool Function(BuildContext)? foreground,
  }) async {
    final cubit = _FakeHomeCubit(home);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      adultTestApp(
        locale: locale,
        brightness: brightness,
        home: BlocProvider<HomeCubit>.value(
          value: cubit,
          child: CustomScrollView(
            slivers: [AdultJourneyHomeSlot(isHomeForeground: foreground)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('flags off: nothing rendered and no cubit or read', (
    tester,
  ) async {
    flagValues[AdultJourneyFeature.personalization.storageKey] = false;
    await pumpSlot(tester, _home());
    expect(find.text(_inviteTitle), findsNothing);
    expect(cubitsBuilt, 0);
    verifyNever(() => load(any()));
  });

  testWidgets('a confirmed adult without a profile sees the invite', (
    tester,
  ) async {
    await pumpSlot(tester, _home());
    expect(find.text(_inviteTitle), findsOneWidget);
    expect(find.text(_todayTitle), findsNothing, reason: 'budget flag off');
  });

  testWidgets('one welcome card: no invite while first-run shows', (
    tester,
  ) async {
    final home = _home(firstRun: true);
    expect(home.isFirstRun, isTrue);
    await pumpSlot(tester, home);
    expect(find.text(_inviteTitle), findsNothing);
  });

  testWidgets('no chosen track or a child profile sees nothing', (
    tester,
  ) async {
    await pumpSlot(tester, _home(track: null));
    expect(find.text(_inviteTitle), findsNothing);
    await pumpSlot(tester, _home(track: MemorizationTrack.kids, isKids: true));
    expect(find.text(_inviteTitle), findsNothing);
    verifyNever(() => load(any()));
  });

  testWidgets('a new Home state for a child hides the visible overlay', (
    tester,
  ) async {
    final home = await pumpSlot(tester, _home());
    expect(find.text(_inviteTitle), findsOneWidget);
    home.push(_home(track: MemorizationTrack.kids, isKids: true));
    await tester.pumpAndSettle();
    expect(find.text(_inviteTitle), findsNothing);
  });

  testWidgets('"Later" snoozes the invite for today only', (tester) async {
    when(() => update(any(), any())).thenAnswer(
      (_) async => const AdultJourneySaveResult.saved(
        AdultJourneyPreferences(setupSnoozedLocalDate: adultTestToday),
      ),
    );
    await pumpSlot(tester, _home());
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    final command =
        verify(() => update('owner-a', captureAny())).captured.single
            as SnoozeAdultSetup;
    expect(command.localDate, adultTestToday);
    expect(find.text(_inviteTitle), findsNothing);
  });

  testWidgets('a failed «Later» shows on the invite, not the time card', (
    tester,
  ) async {
    flagValues[AdultJourneyFeature.todayBudget.storageKey] = true;
    when(() => update(any(), any())).thenAnswer(
      (_) async =>
          const AdultJourneySaveResult.failed(AdultJourneySaveFailure.storage),
    );
    await pumpSlot(tester, _home());
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('adult_invite_error')), findsOneWidget);
    expect(find.byKey(const ValueKey('adult_today_error')), findsNothing);
    expect(find.text(_inviteTitle), findsOneWidget, reason: 'not snoozed');
  });

  testWidgets('the budget flag adds the time card under the invite', (
    tester,
  ) async {
    flagValues[AdultJourneyFeature.todayBudget.storageKey] = true;
    await pumpSlot(tester, _home());
    expect(find.text(_inviteTitle), findsOneWidget);
    expect(find.text(_todayTitle), findsOneWidget);
  });

  group('home visits and the return card', () {
    const welcomeBack = 'Welcome back. Shall we start with a light step?';

    setUp(() {
      flagValues[AdultJourneyFeature.gentleReturn.storageKey] = true;
      when(() => update(any(), any())).thenAnswer(
        (_) async =>
            const AdultJourneySaveResult.unchanged(AdultJourneyPreferences()),
      );
    });

    List<RecordAdultHomeVisit> visits() => verify(
      () => update('owner-a', captureAny()),
    ).captured.whereType<RecordAdultHomeVisit>().toList();

    testWidgets('a foreground adult Home load records one visit', (
      tester,
    ) async {
      await pumpSlot(tester, _home(), foreground: (_) => true);
      expect(visits(), hasLength(1));
    });

    testWidgets('a hidden tab or background Home records nothing', (
      tester,
    ) async {
      await pumpSlot(tester, _home(), foreground: (_) => false);
      verifyNever(() => update(any(), any()));
    });

    testWidgets('a child or unconfirmed adult records nothing', (tester) async {
      await pumpSlot(
        tester,
        _home(track: MemorizationTrack.kids, isKids: true),
        foreground: (_) => true,
      );
      await pumpSlot(tester, _home(track: null), foreground: (_) => true);
      verifyNever(() => update(any(), any()));
    });

    testWidgets('gentle return off: no visit is recorded', (tester) async {
      flagValues[AdultJourneyFeature.gentleReturn.storageKey] = false;
      await pumpSlot(tester, _home(), foreground: (_) => true);
      verifyNever(() => update(any(), any()));
    });

    testWidgets('returning to the app records a visit when Home is in front', (
      tester,
    ) async {
      var inFront = false;
      await pumpSlot(tester, _home(), foreground: (_) => inFront);
      verifyNever(() => update(any(), any()));

      inFront = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(visits(), hasLength(1));
    });

    testWidgets('default check: a page pushed over Home blocks the visit', (
      tester,
    ) async {
      final home = await pumpSlot(tester, _home());
      expect(visits(), hasLength(1), reason: 'Home itself is in front');

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const Text('reader')),
        ),
      );
      await tester.pumpAndSettle();
      home.push(_home(firstRun: false));
      home.push(
        HomeLoaded(
          progress: _progress,
          greeting: 'evening',
          activityStartDate: DateTime.utc(2026, 1, 1),
          selectedTrack: MemorizationTrack.adults,
          heroAction: _explore,
          alternativeActions: const [_explore],
        ),
      );
      await tester.pumpAndSettle();
      verifyNever(() => update('owner-a', captureAny()));
    });

    group('production router shape', () {
      // Home is branch 0 of a StatefulShellRoute.indexedStack; pages opened
      // from Home are top-level routes on the ROOT navigator (app_router).
      late GoRouter router;
      late _FakeHomeCubit home;

      Future<void> pumpRouter(WidgetTester tester) async {
        home = _FakeHomeCubit(_home());
        addTearDown(home.close);
        final rootKey = GlobalKey<NavigatorState>();
        router = GoRouter(
          navigatorKey: rootKey,
          initialLocation: '/',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (_, _, shell) => Scaffold(body: shell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/',
                      builder: (_, _) => const CustomScrollView(
                        slivers: [AdultJourneyHomeSlot()],
                      ),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/other',
                      builder: (_, _) => const Text('other tab'),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/reader',
              parentNavigatorKey: rootKey,
              builder: (_, _) => const Scaffold(body: Text('reader')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          BlocProvider<HomeCubit>.value(
            value: home,
            child: adultTestRouterApp(router: router),
          ),
        );
        await tester.pumpAndSettle();
      }

      HomeLoaded reloaded(String greeting) => HomeLoaded(
        progress: _progress,
        greeting: greeting,
        activityStartDate: DateTime.utc(2026, 1, 1),
        selectedTrack: MemorizationTrack.adults,
        heroAction: _explore,
        alternativeActions: const [_explore],
      );

      testWidgets('Home in front of the shell records a visit', (tester) async {
        await pumpRouter(tester);
        expect(visits(), hasLength(1));
      });

      testWidgets('a root page over Home blocks reloads and resumes', (
        tester,
      ) async {
        await pumpRouter(tester);
        expect(visits(), hasLength(1));

        unawaited(router.push('/reader'));
        await tester.pumpAndSettle();
        expect(find.text('reader'), findsOneWidget);

        home.push(reloaded('evening'));
        await tester.pumpAndSettle();
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        verifyNever(() => update('owner-a', captureAny()));

        // Popping back to Home counts by itself, with no Home reload.
        router.pop();
        await tester.pumpAndSettle();
        expect(visits(), hasLength(1));
      });

      testWidgets('another tab selected blocks the visit', (tester) async {
        await pumpRouter(tester);
        expect(visits(), hasLength(1));

        router.go('/other');
        await tester.pumpAndSettle();
        expect(find.text('other tab'), findsOneWidget);
        home.push(reloaded('evening'));
        await tester.pumpAndSettle();
        verifyNever(() => update('owner-a', captureAny()));

        // Switching back to the Home tab counts, with no Home reload.
        router.go('/');
        await tester.pumpAndSettle();
        expect(visits(), hasLength(1));
      });
    });

    testWidgets('a stored offer for today shows the return card first', (
      tester,
    ) async {
      when(() => load(any())).thenAnswer(
        (_) async => const AdultJourneyLoadResult.ready(
          AdultJourneyPreferences(
            goal: AdultJourneyGoal.reading,
            profileCompleted: true,
            returnOfferLocalDate: adultTestToday,
          ),
        ),
      );
      await pumpSlot(tester, _home(), foreground: (_) => false);
      expect(find.text(welcomeBack), findsOneWidget);
      expect(find.text(_inviteTitle), findsNothing, reason: 'profile done');
    });

    testWidgets('the slot never navigates by itself', (tester) async {
      when(() => load(any())).thenAnswer(
        (_) async => const AdultJourneyLoadResult.ready(
          AdultJourneyPreferences(returnOfferLocalDate: adultTestToday),
        ),
      );
      await pumpSlot(tester, _home(), foreground: (_) => true);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
    });
  });

  group('dark mode and accessibility', () {
    for (final brightness in Brightness.values) {
      for (final locale in ['ar', 'en']) {
        testWidgets('${brightness.name} $locale: guidelines met at 320 px', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          flagValues[AdultJourneyFeature.todayBudget.storageKey] = true;

          await pumpSlot(
            tester,
            _home(),
            brightness: brightness,
            locale: locale,
          );

          expect(tester.takeException(), isNull);
          // Not vacuous: the invite and the three time chips are on screen.
          expect(find.byType(ChoiceChip), findsNWidgets(3));
          expect(find.byType(FilledButton), findsWidgets);
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          handle.dispose();
        });
      }
    }
  });
}
