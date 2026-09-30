import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_house_card.dart';

void main() {
  group('KidsHouseCard', () {
    testWidgets('renders all four visual states', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: Column(
            children: [
              KidsHouseCard(stage: _stage(KidsJourneyStageStatus.locked)),
              KidsHouseCard(stage: _stage(KidsJourneyStageStatus.current)),
              KidsHouseCard(stage: _stage(KidsJourneyStageStatus.completed)),
              KidsHouseCard(stage: _stage(KidsJourneyStageStatus.needsReview)),
            ],
          ),
        ),
      );

      expect(find.byType(KidsHouseCard), findsNWidgets(4));
      expect(
        find.textContaining('This house is locked for now'),
        findsOneWidget,
      );
      expect(find.textContaining('Your current mission'), findsOneWidget);
      expect(find.textContaining('Well done, house completed'), findsOneWidget);
      expect(find.textContaining('Ready for review'), findsOneWidget);
      expect(find.text('Review House 1'), findsOneWidget);
    });

    testWidgets('locked house triggers onLockedTap, not onTap', (tester) async {
      var normalTapped = false;
      var lockedTapped = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsHouseCard(
            stage: _stage(KidsJourneyStageStatus.locked),
            onTap: () => normalTapped = true,
            onLockedTap: () => lockedTapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(KidsHouseCard));
      await tester.pump();

      expect(normalTapped, isFalse);
      expect(lockedTapped, isTrue);
    });

    testWidgets('unlocked house triggers onTap, not onLockedTap', (
      tester,
    ) async {
      var normalTapped = false;
      var lockedTapped = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsHouseCard(
            stage: _stage(KidsJourneyStageStatus.current),
            onTap: () => normalTapped = true,
            onLockedTap: () => lockedTapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(KidsHouseCard));
      await tester.pump();

      expect(normalTapped, isTrue);
      expect(lockedTapped, isFalse);
    });

    testWidgets('displays surah name when provided', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: KidsHouseCard(
            stage: _stage(KidsJourneyStageStatus.current),
            surahName: 'الناس',
          ),
        ),
      );

      expect(find.text('الناس'), findsOneWidget);
    });

    testWidgets('displays progress count correctly', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: KidsHouseCard(stage: _stage(KidsJourneyStageStatus.current)),
        ),
      );

      // Stage has 2 completed out of 5 total
      expect(find.textContaining('2/5'), findsOneWidget);
    });

    group('newly completed glow (K37)', () {
      Future<void> pumpHouse(
        WidgetTester tester, {
        required bool celebrate,
        bool reducedMotion = false,
      }) => tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reducedMotion),
          child: _TestApp(
            child: KidsHouseCard(
              stage: _stage(KidsJourneyStageStatus.completed),
              celebrate: celebrate,
            ),
          ),
        ),
      );

      testWidgets('a celebrated house glows once, then settles', (
        tester,
      ) async {
        await pumpHouse(tester, celebrate: true);

        expect(
          find.byKey(const ValueKey('kids-house-celebration')),
          findsOneWidget,
        );
        expect(tester.hasRunningAnimations, isTrue);

        await tester.pump(const Duration(seconds: 2));
        expect(tester.hasRunningAnimations, isFalse);
      });

      testWidgets('a glow that arrives after the first frame still plays', (
        tester,
      ) async {
        // The map learns which houses to celebrate asynchronously, so the
        // on-screen house is built first and told to celebrate afterwards.
        await pumpHouse(tester, celebrate: false);
        await pumpHouse(tester, celebrate: true);

        expect(tester.hasRunningAnimations, isTrue);
      });

      testWidgets('reduced motion keeps the glow still', (tester) async {
        await pumpHouse(tester, celebrate: true, reducedMotion: true);

        expect(
          find.byKey(const ValueKey('kids-house-celebration')),
          findsOneWidget,
        );
        expect(tester.hasRunningAnimations, isFalse);
      });

      testWidgets('an ordinary house does not glow', (tester) async {
        await pumpHouse(tester, celebrate: false);

        expect(
          find.byKey(const ValueKey('kids-house-celebration')),
          findsNothing,
        );
      });
    });

    testWidgets('shows lock icon only for locked state', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: Column(
            children: [
              KidsHouseCard(
                key: const ValueKey('locked'),
                stage: _stage(KidsJourneyStageStatus.locked),
              ),
              KidsHouseCard(
                key: const ValueKey('current'),
                stage: _stage(KidsJourneyStageStatus.current),
              ),
            ],
          ),
        ),
      );

      // Lock icon should appear in the locked card's stack overlay
      final lockedCard = find.byKey(const ValueKey('locked'));
      expect(
        find.descendant(
          of: lockedCard,
          matching: find.byIcon(Icons.lock_rounded),
        ),
        findsWidgets,
      );
    });
  });
}

KidsJourneyStage _stage(KidsJourneyStageStatus status) {
  return KidsJourneyStage(
    stageNumber: 1,
    surahId: 114,
    startAyah: 1,
    endAyah: 5,
    completedAyahs: switch (status) {
      KidsJourneyStageStatus.locked => const [],
      KidsJourneyStageStatus.current => const [1, 2],
      KidsJourneyStageStatus.completed => const [1, 2, 3, 4, 5],
      KidsJourneyStageStatus.needsReview => const [1, 2, 3],
    },
    status: status,
  );
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
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }
}
