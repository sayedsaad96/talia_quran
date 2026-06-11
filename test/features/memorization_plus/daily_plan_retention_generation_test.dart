import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

void main() {
  late MemorizationPlusLocalDatasourceImpl datasource;
  late MemorizationPlusRepositoryImpl repository;
  final now = DateTime.utc(2026, 6, 10, 12);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    datasource = MemorizationPlusLocalDatasourceImpl(prefs);
    repository = MemorizationPlusRepositoryImpl(
      datasource,
      _SurahQuranRepository(surahId: 114, ayahCount: 10),
    );
  });

  Future<void> saveMemorizedDue({
    required int ayahNumber,
    required ReviewRecordCreatedByMode mode,
    DateTime? nextReviewDate,
    int strengthLevel = 6,
    int intervalDays = 30,
    int totalReviews = 6,
  }) async {
    await datasource.saveReviewRecord(
      AyahReviewRecordModel(
        surahId: 114,
        ayahNumber: ayahNumber,
        strengthLevel: strengthLevel,
        intervalDays: intervalDays,
        lastReviewedAt: now.subtract(const Duration(days: 45)),
        nextReviewDate: nextReviewDate ?? now.subtract(const Duration(days: 1)),
        totalReviews: totalReviews,
        lastRating: PerformanceRating.excellent,
        createdByMode: mode,
      ),
    );
  }

  Future<void> saveNearDue({
    required int ayahNumber,
    ReviewRecordCreatedByMode mode = ReviewRecordCreatedByMode.adultMemPlus,
  }) async {
    await datasource.saveReviewRecord(
      AyahReviewRecordModel(
        surahId: 114,
        ayahNumber: ayahNumber,
        strengthLevel: 3,
        intervalDays: 1,
        lastReviewedAt: now.subtract(const Duration(days: 2)),
        nextReviewDate: now.subtract(const Duration(hours: 1)),
        totalReviews: 2,
        lastRating: PerformanceRating.average,
        createdByMode: mode,
      ),
    );
  }

  Future<DailyPlan> generate() async {
    final result = await repository.generateDailyPlan(
      surahId: 114,
      newAyahsPerDay: 2,
    );
    return result.getOrElse(
      () => throw StateError('Expected plan generation to succeed'),
    );
  }

  group('generateDailyPlan retention bucket', () {
    test('includes adultMemPlus memorized-due retention', () async {
      await saveMemorizedDue(
        ayahNumber: 5,
        mode: ReviewRecordCreatedByMode.adultMemPlus,
      );

      final plan = await generate();
      expect(plan.retentionReview.map((a) => a.ayahNumber), contains(5));
    });

    test('excludes kidsMode memorized-due', () async {
      await saveMemorizedDue(
        ayahNumber: 4,
        mode: ReviewRecordCreatedByMode.kidsMode,
      );

      final plan = await generate();
      expect(plan.retentionReview.map((a) => a.ayahNumber), isNot(contains(4)));
    });

    test('excludes hifz memorized-due', () async {
      await saveMemorizedDue(
        ayahNumber: 4,
        mode: ReviewRecordCreatedByMode.hifz,
      );

      final plan = await generate();
      expect(plan.retentionReview.map((a) => a.ayahNumber), isNot(contains(4)));
    });

    test('excludes unknown memorized-due', () async {
      await saveMemorizedDue(
        ayahNumber: 4,
        mode: ReviewRecordCreatedByMode.unknown,
      );

      final plan = await generate();
      expect(plan.retentionReview.map((a) => a.ayahNumber), isNot(contains(4)));
    });

    test('excludes migration memorized-due', () async {
      await saveMemorizedDue(
        ayahNumber: 4,
        mode: ReviewRecordCreatedByMode.migration,
      );

      final plan = await generate();
      expect(plan.retentionReview.map((a) => a.ayahNumber), isNot(contains(4)));
    });

    test('caps retention at 3', () async {
      for (var ayah = 1; ayah <= 5; ayah++) {
        await saveMemorizedDue(
          ayahNumber: ayah,
          mode: ReviewRecordCreatedByMode.adultMemPlus,
          nextReviewDate: now.subtract(Duration(days: ayah)),
        );
      }

      final plan = await generate();
      expect(plan.retentionReview, hasLength(3));
    });

    test('sorts retention by oldest due date first', () async {
      await saveMemorizedDue(
        ayahNumber: 2,
        mode: ReviewRecordCreatedByMode.adultMemPlus,
        nextReviewDate: now.subtract(const Duration(days: 1)),
        strengthLevel: 7,
      );
      await saveMemorizedDue(
        ayahNumber: 3,
        mode: ReviewRecordCreatedByMode.adultMemPlus,
        nextReviewDate: now.subtract(const Duration(days: 5)),
        strengthLevel: 6,
      );

      final plan = await generate();
      expect(plan.retentionReview.first.ayahNumber, 3);
    });

    test('does not reduce new ayahs', () async {
      await saveMemorizedDue(
        ayahNumber: 9,
        mode: ReviewRecordCreatedByMode.adultMemPlus,
      );

      final plan = await generate();
      expect(plan.newAyahs, hasLength(2));
      expect(plan.totalItems, 2);
    });

    test('does not reduce near revision counts', () async {
      await saveNearDue(ayahNumber: 6);
      await saveNearDue(ayahNumber: 7);
      await saveMemorizedDue(
        ayahNumber: 8,
        mode: ReviewRecordCreatedByMode.adultMemPlus,
      );

      final plan = await generate();
      expect(plan.nearRevision.length, greaterThanOrEqualTo(2));
      expect(plan.retentionReview, isNotEmpty);
    });

    test('retention-only day still produces a plan', () async {
      for (var ayah = 1; ayah <= 10; ayah++) {
        await saveMemorizedDue(
          ayahNumber: ayah,
          mode: ReviewRecordCreatedByMode.adultMemPlus,
        );
      }

      final plan = await generate();
      expect(plan.totalItems, 0);
      expect(plan.hasRetentionReview, isTrue);
    });
  });
}

class _SurahQuranRepository implements QuranRepository {
  _SurahQuranRepository({required this.surahId, required this.ayahCount});

  final int surahId;
  final int ayahCount;

  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int id) async => Right(
    SurahDetail(
      surah: Surah(
        id: surahId,
        nameAr: 'سورة',
        nameEn: 'Surah',
        ayahCount: ayahCount,
        juz: 1,
        type: 'meccan',
        page: 1,
      ),
      ayahs: List.generate(
        ayahCount,
        (index) => Ayah(
          number: index + 1,
          surahId: surahId,
          text: 'آية ${index + 1}',
          numberInSurah: index + 1,
          juz: 1,
          page: 1,
        ),
      ),
    ),
  );

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) =>
      throw UnimplementedError();
}
