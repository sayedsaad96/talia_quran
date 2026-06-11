import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/services/xp_service.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

part 'daily_plan_state.dart';

class DailyPlanCubit extends Cubit<DailyPlanState> {
  DailyPlanCubit(
    this._generateDailyPlan,
    this._getCachedPlan,
    this._evaluateUsecase,
    this._saveDailyPlan,
    this._achievementService,
    this._streakService, // RISK-5 FIX
    this._xpService, // RISK-5 FIX
    this._pathResolver,
  ) : super(const DailyPlanInitial());

  final GenerateDailyPlanUsecase _generateDailyPlan;
  final GetCachedDailyPlanUsecase _getCachedPlan;
  final EvaluateMemorizationUsecase _evaluateUsecase;
  final SaveDailyPlanUsecase _saveDailyPlan;
  final AchievementService _achievementService;
  final StreakService _streakService; // RISK-5 FIX
  final XpService _xpService; // RISK-5 FIX
  final MemorizationPathResolver _pathResolver;

  Future<void> load({required int surahId, int newAyahsPerDay = 5}) async {
    emit(const DailyPlanLoading());
    if (await _isKidsProfile()) {
      emit(const DailyPlanKidsRedirect());
      return;
    }

    // Try cache first
    final cached = await _getCachedPlan();
    final cachedPlan = cached.getOrElse(() => null);

    // Validate cache has actual Ayah text
    bool isCacheValid = false;
    if (cachedPlan != null && cachedPlan.surahId == surahId) {
      final allAyahs = [
        ...cachedPlan.newAyahs,
        ...cachedPlan.nearRevision,
        ...cachedPlan.farRevision,
        ...cachedPlan.retentionReview,
      ];
      final hasMissingText = allAyahs.any(
        (a) =>
            a.ayahText.isEmpty ||
            a.ayahText == '...' ||
            a.ayahText == 'النص غير متوفر',
      );
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
      GenerateDailyPlanParams(surahId: surahId, newAyahsPerDay: newAyahsPerDay),
    );

    result.fold(
      (f) => emit(DailyPlanError(f.message)),
      (plan) => emit(DailyPlanLoaded(plan: plan, surahId: plan.surahId)),
    );
  }

  Future<void> refresh({required int surahId, int newAyahsPerDay = 5}) async {
    emit(const DailyPlanLoading());
    if (await _isKidsProfile()) {
      emit(const DailyPlanKidsRedirect());
      return;
    }

    final result = await _generateDailyPlan(
      GenerateDailyPlanParams(surahId: surahId, newAyahsPerDay: newAyahsPerDay),
    );
    result.fold(
      (f) => emit(DailyPlanError(f.message)),
      (plan) => emit(DailyPlanLoaded(plan: plan, surahId: plan.surahId)),
    );
  }

  Future<bool> _isKidsProfile() async {
    final profile = await _pathResolver.currentProfile();
    return _pathResolver.isKids(profile);
  }

  Future<void> evaluateAyah({
    required int surahId,
    required int ayahNumber,
    required PerformanceRating rating,
  }) async {
    if (state is! DailyPlanLoaded) return;
    final current = state as DailyPlanLoaded;

    emit(
      DailyPlanEvaluating(
        plan: current.plan,
        surahId: current.surahId,
        evaluatingAyah: ayahNumber,
      ),
    );

    final result = await _evaluateUsecase(
      EvaluateMemorizationParams(
        surahId: surahId,
        ayahNumber: ayahNumber,
        rating: rating,
        createdByMode: ReviewRecordCreatedByMode.adultMemPlus,
      ),
    );

    final evaluateFailure = result.fold((f) => f, (_) => null);
    if (evaluateFailure != null) {
      emit(
        DailyPlanLoaded(
          plan: current.plan,
          surahId: current.surahId,
          actionError: evaluateFailure.message,
        ),
      );
      return;
    }

    final isSuccessfulRating = rating != PerformanceRating.weak;
    final updatedPlan = isSuccessfulRating
        ? current.plan.withCompleted(ayahNumber)
        : current.plan;

    if (isSuccessfulRating) {
      // RISK-5 FIX: record streak & XP from MemorizationPlus — same as Hifz
      try {
        await _streakService.recordActivity(activityDelta: 1);
        await _xpService.addXp('ayah_memorized');
      } catch (_) {
        // Non-critical: don't block evaluation on streak/xp failure
      }

      final saveResult = await _saveDailyPlan(updatedPlan);
      final saveFailure = saveResult.fold((f) => f, (_) => null);
      if (saveFailure != null) {
        emit(
          DailyPlanLoaded(
            plan: current.plan,
            surahId: current.surahId,
            actionError: saveFailure.message,
          ),
        );
        return;
      }
    }

    final newAwards = isSuccessfulRating
        ? await _achievementService.checkAndUnlockCertificates()
        : <CertificateAward>[];
    emit(
      DailyPlanLoaded(
        plan: updatedPlan,
        surahId: current.surahId,
        lastEvaluatedAyah: ayahNumber,
        lastRating: rating,
        newAwards: newAwards,
      ),
    );
  }
}
