import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:dartz/dartz.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_home_mission.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_talia_companion.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_daily_missions.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_daily_mission_tile.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_mission_card.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_day_complete_card.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_palette.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_phase_controller.dart';

void main() {
  setUpAll(() {
    Animate.defaultDuration = Duration.zero;
    Animate.restartOnHotReload = false;
  });

  group('KidsGamifiedHomePage', () {
    test('mission route preserves the due-review task type', () {
      const mission = KidsNextMission(
        type: KidsMissionType.dueReview,
        surahId: 114,
        ayahNumbers: [2],
      );

      expect(
        kidsMissionLocation(mission),
        '${AppRoutes.memorizationPlusKids}?surahId=114&ayahNumber=2&missionType=dueReview',
      );
    });

    test('reader links preserve explicit missions and support page one', () {
      expect(
        kidsQuranReaderLocation(113, ayahNumber: 4),
        '${AppRoutes.memorizationPlusKidsQuran}?surahId=113&ayahNumber=4',
      );
      expect(
        kidsQuranReaderLocation(114, pageNumber: 1),
        '${AppRoutes.memorizationPlusKidsQuran}?surahId=114&pageNumber=1',
      );
      expect(
        kidsQuranReaderLocation(114),
        '${AppRoutes.memorizationPlusKidsQuran}?surahId=114',
      );
    });

    testWidgets(
      'treasures chip appears only with a callback and taps through',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1200);
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox()));

        var taps = 0;
        Widget content({VoidCallback? onTreasuresTap}) => _TestApp(
          child: KidsGamifiedHomeContent(
            state: _loadedState,
            onMushafTap: () {},
            onJourneyTap: () {},
            onMissionTap: () {},
            onTreasuresTap: onTreasuresTap,
          ),
        );

        await tester.pumpWidget(content());
        expect(find.byKey(const ValueKey('kids-home-treasures')), findsNothing);

        await tester.pumpWidget(content(onTreasuresTap: () => taps++));
        expect(find.text('My treasures'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('kids-home-treasures')));
        expect(taps, 1);
      },
    );

    testWidgets('renders progress, mission, and in-page navigation cards', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));

      final tapped = <String>[];

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedHomeContent(
            state: _loadedState,
            onMushafTap: () => tapped.add('mushaf'),
            onJourneyTap: () => tapped.add('journey'),
            onMissionTap: () => tapped.add('missions'),
          ),
        ),
      );

      expect(find.text('Welcome, memorization hero!'), findsOneWidget);
      // New early curve: level 2 step costs 200 points with a 50-point
      // first step, so 150 total points = 100/200 = 50% of level 2.
      expect(find.text('Level 2 — 50/100'), findsOneWidget);
      expect(find.text('7 stars'), findsOneWidget);
      expect(find.text('Your mission'), findsOneWidget);
      expect(find.text('Memorization House 2'), findsOneWidget);

      expect(find.text('Mushaf'), findsWidgets);
      expect(find.text('My journey'), findsWidgets);
      expect(find.text('Missions'), findsWidgets);
      expect(find.byType(NavigationBar), findsNothing);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Mushaf'), findsOneWidget);
      expect(find.bySemanticsLabel('My journey'), findsOneWidget);
      expect(find.bySemanticsLabel('Missions'), findsOneWidget);
      final mushaf = find.byKey(const ValueKey('kids-home-action-mushaf'));
      final journey = find.byKey(const ValueKey('kids-home-action-journey'));
      final missions = find.byKey(const ValueKey('kids-home-action-missions'));
      expect(tester.getSize(mushaf), tester.getSize(journey));
      expect(tester.getSize(journey), tester.getSize(missions));
      expect(tester.getSize(mushaf).width, tester.getSize(mushaf).height);
      expect(tester.getTopLeft(mushaf).dy, tester.getTopLeft(journey).dy);
      expect(tester.getTopLeft(journey).dy, tester.getTopLeft(missions).dy);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('kids-home-action-journey')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('kids-home-action-mushaf')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('kids-home-action-mushaf')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('kids-home-action-journey')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('kids-home-action-journey')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('kids-home-action-missions')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('kids-home-action-missions')));
      await tester.pump();

      expect(tapped, ['mushaf', 'journey', 'missions']);
      semantics.dispose();
    });

    testWidgets('Mushaf action targets Kids Quran mode, not adult Quran', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));

      String? location;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedHomeContent(
            state: _loadedState,
            onMushafTap: () => location = kidsQuranReaderLocation(
              _loadedState.surahId,
              pageNumber: 1,
            ),
            onJourneyTap: () {},
            onMissionTap: () {},
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('kids-home-action-mushaf')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('kids-home-action-mushaf')));
      await tester.pump();

      expect(
        location,
        '${AppRoutes.memorizationPlusKidsQuran}?surahId=114&pageNumber=1',
      );
      expect(location, isNot(AppRoutes.quran));
    });

    testWidgets(
      'due review mission is titled Ready for review, not Last mission',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1200);
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox()));

        final reviewState = _loadedState.copyWith(
          nextMission: const KidsNextMission(
            type: KidsMissionType.dueReview,
            surahId: 114,
            ayahNumbers: [2],
          ),
        );

        await tester.pumpWidget(
          _TestApp(
            child: KidsGamifiedHomeContent(
              state: reviewState,
              onMushafTap: () {},
              onJourneyTap: () {},
              onMissionTap: () {},
            ),
          ),
        );

        // The SRS-first resolver surfaced a due review, so the card must not
        // present it as yesterday's ("last") mission.
        expect(find.text('Ready for review'), findsOneWidget);
        expect(find.text('Your mission'), findsNothing);
        // N7: the card describes the ayah the review opens (stage 1), never the
        // current memorization stage's range and progress (stage 2).
        expect(find.textContaining('Ayahs 2-2'), findsOneWidget);
        expect(find.textContaining('Ayahs 3-4'), findsNothing);
      },
    );

    testWidgets('a used-up daily quota shows the day-complete card (N3)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));

      final dayDoneState = _loadedState.copyWith(
        clearNextMission: true,
        dailyGoalCap: 1,
      );

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedHomeContent(
            state: dayDoneState,
            onMushafTap: () {},
            onJourneyTap: () {},
            onMissionTap: () {},
          ),
        ),
      );

      expect(find.byType(KidsDayCompleteCard), findsOneWidget);
      expect(find.textContaining("finished today's missions"), findsOneWidget);
      // No mission the session gate would refuse.
      expect(find.byType(KidsMissionCard), findsNothing);
      expect(find.text('Continue now'), findsNothing);
    });

    testWidgets(
      'a surah finished on a capped day ends the day, not the journey (K18)',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1200);
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox()));

        const surahDoneState = KidsJourneyLoaded(
          surahId: 114,
          stages: [
            KidsJourneyStage(
              stageNumber: 1,
              surahId: 114,
              startAyah: 1,
              endAyah: 6,
              completedAyahs: [1, 2, 3, 4, 5, 6],
              status: KidsJourneyStageStatus.completed,
            ),
          ],
          progress: KidsProgress(
            totalPoints: 60,
            currentLevel: 1,
            currentStreak: 1,
            starsEarned: 6,
            ayahsCompleted: 6,
            lastSessionAt: null,
          ),
          dailyGoalCap: 1,
        );

        await tester.pumpWidget(
          _TestApp(
            child: KidsGamifiedHomeContent(
              state: surahDoneState,
              onMushafTap: () {},
              onJourneyTap: () {},
              onMissionTap: () {},
            ),
          ),
        );

        expect(find.byType(KidsDayCompleteCard), findsOneWidget);
        expect(
          find.textContaining('completed the current memorization journey'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'mission card describes the stage the new mission opens (K19)',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1200);
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox()));

        const budgetSpentState = KidsJourneyLoaded(
          surahId: 114,
          stages: [
            KidsJourneyStage(
              stageNumber: 1,
              surahId: 114,
              startAyah: 1,
              endAyah: 3,
              completedAyahs: [1, 2, 3],
              status: KidsJourneyStageStatus.needsReview,
            ),
            KidsJourneyStage(
              stageNumber: 2,
              surahId: 114,
              startAyah: 4,
              endAyah: 6,
              completedAyahs: [],
              status: KidsJourneyStageStatus.current,
            ),
          ],
          progress: KidsProgress.initial(),
          nextMission: KidsNextMission(
            type: KidsMissionType.newMemorization,
            surahId: 114,
            ayahNumbers: [4],
          ),
        );

        await tester.pumpWidget(
          _TestApp(
            child: KidsGamifiedHomeContent(
              state: budgetSpentState,
              onMushafTap: () {},
              onJourneyTap: () {},
              onMissionTap: () {},
            ),
          ),
        );

        expect(find.text('Memorization House 2'), findsOneWidget);
        expect(find.text('Memorization House 1'), findsNothing);
      },
    );

    testWidgets('a review in another surah shows that surah by name (K20)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));

      final reviewElsewhere = _loadedState.copyWith(
        nextMission: const KidsNextMission(
          type: KidsMissionType.dueReview,
          surahId: 112,
          ayahNumbers: [2],
        ),
        missionSurahName: 'الإخلاص',
      );

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedHomeContent(
            state: reviewElsewhere,
            onMushafTap: () {},
            onJourneyTap: () {},
            onMissionTap: () {},
          ),
        ),
      );

      expect(find.text('الإخلاص'), findsOneWidget);
      expect(find.textContaining('112'), findsNothing);
    });

    testWidgets('a returning child is welcomed back, no streak talk (K33)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));

      Future<void> pumpHome(bool returning) => tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedHomeContent(
            state: _loadedState.copyWith(isReturningAfterBreak: returning),
            onMushafTap: () {},
            onJourneyTap: () {},
            onMissionTap: () {},
          ),
        ),
      );

      await pumpHome(true);
      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text("Let's start with an easy step"), findsOneWidget);
      expect(find.byType(KidsMissionCard), findsOneWidget);

      await pumpHome(false);
      expect(find.text('Welcome back!'), findsNothing);
    });

    testWidgets('finished journey replaces the mission card with celebration', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));

      const finishedState = KidsJourneyLoaded(
        surahId: 114,
        stages: [],
        // Real progress proves the journey was actually completed rather
        // than a first-time child who has not started yet.
        progress: KidsProgress(
          totalPoints: 300,
          currentLevel: 3,
          currentStreak: 2,
          starsEarned: 12,
          ayahsCompleted: 48,
          lastSessionAt: null,
        ),
      );

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedHomeContent(
            state: finishedState,
            onMushafTap: () {},
            onJourneyTap: () {},
            onMissionTap: () {},
          ),
        ),
      );

      // No stage and no mission: celebrate instead of a stale CTA.
      expect(find.byType(KidsMissionCard), findsNothing);
      expect(
        find.textContaining('completed the current memorization journey'),
        findsOneWidget,
      );
      expect(find.text('Continue now'), findsNothing);
    });

    testWidgets(
      'renders correctly with no completed stages (first-time user)',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1200);
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox()));

        const firstTimeState = KidsJourneyLoaded(
          surahId: 114,
          stages: [],
          progress: KidsProgress(
            totalPoints: 0,
            currentLevel: 1,
            currentStreak: 0,
            starsEarned: 0,
            ayahsCompleted: 0,
            lastSessionAt: null,
          ),
        );

        await tester.pumpWidget(
          _TestApp(
            child: KidsGamifiedHomeContent(
              state: firstTimeState,
              onMushafTap: () {},
              onJourneyTap: () {},
              onMissionTap: () {},
            ),
          ),
        );

        // Should still render with default greeting
        expect(find.text('Welcome, memorization hero!'), findsOneWidget);
        // K34: a zero counter is never shown to a new child.
        expect(find.text('0 stars'), findsNothing);
        // Should show first stage prompt
        expect(find.text('Start your first stage today'), findsOneWidget);
      },
    );

    testWidgets('displays personalized greeting with child name', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedHomeContent(
            state: _loadedState,
            childName: 'يوسف',
            onMushafTap: () {},
            onJourneyTap: () {},
            onMissionTap: () {},
          ),
        ),
      );

      expect(find.textContaining('يوسف'), findsOneWidget);
    });

    testWidgets(
      'navigation cards stay tappable in narrow Arabic at large text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox()));

        final tapped = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: KidsGamifiedHomeContent(
              state: _loadedState,
              onMushafTap: () => tapped.add('mushaf'),
              onJourneyTap: () => tapped.add('journey'),
              onMissionTap: () => tapped.add('missions'),
            ),
          ),
        );

        final semantics = tester.ensureSemantics();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('kids-home-action-journey')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.bySemanticsLabel('المصحف'), findsOneWidget);
        expect(find.bySemanticsLabel('رحلتي'), findsOneWidget);
        expect(find.bySemanticsLabel('المهام'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const ValueKey('kids-home-action-mushaf')),
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('kids-home-action-mushaf')));
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(const ValueKey('kids-home-action-journey')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey('kids-home-action-journey')),
        );
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(const ValueKey('kids-home-action-missions')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey('kids-home-action-missions')),
        );
        await tester.pump();

        expect(tapped, ['mushaf', 'journey', 'missions']);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );

    testWidgets('returning from the Mushaf tab reloads the journey', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1600);
      addTearDown(tester.view.reset);
      final cubit = _FakeJourneyCubit();
      getIt.registerFactory<KidsJourneyCubit>(() => cubit);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        if (getIt.isRegistered<KidsJourneyCubit>()) {
          getIt.unregister<KidsJourneyCubit>();
        }
      });

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const KidsGamifiedHomePage(surahId: 114),
          ),
          GoRoute(
            path: AppRoutes.memorizationPlusKidsQuran,
            builder: (context, _) => Scaffold(
              body: TextButton(
                key: const ValueKey('fake-reader-back'),
                onPressed: () => context.pop(),
                child: const Text('back'),
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(cubit.loads, 1);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('kids-home-action-mushaf')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('kids-home-action-mushaf')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('fake-reader-back')), findsOneWidget);
      expect(cubit.loads, 1);

      await tester.tap(find.byKey(const ValueKey('fake-reader-back')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(cubit.loads, 2);
    });

    testWidgets(
      'cards still open after a destination returns home with go, not pop',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1600);
        addTearDown(tester.view.reset);
        final cubit = _FakeJourneyCubit();
        getIt.registerFactory<KidsJourneyCubit>(() => cubit);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          if (getIt.isRegistered<KidsJourneyCubit>()) {
            getIt.unregister<KidsJourneyCubit>();
          }
        });

        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const KidsGamifiedHomePage(surahId: 114),
            ),
            GoRoute(
              path: AppRoutes.memorizationPlusKidsQuran,
              // The real Kids reader leaves with `context.go(home)`, which
              // never completes the home page's `push` future.
              builder: (context, _) => Scaffold(
                body: TextButton(
                  key: const ValueKey('fake-reader-home'),
                  onPressed: () => context.go('/'),
                  child: const Text('home'),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.memorizationPlusKidsJourney,
              builder: (_, _) => const Scaffold(
                body: Text('journey', key: ValueKey('fake-journey')),
              ),
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        Future<void> tapCard(String key) async {
          await tester.scrollUntilVisible(
            find.byKey(ValueKey(key)),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.byKey(ValueKey(key)));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        }

        await tapCard('kids-home-action-mushaf');
        await tester.tap(find.byKey(const ValueKey('fake-reader-home')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('fake-reader-home')), findsNothing);

        await tapCard('kids-home-action-journey');
        expect(find.byKey(const ValueKey('fake-journey')), findsOneWidget);
      },
    );

    group("today's missions", () {
      const readingAvailable = KidsDailyMission(
        id: '2026-10-02:reading',
        kind: KidsDailyMissionKind.reading,
        status: KidsDailyMissionStatus.available,
      );
      const readingDone = KidsDailyMission(
        id: '2026-10-02:reading',
        kind: KidsDailyMissionKind.reading,
        status: KidsDailyMissionStatus.completed,
      );

      Widget home(KidsJourneyLoaded state, {VoidCallback? onReading}) =>
          _TestApp(
            child: KidsGamifiedHomeContent(
              state: state,
              onMushafTap: () {},
              onJourneyTap: () {},
              onMissionTap: () {},
              onReadingMissionTap: onReading,
            ),
          );

      testWidgets('shows the header and the reading tile', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1600);
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox()));
        var taps = 0;

        await tester.pumpWidget(
          home(
            _loadedState.copyWith(dailyMissions: const [readingAvailable]),
            onReading: () => taps++,
          ),
        );

        expect(find.text("Today's missions"), findsOneWidget);
        expect(find.text('Read a page of your Mushaf'), findsOneWidget);
        expect(find.text('Done ✓'), findsNothing);
        await tester.tap(find.byType(KidsDailyMissionTile));
        expect(taps, 1);
      });

      testWidgets('day-complete card and reading tile both show', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1600);
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox()));

        await tester.pumpWidget(
          home(
            _loadedState.copyWith(
              clearNextMission: true,
              dailyGoalCap: 3,
              dailyMissions: const [readingAvailable],
            ),
          ),
        );

        expect(find.byType(KidsDayCompleteCard), findsOneWidget);
        expect(find.text('Read a page of your Mushaf'), findsOneWidget);
      });

      testWidgets('a completed tile says Done and keeps its label', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1600);
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox()));
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          home(_loadedState.copyWith(dailyMissions: const [readingDone])),
        );

        expect(find.text('Done ✓'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Read a page of your Mushaf')),
          findsOneWidget,
        );
        handle.dispose();
      });

      testWidgets('the header is dark on the day sky', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1600);
        addTearDown(tester.view.reset);
        final controller = KidsWorldPhaseController(
          prayerTimes: () async => null,
          clock: () => DateTime(2026, 10, 2, 12),
        );
        getIt.registerSingleton<KidsWorldPhaseController>(controller);

        await tester.pumpWidget(
          home(_loadedState.copyWith(dailyMissions: const [readingAvailable])),
        );
        await tester.pump();
        await tester.pump();

        final heading = tester.widget<Text>(find.text("Today's missions"));
        expect(heading.style?.color, KidsWorldPalette.day.onScene);

        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        getIt.unregister<KidsWorldPhaseController>();
      });

      testWidgets('no missions renders no header', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1600);
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox()));

        await tester.pumpWidget(home(_loadedState));

        expect(find.text("Today's missions"), findsNothing);
      });

      testWidgets('fits 320 px, Arabic, text scale 1.3', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox()));

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: KidsGamifiedHomeContent(
              state: _loadedState.copyWith(
                dailyMissions: const [readingAvailable],
              ),
              onMushafTap: () {},
              onJourneyTap: () {},
              onMissionTap: () {},
            ),
          ),
        );
        await tester.scrollUntilVisible(
          find.text('اقرأ صفحة من مصحفك'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('مهماتي اليوم'), findsOneWidget);
      });
    });

    group('home mission card', () {
      const homeAvailable = KidsDailyMission(
        id: '2026-10-02:home:12',
        kind: KidsDailyMissionKind.home,
        status: KidsDailyMissionStatus.available,
        homeMissionId: '12',
        homeMissionTitle: 'Tidy your room',
      );
      const homeDone = KidsDailyMission(
        id: '2026-10-02:home:12',
        kind: KidsDailyMissionKind.home,
        status: KidsDailyMissionStatus.completed,
        homeMissionId: '12',
        homeMissionTitle: 'Tidy your room',
      );

      Widget home(
        KidsJourneyLoaded state, {
        void Function(String)? onReport,
        bool happy = false,
      }) => _TestApp(
        child: KidsGamifiedHomeContent(
          state: state,
          onMushafTap: () {},
          onJourneyTap: () {},
          onMissionTap: () {},
          onHomeMissionReport: onReport,
          taliaHappy: happy,
        ),
      );

      void bigView(WidgetTester tester) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1600);
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox()));
      }

      bool happyShown(WidgetTester tester) => tester
          .widgetList<KidsTaliaCompanion>(find.byType(KidsTaliaCompanion))
          .any((w) => w.pose == KidsTaliaPose.happy);

      testWidgets('shows the guardian title and an I-did-it button', (
        tester,
      ) async {
        bigView(tester);
        String? reported;
        await tester.pumpWidget(
          home(
            _loadedState.copyWith(dailyMissions: const [homeAvailable]),
            onReport: (id) => reported = id,
          ),
        );

        expect(find.text('Tidy your room'), findsOneWidget);
        expect(find.text('I did it!'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('kids-home-mission-report')),
        );
        expect(reported, '12');
      });

      testWidgets('a reported mission shows Done and no button', (
        tester,
      ) async {
        bigView(tester);
        await tester.pumpWidget(
          home(
            _loadedState.copyWith(dailyMissions: const [homeDone]),
            onReport: (_) {},
          ),
        );

        expect(find.text('Tidy your room'), findsOneWidget);
        expect(find.text('Done ✓'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('kids-home-mission-report')),
          findsNothing,
        );
      });

      testWidgets('a 120-character title fits 320 px at text scale 1.3', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.reset);
        addTearDown(() async => tester.pumpWidget(const SizedBox()));
        final long = KidsDailyMission(
          id: '2026-10-02:home:12',
          kind: KidsDailyMissionKind.home,
          status: KidsDailyMissionStatus.available,
          homeMissionId: '12',
          homeMissionTitle: List.filled(
            20,
            'tidy',
          ).join(' ').padRight(120, 'x'),
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: home(
              _loadedState.copyWith(dailyMissions: [long]),
              onReport: (_) {},
            ),
          ),
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('kids-home-mission-report')),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('Talia is happy only when asked to be', (tester) async {
        bigView(tester);
        await tester.pumpWidget(home(_loadedState));
        expect(happyShown(tester), isFalse);

        await tester.pumpWidget(home(_loadedState, happy: true));
        expect(happyShown(tester), isTrue);
      });

      testWidgets(
        'tapping report calls the repository, reloads, shows Done and Talia '
        'happy for a moment',
        (tester) async {
          bigView(tester);
          final repo = _FakeHomeMissionRepository();
          final cubit = _HomeMissionCubit(repo);
          getIt.registerFactory<KidsJourneyCubit>(() => cubit);
          getIt.registerSingleton<MemorizationPlusRepository>(repo);
          addTearDown(() async {
            await tester.pumpWidget(const SizedBox());
            if (getIt.isRegistered<KidsJourneyCubit>()) {
              getIt.unregister<KidsJourneyCubit>();
            }
            if (getIt.isRegistered<MemorizationPlusRepository>()) {
              getIt.unregister<MemorizationPlusRepository>();
            }
          });

          await tester.pumpWidget(
            const _TestApp(
              child: KidsGamifiedHomePage(surahId: 114, childName: 'Sami'),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(cubit.loads, 1);
          expect(find.text('Tidy your room'), findsOneWidget);
          expect(find.text('Done ✓'), findsNothing);

          await tester.tap(
            find.byKey(const ValueKey('kids-home-mission-report')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(repo.reportedIds, ['12']);
          expect(cubit.loads, 2);
          expect(find.text('Done ✓'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('kids-home-mission-report')),
            findsNothing,
          );
          expect(happyShown(tester), isTrue);

          await tester.pump(const Duration(seconds: 5));
          expect(happyShown(tester), isFalse);
        },
      );
    });
  });

  group('guardian refresh', () {
    Future<_FakeJourneyCubit> pumpHome(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1600);
      addTearDown(tester.view.reset);
      final cubit = _FakeJourneyCubit();
      getIt.registerFactory<KidsJourneyCubit>(() => cubit);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        if (getIt.isRegistered<KidsJourneyCubit>()) {
          getIt.unregister<KidsJourneyCubit>();
        }
      });
      await tester.pumpWidget(
        const _TestApp(child: KidsGamifiedHomePage(surahId: 114)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      return cubit;
    }

    testWidgets('opening the home forces a guardian pull', (tester) async {
      final cubit = await pumpHome(tester);

      expect(cubit.loads, 1);
      expect(cubit.guardianRefreshes, [true]);
    });

    testWidgets('app resume asks for a throttled pull', (tester) async {
      final cubit = await pumpHome(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(cubit.guardianRefreshes, [true, false]);
    });

    testWidgets('pull-to-refresh goes through the guardian refresh', (
      tester,
    ) async {
      final cubit = await pumpHome(tester);

      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();

      expect(cubit.pullToRefreshes, 1);
      expect(cubit.loads, 1);
    });
  });
}

const _loadedState = KidsJourneyLoaded(
  surahId: 114,
  stages: [
    KidsJourneyStage(
      stageNumber: 1,
      surahId: 114,
      startAyah: 1,
      endAyah: 2,
      completedAyahs: [1, 2],
      status: KidsJourneyStageStatus.completed,
    ),
    KidsJourneyStage(
      stageNumber: 2,
      surahId: 114,
      startAyah: 3,
      endAyah: 4,
      completedAyahs: [3],
      status: KidsJourneyStageStatus.current,
    ),
  ],
  progress: KidsProgress(
    totalPoints: 150,
    currentLevel: 2,
    currentStreak: 3,
    starsEarned: 7,
    ayahsCompleted: 3,
    lastSessionAt: null,
  ),
);

class _FakeJourneyCubit extends Cubit<KidsJourneyState>
    implements KidsJourneyCubit {
  _FakeJourneyCubit() : super(const KidsJourneyInitial());

  int loads = 0;
  final guardianRefreshes = <bool>[];
  int pullToRefreshes = 0;

  @override
  Future<void> load({
    required int surahId,
    bool followFrontier = false,
    bool showLoading = true,
  }) async {
    loads++;
    emit(_loadedState);
  }

  @override
  Future<void> refreshFromGuardian({
    required int surahId,
    bool force = false,
  }) async => guardianRefreshes.add(force);

  @override
  Future<void> refresh({required int surahId}) async => pullToRefreshes++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}

class _FakeHomeMissionRepository implements MemorizationPlusRepository {
  final reportedIds = <String>[];
  bool reported = false;

  @override
  Future<Either<Failure, List<KidsHomeMission>>> reportHomeMission(
    String id,
  ) async {
    reportedIds.add(id);
    reported = true;
    return const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HomeMissionCubit extends Cubit<KidsJourneyState>
    implements KidsJourneyCubit {
  _HomeMissionCubit(this._repo) : super(const KidsJourneyInitial());

  final _FakeHomeMissionRepository _repo;
  int loads = 0;

  @override
  Future<void> refreshFromGuardian({
    required int surahId,
    bool force = false,
  }) async {}

  @override
  Future<void> load({
    required int surahId,
    bool followFrontier = false,
    bool showLoading = true,
  }) async {
    loads++;
    emit(
      _loadedState.copyWith(
        dailyMissions: [
          KidsDailyMission(
            id: '2026-10-02:home:12',
            kind: KidsDailyMissionKind.home,
            status: _repo.reported
                ? KidsDailyMissionStatus.completed
                : KidsDailyMissionStatus.available,
            homeMissionId: '12',
            homeMissionTitle: 'Tidy your room',
          ),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
