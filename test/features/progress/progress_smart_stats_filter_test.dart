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

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeStreakReader implements StreakReader {
  const _FakeStreakReader();
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}

class _FakeProgressDatasource implements ProgressLocalDatasource {
  @override
  List<int> getReadPages() => const [];
  @override
  Future<void> saveReadPage(int pageNumber) async {}
}

class _FakeMemPlusDatasource implements MemorizationPlusLocalDatasource {
  _FakeMemPlusDatasource(this.records);
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
  Future<List<AyahModel>> getAyahsByPage(int pageNumber) async => const [];
  @override
  Future<Map<int, List<AyahModel>>> getAyahsGroupedByJuz() async => const {};
  @override
  Future<List<SurahModel>> getSurahs() async => const [];
  @override
  Future<List<AyahModel>> searchAyahs(String query) async => const [];
}

// ── Helpers ────────────────────────────────────────────────────────────────────

/// Creates a review record model with the given mode and strengthLevel.
AyahReviewRecordModel _reviewRecord(
  int ayahNumber,
  ReviewRecordCreatedByMode mode, {
  int strengthLevel = 6,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return AyahReviewRecordModel(
    surahId: 1,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel,
    intervalDays: 30,
    lastReviewedAt: now.subtract(const Duration(days: 35)),
    nextReviewDate: now.subtract(const Duration(days: 5)),
    totalReviews: 5,
    lastRating: PerformanceRating.excellent,
    createdByMode: mode,
  );
}

ProgressRepositoryImpl _repo(List<AyahReviewRecordModel> records) =>
    ProgressRepositoryImpl(
      _FakeProgressDatasource(),
      _FakeMemPlusDatasource(records),
      _FakeQuranDatasource(),
      const _FakeStreakReader(),
      ProgressEventsBus(),
    );

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('ProgressRepositoryImpl — adult production source filtering', () {
    test('v2Session record counts in memorizedAyahs when strength >= 6', () async {
      final result = await _repo([
        _reviewRecord(1, ReviewRecordCreatedByMode.v2Session),
      ]).getOverallProgress();
      final progress = result.getOrElse(() => throw StateError('failed'));
      expect(progress.memorizedAyahs, 1);
      expect(progress.memorizedAyahs, 1);
    });

    test('kidsMode record is excluded from adult production counts', () async {
      final result = await _repo([
        _reviewRecord(1, ReviewRecordCreatedByMode.kidsMode),
      ]).getOverallProgress();
      final progress = result.getOrElse(() => throw StateError('failed'));
      expect(progress.memorizedAyahs, 0);
      expect(progress.memorizedAyahs, 0);
    });

    test('hifz (repaired legacy) record counts in adult production', () async {
      final result = await _repo([
        _reviewRecord(1, ReviewRecordCreatedByMode.hifz),
      ]).getOverallProgress();
      final progress = result.getOrElse(() => throw StateError('failed'));
      expect(progress.memorizedAyahs, 1);
    });

    test('legacy ambiguous source tags do not count in adult progress', () async {
      final result = await _repo([
        _reviewRecord(1, ReviewRecordCreatedByMode.adultMemPlus),
        _reviewRecord(2, ReviewRecordCreatedByMode.unknown),
        _reviewRecord(3, ReviewRecordCreatedByMode.migration),
      ]).getOverallProgress();
      final progress = result.getOrElse(() => throw StateError('failed'));
      expect(progress.memorizedAyahs, 0);
    });

    test('mixed source list counts v2Session + hifz only', () async {
      final result = await _repo([
        _reviewRecord(1, ReviewRecordCreatedByMode.v2Session),
        _reviewRecord(2, ReviewRecordCreatedByMode.kidsMode),
        _reviewRecord(3, ReviewRecordCreatedByMode.adultMemPlus),
        _reviewRecord(4, ReviewRecordCreatedByMode.unknown),
        _reviewRecord(5, ReviewRecordCreatedByMode.migration),
        _reviewRecord(6, ReviewRecordCreatedByMode.hifz),
      ]).getOverallProgress();
      final progress = result.getOrElse(() => throw StateError('failed'));
      expect(progress.memorizedAyahs, 2);
    });

    test('due reviews count only adult production records', () async {
      final result = await _repo([
        _reviewRecord(
          1,
          ReviewRecordCreatedByMode.v2Session,
          strengthLevel: 3,
        ),
        _reviewRecord(
          2,
          ReviewRecordCreatedByMode.kidsMode,
          strengthLevel: 3,
        ),
      ]).getOverallProgress();
      final progress = result.getOrElse(() => throw StateError('failed'));
      expect(progress.reviewAyahs, 1);
      expect(progress.reviewAyahs, 1);
    });
  });

  group('ProgressRepositoryImpl — two-tier memorization metrics', () {
    test('started includes reviewed-once; memorized requires strength >= 6', () async {
      final result = await _repo([
        _reviewRecord(
          1,
          ReviewRecordCreatedByMode.v2Session,
          strengthLevel: 6,
        ),
        _reviewRecord(
          2,
          ReviewRecordCreatedByMode.v2Session,
          strengthLevel: 3,
        ),
        _reviewRecord(
          3,
          ReviewRecordCreatedByMode.v2Session,
          strengthLevel: 5,
        ),
      ]).getOverallProgress();
      final progress = result.getOrElse(() => throw StateError('failed'));

      expect(progress.startedAyahs, 3);
      expect(progress.memorizedAyahs, 1);
      expect(progress.learningAyahs, 2);
      expect(progress.memorizedAyahs + progress.learningAyahs, progress.startedAyahs);
    });

    test('reviewedAyahsTotal sums review repetitions across counted records', () async {
      final result = await _repo([
        _reviewRecord(1, ReviewRecordCreatedByMode.v2Session),
        _reviewRecord(2, ReviewRecordCreatedByMode.v2Session),
      ]).getOverallProgress();
      final progress = result.getOrElse(() => throw StateError('failed'));
      expect(progress.reviewedAyahsTotal, 10);
    });
  });
}
