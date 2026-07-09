import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
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
        smartRecords: [_smartMemorized(1, 1), _smartMemorized(1, 2)],
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
        smartRecords: [_smartMemorized(1, 1), _smartMemorized(1, 2)],
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
          smartRecords: [
            _smartMemorized(1, 1),
            _smartMemorized(1, 2),
            _smartMemorized(2, 1),
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
          smartRecords: [_smartMemorized(1, 1)],
        );

        final firstAwards = await service.checkAndUnlockCertificates();
        final secondAwards = await service.checkAndUnlockCertificates();
        final firstIds = firstAwards.map((award) => award.id).toSet();

        expect(firstIds, containsAll(['cert_surah_1', 'cert_juz_1']));
        expect(secondAwards, isEmpty);
      },
    );

    test(
      'pushes every newly-earned certificate to the cloud repository',
      () async {
        final repository = _RecordingMemPlusRepository();
        final service = await _buildService(
          surahs: [_surah(1, ayahCount: 1)],
          ayahsByJuz: {
            1: [_ayah(1, 1, juz: 1)],
          },
          smartRecords: [_smartMemorized(1, 1)],
          repository: repository,
        );

        final awards = await service.checkAndUnlockCertificates();
        // Best-effort push runs via unawaited(); flush the microtask queue.
        await Future<void>.delayed(Duration.zero);

        expect(awards, isNotEmpty);
        expect(
          repository.pushedCertificateIds,
          containsAll(awards.map((a) => a.id)),
        );
      },
    );

    test(
      'does not push to the cloud when no repository is configured',
      () async {
        final service = await _buildService(
          surahs: [_surah(1, ayahCount: 1)],
          ayahsByJuz: {
            1: [_ayah(1, 1, juz: 1)],
          },
          smartRecords: [_smartMemorized(1, 1)],
        );

        // No repository injected — must not throw.
        await expectLater(service.checkAndUnlockCertificates(), completes);
      },
    );
  });
}

Future<AchievementService> _buildService({
  required List<SurahModel> surahs,
  required Map<int, List<AyahModel>> ayahsByJuz,
  List<AyahReviewRecordModel> smartRecords = const [],
  MemorizationPlusRepository? repository,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return AchievementService(
    prefs,
    _FakeMemPlusDatasource(smartRecords),
    _FakeQuranDatasource(surahs: surahs, ayahsByJuz: ayahsByJuz),
    ProgressEventsBus(),
    repository,
  );
}

class _RecordingMemPlusRepository implements MemorizationPlusRepository {
  final List<String> pushedCertificateIds = [];

  @override
  Future<Either<Failure, void>> pushCertificatesToCloud(
    List<CertificateAward> certificates,
  ) async {
    pushedCertificateIds.addAll(certificates.map((c) => c.id));
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
    createdByMode: ReviewRecordCreatedByMode.v2Session,
  );
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
  Future<List<AyahReviewRecordModel>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
    bool includeAllAudiences = false,
  }) async => records;

  @override
  Future<AyahReviewRecordModel?> getReviewRecord(
    int surahId,
    int ayahNumber, {
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async {
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
  Future<void> clearSelectedTrack() async {}

  @override
  Future<void> saveReviewRecord(AyahReviewRecordModel record) async {}

  @override
  Future<DailyPlanModel?> getCachedDailyPlan() async => null;

  @override
  Future<void> saveDailyPlan(DailyPlanModel plan) async {}
  @override
  Future<void> clearDailyPlanCache() async {}

  @override
  Future<KidsProgressModel> getKidsProgress() async =>
      const KidsProgressModel.empty();

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
  Future<CustomMemorizationPlanModel?> getCustomPlan() async => null;

  @override
  Future<void> saveCustomPlan(CustomMemorizationPlanModel plan) async {}

  @override
  Future<void> deleteCustomPlan() async {}

  @override
  Future<SmartMemorizationSettingsModel> getSmartSettings() async =>
      const SmartMemorizationSettingsModel();

  @override
  Future<void> saveSmartSettings(
    SmartMemorizationSettingsModel settings,
  ) async {}

  @override
  bool getIsParentMode() => false;

  @override
  Future<void> setIsParentMode(bool value) async {}

  @override
  Future<void> clearIsParentMode() async {}
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
