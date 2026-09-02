import '../entities/khatmah_plan.dart';
import '../repositories/khatmah_repository.dart';

/// Persists schedule-only edits. It deliberately accepts a complete plan rather
/// than a page number, so reader coverage remains owned by record-reading.
class UpdateKhatmahScheduleUsecase {
  const UpdateKhatmahScheduleUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<KhatmahPlan> call(KhatmahPlan plan) async {
    await _repository.updatePlan(plan);
    return plan;
  }
}
