import '../repositories/khatmah_repository.dart';

class DeleteKhatmahUsecase {
  const DeleteKhatmahUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<void> call({String? expectedPlanId}) {
    return _repository.deletePlan(expectedPlanId: expectedPlanId);
  }
}
