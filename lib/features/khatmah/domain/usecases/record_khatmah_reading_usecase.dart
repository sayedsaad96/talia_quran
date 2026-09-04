import '../entities/khatmah_plan.dart';
import '../entities/khatmah_reading_result.dart';
import '../entities/khatmah_scheduling_engine.dart';
import '../repositories/khatmah_repository.dart';

class RecordKhatmahReadingUsecase {
  const RecordKhatmahReadingUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<KhatmahReadingResult> call(
    KhatmahPlan plan,
    int pageNumber, {
    required KhatmahReadingSource source,
    DateTime? readAt,
  }) async {
    if (plan.status != KhatmahStatus.active) {
      throw const KhatmahProgressException(
        'Only active Khatmah plans can record reading progress.',
      );
    }
    if (pageNumber < 1 || pageNumber > KhatmahSchedulingEngine.totalPages) {
      throw const KhatmahProgressException(
        'Page number must be between 1 and '
        '${KhatmahSchedulingEngine.totalPages}.',
      );
    }

    final readingDate = readAt ?? DateTime.now();
    final confirmedStart = plan.nextUnreadPage;
    return _repository.mutatePlan(plan, (current) {
      final anchoredPlan = current.anchorDailyTarget(readingDate);
      final coveredPlan = switch (source) {
        KhatmahReadingSource.digital => anchoredPlan.recordPage(pageNumber),
        KhatmahReadingSource.physical => anchoredPlan.copyWith(
          completedPages: {
            ...anchoredPlan.completedPages,
            for (var page = confirmedStart; page <= pageNumber; page++) page,
          },
        ),
      };
      final updatedPlan = coveredPlan.copyWith(
        lastReadDate: readingDate,
        status: coveredPlan.isComplete ? KhatmahStatus.completed : null,
      );

      return updatedPlan;
    });
  }
}
