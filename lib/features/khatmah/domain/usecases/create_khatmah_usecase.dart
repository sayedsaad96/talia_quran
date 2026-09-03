import '../entities/khatmah_plan.dart';
import '../repositories/khatmah_repository.dart';

class KhatmahPlanAlreadyExistsException implements Exception {
  const KhatmahPlanAlreadyExistsException(this.existingPlan);

  final KhatmahPlan existingPlan;

  @override
  String toString() =>
      'KhatmahPlanAlreadyExistsException: A ${existingPlan.status.name} Khatmah plan already exists.';
}

class CreateKhatmahUsecase {
  const CreateKhatmahUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<void> call(KhatmahPlan plan) async {
    final existingPlan = await _repository.getActivePlan();
    if (existingPlan != null &&
        (existingPlan.status == KhatmahStatus.active ||
            existingPlan.status == KhatmahStatus.paused)) {
      throw KhatmahPlanAlreadyExistsException(existingPlan);
    }

    // A completed plan must have been archived and removed. If a legacy
    // terminal plan remains in active storage, clear that stale copy before
    // allowing a genuinely new plan to be saved.
    if (existingPlan?.status == KhatmahStatus.completed) {
      await _repository.deletePlan();
    }
    await _repository.createPlan(plan);
  }
}
