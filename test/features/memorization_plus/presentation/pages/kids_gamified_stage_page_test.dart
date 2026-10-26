import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart';

import 'package:flutter_animate/flutter_animate.dart';

void main() {
  setUpAll(() {
    Animate.defaultDuration = Duration.zero;
  });

  group('KidsGamifiedStagePage', () {
    testWidgets(
      'mandatory review shows remaining ayahs and routes the first pending recitation in RTL',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 740);
        addTearDown(tester.view.reset);
        const stage = KidsJourneyStage(
          stageNumber: 1,
          surahId: 114,
          startAyah: 1,
          endAyah: 3,
          completedAyahs: [1, 2, 3],
          status: KidsJourneyStageStatus.needsReview,
          requiresHouseReview: true,
          pendingHouseReviewAyahs: [2, 3],
        );
        var started = false;
        await tester.pumpWidget(
          _TestApp(
            locale: const Locale('ar'),
            child: KidsGamifiedStageContent(
              stage: stage,
              surahName: 'الناس',
              onBack: () {},
              onStartMission: () => started = true,
            ),
          ),
        );
        final action = find.text('ابدأ تسميع آيات البيت');
        expect(find.text('متبقي للتسميع: ٢ آية'), findsOneWidget);
        await tester.ensureVisible(action);
        await tester.pump();
        await tester.tap(action);
        expect(started, isTrue);
        expect(
          kidsNextMissionLocation(stage),
          '${AppRoutes.memorizationPlusKids}?surahId=114&ayahNumber=2&missionType=linkedReview',
        );
        expect(tester.takeException(), isNull);
      },
    );

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

      await tester.tap(find.byTooltip('Back'));
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
    testWidgets('without a surah name the header shows the Arabic name, not '
        'a raw number', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);
      final getIt = GetIt.instance;
      getIt.registerSingleton<MemorizationPlusRepository>(_NoJourneyRepo());
      addTearDown(() => getIt.unregister<MemorizationPlusRepository>());

      const fatihaStage = KidsJourneyStage(
        stageNumber: 1,
        surahId: 1,
        startAyah: 1,
        endAyah: 3,
        completedAyahs: [],
        status: KidsJourneyStageStatus.current,
      );
      await tester.pumpWidget(
        const _TestApp(
          locale: Locale('ar'),
          child: KidsGamifiedStagePage(stage: fatihaStage),
        ),
      );
      await tester.pump();

      final header = find.textContaining('الفاتحة');
      expect(header, findsOneWidget);
      final text = tester.widget<Text>(header).data!;
      expect(text.contains('1'), isFalse);
      expect(text.contains('٣'), isTrue);
    });

    test('stage mission route carries the resolved mission type', () {
      // The current stage asks to resume: the session restores a paused run
      // or resolves the ayah's real semantics (N1).
      expect(
        kidsNextMissionLocation(_stage),
        '${AppRoutes.memorizationPlusKids}'
        '?surahId=114&ayahNumber=4&missionType=resume',
      );

      // A fresh current stage uses the same resume-or-resolve contract, so a
      // paused session on its first ayah is never overwritten.
      const freshStage = KidsJourneyStage(
        stageNumber: 1,
        surahId: 114,
        startAyah: 1,
        endAyah: 2,
        completedAyahs: [],
        status: KidsJourneyStageStatus.current,
      );
      expect(
        kidsNextMissionLocation(freshStage),
        '${AppRoutes.memorizationPlusKids}'
        '?surahId=114&ayahNumber=1&missionType=resume',
      );

      // Finished stages open a linked review from their first ayah.
      for (final status in [
        KidsJourneyStageStatus.completed,
        KidsJourneyStageStatus.needsReview,
      ]) {
        final finished = KidsJourneyStage(
          stageNumber: 1,
          surahId: 114,
          startAyah: 1,
          endAyah: 2,
          completedAyahs: const [1, 2],
          status: status,
        );
        expect(
          kidsNextMissionLocation(finished),
          '${AppRoutes.memorizationPlusKids}'
          '?surahId=114&ayahNumber=1&missionType=linkedReview',
        );
      }
    });

    test('a house that needs review opens its due ayah (K30)', () {
      // The data layer names the most overdue ayah; the page only routes.
      const needsReview = KidsJourneyStage(
        stageNumber: 1,
        surahId: 114,
        startAyah: 1,
        endAyah: 3,
        completedAyahs: [1, 2, 3],
        status: KidsJourneyStageStatus.needsReview,
        reviewAyah: 2,
      );

      expect(
        kidsNextMissionLocation(needsReview),
        '${AppRoutes.memorizationPlusKids}'
        '?surahId=114&ayahNumber=2&missionType=linkedReview',
      );
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

/// The stage page asks the repository for the authoritative stage; a failure
/// keeps the stage it was opened with.
class _NoJourneyRepo implements MemorizationPlusRepository {
  @override
  Future<Either<Failure, List<KidsJourneyStage>>> getKidsJourney({
    bool freezeForSession = false,
    required int surahId,
  }) async => const Left(CacheFailure('offline'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
