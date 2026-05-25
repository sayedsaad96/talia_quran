import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/quiz_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class _FakeMemorizationPlusRepository implements MemorizationPlusRepository {
  _FakeMemorizationPlusRepository(this.record);

  final AyahReviewRecord record;
  PerformanceRating? evaluatedRating;

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords() async =>
      Right([record]);

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async =>
      const Right(null);

  @override
  Future<Either<Failure, AyahReviewRecord>> evaluateAyah({
    required int surahId,
    required int ayahNumber,
    required PerformanceRating rating,
  }) async {
    evaluatedRating = rating;
    return Right(record.copyWith(lastRating: rating));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuranRepository implements QuranRepository {
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async =>
      const Right(
        SurahDetail(
          surah: Surah(
            id: 1,
            nameAr: 'الفاتحة',
            nameEn: 'Al-Fatihah',
            ayahCount: 7,
            juz: 1,
            type: 'meccan',
            page: 1,
          ),
          ayahs: [
            Ayah(
              number: 1,
              surahId: 1,
              text: 'بسم الله الرحمن الرحيم',
              numberInSurah: 1,
              juz: 1,
              page: 1,
            ),
          ],
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

void main() {
  group('QuizCubit manual rating fallback', () {
    late _FakeMemorizationPlusRepository repository;
    late _FakeQuranRepository quranRepository;
    late _FakeAchievementService achievementService;
    late QuizCubit cubit;

    final now = DateTime.utc(2026);
    late AyahReviewRecord record;

    setUp(() {
      record = AyahReviewRecord(
        surahId: 1,
        ayahNumber: 1,
        strengthLevel: 2,
        intervalDays: 1,
        lastReviewedAt: now,
        nextReviewDate: now,
        totalReviews: 1,
        lastRating: PerformanceRating.average,
      );

      repository = _FakeMemorizationPlusRepository(record);
      quranRepository = _FakeQuranRepository();
      achievementService = _FakeAchievementService();
      cubit = QuizCubit(repository, quranRepository, achievementService);
    });

    tearDown(() => cubit.close());

    test('saves manual rating through the normal evaluation path', () async {
      await cubit.loadQuiz(surahId: 1, ayahNumbers: const [1]);
      expect(cubit.state, isA<QuizQuestion>());

      await cubit.submitManualRating(PerformanceRating.average);

      final state = cubit.state;
      expect(state, isA<QuizAnswerResult>());
      final result = state as QuizAnswerResult;
      expect(result.passed, isTrue);
      expect(result.userText, 'تقييم يدوي: متوسط');
      expect(result.scorePercent, 70);
      expect(repository.evaluatedRating, PerformanceRating.average);
    });
  });
}
