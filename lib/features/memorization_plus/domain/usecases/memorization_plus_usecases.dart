import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/memorization_entities.dart';
import '../repositories/memorization_plus_repository.dart';

// ─── GenerateDailyPlanUsecase ─────────────────────────────────────────────────

class GenerateDailyPlanParams {
  const GenerateDailyPlanParams({
    required this.surahId,
    this.newAyahsPerDay = 5,
  });
  final int surahId;
  final int newAyahsPerDay;
}

class GenerateDailyPlanUsecase
    implements UseCase<DailyPlan, GenerateDailyPlanParams> {
  const GenerateDailyPlanUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, DailyPlan>> call(GenerateDailyPlanParams params) =>
      _repository.generateDailyPlan(
        surahId: params.surahId,
        newAyahsPerDay: params.newAyahsPerDay,
      );
}

// ─── EvaluateMemorizationUsecase ──────────────────────────────────────────────

class EvaluateMemorizationParams {
  const EvaluateMemorizationParams({
    required this.surahId,
    required this.ayahNumber,
    required this.rating,
  });
  final int surahId;
  final int ayahNumber;
  final PerformanceRating rating;
}

class EvaluateMemorizationUsecase
    implements UseCase<AyahReviewRecord, EvaluateMemorizationParams> {
  const EvaluateMemorizationUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, AyahReviewRecord>> call(
    EvaluateMemorizationParams params,
  ) => _repository.evaluateAyah(
    surahId: params.surahId,
    ayahNumber: params.ayahNumber,
    rating: params.rating,
  );
}

// ─── MarkAyahMemorizedUsecase ────────────────────────────────────────────────

class MarkAyahMemorizedParams {
  const MarkAyahMemorizedParams({
    required this.surahId,
    required this.ayahNumber,
  });
  final int surahId;
  final int ayahNumber;
}

class MarkAyahMemorizedUsecase
    implements UseCase<AyahReviewRecord, MarkAyahMemorizedParams> {
  const MarkAyahMemorizedUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, AyahReviewRecord>> call(
    MarkAyahMemorizedParams params,
  ) => _repository.markAyahMemorized(
    surahId: params.surahId,
    ayahNumber: params.ayahNumber,
  );
}

// ─── ScheduleNextReviewUsecase ────────────────────────────────────────────────

/// Standalone scheduling logic — usable independently for testing.
class ScheduleNextReviewUsecase {
  const ScheduleNextReviewUsecase();

  AyahReviewRecord schedule(AyahReviewRecord record, PerformanceRating rating) {
    final now = DateTime.now();
    final int newStrength;
    final int newInterval;

    switch (rating) {
      case PerformanceRating.excellent:
        newStrength = (record.strengthLevel + 1).clamp(0, 10);
        // Aggressively space out: current interval * 2.5 (min 1 day)
        newInterval = record.strengthLevel == 0
            ? 1
            : (record.intervalDays * 2.5).round().clamp(1, 180);
      case PerformanceRating.average:
        newStrength = record.strengthLevel; // no change
        // Moderate spacing: current interval * 1.5
        newInterval = record.strengthLevel == 0
            ? 1
            : (record.intervalDays * 1.5).round().clamp(1, 90);
      case PerformanceRating.weak:
        newStrength = (record.strengthLevel - 1).clamp(0, 10);
        // Reset to 1 day — review tomorrow
        newInterval = 1;
    }

    return record.copyWith(
      strengthLevel: newStrength,
      intervalDays: newInterval,
      lastReviewedAt: now,
      nextReviewDate: now.add(Duration(days: newInterval)),
      totalReviews: record.totalReviews + 1,
      lastRating: rating,
    );
  }
}

// ─── GetKidsProgressUsecase ───────────────────────────────────────────────────

class GetKidsProgressUsecase implements UseCaseNoParams<KidsProgress> {
  const GetKidsProgressUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, KidsProgress>> call() => _repository.getKidsProgress();
}

// ─── AwardKidsPointsUsecase ───────────────────────────────────────────────────

class AwardKidsPointsParams {
  const AwardKidsPointsParams({
    required this.surahId,
    required this.ayahNumber,
    required this.repeatsCompleted,
  });
  final int surahId;
  final int ayahNumber;
  final int repeatsCompleted;
}

class AwardKidsPointsUsecase
    implements UseCase<KidsProgress, AwardKidsPointsParams> {
  const AwardKidsPointsUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, KidsProgress>> call(AwardKidsPointsParams params) =>
      _repository.awardKidsPoints(
        surahId: params.surahId,
        ayahNumber: params.ayahNumber,
        repeatsCompleted: params.repeatsCompleted,
      );
}

class GetCachedDailyPlanUsecase implements UseCaseNoParams<DailyPlan?> {
  const GetCachedDailyPlanUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, DailyPlan?>> call() =>
      _repository.getCachedDailyPlan();
}

// ─── GetCustomPlanUsecase ─────────────────────────────────────────────────────

class GetCustomPlanUsecase implements UseCaseNoParams<CustomMemorizationPlan?> {
  const GetCustomPlanUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> call() =>
      _repository.getCustomPlan();
}

// ─── SaveDailyPlanUsecase ─────────────────────────────────────────────────────

class SaveDailyPlanUsecase implements UseCase<void, DailyPlan> {
  const SaveDailyPlanUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, void>> call(DailyPlan plan) =>
      _repository.saveDailyPlan(plan);
}
