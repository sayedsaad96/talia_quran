import '../entities/khatmah_plan.dart';
import '../entities/khatmah_reading_result.dart';
import '../repositories/khatmah_repository.dart';

/// Persists only schedule metadata from the authoritative active plan.
class UpdateKhatmahScheduleUsecase {
  const UpdateKhatmahScheduleUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<KhatmahPlan> call({
    required String planId,
    required int targetPagesPerDay,
    required int targetDays,
    required DateTime expectedEndDate,
  }) async {
    final current = await _repository.getActivePlan();
    if (current == null ||
        current.id != planId ||
        current.status != KhatmahStatus.active) {
      throw const KhatmahProgressException(
        'Only the current active Khatmah schedule can be changed.',
      );
    }
    final updated = current.copyWith(
      targetPagesPerDay: targetPagesPerDay,
      targetDays: targetDays,
      expectedEndDate: expectedEndDate,
    );
    await _repository.updatePlan(updated);
    return updated;
  }
}
