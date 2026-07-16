import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/get_last_reviewed_surah_id_usecase.dart';

void main() {
  group('GetLastReviewedSurahIdUseCase', () {
    test(
      'returns surah id of the most recently reviewed started ayah',
      () async {
        final useCase = GetLastReviewedSurahIdUseCase(
          _FakeRepository(
            records: [
              _record(
                surahId: 1,
                ayahNumber: 1,
                totalReviews: 2,
                lastReviewedAt: DateTime.utc(2026, 1, 1),
              ),
              _record(
                surahId: 2,
                ayahNumber: 5,
                totalReviews: 3,
                lastReviewedAt: DateTime.utc(2026, 6, 1),
              ),
            ],
          ),
        );

        final result = await useCase();

        expect(result, const Right(2));
      },
    );

    test('ignores never-started ayahs', () async {
      final useCase = GetLastReviewedSurahIdUseCase(
        _FakeRepository(
          records: [
            _record(
              surahId: 2,
              ayahNumber: 1,
              totalReviews: 0,
              lastReviewedAt: DateTime.utc(2026, 6, 1),
            ),
          ],
        ),
      );

      final result = await useCase();

      expect(result, const Right(null));
    });
  });
}

AyahReviewRecord _record({
  required int surahId,
  required int ayahNumber,
  required int totalReviews,
  required DateTime lastReviewedAt,
}) {
  return AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: 3,
    intervalDays: 7,
    lastReviewedAt: lastReviewedAt,
    nextReviewDate: lastReviewedAt.add(const Duration(days: 7)),
    totalReviews: totalReviews,
    lastRating: PerformanceRating.average,
    createdByMode: ReviewRecordCreatedByMode.v2Session,
  );
}

class _FakeRepository implements MemorizationPlusRepository {
  _FakeRepository({this.records = const []});

  final List<AyahReviewRecord> records;

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async =>
      Right(records);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();

  @override
  Future<bool> hasPendingCloudWork() async => false;
}
