import '../entities/khatmah_dedication.dart';
import '../entities/khatmah_plan.dart';
import '../repositories/khatmah_repository.dart';

/// Changes only the dedication (and the title derived from it), on an active
/// or paused plan. Progress and schedule are left untouched.
class UpdateKhatmahDedicationUsecase {
  const UpdateKhatmahDedicationUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<KhatmahPlan> call(
    KhatmahPlan plan,
    KhatmahDedication dedication,
  ) async {
    final result = await _repository.mutatePlan(
      plan,
      (current) => current.copyWith(
        dedication: dedication,
        title: KhatmahPlan.titleFor(dedication),
      ),
      requiredStatus: plan.status,
    );
    return result.plan;
  }
}
