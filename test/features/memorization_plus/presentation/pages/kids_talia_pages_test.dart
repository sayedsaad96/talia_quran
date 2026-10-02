import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_talia_companion.dart';
import 'package:talia_quran/features/quran/presentation/pages/kids_quran_reader_page.dart';

const _stage = KidsJourneyStage(
  stageNumber: 1,
  surahId: 114,
  startAyah: 1,
  endAyah: 2,
  completedAyahs: [],
  status: KidsJourneyStageStatus.current,
);

const _state = KidsJourneyLoaded(
  surahId: 114,
  surahName: 'سورة الناس',
  stages: [_stage],
  progress: KidsProgress(
    totalPoints: 10,
    currentLevel: 1,
    currentStreak: 1,
    starsEarned: 1,
    ayahsCompleted: 1,
    lastSessionAt: null,
  ),
  nextMission: KidsNextMission(
    type: KidsMissionType.newMemorization,
    surahId: 114,
    ayahNumbers: [1],
  ),
);

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: c!,
  ),
  home: child,
);

Widget _home() => KidsGamifiedHomeContent(
  state: _state,
  childName: 'يوسف',
  onMushafTap: () {},
  onJourneyTap: () {},
  onMissionTap: () {},
);

Widget _journey() => KidsGamifiedJourneyContent(
  state: _state,
  onBack: () {},
  onStageSelected: (_) {},
);

Widget _stagePage() => KidsGamifiedStageContent(
  stage: _stage,
  surahName: 'سورة الناس',
  onBack: () {},
  onStartMission: () {},
);

Widget _completion() => KidsGamifiedCompletionContent(
  starsEarned: 3,
  onNext: () {},
  onReturnToMap: () {},
);

void main() {
  testWidgets('home shows Talia with the guide bubble', (tester) async {
    await tester.pumpWidget(_app(_home()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(KidsTaliaCompanion), findsOneWidget);
    expect(find.text('مهمتك جاهزة، هيا نبدأ!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('journey shows Talia with the map bubble', (tester) async {
    await tester.pumpWidget(_app(_journey()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('هيا نكمل المغامرة!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('stage shows Talia with the ready bubble', (tester) async {
    await tester.pumpWidget(_app(_stagePage()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('هل أنت مستعد؟'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('completion shows Talia celebrating', (tester) async {
    await tester.pumpWidget(_app(_completion()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(KidsTaliaCompanion), findsOneWidget);
    expect(find.text('أحسنت! بارك الله فيك'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reader shows a static reading avatar, no companion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        KidsQuranReaderContent(
          pageNumber: 604,
          onBack: () {},
          reader: const SizedBox(),
        ),
      ),
    );
    expect(find.byType(KidsTaliaCompanion), findsNothing);
    final avatar = tester.widget<Image>(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName.endsWith(
              'talia_reading_quran.png',
            ),
      ),
    );
    expect(avatar.height, 40);
  });

  final screens = <String, Widget Function()>{
    'home': _home,
    'journey': _journey,
    'stage': _stagePage,
    'completion': _completion,
  };
  for (final entry in screens.entries) {
    testWidgets('${entry.key} fits 320x640 at 1.3 text scale', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.reset();
      });
      await tester.pumpWidget(_app(entry.value(), scale: 1.3));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  }
}
