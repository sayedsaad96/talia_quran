import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart';

void main() {
  group('KidsGamifiedCompletionPage', () {
    testWidgets('renders rewards and navigation actions', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      var nextTapped = false;
      var mapTapped = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedCompletionContent(
            starsEarned: 2,
            onNext: () => nextTapped = true,
            onReturnToMap: () => mapTapped = true,
          ),
        ),
      );

      expect(find.text('Well done!'), findsOneWidget);
      expect(find.text('+2 stars'), findsOneWidget);
      expect(find.text('+3 gems'), findsNothing);
      expect(find.text('Start mission'), findsOneWidget);
      expect(find.text('Return to map'), findsOneWidget);

      await tester.tap(find.text('Start mission'));
      await tester.pump();
      await tester.tap(find.text('Return to map'));
      await tester.pump();

      expect(nextTapped, isTrue);
      expect(mapTapped, isTrue);
    });

    testWidgets('the Next arrow points forward in Arabic (K22)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          locale: const Locale('ar'),
          child: KidsGamifiedCompletionContent(
            starsEarned: 1,
            onNext: () {},
            onReturnToMap: () {},
          ),
        ),
      );

      // The forward arrow mirrors itself under RTL; a hand-picked "back"
      // arrow would point the child backwards.
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });

    testWidgets('a review without stars never shows "+0 stars" (K23)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedCompletionContent(
            starsEarned: 0,
            pointsEarned: 5,
            onNext: () {},
            onReturnToMap: () {},
          ),
        ),
      );

      expect(find.textContaining('stars'), findsNothing);
      expect(find.text('+5 gems'), findsOneWidget);
    });

    testWidgets('after the session goal it says "enough for today" (K36)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedCompletionContent(
            starsEarned: 1,
            sessionGoalReached: true,
            onNext: () {},
            onReturnToMap: () {},
          ),
        ),
      );

      expect(
        find.textContaining("That's enough time for today"),
        findsOneWidget,
      );
      // Gentle, not blocking.
      expect(find.text('Start mission'), findsOneWidget);
    });

    testWidgets('large text stacks the two actions instead of squeezing', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 900),
            textScaler: TextScaler.linear(2),
          ),
          child: _TestApp(
            child: KidsGamifiedCompletionContent(
              starsEarned: 1,
              onNext: () {},
              onReturnToMap: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final map = tester.getCenter(find.text('Return to map'));
      final next = tester.getCenter(find.text('Start mission'));
      expect(map.dy, isNot(next.dy));
    });

    testWidgets('hides next button when showNextButton is false', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedCompletionContent(
            starsEarned: 2,
            showNextButton: false,
            onNext: () {},
            onReturnToMap: () {},
          ),
        ),
      );

      expect(find.text('Start mission'), findsNothing);
      expect(find.text('Return to map'), findsOneWidget);
    });

    testWidgets('a used-up quota ends the day in place of Next (N3)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedCompletionContent(
            starsEarned: 1,
            showNextButton: false,
            dailyGoalCap: 1,
            onNext: () {},
            onReturnToMap: () {},
          ),
        ),
      );

      expect(find.textContaining("finished today's missions"), findsOneWidget);
      expect(find.text('Start mission'), findsNothing);
      expect(find.text('Return to map'), findsOneWidget);
    });

    testWidgets('session points render as a gems pill next to stars', (
      tester,
    ) async {
      // K11: real session points are no longer swallowed — they show next to
      // the stars, and a level-up adds its own celebration pill.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedCompletionContent(
            starsEarned: 2,
            pointsEarned: 14,
            leveledUpTo: 3,
            onNext: () {},
            onReturnToMap: () {},
          ),
        ),
      );

      expect(find.text('+2 stars'), findsOneWidget);
      expect(find.text('+14 gems'), findsOneWidget);
      expect(find.text('Level 3'), findsOneWidget);
    });

    testWidgets('zero points and no level-up show stars only', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedCompletionContent(
            starsEarned: 1,
            onNext: () {},
            onReturnToMap: () {},
          ),
        ),
      );

      expect(find.text('+1 star'), findsOneWidget);
      expect(find.textContaining('gems'), findsNothing);
      expect(find.textContaining('Level'), findsNothing);
    });

    test('completed surah advances instead of reopening its last ayah', () {
      // After finishing the whole surah, the shared SRS resolver — the same
      // one the home screen uses — advances to the next surah in the reverse
      // Juz-Amma path instead of reopening the ayah just completed.
      const stages = [
        KidsJourneyStage(
          stageNumber: 1,
          surahId: 114,
          startAyah: 1,
          endAyah: 6,
          completedAyahs: [1, 2, 3, 4, 5, 6],
          status: KidsJourneyStageStatus.completed,
        ),
      ];

      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: stages,
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 24),
      );

      expect(mission?.surahId, 113);
      expect(mission?.startAyah, 1);
    });
    test(
      'selects the current journey mission instead of incrementing ayah',
      () {
        const stages = [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 5,
            completedAyahs: [1, 2, 3, 4, 5],
            status: KidsJourneyStageStatus.completed,
          ),
          KidsJourneyStage(
            stageNumber: 2,
            surahId: 114,
            startAyah: 6,
            endAyah: 6,
            completedAyahs: [],
            status: KidsJourneyStageStatus.current,
          ),
        ];

        final mission = const KidsNextMissionResolver().resolve(
          activeSurahId: 114,
          stages: stages,
          reviewRecords: const [],
          now: DateTime.utc(2026, 9, 24),
        );

        expect(mission?.surahId, 114);
        expect(mission?.startAyah, 6);
      },
    );
    test(
      'a due review outranks new memorization exactly like the home screen',
      () {
        const stages = [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 2,
            endAyah: 2,
            completedAyahs: [],
            status: KidsJourneyStageStatus.current,
          ),
        ];
        final mission = const KidsNextMissionResolver().resolve(
          activeSurahId: 114,
          stages: stages,
          reviewRecords: [_dueReviewRecord(surahId: 113, ayahNumber: 3)],
          now: DateTime.utc(2026, 9, 24),
        );

        expect(mission?.type, KidsMissionType.dueReview);
        expect(mission?.surahId, 113);
        expect(mission?.startAyah, 3);
      },
    );

    testWidgets('the celebration fires confetti behind the reward card (W2)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedCompletionContent(
            starsEarned: 2,
            onNext: () {},
            onReturnToMap: () {},
          ),
        ),
      );
      // Confetti animates continuously, so pump a frame instead of
      // settling — the widget is in the tree from the first build.
      await tester.pump(const Duration(milliseconds: 200));

      // The completion moment is multi-sensory: a confetti burst plays
      // behind the reward card.
      expect(find.byType(ConfettiWidget), findsOneWidget);
    });

    testWidgets('a level-up celebration renders too (W2)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedCompletionContent(
            starsEarned: 3,
            pointsEarned: 15,
            leveledUpTo: 2,
            onNext: () {},
            onReturnToMap: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ConfettiWidget), findsOneWidget);
      expect(find.textContaining('Level'), findsOneWidget);
    });

    testWidgets('reward image respects reduced motion (R5)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _TestApp(
            child: KidsGamifiedCompletionContent(
              starsEarned: 2,
              onNext: () {},
              onReturnToMap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}

AyahReviewRecord _dueReviewRecord({
  required int surahId,
  required int ayahNumber,
}) => AyahReviewRecord(
  surahId: surahId,
  ayahNumber: ayahNumber,
  strengthLevel: 5,
  intervalDays: 1,
  lastReviewedAt: DateTime.utc(2026, 8, 30),
  nextReviewDate: DateTime.utc(2026, 9, 1),
  totalReviews: 2,
  lastRating: PerformanceRating.excellent,
  createdByMode: ReviewRecordCreatedByMode.kidsMode,
);

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child, this.locale = const Locale('en')});

  final Widget child;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
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
