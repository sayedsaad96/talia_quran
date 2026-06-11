import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/hifz/data/datasources/hifz_local_datasource.dart';
import 'package:talia_quran/features/hifz/data/models/ayah_progress_model.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
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

class _FakeHifzDatasource implements HifzLocalDatasource {
  @override
  Future<List<AyahProgressModel>> getAllProgress() async => const [];
  @override
  Future<AyahProgressModel?> getAyahProgress(
    int surahId,
    int ayahNumber,
  ) async => null;
  @override
  String? getHifzPath() => null;
  @override
  Future<Set<String>> getPassedCheckpointKeys(int surahId) async => const {};
  @override
  Future<void> markCheckpointPassed(String checkpointKey) async {}
  @override
  Future<List<AyahProgressModel>> getProgressForSurah(int surahId) async =>
      const [];
  @override
  Future<void> saveAyahProgress(AyahProgressModel progress) async {}
  @override
  Future<void> saveHifzPath(String path) async {}
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
  Future<void> deleteCustomPlan() async {}
  @override
  Future<List<AyahReviewRecordModel>> getAllReviewRecords() async => records;
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
  int strengthLevel = 6, // default: memorized
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
      _FakeHifzDatasource(),
      _FakeMemPlusDatasource(records),
      _FakeQuranDatasource(),
      const _FakeStreakReader(),
    );

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('ProgressRepositoryImpl — Sprint 8B smartMemorizedAyahs filtering', () {
    // ── Sources that must count ───────────────────────────────────────────

    test(
      'adultMemPlus memorized record counts in smartMemorizedAyahs',
      () async {
        final result = await _repo([
          _reviewRecord(1, ReviewRecordCreatedByMode.adultMemPlus),
        ]).getOverallProgress();
        final progress = result.getOrElse(() => throw StateError('failed'));
        expect(progress.smartMemorizedAyahs, 1);
      },
    );

    test(
      'unknown memorized record counts in smartMemorizedAyahs (backward compat)',
      () async {
        final result = await _repo([
          _reviewRecord(1, ReviewRecordCreatedByMode.unknown),
        ]).getOverallProgress();
        final progress = result.getOrElse(() => throw StateError('failed'));
        expect(progress.smartMemorizedAyahs, 1);
      },
    );

    test(
      'migration memorized record counts in smartMemorizedAyahs (backward compat)',
      () async {
        final result = await _repo([
          _reviewRecord(1, ReviewRecordCreatedByMode.migration),
        ]).getOverallProgress();
        final progress = result.getOrElse(() => throw StateError('failed'));
        expect(progress.smartMemorizedAyahs, 1);
      },
    );

    // ── Sources that must NOT count ───────────────────────────────────────

    test(
      'kidsMode memorized record does NOT count in smartMemorizedAyahs',
      () async {
        final result = await _repo([
          _reviewRecord(1, ReviewRecordCreatedByMode.kidsMode),
        ]).getOverallProgress();
        final progress = result.getOrElse(() => throw StateError('failed'));
        expect(progress.smartMemorizedAyahs, 0);
      },
    );

    test(
      'hifz memorized record does NOT count in smartMemorizedAyahs',
      () async {
        final result = await _repo([
          _reviewRecord(1, ReviewRecordCreatedByMode.hifz),
        ]).getOverallProgress();
        final progress = result.getOrElse(() => throw StateError('failed'));
        expect(progress.smartMemorizedAyahs, 0);
      },
    );

    // ── Mixed sources ─────────────────────────────────────────────────────

    test(
      'only adult-compatible records are counted in mixed source list',
      () async {
        final result = await _repo([
          _reviewRecord(1, ReviewRecordCreatedByMode.adultMemPlus), // +1
          _reviewRecord(2, ReviewRecordCreatedByMode.unknown), // +1
          _reviewRecord(3, ReviewRecordCreatedByMode.migration), // +1
          _reviewRecord(4, ReviewRecordCreatedByMode.kidsMode), // excluded
          _reviewRecord(5, ReviewRecordCreatedByMode.hifz), // excluded
        ]).getOverallProgress();
        final progress = result.getOrElse(() => throw StateError('failed'));
        expect(progress.smartMemorizedAyahs, 3);
      },
    );

    // ── smartReviewAyahs — naturally safe but now defensively filtered ────

    test(
      'smartReviewAyahs is 0 when only kidsMode records exist (defensive filter)',
      () async {
        // kidsMode records have strengthLevel >= 6, already outside 0-5 range.
        // The explicit filter makes this robust to any future kidsMode records
        // with strengthLevel in 1-5.
        final result = await _repo([
          _reviewRecord(
            1,
            ReviewRecordCreatedByMode.kidsMode,
            strengthLevel: 3,
          ),
        ]).getOverallProgress();
        final progress = result.getOrElse(() => throw StateError('failed'));
        expect(progress.smartReviewAyahs, 0);
      },
    );

    test(
      'smartReviewAyahs counts adultMemPlus non-memorized records',
      () async {
        final result = await _repo([
          _reviewRecord(
            1,
            ReviewRecordCreatedByMode.adultMemPlus,
            strengthLevel: 3,
          ),
        ]).getOverallProgress();
        final progress = result.getOrElse(() => throw StateError('failed'));
        expect(progress.smartReviewAyahs, 1);
      },
    );

    // ── Hifz progress unaffected ──────────────────────────────────────────

    test(
      'memorizedAyahs (Hifz) is unaffected by MemPlus source filtering',
      () async {
        // No MemPlus records; Hifz path is separate and unchanged.
        final result = await _repo([]).getOverallProgress();
        final progress = result.getOrElse(() => throw StateError('failed'));
        // Hifz is driven by HifzLocalDatasource (fake returns empty).
        expect(progress.memorizedAyahs, 0);
        expect(progress.smartMemorizedAyahs, 0);
      },
    );
  });
}
