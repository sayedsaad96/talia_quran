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
  Object? get authority => _repository.authority;
  Stream<void>? get changes => _repository.changes;

  Future<void> call(KhatmahPlan plan) async {
    final existingPlan = await _repository.createPlanIfAbsent(plan);
    if (existingPlan != null) {
      throw KhatmahPlanAlreadyExistsException(existingPlan);
    }
  }
}
