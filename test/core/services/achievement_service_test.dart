import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/features/hifz/data/datasources/hifz_local_datasource.dart';
import 'package:talia_quran/features/hifz/data/models/ayah_progress_model.dart';
import 'package:talia_quran/features/hifz/domain/entities/hifz_entities.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/quran/data/datasources/quran_local_datasource.dart';
import 'package:talia_quran/features/quran/data/models/ayah_model.dart';
import 'package:talia_quran/features/quran/data/models/surah_model.dart';

void main() {
  group('AchievementService', () {
    test('does not award a surah or juz certificate before 100%', () async {
      final service = await _buildService(
        surahs: [_surah(1, ayahCount: 3)],
        ayahsByJuz: {
          1: [_ayah(1, 1, juz: 1), _ayah(1, 2, juz: 1), _ayah(1, 3, juz: 1)],
        },
        hifzProgress: [_memorizedProgress(1, 1), _memorizedProgress(1, 2)],
      );

      final awards = await service.checkAndUnlockCertificates();

      expect(awards, isEmpty);
    });

    test('awards a surah certificate for any fully memorized surah', () async {
      final service = await _buildService(
        surahs: [_surah(1, ayahCount: 2), _surah(2, ayahCount: 1)],
        ayahsByJuz: {
          1: [_ayah(1, 1, juz: 1), _ayah(1, 2, juz: 1), _ayah(2, 1, juz: 1)],
        },
        hifzProgress: [_memorizedProgress(1, 1), _memorizedProgress(1, 2)],
      );

      final awards = await service.checkAndUnlockCertificates();
      final ids = awards.map((award) => award.id).toSet();

      expect(ids, contains('cert_surah_1'));
      expect(ids, isNot(contains('cert_juz_1')));
    });

    test(
      'awards a juz certificate only when all juz ayahs are memorized',
      () async {
        final service = await _buildService(
          surahs: [_surah(1, ayahCount: 2), _surah(2, ayahCount: 1)],
          ayahsByJuz: {
            1: [_ayah(1, 1, juz: 1), _ayah(1, 2, juz: 1), _ayah(2, 1, juz: 1)],
          },
          hifzProgress: [
            _memorizedProgress(1, 1),
            _memorizedProgress(1, 2),
            _memorizedProgress(2, 1),
          ],
        );

        final awards = await service.checkAndUnlockCertificates();

        expect(awards.map((award) => award.id), contains('cert_juz_1'));
      },
    );

    test('counts MemorizationPlus strength 6 records as memorized', () async {
      final service = await _buildService(
        surahs: [_surah(1, ayahCount: 2), _surah(2, ayahCount: 1)],
        ayahsByJuz: {
          1: [_ayah(1, 1, juz: 1), _ayah(1, 2, juz: 1), _ayah(2, 1, juz: 1)],
        },
        smartRecords: [_smartMemorized(1, 1), _smartMemorized(1, 2)],
      );

      final awards = await service.checkAndUnlockCertificates();

      expect(awards.map((award) => award.id), contains('cert_surah_1'));
    });

    test(
      'returns multiple new certificates once and does not duplicate them',
      () async {
        final service = await _buildService(
          surahs: [_surah(1, ayahCount: 1)],
          ayahsByJuz: {
            1: [_ayah(1, 1, juz: 1)],
          },
          hifzProgress: [_memorizedProgress(1, 1)],
        );

        final firstAwards = await service.checkAndUnlockCertificates();
        final secondAwards = await service.checkAndUnlockCertificates();
        final firstIds = firstAwards.map((award) => award.id).toSet();

        expect(firstIds, containsAll(['cert_surah_1', 'cert_juz_1']));
        expect(secondAwards, isEmpty);
      },
    );
  });
}

Future<AchievementService> _buildService({
  required List<SurahModel> surahs,
  required Map<int, List<AyahModel>> ayahsByJuz,
  List<AyahProgressModel> hifzProgress = const [],
  List<AyahReviewRecordModel> smartRecords = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return AchievementService(
    prefs,
    _FakeHifzDatasource(hifzProgress),
    _FakeMemPlusDatasource(smartRecords),
    _FakeQuranDatasource(surahs: surahs, ayahsByJuz: ayahsByJuz),
  );
}

SurahModel _surah(int id, {required int ayahCount}) => SurahModel(
  id: id,
  nameAr: 'سورة $id',
  nameEn: 'Surah $id',
  ayahCount: ayahCount,
  juz: 1,
  type: 'meccan',
  page: 1,
);

AyahModel _ayah(int surahId, int numberInSurah, {required int juz}) =>
    AyahModel(
      number: (surahId * 1000) + numberInSurah,
      surahId: surahId,
      text: 'آية $numberInSurah',
      numberInSurah: numberInSurah,
      juz: juz,
      page: 1,
    );

AyahProgressModel _memorizedProgress(int surahId, int ayahNumber) {
  final now = DateTime(2026, 5, 7);
  return AyahProgressModel(
    surahId: surahId,
    ayahNumber: ayahNumber,
    status: AyahStatus.memorized,
    repetitions: 5,
    nextReviewDate: now,
    lastReviewDate: now,
  );
}

AyahReviewRecordModel _smartMemorized(int surahId, int ayahNumber) {
  final now = DateTime(2026, 5, 7);
  return AyahReviewRecordModel(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: 6,
    intervalDays: 30,
    lastReviewedAt: now,
    nextReviewDate: now.add(const Duration(days: 30)),
    totalReviews: 6,
    lastRating: PerformanceRating.excellent,
  );
}

class _FakeHifzDatasource implements HifzLocalDatasource {
  _FakeHifzDatasource(this.progress);

  final List<AyahProgressModel> progress;

  @override
  Future<List<AyahProgressModel>> getAllProgress() async => progress;

  @override
  Future<AyahProgressModel?> getAyahProgress(
    int surahId,
    int ayahNumber,
  ) async {
    for (final item in progress) {
      if (item.surahId == surahId && item.ayahNumber == ayahNumber) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<List<AyahProgressModel>> getProgressForSurah(int surahId) async =>
      progress.where((item) => item.surahId == surahId).toList();

  @override
  String? getHifzPath() => null;

  @override
  Future<void> saveAyahProgress(AyahProgressModel progress) async {}

  @override
  Future<void> saveHifzPath(String path) async {}
}

class _FakeMemPlusDatasource implements MemorizationPlusLocalDatasource {
  _FakeMemPlusDatasource(this.records);

  final List<AyahReviewRecordModel> records;

  @override
  Future<List<AyahReviewRecordModel>> getAllReviewRecords() async => records;

  @override
  Future<AyahReviewRecordModel?> getReviewRecord(
    int surahId,
    int ayahNumber,
  ) async {
    for (final item in records) {
      if (item.surahId == surahId && item.ayahNumber == ayahNumber) {
        return item;
      }
    }
    return null;
  }

  @override
  String? getSelectedTrack() => null;

  @override
  Future<void> saveSelectedTrack(String track) async {}

  @override
  Future<void> saveReviewRecord(AyahReviewRecordModel record) async {}

  @override
  Future<DailyPlanModel?> getCachedDailyPlan() async => null;

  @override
  Future<void> saveDailyPlan(DailyPlanModel plan) async {}

  @override
  Future<KidsProgressModel> getKidsProgress() async =>
      const KidsProgressModel.empty();

  @override
  Future<void> saveKidsProgress(KidsProgressModel progress) async {}

  @override
  Future<CustomMemorizationPlanModel?> getCustomPlan() async => null;

  @override
  Future<void> saveCustomPlan(CustomMemorizationPlanModel plan) async {}

  @override
  Future<void> deleteCustomPlan() async {}
}

class _FakeQuranDatasource implements QuranLocalDatasource {
  _FakeQuranDatasource({required this.surahs, required this.ayahsByJuz}) {
    for (final ayahs in ayahsByJuz.values) {
      for (final ayah in ayahs) {
        _ayahsBySurah.putIfAbsent(ayah.surahId, () => []).add(ayah);
      }
    }
  }

  final List<SurahModel> surahs;
  final Map<int, List<AyahModel>> ayahsByJuz;
  final Map<int, List<AyahModel>> _ayahsBySurah = {};

  @override
  Future<List<SurahModel>> getSurahs() async => surahs;

  @override
  Future<List<AyahModel>> getAyahs(int surahId) async =>
      _ayahsBySurah[surahId] ?? const [];

  @override
  Future<Map<int, List<AyahModel>>> getAyahsGroupedByJuz() async => ayahsByJuz;

  @override
  Future<List<AyahModel>> getAyahsByPage(int pageNumber) async => const [];

  @override
  Future<List<AyahModel>> searchAyahs(String query) async => const [];
}
