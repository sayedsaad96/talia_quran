import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/quiz_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeRepo implements MemorizationPlusRepository {
  _FakeRepo(this.records);
  final List<AyahReviewRecord> records;

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords() async =>
      Right(records);

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async =>
      const Right(null);

  @override
  Future<Either<Failure, AyahReviewRecord>> evaluateAyah({
    required int surahId,
    required int ayahNumber,
    required PerformanceRating rating,
    ReviewRecordCreatedByMode createdByMode =
        ReviewRecordCreatedByMode.adultMemPlus,
  }) async => Right(
    _record(surahId, ayahNumber, ReviewRecordCreatedByMode.adultMemPlus),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuranRepo implements QuranRepository {
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async =>
      Right(
        SurahDetail(
          surah: Surah(
            id: surahId,
            nameAr: 'الفاتحة',
            nameEn: 'Al-Fatihah',
            ayahCount: 7,
            juz: 1,
            type: 'meccan',
            page: 1,
          ),
          ayahs: List.generate(
            7,
            (i) => Ayah(
              number: i + 1,
              surahId: surahId,
              text: 'آية ${i + 1}',
              numberInSurah: i + 1,
              juz: 1,
              page: 1,
            ),
          ),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAchievementService implements AchievementService {
  @override
  Future<List<CertificateAward>> checkAndUnlockCertificates() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── Helpers ────────────────────────────────────────────────────────────────────

AyahReviewRecord _record(
  int surahId,
  int ayahNumber,
  ReviewRecordCreatedByMode mode, {
  int totalReviews = 2,
  int strengthLevel = 3,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel,
    intervalDays: 7,
    lastReviewedAt: now.subtract(const Duration(days: 2)),
    nextReviewDate: now.subtract(const Duration(hours: 1)),
    totalReviews: totalReviews,
    lastRating: PerformanceRating.average,
    createdByMode: mode,
  );
}

QuizCubit _cubit(List<AyahReviewRecord> records) =>
    QuizCubit(_FakeRepo(records), _FakeQuranRepo(), _FakeAchievementService());

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('QuizCubit — Sprint 8B source filtering', () {
    tearDown(() {});

    // ── Sources that must be included ─────────────────────────────────────

    test('adultMemPlus record is eligible for quiz', () async {
      final cubit = _cubit([
        _record(1, 1, ReviewRecordCreatedByMode.adultMemPlus),
      ]);
      await cubit.loadQuiz(surahId: 1);
      expect(cubit.state, isA<QuizQuestion>());
      await cubit.close();
    });

    test('unknown record is eligible for quiz (backward compat)', () async {
      final cubit = _cubit([_record(1, 1, ReviewRecordCreatedByMode.unknown)]);
      await cubit.loadQuiz(surahId: 1);
      expect(cubit.state, isA<QuizQuestion>());
      await cubit.close();
    });

    test('migration record is eligible for quiz (backward compat)', () async {
      final cubit = _cubit([
        _record(1, 1, ReviewRecordCreatedByMode.migration),
      ]);
      await cubit.loadQuiz(surahId: 1);
      expect(cubit.state, isA<QuizQuestion>());
      await cubit.close();
    });

    // ── Sources that must be excluded ─────────────────────────────────────

    test('kidsMode record is NOT eligible for adult quiz', () async {
      final cubit = _cubit([_record(1, 1, ReviewRecordCreatedByMode.kidsMode)]);
      // With no eligible records, quiz should fail to load (no question state).
      await cubit.loadQuiz(surahId: 1);
      // State will not be QuizQuestion because the only record is filtered out.
      expect(cubit.state, isNot(isA<QuizQuestion>()));
      await cubit.close();
    });

    test('hifz record is NOT eligible for adult quiz', () async {
      final cubit = _cubit([_record(1, 1, ReviewRecordCreatedByMode.hifz)]);
      await cubit.loadQuiz(surahId: 1);
      expect(cubit.state, isNot(isA<QuizQuestion>()));
      await cubit.close();
    });

    // ── Mixed sources — only eligible records remain ───────────────────────

    test('kidsMode record does not shadow adultMemPlus in same surah', () async {
      // Same surah: ayah 1 is kidsMode, ayah 2 is adultMemPlus.
      // Only ayah 2 should be eligible.
      final cubit = _cubit([
        _record(1, 1, ReviewRecordCreatedByMode.kidsMode),
        _record(1, 2, ReviewRecordCreatedByMode.adultMemPlus),
      ]);
      await cubit.loadQuiz(surahId: 1);
      // adultMemPlus record is present — quiz loads.
      expect(cubit.state, isA<QuizQuestion>());
      final state = cubit.state as QuizQuestion;
      // The first question must be the adult-compatible ayah, not the kids one.
      expect(state.ayahNumber, 2);
      await cubit.close();
    });

    // ── Explicit ayahNumbers route ─────────────────────────────────────────

    test('explicit ayahNumbers route limits quiz to specified ayah', () async {
      final cubit = _cubit([
        _record(1, 1, ReviewRecordCreatedByMode.adultMemPlus),
        _record(1, 2, ReviewRecordCreatedByMode.adultMemPlus),
      ]);
      await cubit.loadQuiz(surahId: 1, ayahNumbers: const [2]);
      // Only ayah 2 specified — quiz starts on ayah 2.
      expect(cubit.state, isA<QuizQuestion>());
      final state = cubit.state as QuizQuestion;
      expect(state.ayahNumber, 2);
      await cubit.close();
    });

    test(
      'explicit ayahNumbers from Smart Coach still works with kidsMode records present',
      () async {
        // adultMemPlus ayah 3 forced via explicit ayahNumbers.
        // kidsMode ayah 1 is also in the store — must not interfere.
        final cubit = _cubit([
          _record(1, 1, ReviewRecordCreatedByMode.kidsMode),
          _record(1, 3, ReviewRecordCreatedByMode.adultMemPlus),
        ]);
        // Smart Coach passes explicit ayah number — must work.
        await cubit.loadQuiz(surahId: 1, ayahNumbers: const [3]);
        expect(cubit.state, isA<QuizQuestion>());
        final state = cubit.state as QuizQuestion;
        expect(state.ayahNumber, 3);
        await cubit.close();
      },
    );

    // ── totalReviews = 0 still excluded ──────────────────────────────────

    test(
      'adultMemPlus record with totalReviews 0 is still excluded (pre-existing behavior)',
      () async {
        final cubit = _cubit([
          _record(
            1,
            1,
            ReviewRecordCreatedByMode.adultMemPlus,
            totalReviews: 0,
          ),
        ]);
        await cubit.loadQuiz(surahId: 1);
        expect(cubit.state, isNot(isA<QuizQuestion>()));
        await cubit.close();
      },
    );
  });
}
