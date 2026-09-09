import '../entities/khatmah_plan.dart';
import '../entities/khatmah_reading_result.dart';
import '../entities/khatmah_scheduling_engine.dart';
import '../repositories/khatmah_repository.dart';
import '../../../../core/services/activity_event_recorder.dart';
import '../../../home/domain/entities/activity_event.dart';

class RecordKhatmahReadingUsecase {
  const RecordKhatmahReadingUsecase(
    this._repository, [
    this._activityRecorder,
  ]);

  final KhatmahRepository _repository;
  final ActivityEventRecorder? _activityRecorder;

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
    final result = await _repository.mutatePlan(plan, (current) {
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
    for (final page in result.newlyCompletedPages) {
      await _activityRecorder?.record(
        ActivityEvent(
          occurredAt: readingDate,
          kind: ActivityEventKind.khatmah,
          idempotencyKey:
              'khatmah|${ActivityEventRecorder.dayKey(readingDate)}|$page',
          pageNumber: page,
        ),
      );
    }
    return result;
  }
}
