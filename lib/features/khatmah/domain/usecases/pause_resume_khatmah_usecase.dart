import '../entities/khatmah_plan.dart';
import '../repositories/khatmah_repository.dart';

class PauseResumeKhatmahUsecase {
  const PauseResumeKhatmahUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<KhatmahPlan> pause(KhatmahPlan plan, [DateTime? pausedAt]) async {
    final pausedPlan = plan.pause(at: pausedAt);
    await _repository.updatePlan(pausedPlan);
    return pausedPlan;
  }

  Future<KhatmahPlan> resume(KhatmahPlan plan, [DateTime? fromDate]) async {
    final resumedPlan = plan.resume(fromDate: fromDate);
    await _repository.updatePlan(resumedPlan);
    return resumedPlan;
  }
}
