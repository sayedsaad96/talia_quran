import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_house_card.dart';

import 'package:flutter_animate/flutter_animate.dart';

void main() {
  setUpAll(() {
    Animate.defaultDuration = Duration.zero;
  });

  group('KidsGamifiedJourneyPage', () {
    testWidgets('renders journey stages and selects unlocked house', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.reset();
      });

      KidsJourneyStage? selectedStage;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedJourneyContent(
            state: _loadedState,
            onBack: () {},
            onStageSelected: (stage) => selectedStage = stage,
          ),
        ),
      );

      expect(find.text('Memorization map'), findsOneWidget);
      expect(find.byType(KidsHouseCard), findsNWidgets(3));
      expect(find.text('Memorization House 1'), findsOneWidget);
      expect(find.text('Memorization House 2'), findsOneWidget);
      expect(find.text('Memorization House 3'), findsOneWidget);

      await tester.ensureVisible(find.text('Memorization House 2'));
      await tester.tap(find.text('Memorization House 2'));
      await tester.pumpAndSettle();

      expect(selectedStage?.stageNumber, 2);
    });

    testWidgets('tapping locked stage shows SnackBar, not navigation', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.reset();
      });

      KidsJourneyStage? selectedStage;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedJourneyContent(
            state: _loadedState,
            onBack: () {},
            onStageSelected: (stage) => selectedStage = stage,
          ),
        ),
      );

      await tester.ensureVisible(find.text('Memorization House 3'));
      await tester.tap(find.text('Memorization House 3'));
      await tester.pump();

      // Locked stage should NOT trigger navigation
      expect(selectedStage, isNull);
      // Should show a SnackBar with locked message
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('renders empty state when no stages exist', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.reset();
      });

      const emptyState = KidsJourneyLoaded(
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
          child: KidsGamifiedJourneyContent(
            state: emptyState,
            onBack: () {},
            onStageSelected: (_) {},
          ),
        ),
      );

      expect(find.byType(KidsHouseCard), findsNothing);
      // Should show the completion/empty message
      expect(
        find.textContaining('completed the current memorization journey'),
        findsOneWidget,
      );
    });

    testWidgets('long journey builds only visible stage cards lazily', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);
      final stages = List.generate(
        100,
        (index) => KidsJourneyStage(
          stageNumber: index + 1,
          surahId: 2,
          startAyah: index + 1,
          endAyah: index + 1,
          completedAyahs: const [],
          status: index == 0
              ? KidsJourneyStageStatus.current
              : KidsJourneyStageStatus.locked,
        ),
      );

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedJourneyContent(
            state: KidsJourneyLoaded(
              surahId: 2,
              stages: stages,
              progress: const KidsProgress.initial(),
            ),
            onBack: () {},
            onStageSelected: (_) {},
          ),
        ),
      );

      expect(find.byType(KidsHouseCard).evaluate().length, lessThan(100));
    });
    testWidgets('back button triggers onBack callback', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.reset();
      });

      var backCalled = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedJourneyContent(
            state: _loadedState,
            onBack: () => backCalled = true,
            onStageSelected: (_) {},
          ),
        ),
      );

      await tester.tap(find.byTooltip('Back'));
      await tester.pump();

      expect(backCalled, isTrue);
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
    KidsJourneyStage(
      stageNumber: 3,
      surahId: 114,
      startAyah: 5,
      endAyah: 6,
      completedAyahs: [],
      status: KidsJourneyStageStatus.locked,
    ),
  ],
  progress: KidsProgress(
    totalPoints: 125,
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
      home: Scaffold(body: child),
    );
  }
}
