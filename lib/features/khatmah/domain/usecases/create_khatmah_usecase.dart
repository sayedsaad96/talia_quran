import '../entities/khatmah_plan.dart';
import '../repositories/khatmah_repository.dart';

class CreateKhatmahUsecase {
  const CreateKhatmahUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<void> call(KhatmahPlan plan) {
    return _repository.createPlan(plan);
  }
}
