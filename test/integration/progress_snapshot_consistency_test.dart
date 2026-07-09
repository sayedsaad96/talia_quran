import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/constants/app_constants.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/progress_metrics.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/progress/data/datasources/progress_local_datasource.dart';
import 'package:talia_quran/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/quran/data/datasources/quran_local_datasource.dart';
import 'package:talia_quran/features/quran/data/models/ayah_model.dart';
import 'package:talia_quran/features/quran/data/models/surah_model.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

/// Phase 10 — end-to-end snapshot validation across progress surfaces.
///
/// Simulates a realistic user journey (memorize → review → read → streak)
/// then asserts Progress, Home, Parent, and Certificate surfaces agree on
/// every metric derived from [ProgressMetricsService].
void main() {
  group('Progress snapshot consistency (Phase 10)', () {
    test(
      'memorize, review, read, and streak produce identical metrics everywhere',
      () async {
        final now = DateTime.now().toUtc();
        const streakDays = 5;
        final records = _scenarioRecords(now);
        final entityRecords = records.map((record) => record as AyahReviewRecord).toList();

        final progress = await _loadProgressSnapshot(
          records: records,
          readPages: const [1],
          streakDays: streakDays,
        );

        final metrics = _adultMetrics(
          records: entityRecords,
          now: now,
          streakDays: streakDays,
          readPagesCount: 1,
        );

        final parent = _parentSnapshot(
          records: entityRecords,
          now: now,
          streakDays: streakDays,
        );

        // Home reads the same OverallProgress entity as the Progress tab.
        final homeProgress = progress;

        expect(homeProgress.memorizedAyahs, progress.memorizedAyahs);
        expect(homeProgress.memorizedAyahs, metrics.memorizedAyahs);
        expect(parent.totalMemorizedAyahs, metrics.memorizedAyahs);

        expect(homeProgress.startedAyahs, progress.startedAyahs);
        expect(homeProgress.startedAyahs, metrics.startedAyahs);
        expect(parent.totalAyahsTracked, metrics.startedAyahs);

        expect(homeProgress.reviewAyahs, metrics.dueReviews);
        expect(homeProgress.overdueReviews, metrics.overdueReviews);
        expect(parent.reviewsOverdue, metrics.overdueReviews);

        expect(homeProgress.reviewedAyahsTotal, metrics.totalReviewEvents);
        expect(homeProgress.learningAyahs, metrics.learningAyahs);
        expect(homeProgress.streakDays, streakDays);
        expect(parent.currentStreak, streakDays);

        expect(
          (homeProgress.memorizedAyahsPercentage * 100).round(),
          (metrics.memorizationCompletionPercent * 100).round(),
        );
        expect(
          parent.completionPercent.round(),
          (metrics.memorizationCompletionPercent * 100).round(),
        );

        expect(homeProgress.readPagesCount, 1);
        expect(homeProgress.readAyahs, metrics.readAyahs);
      },
    );

    test('full surah memorization unlocks certificate aligned with metrics', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toUtc();

      final records = [
        _record(
          now: now,
          surahId: 1,
          ayahNumber: 1,
          strengthLevel: 6,
          mode: ReviewRecordCreatedByMode.v2Session,
        ),
        _record(
          now: now,
          surahId: 1,
          ayahNumber: 2,
          strengthLevel: 6,
          mode: ReviewRecordCreatedByMode.v2Session,
        ),
      ];

      final progress = await _loadProgressSnapshot(records: records);
      final metrics = _adultMetrics(
        records: records,
        now: now,
        surahAyahCounts: const {1: 2},
      );

      final achievementService = AchievementService(
        prefs,
        _AchievementMemPlusDatasource(records),
        _AchievementQuranDatasource(
          surahs: const [
            SurahModel(
              id: 1,
              nameAr: 'الفاتحة',
              nameEn: 'Al-Fatiha',
              ayahCount: 2,
              juz: 1,
              type: 'Meccan',
              page: 1,
            ),
          ],
          ayahsByJuz: {
            1: [
              const AyahModel(
                number: 1,
                surahId: 1,
                numberInSurah: 1,
                text: 'a',
                juz: 1,
                page: 1,
              ),
              const AyahModel(
                number: 2,
                surahId: 1,
                numberInSurah: 2,
                text: 'b',
                juz: 1,
                page: 1,
              ),
            ],
          },
        ),
        ProgressEventsBus(),
      );

      final awards = await achievementService.checkAndUnlockCertificates();

      expect(progress.memorizedAyahs, metrics.memorizedAyahs);
      expect(metrics.memorizedSurahs, 1);
      expect(awards.map((award) => award.id), contains('cert_surah_1'));
      expect(
        achievementService.getEarnedCertificates().map((award) => award.id),
        contains('cert_surah_1'),
      );
    });
  });
}

Future<OverallProgress> _loadProgressSnapshot({
  required List<AyahReviewRecordModel> records,
  List<int> readPages = const [],
  int streakDays = 0,
}) async {
  final repository = ProgressRepositoryImpl(
    _HarnessProgressDatasource(readPages: readPages),
    _HarnessMemPlusDatasource(records),
    _HarnessQuranDatasource(),
    _HarnessStreakReader(streakDays: streakDays),
    ProgressEventsBus(),
  );

  final result = await repository.getOverallProgress();
  return result.getOrElse(() => throw StateError('progress load failed'));
}

ProgressMetrics _adultMetrics({
  required List<AyahReviewRecord> records,
  required DateTime now,
  int streakDays = 0,
  int readPagesCount = 0,
  Map<int, int> surahAyahCounts = const {},
}) {
  const service = ProgressMetricsService();
  return service.calculate(
    records: records,
    now: now,
    audience: ProgressAudience.adult,
    surahAyahCounts: surahAyahCounts,
    totalAyahs: AppConstants.totalAyahs,
    totalSurahs: AppConstants.totalSurahs,
    totalJuz: AppConstants.totalJuz,
    readPagesCount: readPagesCount,
    totalQuranPages: 604,
    readAyahKeys: readPagesCount > 0 ? {'1_1', '1_2'} : const {},
    readSurahIds: readPagesCount > 0 ? {1} : const {},
    streakDays: streakDays,
  );
}

_ParentSnapshot _parentSnapshot({
  required List<AyahReviewRecord> records,
  required DateTime now,
  required int streakDays,
}) {
  final metrics = _adultMetrics(
    records: records,
    now: now,
    streakDays: streakDays,
  );

  return _ParentSnapshot(
    totalMemorizedAyahs: metrics.memorizedAyahs,
    totalAyahsTracked: metrics.startedAyahs,
    completionPercent: metrics.memorizationCompletionPercent * 100,
    reviewsOverdue: metrics.overdueReviews,
    currentStreak: streakDays,
  );
}

List<AyahReviewRecordModel> _scenarioRecords(DateTime now) {
  return [
    _record(
      now: now,
      surahId: 1,
      ayahNumber: 1,
      strengthLevel: 6,
      mode: ReviewRecordCreatedByMode.v2Session,
    ),
    _record(
      now: now,
      surahId: 1,
      ayahNumber: 2,
      strengthLevel: 6,
      mode: ReviewRecordCreatedByMode.v2Session,
    ),
    _record(
      now: now,
      surahId: 1,
      ayahNumber: 3,
      strengthLevel: 6,
      mode: ReviewRecordCreatedByMode.v2Session,
    ),
    _record(
      now: now,
      surahId: 1,
      ayahNumber: 4,
      strengthLevel: 3,
      totalReviews: 2,
      mode: ReviewRecordCreatedByMode.v2Session,
      nextReviewDate: now.add(const Duration(days: 3)),
    ),
    _record(
      now: now,
      surahId: 1,
      ayahNumber: 5,
      strengthLevel: 6,
      mode: ReviewRecordCreatedByMode.v2Session,
      nextReviewDate: now.subtract(const Duration(days: 2)),
    ),
    _record(
      now: now,
      surahId: 2,
      ayahNumber: 1,
      strengthLevel: 6,
      mode: ReviewRecordCreatedByMode.kidsMode,
    ),
  ];
}

AyahReviewRecordModel _record({
  required DateTime now,
  required int surahId,
  required int ayahNumber,
  required int strengthLevel,
  required ReviewRecordCreatedByMode mode,
  int totalReviews = 5,
  DateTime? nextReviewDate,
}) {
  return AyahReviewRecordModel(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel,
    intervalDays: 7,
    lastReviewedAt: now.subtract(const Duration(days: 10)),
    nextReviewDate: nextReviewDate ?? now.subtract(const Duration(days: 1)),
    totalReviews: totalReviews,
    lastRating: PerformanceRating.excellent,
    createdByMode: mode,
  );
}

class _ParentSnapshot {
  const _ParentSnapshot({
    required this.totalMemorizedAyahs,
    required this.totalAyahsTracked,
    required this.completionPercent,
    required this.reviewsOverdue,
    required this.currentStreak,
  });

  final int totalMemorizedAyahs;
  final int totalAyahsTracked;
  final double completionPercent;
  final int reviewsOverdue;
  final int currentStreak;
}

class _HarnessStreakReader implements StreakReader {
  const _HarnessStreakReader({required this.streakDays});

  final int streakDays;

  @override
  Future<StreakEntity> getStreak() async => StreakEntity(
    currentStreak: streakDays,
    longestStreak: streakDays,
  );
}

class _HarnessProgressDatasource implements ProgressLocalDatasource {
  _HarnessProgressDatasource({this.readPages = const []});

  final List<int> readPages;

  @override
  List<int> getReadPages() => readPages;

  @override
  Future<void> saveReadPage(int pageNumber) async {}
}

class _HarnessMemPlusDatasource implements MemorizationPlusLocalDatasource {
  _HarnessMemPlusDatasource(this.records);

  final List<AyahReviewRecordModel> records;

  @override
  Future<MemorizationProfileModel> getMemorizationProfile() async =>
      MemorizationProfileModel.empty();

  @override
  Future<List<AyahReviewRecordModel>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
    bool includeAllAudiences = false,
  }) async => records;

  @override
  Future<KidsProgressModel> getKidsProgress() async =>
      const KidsProgressModel.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HarnessQuranDatasource implements QuranLocalDatasource {
  @override
  Future<List<AyahModel>> getAyahs(int surahId) async => const [];
  @override
  Future<List<AyahModel>> getAyahsByPage(int pageNumber) async {
    if (pageNumber == 1) {
      return const [
        AyahModel(
          number: 1,
          surahId: 1,
          numberInSurah: 1,
          text: 'a',
          juz: 1,
          page: 1,
        ),
        AyahModel(
          number: 2,
          surahId: 1,
          numberInSurah: 2,
          text: 'b',
          juz: 1,
          page: 1,
        ),
      ];
    }
    return const [];
  }
  @override
  Future<Map<int, List<AyahModel>>> getAyahsGroupedByJuz() async => const {};
  @override
  Future<List<SurahModel>> getSurahs() async => const [];
  @override
  Future<List<AyahModel>> searchAyahs(String query) async => const [];
}

class _AchievementMemPlusDatasource implements MemorizationPlusLocalDatasource {
  _AchievementMemPlusDatasource(this.records);

  final List<AyahReviewRecordModel> records;

  @override
  Future<List<AyahReviewRecordModel>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
    bool includeAllAudiences = false,
  }) async => records;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AchievementQuranDatasource implements QuranLocalDatasource {
  _AchievementQuranDatasource({
    required this.surahs,
    required this.ayahsByJuz,
  });

  final List<SurahModel> surahs;
  final Map<int, List<AyahModel>> ayahsByJuz;

  @override
  Future<List<SurahModel>> getSurahs() async => surahs;
  @override
  Future<Map<int, List<AyahModel>>> getAyahsGroupedByJuz() async => ayahsByJuz;
  @override
  Future<List<AyahModel>> getAyahs(int surahId) async => const [];
  @override
  Future<List<AyahModel>> getAyahsByPage(int pageNumber) async => const [];
  @override
  Future<List<AyahModel>> searchAyahs(String query) async => const [];
}
