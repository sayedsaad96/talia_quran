import '../entities/khatmah_plan.dart';
import '../entities/khatmah_scheduling_engine.dart';
import '../repositories/khatmah_repository.dart';

class CompleteKhatmahUsecase {
  const CompleteKhatmahUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<void> call(KhatmahPlan plan) async {
    final completedPlan = plan.copyWith(
      currentPage: KhatmahSchedulingEngine.totalPages,
      status: KhatmahStatus.completed,
    );
    await _repository.completePlan(completedPlan);
  }
}
