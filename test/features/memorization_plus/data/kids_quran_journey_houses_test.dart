import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_kids_local_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

class _FakeQuranRepository implements QuranRepository {
  static const _counts = {1: 7, 103: 3, 67: 30, 113: 5};

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async {
    final count = _counts[surahId];
    if (count == null) return const Left(CacheFailure());
    return Right(
      SurahDetail(
        surah: Surah(
          id: surahId,
          nameAr: 'سورة',
          nameEn: 'Surah',
          ayahCount: count,
          juz: 1,
          type: 'meccan',
          page: 1,
        ),
        ayahs: [
          for (var n = 1; n <= count; n++)
            Ayah(number: n, surahId: surahId, text: 'x', numberInSurah: n),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStreakReader implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}

class _FakeProgressEventsBus implements ProgressEventsBus {
  @override
  void notify(ProgressChangedReason reason) {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences prefs;
  late MemorizationPlusLocalDatasourceImpl datasource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  MemorizationKidsLocalService serviceFor({bool journeyEnabled = true}) {
    const provider = FixedRecordOwnerProvider('a');
    datasource = MemorizationPlusLocalDatasourceImpl(prefs, owner: provider);
    return MemorizationKidsLocalService(
      datasource,
      _FakeQuranRepository(),
      _FakeStreakReader(),
      _FakeProgressEventsBus(),
      null,
      owner: provider,
      quranJourneyEnabled: () => journeyEnabled,
    );
  }

  Future<List<KidsJourneyStage>> journey(
    MemorizationKidsLocalService service,
    int surahId,
  ) async => (await service.getKidsJourney(
    surahId: surahId,
  )).fold((f) => fail('expected Right, got $f'), (v) => v);

  Future<void> seedRewards(int surahId, Iterable<int> ayahs) =>
      datasource.saveKidsSessionLogs([
        for (final ayah in ayahs)
          KidsSessionLogModel(
            id: 'reward_${surahId}_$ayah',
            surahId: surahId,
            ayahNumber: ayah,
            repeatsCompleted: 3,
            pointsEarned: 10,
            completedAt: DateTime.now().subtract(const Duration(days: 30)),
          ),
      ]);

  test('whole surah 103 is one stage of 3 ayahs', () async {
    final service = serviceFor();
    await service.setKidsAyahsPerHouse(2);
    await service.setKidsSurahSplit(103, whole: true);

    final stages = await journey(service, 103);
    expect(stages.length, 1);
    expect(stages.single.startAyah, 1);
    expect(stages.single.endAyah, 3);
  });

  test('whole is ignored for a 30-ayah surah stored as whole', () async {
    final service = serviceFor();
    await datasource.updateKidsHouseSettings(
      (current) => current.copyWith(kidsWholeSurahIds: {67}),
    );

    final stages = await journey(service, 67);
    final defaultSize = KidsSessionPolicy.forChildAge(null).journeyStageSize;
    expect(stages.length, greaterThan(1));
    expect(stages.first.endAyah - stages.first.startAyah + 1, defaultSize);
  });

  test('whole wins over a stray house size key for the same surah', () async {
    final service = serviceFor();
    await datasource.updateKidsHouseSettings(
      (current) => current.copyWith(
        kidsWholeSurahIds: {103},
        kidsHouseSizesBySurah: {103: 1},
      ),
    );

    final stages = await journey(service, 103);
    expect(stages.length, 1);
    expect(stages.single.endAyah, 3);
  });

  test('re-splitting a started surah keeps completed ayahs', () async {
    final service = serviceFor();
    await service.setKidsSurahSplit(67, whole: false, stageSize: 5);
    await seedRewards(67, [1, 2, 3, 4, 5]);

    await service.setKidsSurahSplit(67, whole: false, stageSize: 3);
    final stages = await journey(service, 67);

    expect(stages[0].startAyah, 1);
    expect(stages[0].endAyah, 3);
    expect(stages[1].startAyah, 4);
    expect(stages[1].endAyah, 6);
    final completed = {for (final s in stages) ...s.completedAyahs};
    expect(completed, {1, 2, 3, 4, 5});
    expect(stages[0].status, KidsJourneyStageStatus.needsReview);
    expect(stages[1].status, KidsJourneyStageStatus.locked);
  });

  test('quran journey never locks a later surah', () async {
    final service = serviceFor();
    await service.setKidsJourneyPath(KidsJourneyPathId.quranFromNas);

    final stages = await journey(service, 113);
    expect(stages.first.status, KidsJourneyStageStatus.current);
  });

  test('adventure still locks a later surah (unchanged)', () async {
    final service = serviceFor();
    await service.setKidsJourneyPath(KidsJourneyPathId.juzAmmaAdventure);

    final stages = await journey(service, 113);
    expect(stages.first.status, KidsJourneyStageStatus.locked);
  });
}
