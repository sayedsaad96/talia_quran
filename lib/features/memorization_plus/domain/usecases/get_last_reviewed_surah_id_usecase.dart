import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/memorization/review_record_filters.dart';
import '../../../../core/utils/usecase.dart';
import '../repositories/memorization_plus_repository.dart';

/// Returns the surah id of the most recently reviewed started ayah, if any.
class GetLastReviewedSurahIdUseCase implements UseCaseNoParams<int?> {
  const GetLastReviewedSurahIdUseCase(this._repository);

  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, int?>> call() async {
    final recordsResult = await _repository.getAllReviewRecords();
    return recordsResult.map((records) {
      final started = records
          .where(ReviewRecordFilters.isStarted)
          .where((record) => record.surahId >= 1 && record.surahId <= 114)
          .toList()
        ..sort(
          (a, b) =>
              b.lastReviewedAt.toUtc().compareTo(a.lastReviewedAt.toUtc()),
        );
      return started.isEmpty ? null : started.first.surahId;
    });
  }
}
