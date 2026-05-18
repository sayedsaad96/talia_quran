import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/hifz/data/datasources/hifz_local_datasource.dart';
import 'package:talia_quran/features/hifz/data/models/ayah_progress_model.dart';
import 'package:talia_quran/features/hifz/domain/entities/hifz_entities.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/progress/data/datasources/progress_local_datasource.dart';
import 'package:talia_quran/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:talia_quran/features/quran/data/datasources/quran_local_datasource.dart';
import 'package:talia_quran/features/quran/data/models/ayah_model.dart';
import 'package:talia_quran/features/quran/data/models/surah_model.dart';

void main() {
  group('ProgressRepositoryImpl', () {
    test(
      'counts a surah as memorized only when all ayahs are memorized',
      () async {
        final repository = ProgressRepositoryImpl(
          _FakeProgressDatasource(),
          _FakeHifzDatasource([
            AyahProgressModel(
              surahId: 1,
              ayahNumber: 1,
              status: AyahStatus.memorized,
              repetitions: 5,
              nextReviewDate: DateTime(2026, 5, 5),
              lastReviewDate: DateTime(2026, 5, 5),
            ),
            AyahProgressModel(
              surahId: 2,
              ayahNumber: 1,
              status: AyahStatus.memorized,
              repetitions: 5,
              nextReviewDate: DateTime(2026, 5, 5),
              lastReviewDate: DateTime(2026, 5, 5),
            ),
            AyahProgressModel(
              surahId: 2,
              ayahNumber: 2,
              status: AyahStatus.memorized,
              repetitions: 5,
              nextReviewDate: DateTime(2026, 5, 5),
              lastReviewDate: DateTime(2026, 5, 5),
            ),
          ]),
          _FakeMemPlusDatasource(),
          _FakeQuranDatasource(),
        );

        final result = await repository.getOverallProgress();
        final progress = result.getOrElse(() => throw StateError('failed'));

        expect(progress.memorizedSurahs, 1);
      },
    );

    test(
      'derives read ayah and surah counts from confirmed read pages',
      () async {
        final repository = ProgressRepositoryImpl(
          _FakeProgressDatasource(readPages: const [1, 2]),
          _FakeHifzDatasource(const []),
          _FakeMemPlusDatasource(),
          _FakeQuranDatasource(),
        );

        final result = await repository.getOverallProgress();
        final progress = result.getOrElse(() => throw StateError('failed'));

        expect(progress.readPagesCount, 2);
        expect(progress.readAyahs, 3);
        expect(progress.readSurahs, 2);
      },
    );
  });
}

class _FakeProgressDatasource implements ProgressLocalDatasource {
  _FakeProgressDatasource({this.readPages = const []});
  final List<int> readPages;

  @override
  DateTime? getLastActiveDate() => DateTime(2026, 5, 5);

  @override
  List<int> getReadPages() => readPages;

  @override
  int getStreakDays() => 3;

  @override
  Future<void> saveReadPage(int pageNumber) async {}

  @override
  Future<void> saveStreak(int days, DateTime date) async {}
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
  String? getHifzPath() => null;

  @override
  Future<Set<String>> getPassedCheckpointKeys(int surahId) async => {};

  @override
  Future<void> markCheckpointPassed(String checkpointKey) async {}

  @override
  Future<List<AyahProgressModel>> getProgressForSurah(int surahId) async =>
      progress.where((p) => p.surahId == surahId).toList();

  @override
  Future<void> saveAyahProgress(AyahProgressModel progress) async {}

  @override
  Future<void> saveHifzPath(String path) async {}
}

class _FakeMemPlusDatasource implements MemorizationPlusLocalDatasource {
  @override
  Future<MemorizationProfileModel> getMemorizationProfile() async =>
      MemorizationProfileModel.empty();

  @override
  Future<void> saveMemorizationProfile(
    MemorizationProfileModel profile,
  ) async {}

  @override
  Future<void> clearMemorizationProfile() async {}

  @override
  Future<PairingSessionModel?> getPairingSession() async => null;

  @override
  Future<void> savePairingSession(PairingSessionModel session) async {}

  @override
  Future<void> clearPairingSession() async {}

  @override
  Future<void> deleteCustomPlan() async {}

  @override
  Future<List<AyahReviewRecordModel>> getAllReviewRecords() async => const [];

  @override
  Future<DailyPlanModel?> getCachedDailyPlan() async => null;

  @override
  Future<CustomMemorizationPlanModel?> getCustomPlan() async => null;

  @override
  Future<KidsProgressModel> getKidsProgress() async =>
      const KidsProgressModel.empty();

  @override
  Future<AyahReviewRecordModel?> getReviewRecord(
    int surahId,
    int ayahNumber,
  ) async => null;

  @override
  String? getSelectedTrack() => null;

  @override
  Future<void> saveCustomPlan(CustomMemorizationPlanModel plan) async {}

  @override
  Future<void> saveDailyPlan(DailyPlanModel plan) async {}

  @override
  Future<void> saveKidsProgress(KidsProgressModel progress) async {}

  @override
  Future<List<KidsSessionLogModel>> getKidsSessionLogs() async => const [];

  @override
  Future<void> saveKidsSessionLog(KidsSessionLogModel log) async {}

  @override
  Future<void> saveKidsSessionLogs(List<KidsSessionLogModel> logs) async {}

  @override
  Future<ParentSettingsModel> getParentSettings() async =>
      const ParentSettingsModel.defaults();

  @override
  Future<void> saveParentSettings(ParentSettingsModel settings) async {}

  @override
  Future<List<ParentRewardModel>> getParentRewards() async => const [];

  @override
  Future<void> saveParentRewards(List<ParentRewardModel> rewards) async {}

  @override
  Future<void> saveReviewRecord(AyahReviewRecordModel record) async {}

  @override
  Future<void> saveSelectedTrack(String track) async {}

  @override
  Future<void> clearSelectedTrack() async {}

  @override
  bool getIsParentMode() => false;

  @override
  Future<void> setIsParentMode(bool value) async {}

  @override
  Future<void> clearIsParentMode() async {}

  @override
  Future<SmartMemorizationSettingsModel> getSmartSettings() async =>
      const SmartMemorizationSettingsModel();

  @override
  Future<void> saveSmartSettings(
    SmartMemorizationSettingsModel settings,
  ) async {}
}

class _FakeQuranDatasource implements QuranLocalDatasource {
  @override
  Future<List<AyahModel>> getAyahs(int surahId) async => const [];

  @override
  Future<List<AyahModel>> getAyahsByPage(int pageNumber) async {
    return switch (pageNumber) {
      1 => const [
        AyahModel(
          number: 1,
          surahId: 1,
          text: 'آية 1',
          numberInSurah: 1,
          juz: 1,
          page: 1,
        ),
        AyahModel(
          number: 2,
          surahId: 1,
          text: 'آية 2',
          numberInSurah: 2,
          juz: 1,
          page: 1,
        ),
      ],
      2 => const [
        AyahModel(
          number: 3,
          surahId: 2,
          text: 'آية 1',
          numberInSurah: 1,
          juz: 1,
          page: 2,
        ),
      ],
      _ => const [],
    };
  }

  @override
  Future<Map<int, List<AyahModel>>> getAyahsGroupedByJuz() async => const {};

  @override
  Future<List<SurahModel>> getSurahs() async => const [
    SurahModel(
      id: 1,
      nameAr: 'الفاتحة',
      nameEn: 'Al-Fatihah',
      ayahCount: 2,
      juz: 1,
      type: 'meccan',
      page: 1,
    ),
    SurahModel(
      id: 2,
      nameAr: 'البقرة',
      nameEn: 'Al-Baqarah',
      ayahCount: 2,
      juz: 1,
      type: 'medinan',
      page: 2,
    ),
  ];

  @override
  Future<List<AyahModel>> searchAyahs(String query) async => const [];
}
