import '../entities/khatmah_plan.dart';
import '../repositories/khatmah_repository.dart';

class GetActiveKhatmahUsecase {
  const GetActiveKhatmahUsecase(this._repository);

  final KhatmahRepository _repository;
  Stream<void>? get changes => _repository.changes;
  Object? get authority => _repository.authority;

  Future<KhatmahPlan?> call() {
    return _repository.getActivePlan();
  }
}
