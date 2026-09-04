import '../entities/khatmah_plan.dart';
import '../repositories/khatmah_repository.dart';

class PauseResumeKhatmahUsecase {
  const PauseResumeKhatmahUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<KhatmahPlan> pause(KhatmahPlan plan, [DateTime? pausedAt]) async {
    return (await _repository.mutatePlan(
      plan,
      (current) => current.pause(at: pausedAt),
    )).plan;
  }

  Future<KhatmahPlan> resume(KhatmahPlan plan, [DateTime? fromDate]) async {
    return (await _repository.mutatePlan(
      plan,
      (current) => current.resume(fromDate: fromDate),
      requiredStatus: KhatmahStatus.paused,
    )).plan;
  }
}
