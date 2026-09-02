import '../entities/khatmah_plan.dart';
import '../repositories/khatmah_repository.dart';

class UpdateKhatmahProgressUsecase {
  const UpdateKhatmahProgressUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<KhatmahPlan> call(
    KhatmahPlan plan,
    int pageNumber, [
    DateTime? lastReadDate,
  ]) async {
    final updatedPlan = plan.copyWith(
      currentPage: pageNumber,
      lastReadDate: lastReadDate ?? DateTime.now(),
    );
    await _repository.updatePlan(updatedPlan);
    return updatedPlan;
  }
}
