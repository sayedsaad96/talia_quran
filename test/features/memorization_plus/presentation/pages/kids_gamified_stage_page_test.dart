import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart';

import 'package:flutter_animate/flutter_animate.dart';

void main() {
  setUpAll(() {
    Animate.defaultDuration = Duration.zero;
  });

  group('KidsGamifiedStagePage', () {
    testWidgets('renders stage info and starts mission', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.reset();
      });

      var started = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedStageContent(
            stage: _stage,
            surahName: 'Surah 114',
            onBack: () {},
            onStartMission: () => started = true,
          ),
        ),
      );

      expect(find.text('Memorization House 2'), findsOneWidget);
      expect(find.text('Surah 114 • Ayahs 3-4'), findsOneWidget);
      expect(find.text('Listen'), findsOneWidget);
      expect(find.text('Repeat'), findsOneWidget);
      expect(find.text('Test yourself'), findsOneWidget);
      expect(find.text('Start mission'), findsOneWidget);

      await tester.tap(find.text('Start mission'));
      await tester.pump();

      expect(started, isTrue);
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
          child: KidsGamifiedStageContent(
            stage: _stage,
            surahName: 'الناس',
            onBack: () => backCalled = true,
            onStartMission: () {},
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pump();

      expect(backCalled, isTrue);
    });

    testWidgets('displays three mission steps with subtitles', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedStageContent(
            stage: _stage,
            surahName: 'الناس',
            onBack: () {},
            onStartMission: () {},
          ),
        ),
      );

      // Verify step titles
      expect(find.text('Listen'), findsOneWidget);
      expect(find.text('Repeat'), findsOneWidget);
      expect(find.text('Test yourself'), findsOneWidget);

      // Verify step subtitles
      expect(find.text('Listen carefully to the ayah'), findsOneWidget);
      expect(
        find.text('Repeat after the reciter until it settles'),
        findsOneWidget,
      );
      expect(find.text('Try reciting without help'), findsOneWidget);
    });

    testWidgets('renders correctly for a completed stage', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      const completedStage = KidsJourneyStage(
        stageNumber: 1,
        surahId: 114,
        startAyah: 1,
        endAyah: 6,
        completedAyahs: [1, 2, 3, 4, 5, 6],
        status: KidsJourneyStageStatus.completed,
      );

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedStageContent(
            stage: completedStage,
            surahName: 'الناس',
            onBack: () {},
            onStartMission: () {},
          ),
        ),
      );

      expect(find.text('Memorization House 1'), findsOneWidget);
      expect(find.text('Start mission'), findsOneWidget);
    });
  });
}

const _stage = KidsJourneyStage(
  stageNumber: 2,
  surahId: 114,
  startAyah: 3,
  endAyah: 4,
  completedAyahs: [3],
  status: KidsJourneyStageStatus.current,
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
