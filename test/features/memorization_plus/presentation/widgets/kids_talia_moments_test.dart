import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_talia_companion.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_talia_moments.dart';

const _someProgress = KidsProgress(
  totalPoints: 10,
  currentLevel: 1,
  currentStreak: 1,
  starsEarned: 1,
  ayahsCompleted: 3,
  lastSessionAt: null,
);

const _stage = KidsJourneyStage(
  stageNumber: 1,
  surahId: 114,
  startAyah: 1,
  endAyah: 2,
  completedAyahs: [],
  status: KidsJourneyStageStatus.current,
);

const _mission = KidsNextMission(
  type: KidsMissionType.newMemorization,
  surahId: 114,
  ayahNumbers: [1],
);

KidsJourneyLoaded _state({
  KidsProgress progress = _someProgress,
  KidsJourneyStage? currentStage,
  KidsNextMission? nextMission,
  int? dailyGoalCap,
  bool returning = false,
}) => KidsJourneyLoaded(
  surahId: 114,
  stages: [?currentStage],
  progress: progress,
  nextMission: nextMission,
  dailyGoalCap: dailyGoalCap,
  isReturningAfterBreak: returning,
);

void main() {
  group('kidsHomeTaliaMoment', () {
    test('daily cap wins over everything', () {
      expect(
        kidsHomeTaliaMoment(_state(dailyGoalCap: 1, returning: true)),
        KidsTaliaMoment.farewell,
      );
    });

    test('no stage, no mission, real progress is journeyDone', () {
      expect(kidsHomeTaliaMoment(_state()), KidsTaliaMoment.journeyDone);
    });

    test('a child with no progress yet is not journeyDone', () {
      expect(
        kidsHomeTaliaMoment(_state(progress: const KidsProgress.initial())),
        KidsTaliaMoment.guide,
      );
    });

    test('returning after a break waves hello', () {
      expect(
        kidsHomeTaliaMoment(
          _state(currentStage: _stage, nextMission: _mission, returning: true),
        ),
        KidsTaliaMoment.welcomeBack,
      );
    });

    test('journeyDone wins over welcomeBack', () {
      expect(
        kidsHomeTaliaMoment(_state(returning: true)),
        KidsTaliaMoment.journeyDone,
      );
    });

    test('otherwise guide', () {
      expect(
        kidsHomeTaliaMoment(
          _state(currentStage: _stage, nextMission: _mission),
        ),
        KidsTaliaMoment.guide,
      );
    });
  });

  test('every moment maps to its pose', () {
    expect(
      kidsTaliaPoseForMoment(KidsTaliaMoment.guide),
      KidsTaliaPose.pointRight,
    );
    expect(
      kidsTaliaPoseForMoment(KidsTaliaMoment.welcomeBack),
      KidsTaliaPose.wave,
    );
    expect(
      kidsTaliaPoseForMoment(KidsTaliaMoment.farewell),
      KidsTaliaPose.wave,
    );
    expect(
      kidsTaliaPoseForMoment(KidsTaliaMoment.journeyDone),
      KidsTaliaPose.celebrate,
    );
    expect(
      kidsTaliaPoseForMoment(KidsTaliaMoment.mapGuide),
      KidsTaliaPose.pointRight,
    );
    expect(
      kidsTaliaPoseForMoment(KidsTaliaMoment.stageReady),
      KidsTaliaPose.idle,
    );
    expect(
      kidsTaliaPoseForMoment(KidsTaliaMoment.celebrate),
      KidsTaliaPose.celebrate,
    );
  });

  testWidgets('every moment has its Arabic bubble', (tester) async {
    final lines = <KidsTaliaMoment, String>{};
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            for (final m in KidsTaliaMoment.values) {
              lines[m] = kidsTaliaMomentBubble(context, m);
            }
            return const SizedBox();
          },
        ),
      ),
    );
    expect(lines[KidsTaliaMoment.guide], 'مهمتك جاهزة، هيا نبدأ!');
    expect(lines[KidsTaliaMoment.welcomeBack], 'اشتقت إليك!');
    expect(lines[KidsTaliaMoment.farewell], 'أحسنت اليوم! نلتقي غدًا');
    expect(lines[KidsTaliaMoment.journeyDone], 'أتممت رحلتك كلها!');
    expect(lines[KidsTaliaMoment.mapGuide], 'هيا نكمل المغامرة!');
    expect(lines[KidsTaliaMoment.stageReady], 'هل أنت مستعد؟');
    expect(lines[KidsTaliaMoment.celebrate], 'أحسنت! بارك الله فيك');
  });
}
