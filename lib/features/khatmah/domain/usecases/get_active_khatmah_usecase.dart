import '../entities/khatmah_plan.dart';
import '../repositories/khatmah_repository.dart';

class GetActiveKhatmahUsecase {
  const GetActiveKhatmahUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<KhatmahPlan?> call() {
    return _repository.getActivePlan();
  }
}
