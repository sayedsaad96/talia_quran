/// Renders the kids screens in the day and night world with the real Arabic
/// fonts so the PNGs can be reviewed as design references. The phase is forced
/// through a [KidsWorldPhaseController] whose clock yields the wanted phase.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_adventure_regions.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_daily_missions.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_treasures_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_talia_companion.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_phase_controller.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(rootBundle.load(path));
  }
  await loader.load();
}

const _stages = [
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
];

const _progress = KidsProgress(
  totalPoints: 150,
  currentLevel: 2,
  currentStreak: 3,
  starsEarned: 7,
  ayahsCompleted: 3,
  lastSessionAt: null,
);

const _journey = KidsJourneyLoaded(
  surahId: 114,
  stages: _stages,
  progress: _progress,
);

const _learning = KidsNextMission(
  type: KidsMissionType.newMemorization,
  surahId: 114,
  ayahNumbers: [3],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String ayahText;

  setUpAll(() async {
    await _loadFont('Amiri', [
      'assets/fonts/Amiri/Amiri-Regular.ttf',
      'assets/fonts/Amiri/Amiri-Bold.ttf',
    ]);
    await _loadFont('Noto_Sans', [
      'assets/fonts/Noto_Sans/NotoSans-Regular.ttf',
      'assets/fonts/Noto_Sans/NotoSans-Bold.ttf',
    ]);
    await _loadFont('Noto_Naskh_Arabic', [
      'assets/fonts/Noto_Naskh_Arabic/NotoNaskhArabic-Regular.ttf',
      'assets/fonts/Noto_Naskh_Arabic/NotoNaskhArabic-Bold.ttf',
    ]);
    // Talia icon system (the app's only icon fonts).
    await _loadFont('TaliaIcons', ['assets/fonts/TaliaIcons/TaliaIcons.ttf']);
    await _loadFont('TaliaIconsKids', [
      'assets/fonts/TaliaIcons/TaliaIconsKids.ttf',
    ]);
    try {
      await _loadFont('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']);
    } catch (_) {
      // Icon font is unavailable in some SDK layouts; previews still render.
    }
    // Verbatim canonical text of 114:3 - never typed by hand.
    final json =
        jsonDecode(File('assets/data/quran.json').readAsStringSync())
            as Map<String, dynamic>;
    ayahText = (json['114'] as List)[2]['text'] as String;
  });

  tearDown(() async {
    if (getIt.isRegistered<KidsWorldPhaseController>()) {
      await getIt.unregister<KidsWorldPhaseController>();
    }
  });

  Widget app(Widget child) => MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        // Text without an explicit family would fall back to the test font.
        fontFamily: 'Noto_Sans',
        fontFamilyFallback: const ['Noto_Naskh_Arabic'],
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  KidsModeLoaded sessionState() => KidsModeLoaded(
    surahId: 114,
    ayahNumber: 3,
    ayahText: ayahText,
    sessionState: V2SessionState.initial(
      surahId: 114,
      blockAyahs: [
        Ayah(number: 6234, surahId: 114, text: ayahText, numberInSurah: 3),
      ],
      blockReviewRequired: false,
    ),
    progress: _progress,
    isPlaying: false,
    currentLoop: 1,
    maxLoops: 3,
    isCompleted: false,
  );

  final screens = <String, Widget Function()>{
    'home': () => KidsGamifiedHomeContent(
      state: _journey,
      childName: 'سارة',
      onMushafTap: () {},
      onJourneyTap: () {},
      onMissionTap: () {},
    ),
    'home_missions': () => KidsGamifiedHomeContent(
      state: _journey.copyWith(
        nextMission: _learning,
        dailyMissions: const [
          KidsDailyMission(
            id: '2026-10-02:learning',
            kind: KidsDailyMissionKind.learning,
            status: KidsDailyMissionStatus.available,
            learning: _learning,
          ),
          KidsDailyMission(
            id: '2026-10-02:reading',
            kind: KidsDailyMissionKind.reading,
            status: KidsDailyMissionStatus.available,
          ),
        ],
      ),
      childName: 'سارة',
      onMushafTap: () {},
      onJourneyTap: () {},
      onMissionTap: () {},
      onReadingMissionTap: () {},
      onTreasuresTap: () {},
    ),
    'treasures': () => KidsTreasuresContent(
      regions: kidsRegionProgress({114, 113, 112, 111, 110, 109, 108}),
      certificates: [
        CertificateAward(
          id: 'c1',
          titleAr: 'شهادة حفظ سورة الناس',
          type: CertificateType.surah,
          earnedAt: DateTime(2026, 10, 1),
          surahId: 114,
          surahNameAr: 'الناس',
          surahNameEn: 'An-Nas',
        ),
      ],
      onBack: () {},
    ),
    'journey': () => KidsGamifiedJourneyContent(
      state: _journey,
      onBack: () {},
      onStageSelected: (_) {},
    ),
    'stage': () => KidsGamifiedStageContent(
      stage: _stages[1],
      surahName: 'الناس',
      onBack: () {},
      onStartMission: () {},
    ),
    'session': () => KidsGamifiedListenContent(
      state: sessionState(),
      onBack: () {},
      onPlayPause: () {},
      onRecordRecitation: () {},
      onStopRecording: () {},
      onTryFromMemory: () {},
    ),
    'completion': () => KidsGamifiedCompletionContent(
      starsEarned: 3,
      pointsEarned: 15,
      onNext: () {},
      onReturnToMap: () {},
    ),
  };

  for (final phase in ['day', 'night']) {
    for (final entry in screens.entries) {
      testWidgets('capture kids ${entry.key} $phase', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 1100));
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetDevicePixelRatio();
          return tester.binding.setSurfaceSize(null);
        });

        final hour = phase == 'day' ? 12 : 21;
        final controller = KidsWorldPhaseController(
          prayerTimes: () async => null,
          clock: () => DateTime(2026, 10, 2, hour),
        );
        getIt.registerSingleton<KidsWorldPhaseController>(controller);

        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: app(entry.value()),
          ),
        );
        await tester.runAsync(() => controller.refresh());
        await tester.pump();
        await tester.runAsync(() async {
          final context = tester.element(find.byType(Scaffold).first);
          for (final pose in KidsTaliaPose.values) {
            try {
              await precacheImage(AssetImage(pose.asset), context);
            } catch (_) {
              // A missing pose only affects the preview, not the assertion.
            }
          }
        });
        // Let the screens' own bundled images (houses, reward) finish decoding.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump(const Duration(milliseconds: 100));

        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile('preview/kids_${entry.key}_$phase.png'),
        );

        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        await getIt.unregister<KidsWorldPhaseController>();
      });
    }
  }
}
