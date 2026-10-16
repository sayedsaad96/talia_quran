import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

import 'kids_journey_cubit_test.mocks.dart';

void main() {
  late MockGetKidsJourneyUsecase getJourney;
  late MockGetKidsProgressUsecase getProgress;
  late MockQuranRepository quran;
  late List<KidsJourneyStage> stages;
  late ParentSettings settings;
  late List<KidsSessionLog> logs;
  late List<({int surahId, bool whole, int? stageSize})> saved;
  late KidsJourneyCubit cubit;
  var splitResult = true;

  const surah = Surah(
    id: 103,
    nameAr: 'العصر',
    nameEn: 'Al-Asr',
    ayahCount: 3,
    juz: 30,
    type: 'meccan',
    page: 601,
  );

  List<KidsJourneyStage> stagesOf(int size, int total) => [
    for (var start = 1, n = 1; start <= total; start += size, n++)
      KidsJourneyStage(
        stageNumber: n,
        surahId: 103,
        startAyah: start,
        endAyah: (start + size - 1).clamp(1, total),
        completedAyahs: const [],
        status: n == 1
            ? KidsJourneyStageStatus.current
            : KidsJourneyStageStatus.locked,
      ),
  ];

  KidsJourneyCubit build({
    KidsJourneyPathDefinition path = KidsJourneyPathDefinition.adventure,
    bool withSettings = true,
  }) => KidsJourneyCubit(
    getJourney,
    getProgress,
    quran,
    sessionLogsLoader: () async => logs,
    pathLoader: () async => path,
    policyLoader: () async => KidsSessionPolicy.forAge(8),
    settingsLoader: withSettings ? () async => settings : null,
    splitSaver: (surahId, {required whole, stageSize}) async {
      saved.add((surahId: surahId, whole: whole, stageSize: stageSize));
      if (!splitResult) {
        return const Left(ValidationFailure());
      }
      if (whole) {
        stages = [
          const KidsJourneyStage(
            stageNumber: 1,
            surahId: 103,
            startAyah: 1,
            endAyah: 3,
            completedAyahs: [],
            status: KidsJourneyStageStatus.current,
          ),
        ];
        settings = settings.copyWith(kidsWholeSurahIds: {surahId});
      }
      return Right(settings);
    },
  );

  setUp(() {
    getJourney = MockGetKidsJourneyUsecase();
    getProgress = MockGetKidsProgressUsecase();
    quran = MockQuranRepository();
    stages = stagesOf(1, 3);
    settings = const ParentSettings();
    logs = [];
    saved = [];
    splitResult = true;
    when(getJourney(any)).thenAnswer((_) async => Right(stages));
    when(
      getProgress(),
    ).thenAnswer((_) async => const Right(KidsProgress.initial()));
    when(quran.getSurahDetail(103)).thenAnswer(
      (_) async => const Right(SurahDetail(surah: surah, ayahs: [])),
    );
    when(quran.getSurahs()).thenAnswer((_) async => const Right([surah]));
  });

  tearDown(() => cubit.close());

  KidsJourneyLoaded loaded() => cubit.state as KidsJourneyLoaded;

  test('Quran journey with nothing chosen needs a split choice', () async {
    cubit = build(
      path: KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas),
    );
    await cubit.load(surahId: 103);
    expect(loaded().isQuranJourney, isTrue);
    expect(loaded().needsSplitChoice, isTrue);
    expect(loaded().surahAyahCount, 3);
    expect(
      loaded().defaultStageSize,
      KidsSessionPolicy.forAge(8).journeyStageSize,
    );
  });

  test('guardian default size wins over the age default', () async {
    settings = const ParentSettings(kidsAyahsPerHouse: 6);
    cubit = build(
      path: KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas),
    );
    await cubit.load(surahId: 103);
    expect(loaded().defaultStageSize, 6);
  });

  test('adventure path never asks', () async {
    cubit = build();
    await cubit.load(surahId: 103);
    expect(loaded().isQuranJourney, isFalse);
    expect(loaded().needsSplitChoice, isFalse);
  });

  test('no settings loader means no prompt', () async {
    cubit = build(
      path: KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas),
      withSettings: false,
    );
    await cubit.load(surahId: 103);
    expect(loaded().needsSplitChoice, isFalse);
  });

  test('already whole, frozen, or rewarded surah does not ask', () async {
    final path = KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas);
    settings = const ParentSettings(kidsWholeSurahIds: {103});
    cubit = build(path: path);
    await cubit.load(surahId: 103);
    expect(loaded().needsSplitChoice, isFalse);
    await cubit.close();

    settings = const ParentSettings(kidsHouseSizesBySurah: {103: 2});
    cubit = build(path: path);
    await cubit.load(surahId: 103);
    expect(loaded().needsSplitChoice, isFalse);
    await cubit.close();

    settings = const ParentSettings();
    logs = [
      KidsSessionLog(
        id: 'l1',
        surahId: 103,
        ayahNumber: 1,
        repeatsCompleted: 3,
        pointsEarned: 10,
        completedAt: DateTime.utc(2026, 1, 1),
        missionType: KidsMissionType.newMemorization,
      ),
    ];
    cubit = build(path: path);
    await cubit.load(surahId: 103);
    expect(loaded().needsSplitChoice, isFalse);
  });

  test('chooseSplit reloads with one stage for whole 103', () async {
    cubit = build(
      path: KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas),
    );
    await cubit.load(surahId: 103);
    expect(loaded().stages.length, 3);

    final ok = await cubit.chooseSplit(surahId: 103, whole: true);

    expect(ok, isTrue);
    expect(saved.single.whole, isTrue);
    expect(loaded().stages.length, 1);
    expect(loaded().needsSplitChoice, isFalse);
  });

  test('exposes the surah current choice for the change menu', () async {
    final path = KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas);
    settings = const ParentSettings(kidsWholeSurahIds: {103});
    cubit = build(path: path);
    await cubit.load(surahId: 103);
    expect(loaded().currentSplitWhole, isTrue);
    await cubit.close();

    settings = const ParentSettings(kidsHouseSizesBySurah: {103: 2});
    cubit = build(path: path);
    await cubit.load(surahId: 103);
    expect(loaded().currentSplitWhole, isFalse);
    expect(loaded().currentStageSize, 2);
    await cubit.close();

    settings = const ParentSettings();
    cubit = build(path: path);
    await cubit.load(surahId: 103);
    expect(loaded().currentStageSize, loaded().defaultStageSize);
  });

  test('the home mission asks the split question first (spec 4.4)', () async {
    cubit = build(
      path: KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas),
    );
    await cubit.load(surahId: 103);
    expect(loaded().nextMission?.type, KidsMissionType.newMemorization);
    expect(loaded().nextMissionNeedsSplitChoice, isTrue);
    await cubit.close();

    cubit = build();
    await cubit.load(surahId: 103);
    expect(loaded().nextMissionNeedsSplitChoice, isFalse);
  });

  group('next mission follows the path (F7)', () {
    KidsJourneyStage stage(int surahId, {required bool done}) =>
        KidsJourneyStage(
          stageNumber: 1,
          surahId: surahId,
          startAyah: 1,
          endAyah: 3,
          completedAyahs: done ? const [1, 2, 3] : const [],
          status: done
              ? KidsJourneyStageStatus.completed
              : KidsJourneyStageStatus.current,
        );

    setUp(() {
      when(getJourney(any)).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as GetKidsJourneyParams;
        return Right([stage(params.surahId, done: params.surahId == 67)]);
      });
      when(quran.getSurahDetail(any)).thenAnswer(
        (_) async => const Right(SurahDetail(surah: surah, ayahs: [])),
      );
    });

    test('Quran journey from An-Nas moves from a finished 67 to 66', () async {
      cubit = build(
        path: KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas),
      );
      await cubit.load(surahId: 67);
      expect(loaded().nextMission?.surahId, 66);
    });

    test('a throwing path loader behaves exactly like the adventure', () async {
      cubit = build();
      await cubit.load(surahId: 67);
      final adventureMission = loaded().nextMission;
      await cubit.close();

      cubit = KidsJourneyCubit(
        getJourney,
        getProgress,
        quran,
        sessionLogsLoader: () async => logs,
        pathLoader: () async => throw StateError('prefs'),
        policyLoader: () async => KidsSessionPolicy.forAge(8),
        settingsLoader: () async => settings,
      );
      await cubit.load(surahId: 67);
      expect(loaded().isQuranJourney, isFalse);
      expect(loaded().nextMission, adventureMission);
      expect(loaded().nextMission?.surahId, isNot(66));
    });
  });

  test('chooseSplit returns false and keeps state when saving fails', () async {
    cubit = build(
      path: KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas),
    );
    await cubit.load(surahId: 103);
    splitResult = false;

    final ok = await cubit.chooseSplit(
      surahId: 103,
      whole: false,
      stageSize: 2,
    );

    expect(ok, isFalse);
    expect(loaded().needsSplitChoice, isTrue);
  });
}
