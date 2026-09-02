import '../entities/khatmah_plan.dart';
import '../entities/khatmah_reading_result.dart';
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
    if (pageNumber < 1 || pageNumber > 604) {
      throw const KhatmahProgressException(
        'Page number must be between 1 and 604.',
      );
    }

    final coveredPlan = switch (source) {
      KhatmahReadingSource.digital => plan.recordPage(pageNumber),
      KhatmahReadingSource.physical => plan.recordThroughPage(pageNumber),
    };
    final newlyCompletedPages = coveredPlan.completedPages.difference(
      plan.completedPages,
    );
    final updatedPlan = coveredPlan.copyWith(
      lastReadDate: readAt ?? DateTime.now(),
      status: coveredPlan.isComplete ? KhatmahStatus.completed : null,
    );

    if (!updatedPlan.isComplete) {
      await _repository.updatePlan(updatedPlan);
      return KhatmahReadingResult(
        plan: updatedPlan,
        newlyCompletedPages: newlyCompletedPages,
      );
    }

    final historyEntry = await _repository.completePlan(updatedPlan);
    return KhatmahReadingResult(
      plan: updatedPlan,
      historyEntry: historyEntry,
      newlyCompletedPages: newlyCompletedPages,
    );
  }
}
