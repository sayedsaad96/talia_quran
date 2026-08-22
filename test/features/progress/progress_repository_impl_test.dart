import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/progress/data/datasources/progress_local_datasource.dart';
import 'package:talia_quran/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:talia_quran/features/quran/data/datasources/quran_local_datasource.dart';
import 'package:talia_quran/features/quran/data/models/ayah_model.dart';
import 'package:talia_quran/features/quran/data/models/surah_model.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

void main() {
  group('ProgressRepositoryImpl', () {
    test(
      'counts a surah as memorized only when all ayahs reach strength >= 6',
      () async {
        final repository = ProgressRepositoryImpl(
          _FakeProgressDatasource(),
          _FakeMemPlusDatasource([
            _reviewRecord(1, 1),
            _reviewRecord(2, 1),
            _reviewRecord(2, 2),
          ]),
          _FakeQuranDatasource(),
          const _FakeStreakReader(),
          ProgressEventsBus(),
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
          _FakeMemPlusDatasource(),
          _FakeQuranDatasource(),
          const _FakeStreakReader(),
          ProgressEventsBus(),
        );

        final result = await repository.getOverallProgress();
        final progress = result.getOrElse(() => throw StateError('failed'));

        expect(progress.readPagesCount, 2);
        expect(progress.readAyahs, 3);
        expect(progress.readSurahs, 2);
      },
    );

    test('getOverallProgress reads streak from StreakReader', () async {
      final progressDatasource = _FakeProgressDatasource();
      final repository = ProgressRepositoryImpl(
        progressDatasource,
        _FakeMemPlusDatasource(),
        _FakeQuranDatasource(),
        _FakeStreakReader(
          currentStreak: 7,
          lastActivityDate: DateTime.utc(2026, 5, 6),
        ),
        ProgressEventsBus(),
      );

      final result = await repository.getOverallProgress();
      final progress = result.getOrElse(() => throw StateError('failed'));

      expect(progress.streakDays, 7);
      expect(progress.lastActiveDate, DateTime.utc(2026, 5, 6));
      expect(progressDatasource.saveReadPageCalls, 0);
    });

    test('two-tier metrics: started vs memorized are disjoint', () async {
      final repository = ProgressRepositoryImpl(
        _FakeProgressDatasource(),
        _FakeMemPlusDatasource([
          _reviewRecord(1, 1), // strength 6 — memorized
          AyahReviewRecordModel(
            surahId: 1,
            ayahNumber: 2,
            strengthLevel: 3,
            intervalDays: 7,
            lastReviewedAt: DateTime(2026, 5, 5),
            nextReviewDate: DateTime(2026, 5, 12),
            totalReviews: 2,
            lastRating: PerformanceRating.average,
            createdByMode: ReviewRecordCreatedByMode.v2Session,
          ),
        ]),
        _FakeQuranDatasource(),
        const _FakeStreakReader(),
        ProgressEventsBus(),
      );

      final result = await repository.getOverallProgress();
      final progress = result.getOrElse(() => throw StateError('failed'));

      expect(progress.startedAyahs, 2);
      expect(progress.memorizedAyahs, 1);
      expect(progress.learningAyahs, 1);
    });
  });
}

class _FakeStreakReader implements StreakReader {
  const _FakeStreakReader({this.currentStreak = 3, this.lastActivityDate});

  final int currentStreak;
  final DateTime? lastActivityDate;

  @override
  Future<StreakEntity> getStreak() async => StreakEntity(
    currentStreak: currentStreak,
    longestStreak: currentStreak,
    lastActivityDate: lastActivityDate,
  );
}

class _FakeProgressDatasource implements ProgressLocalDatasource {
  _FakeProgressDatasource({this.readPages = const []});
  final List<int> readPages;
  int saveReadPageCalls = 0;

  @override
  List<int> getReadPages() => readPages;

  @override
  Future<void> saveReadPage(int pageNumber) async {
    saveReadPageCalls++;
  }
}

AyahReviewRecordModel _reviewRecord(int surahId, int ayahNumber) {
  final now = DateTime(2026, 5, 5);
  return AyahReviewRecordModel(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: 6,
    intervalDays: 30,
    lastReviewedAt: now,
    nextReviewDate: now.add(const Duration(days: 30)),
    totalReviews: 1,
    lastRating: PerformanceRating.excellent,
    createdByMode: ReviewRecordCreatedByMode.v2Session,
  );
}

class _FakeMemPlusDatasource implements MemorizationPlusLocalDatasource {
  _FakeMemPlusDatasource([this.records = const []]);

  final List<AyahReviewRecordModel> records;

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
  Future<void> migrateReviewRecordsToIsarIfNeeded() async {}

  @override
  Future<void> migrateAudienceScopedReviewKeysIfNeeded() async {}

  @override
  Future<void> migrateReviewRecordIdentityIfNeeded() async {}

  @override
  Future<int> claimLocalReviewRecords() async => 0;

  @override
  Future<void> deleteCustomPlan() async {}

  @override
  Future<List<AyahReviewRecordModel>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
    bool includeAllAudiences = false,
  }) async => records;

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
    int ayahNumber, {
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async => null;

  @override
  String? getSelectedTrack() => null;

  @override
  Future<void> saveCustomPlan(CustomMemorizationPlanModel plan) async {}

  @override
  Future<void> saveDailyPlan(DailyPlanModel plan) async {}
  @override
  Future<void> clearDailyPlanCache() async {}

  @override
  Future<void> saveKidsProgress(KidsProgressModel progress) async {}

  @override
  Future<List<KidsSessionLogModel>> getKidsSessionLogs() async => const [];

  @override
  Future<void> saveKidsSessionLog(KidsSessionLogModel log) async {}

  @override
  Future<void> saveKidsSessionLogs(List<KidsSessionLogModel> logs) async {}
  @override
  Future<void> markKidsSessionLogsCloudSynced(Iterable<String> localIds) async {}

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
  Future<void> saveReviewRecord(
    AyahReviewRecordModel record, {
    bool markCloudDirty = true,
  }) async {}

  @override
  Future<List<AyahReviewRecordModel>> getCloudDirtyReviewRecords({
    bool includeAllAudiences = false,
  }) async => records;

  @override
  Future<void> markReviewRecordsCloudSynced(
    Iterable<String> compositeKeys,
  ) async {}

  @override
  Future<void> markReviewRecordsCloudSyncedAtVersions(
    Map<String, int> acknowledgedVersions,
  ) async {}

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
  Future<void> ensureLoaded() async {}

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
