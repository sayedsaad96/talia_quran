import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_mission_card.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_day_complete_card.dart';

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

    test('the Mushaf opens at the mission ayah (K26)', () {
      expect(
        kidsQuranReaderLocation(113, ayahNumber: 4),
        '${AppRoutes.memorizationPlusKidsQuran}?surahId=113&ayahNumber=4',
      );
      expect(
        kidsQuranReaderLocation(114),
        '${AppRoutes.memorizationPlusKidsQuran}?surahId=114',
      );
    });

    testWidgets('renders progress, mission, and bottom navigation actions', (
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
            onHomeTap: () => tapped.add('home'),
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

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Mushaf'), findsWidgets);
      expect(find.text('My journey'), findsWidgets);
      expect(find.text('Missions'), findsWidgets);
      expect(
        find.byKey(const ValueKey('kids-home-action-mushaf')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('kids-home-action-journey')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('kids-home-action-missions')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('kids-home-nav-home')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('kids-home-nav-mushaf')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('kids-home-nav-journey')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('kids-home-nav-missions')));
      await tester.pump();

      expect(tapped, ['home', 'mushaf', 'journey', 'missions']);
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
            onHomeTap: () {},
            onMushafTap: () =>
                location = kidsQuranReaderLocation(_loadedState.surahId),
            onJourneyTap: () {},
            onMissionTap: () {},
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('kids-home-nav-mushaf')));
      await tester.pump();

      expect(location, '${AppRoutes.memorizationPlusKidsQuran}?surahId=114');
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
              onHomeTap: () {},
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
            onHomeTap: () {},
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
              onHomeTap: () {},
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
              onHomeTap: () {},
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
            onHomeTap: () {},
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
            onHomeTap: () {},
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
            onHomeTap: () {},
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
              onHomeTap: () {},
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
            onHomeTap: () {},
            onMushafTap: () {},
            onJourneyTap: () {},
            onMissionTap: () {},
          ),
        ),
      );

      expect(find.textContaining('يوسف'), findsOneWidget);
    });

    testWidgets('bottom navigation buttons trigger correct callbacks', (
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
            onHomeTap: () => tapped.add('home'),
            onMushafTap: () => tapped.add('mushaf'),
            onJourneyTap: () => tapped.add('journey'),
            onMissionTap: () => tapped.add('missions'),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('kids-home-nav-home')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('kids-home-nav-mushaf')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('kids-home-nav-journey')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('kids-home-nav-missions')));
      await tester.pump();

      expect(tapped, ['home', 'mushaf', 'journey', 'missions']);
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
