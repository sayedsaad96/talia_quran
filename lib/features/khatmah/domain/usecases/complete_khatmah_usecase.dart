import '../entities/khatmah_plan.dart';
import '../entities/khatmah_reading_result.dart';
import '../repositories/khatmah_repository.dart';

class CompleteKhatmahUsecase {
  const CompleteKhatmahUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<void> call(KhatmahPlan plan) async {
    if (!plan.isComplete) {
      throw const KhatmahProgressException(
        'Every Quran page must be explicitly recorded before completion.',
      );
    }
    final completedPlan = plan.copyWith(status: KhatmahStatus.completed);
    await _repository.completePlan(completedPlan);
  }
}
