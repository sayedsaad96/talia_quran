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
  static const _counts = {103: 3, 67: 30};

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
        ayahs: const [],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Answers any request with a short surah whose id is always 112.
class _WrongSurahQuranRepository implements QuranRepository {
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async =>
      const Right(
        SurahDetail(
          surah: Surah(
            id: 112,
            nameAr: 'سورة',
            nameEn: 'Surah',
            ayahCount: 4,
            juz: 30,
            type: 'meccan',
            page: 1,
          ),
          ayahs: [],
        ),
      );

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

  MemorizationKidsLocalService serviceFor(
    String owner, {
    bool journeyEnabled = false,
  }) {
    final provider = FixedRecordOwnerProvider(owner);
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

  ParentSettings settingsOf(Either<Failure, ParentSettings> either) =>
      either.fold((f) => fail('expected Right, got $f'), (v) => v);

  test('model round-trips path id and whole surahs', () {
    const model = ParentSettingsModel(
      kidsJourneyPathId: 'quran_from_nas',
      kidsWholeSurahIds: {103, 1},
    );
    final back = ParentSettingsModel.fromJson(model.toJson());
    expect(back.kidsJourneyPathId, 'quran_from_nas');
    expect(back.kidsWholeSurahIds, {103, 1});
  });

  test('model drops invalid whole surah ids', () {
    final model = ParentSettingsModel.fromJson({
      'kidsWholeSurahIds': [0, 115, 'x', 103, 103],
    });
    expect(model.kidsWholeSurahIds, {103});
  });

  test('saveParentSettings keeps path id and whole surahs', () async {
    final service = serviceFor('a');
    await service.setKidsJourneyPath(KidsJourneyPathId.quranFromNas);
    await service.setKidsSurahSplit(103, whole: true);

    // A default (stale) snapshot must not wipe the stored path or splits.
    await datasource.saveParentSettings(
      ParentSettingsModel.fromEntity(const ParentSettings(reminderHour: 7)),
    );

    final after = await datasource.getParentSettings();
    expect(after.reminderHour, 7);
    expect(after.kidsJourneyPathId, 'quran_from_nas');
    expect(after.kidsWholeSurahIds, {103});
  });

  test('saveParentSettings cannot set a path id that is not stored', () async {
    serviceFor('a');
    await datasource.saveParentSettings(
      ParentSettingsModel.fromEntity(
        const ParentSettings(kidsJourneyPathId: 'quran_from_nas'),
      ),
    );

    expect((await datasource.getParentSettings()).kidsJourneyPathId, isNull);
  });

  test('setKidsSurahSplit whole rejects a surah over 20 ayahs', () async {
    final result = await serviceFor('a').setKidsSurahSplit(67, whole: true);
    expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    expect((await datasource.getParentSettings()).kidsWholeSurahIds, isEmpty);
  });

  test('setKidsSurahSplit rejects an out-of-range surah id', () async {
    final service = serviceFor('a');
    for (final id in [0, 115]) {
      final result = await service.setKidsSurahSplit(id, whole: true);
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    }
  });

  test('setKidsSurahSplit whole on 103 then staged 3 swaps storage', () async {
    final service = serviceFor('a');
    await service.setKidsSurahSplit(103, whole: false, stageSize: 2);

    final whole = settingsOf(await service.setKidsSurahSplit(103, whole: true));
    expect(whole.kidsWholeSurahIds, {103});
    expect(whole.kidsHouseSizesBySurah.containsKey(103), isFalse);

    final staged = settingsOf(
      await service.setKidsSurahSplit(103, whole: false, stageSize: 3),
    );
    expect(staged.kidsWholeSurahIds, isEmpty);
    expect(staged.kidsHouseSizesBySurah[103], 3);
  });

  test('setKidsSurahSplit rejects stageSize 0 and 11', () async {
    final service = serviceFor('a');
    for (final size in [0, 11, null]) {
      final result = await service.setKidsSurahSplit(
        103,
        whole: false,
        stageSize: size,
      );
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    }
  });

  test('getKidsJourneyPath is the adventure while the flag is off', () async {
    final service = serviceFor('a');
    await service.setKidsJourneyPath(KidsJourneyPathId.quranFromNas);
    final path = (await service.getKidsJourneyPath()).fold(
      (f) => fail('$f'),
      (v) => v,
    );
    expect(path.id, KidsJourneyPathId.juzAmmaAdventure);
  });

  test(
    'getKidsJourneyPath returns the stored path when the flag is on',
    () async {
      final service = serviceFor('a', journeyEnabled: true);
      await service.setKidsJourneyPath(KidsJourneyPathId.quranFromNas);
      final path = (await service.getKidsJourneyPath()).fold(
        (f) => fail('$f'),
        (v) => v,
      );
      expect(path.id, KidsJourneyPathId.quranFromNas);
    },
  );

  test('setKidsJourneyPath keeps a starting surah the new path contains '
      '(R10)', () async {
    final service = serviceFor('a', journeyEnabled: true);
    await datasource.saveParentSettings(
      ParentSettingsModel.fromEntity(
        const ParentSettings(startingSurahId: 113),
      ),
    );

    final next = settingsOf(
      await service.setKidsJourneyPath(KidsJourneyPathId.quranFromFatiha),
    );

    expect(next.startingSurahId, 113);
    expect((await datasource.getParentSettings()).startingSurahId, 113);
  });

  test('setKidsJourneyPath resets a starting surah the new path lacks '
      '(R10)', () async {
    final service = serviceFor('a', journeyEnabled: true);
    await service.setKidsJourneyPath(KidsJourneyPathId.quranFromFatiha);
    await datasource.saveParentSettings(
      ParentSettingsModel.fromEntity(
        (await datasource.getParentSettings()).copyWith(startingSurahId: 2),
      ),
    );
    expect((await datasource.getParentSettings()).startingSurahId, 2);

    final next = settingsOf(
      await service.setKidsJourneyPath(KidsJourneyPathId.juzAmmaAdventure),
    );

    expect(next.startingSurahId, 1);
    expect(next.kidsJourneyPathId, 'fatiha_then_juz_amma');
    expect((await datasource.getParentSettings()).startingSurahId, 1);
  });

  test('setKidsSurahSplit fails when the loaded surah is not the requested '
      'one', () async {
    final provider = FixedRecordOwnerProvider('a');
    datasource = MemorizationPlusLocalDatasourceImpl(prefs, owner: provider);
    final service = MemorizationKidsLocalService(
      datasource,
      _WrongSurahQuranRepository(),
      _FakeStreakReader(),
      _FakeProgressEventsBus(),
      null,
      owner: provider,
    );

    final result = await service.setKidsSurahSplit(103, whole: true);

    expect(result.isLeft(), isTrue);
    expect((await datasource.getParentSettings()).kidsWholeSurahIds, isEmpty);
  });

  test('settings written for owner A are not visible to owner B', () async {
    final a = serviceFor('a', journeyEnabled: true);
    await a.setKidsJourneyPath(KidsJourneyPathId.quranFromFatiha);
    await a.setKidsSurahSplit(103, whole: true);

    final b = serviceFor('b', journeyEnabled: true);
    final bSettings = await datasource.getParentSettings();
    expect(bSettings.kidsJourneyPathId, isNull);
    expect(bSettings.kidsWholeSurahIds, isEmpty);
    final path = (await b.getKidsJourneyPath()).fold(
      (f) => fail('$f'),
      (v) => v,
    );
    expect(path.id, KidsJourneyPathId.juzAmmaAdventure);
  });
}
