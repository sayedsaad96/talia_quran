import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

part 'daily_plan_state.dart';

class DailyPlanCubit extends Cubit<DailyPlanState> {
  DailyPlanCubit(
    this._generateDailyPlan,
    this._getCachedPlan,
    this._evaluateUsecase,
    this._repository,
  ) : super(const DailyPlanInitial());

  final GenerateDailyPlanUsecase _generateDailyPlan;
  final GetCachedDailyPlanUsecase _getCachedPlan;
  final EvaluateMemorizationUsecase _evaluateUsecase;
  final MemorizationPlusRepository _repository;

  Future<void> load({required int surahId, int newAyahsPerDay = 5}) async {
    emit(const DailyPlanLoading());

    // Try cache first
    final cached = await _getCachedPlan();
    final cachedPlan = cached.getOrElse(() => null);
    
    // Validate cache has actual Ayah text
    bool isCacheValid = false;
    if (cachedPlan != null && cachedPlan.surahId == surahId) {
      final allAyahs = [
        ...cachedPlan.newAyahs, ...cachedPlan.nearRevision, ...cachedPlan.farRevision
      ];
      final hasMissingText = allAyahs.any((a) => a.ayahText.isEmpty || a.ayahText == '...' || a.ayahText == 'النص غير متوفر');
      if (!hasMissingText) {
        isCacheValid = true;
      }
    }

    if (isCacheValid) {
      emit(DailyPlanLoaded(plan: cachedPlan!, surahId: surahId));
      return;
    }

    // Generate fresh plan
    final result = await _generateDailyPlan(
      GenerateDailyPlanParams(
        surahId: surahId,
        newAyahsPerDay: newAyahsPerDay,
      ),
    );

    result.fold(
      (f) => emit(DailyPlanError(f.message)),
      (plan) => emit(DailyPlanLoaded(plan: plan, surahId: plan.surahId)),
    );
  }

  Future<void> refresh({required int surahId, int newAyahsPerDay = 5}) async {
    emit(const DailyPlanLoading());
    final result = await _generateDailyPlan(
      GenerateDailyPlanParams(
        surahId: surahId,
        newAyahsPerDay: newAyahsPerDay,
      ),
    );
    result.fold(
      (f) => emit(DailyPlanError(f.message)),
      (plan) => emit(DailyPlanLoaded(plan: plan, surahId: plan.surahId)),
    );
  }

  Future<void> evaluateAyah({
    required int surahId,
    required int ayahNumber,
    required PerformanceRating rating,
  }) async {
    if (state is! DailyPlanLoaded) return;
    final current = state as DailyPlanLoaded;

    emit(DailyPlanEvaluating(
      plan: current.plan,
      surahId: current.surahId,
      evaluatingAyah: ayahNumber,
    ));

    final result = await _evaluateUsecase(EvaluateMemorizationParams(
      surahId: surahId,
      ayahNumber: ayahNumber,
      rating: rating,
    ));

    result.fold(
      (f) => emit(DailyPlanLoaded(plan: current.plan, surahId: current.surahId)),
      (updatedRecord) {
        final updatedPlan = current.plan.withCompleted(ayahNumber);
        // Persist the updated plan
        _repository.saveDailyPlan(updatedPlan);
        emit(DailyPlanLoaded(
          plan: updatedPlan,
          surahId: current.surahId,
          lastEvaluatedAyah: ayahNumber,
          lastRating: rating,
        ));
      },
    );
  }
}
