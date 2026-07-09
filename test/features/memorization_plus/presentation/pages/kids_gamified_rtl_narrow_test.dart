import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  group('Kids gamified Arabic narrow layout', () {
    testWidgets('home page renders at 320px without layout exceptions', (
      tester,
    ) async {
      await _pumpNarrowArabic(
        tester,
        KidsGamifiedHomeContent(
          state: _journeyState,
          childName: 'يوسف',
          onHomeTap: () {},
          onMushafTap: () {},
          onJourneyTap: () {},
          onMissionTap: () {},
        ),
      );
    });

    testWidgets('journey map renders at 320px without layout exceptions', (
      tester,
    ) async {
      await _pumpNarrowArabic(
        tester,
        KidsGamifiedJourneyContent(
          state: _journeyState,
          onBack: () {},
          onStageSelected: (_) {},
        ),
      );
    });

    testWidgets('stage page renders at 320px without layout exceptions', (
      tester,
    ) async {
      await _pumpNarrowArabic(
        tester,
        KidsGamifiedStageContent(
          stage: _currentStage,
          surahName: 'سورة الناس',
          onBack: () {},
          onStartMission: () {},
        ),
      );
    });

    testWidgets('listen page renders at 320px without layout exceptions', (
      tester,
    ) async {
      await _pumpNarrowArabic(
        tester,
        KidsGamifiedListenContent(
          state: _listenState,
          onBack: () {},
          onPlayPause: () {},
          onRecordRecitation: () {},
          onStopRecording: () {},
        ),
      );
    });

    testWidgets('completion page renders at 320px without layout exceptions', (
      tester,
    ) async {
      await _pumpNarrowArabic(
        tester,
        KidsGamifiedCompletionContent(
          starsEarned: 3,
          gemsEarned: 1,
          onNext: () {},
          onReturnToMap: () {},
        ),
      );
    });
  });
}

Future<void> _pumpNarrowArabic(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_ArabicTestApp(child: child));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

  final scrollable = find.byType(Scrollable);
  if (scrollable.evaluate().isNotEmpty) {
    await tester.drag(scrollable.first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }
}

const _progress = KidsProgress(
  totalPoints: 150,
  currentLevel: 2,
  currentStreak: 3,
  starsEarned: 7,
  ayahsCompleted: 3,
  lastSessionAt: null,
);

const _currentStage = KidsJourneyStage(
  stageNumber: 2,
  surahId: 114,
  startAyah: 3,
  endAyah: 4,
  completedAyahs: [3],
  status: KidsJourneyStageStatus.current,
);

const _journeyState = KidsJourneyLoaded(
  surahId: 114,
  surahName: 'سورة الناس',
  stages: [
    KidsJourneyStage(
      stageNumber: 1,
      surahId: 114,
      startAyah: 1,
      endAyah: 2,
      completedAyahs: [1, 2],
      status: KidsJourneyStageStatus.completed,
    ),
    _currentStage,
    KidsJourneyStage(
      stageNumber: 3,
      surahId: 114,
      startAyah: 5,
      endAyah: 6,
      completedAyahs: [],
      status: KidsJourneyStageStatus.locked,
    ),
    KidsJourneyStage(
      stageNumber: 4,
      surahId: 114,
      startAyah: 7,
      endAyah: 8,
      completedAyahs: [],
      status: KidsJourneyStageStatus.needsReview,
    ),
  ],
  progress: _progress,
);

final _listenState = KidsModeLoaded(
  surahId: 114,
  ayahNumber: 3,
  ayahText: 'مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ',
  sessionState: _testSessionState(),
  progress: _progress,
  isPlaying: false,
  currentLoop: 1,
  maxLoops: 3,
  isCompleted: false,
);

V2SessionState _testSessionState() {
  return V2SessionState.initial(
    surahId: 114,
    blockAyahs: const [
      Ayah(
        number: 6234,
        surahId: 114,
        text: 'مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ',
        numberInSurah: 3,
      ),
    ],
    blockReviewRequired: false,
  );
}

class _ArabicTestApp extends StatelessWidget {
  const _ArabicTestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ar'),
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
