import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart';

void main() {
  group('KidsGamifiedHomePage', () {
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
      expect(find.text('Level 2 — 25/100'), findsOneWidget);
      expect(find.text('7 stars'), findsOneWidget);
      expect(find.text('Last mission'), findsOneWidget);
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
      'renders correctly with no completed stages (first-time user)',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1200);
        addTearDown(tester.view.reset);

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
        // Should show 0 stars
        expect(find.text('0 stars'), findsOneWidget);
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
