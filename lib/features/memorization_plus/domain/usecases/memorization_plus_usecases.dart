import 'dart:math' as math;
import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/memorization_entities.dart';
import '../repositories/memorization_plus_repository.dart';

export 'get_last_reviewed_surah_id_usecase.dart';
export 'adaptive_recommendations_usecase.dart';
export 'fsrs_agreement_usecase.dart';
export 'leech_analysis_usecase.dart';
export 'migration_readiness_usecase.dart';
export 'retention_insights_usecase.dart';
export 'review_workload_insights_usecase.dart';

// ─── ScheduleNextReviewUsecase ────────────────────────────────────────────────

/// Standalone scheduling logic — usable independently for testing.
class ScheduleNextReviewUsecase {
  const ScheduleNextReviewUsecase();

  int _applyFuzz(int interval, int ayahNumber) {
    if (interval <= 2) return interval;
    final random = math.Random(ayahNumber + interval);
    final multiplier = 0.95 + (random.nextDouble() * 0.10);
    return (interval * multiplier).round();
  }

  AyahReviewRecord schedule(
    AyahReviewRecord record,
    PerformanceRating rating, [
    DateTime? nowOverride,
  ]) {
    // UTC: all SM-2 scheduling dates must be UTC for cross-timezone consistency.
    final now = nowOverride ?? DateTime.now().toUtc();
    final int newStrength;
    int newInterval;
    double newEaseFactor = record.easeFactor;
    int newLapses = record.lapses;

    // Overdue Compensation Logic
    final actualElapsedDays = now.difference(record.lastReviewedAt).inDays;
    int effectiveBase;

    if (record.intervalDays < 14) {
      final maxAllowedBase = record.intervalDays * 2;
      effectiveBase = math.min(actualElapsedDays, maxAllowedBase);
      effectiveBase = math.max(record.intervalDays, effectiveBase);
    } else {
      effectiveBase = math.max(record.intervalDays, actualElapsedDays);
    }

    switch (rating) {
      case PerformanceRating.excellent:
        newStrength = (record.strengthLevel + 1).clamp(0, 10);
        newEaseFactor = (record.easeFactor + 0.15).clamp(1.3, 3.3);
        if (record.strengthLevel == 0) {
          newInterval = 1;
        } else {
          final int rawInterval = (effectiveBase * newEaseFactor).round();
          newInterval = _applyFuzz(
            rawInterval,
            record.ayahNumber,
          ).clamp(1, 180);
        }
      case PerformanceRating.average:
        newStrength = record.strengthLevel; // no change
        newEaseFactor = (record.easeFactor - 0.10).clamp(1.3, 3.3);
        if (record.strengthLevel == 0) {
          newInterval = 1;
        } else {
          final int rawInterval =
              (effectiveBase * math.max(1.2, newEaseFactor - 1.0)).round();
          newInterval = _applyFuzz(rawInterval, record.ayahNumber).clamp(1, 90);
        }
      case PerformanceRating.weak:
        newStrength = (record.strengthLevel - 1).clamp(0, 10);
        newEaseFactor = (record.easeFactor - 0.20).clamp(1.3, 3.3);
        newLapses = record.lapses + 1;
        // Soft lapse based on interval size (Overdue compensation not applied to weak)
        newInterval = record.intervalDays <= 7
            ? math.max(1, (record.intervalDays * 0.5).round())
            : math.max(3, (record.intervalDays * 0.3).round());
    }

    return record.copyWith(
      strengthLevel: newStrength,
      intervalDays: newInterval,
      lastReviewedAt: now,
      nextReviewDate: now.add(Duration(days: newInterval)),
      totalReviews: record.totalReviews + 1,
      lastRating: rating,
      easeFactor: newEaseFactor,
      lapses: newLapses,
    );
  }
}

// ─── FsrsStateTrackerUsecase (V3.3 Preparation) ──────────────────────────────

/// Passive FSRS state tracking — **not on the production write path** (D4).
///
/// Production scheduling is SM-2 via [ScheduleNextReviewUsecase] in
/// `V2SessionReviewAdapter`. Kept for unit tests / future shadow analytics;
/// do not register in DI or call from `saveReviewRecord` until product signs off.
class FsrsStateTrackerUsecase {
  const FsrsStateTrackerUsecase();

  AyahReviewRecord update(
    AyahReviewRecord record,
    PerformanceRating rating, [
    DateTime? nowOverride,
  ]) {
    final now = nowOverride ?? DateTime.now().toUtc();

    // Difficulty Tracking
    double newDifficulty = record.difficulty;
    if (rating == PerformanceRating.excellent) {
      newDifficulty -= 0.05;
    } else if (rating == PerformanceRating.weak) {
      newDifficulty += 0.10;
    }
    newDifficulty = newDifficulty.clamp(1.0, 10.0);

    // Stability Tracking (Using actual elapsed days)
    final actualElapsedDays = math.max(
      0,
      now.difference(record.lastReviewedAt).inDays,
    );
    double newStability = record.stability;

    if (rating == PerformanceRating.excellent) {
      newStability += actualElapsedDays;
    } else if (rating == PerformanceRating.average) {
      newStability += actualElapsedDays * 0.5;
    } else if (rating == PerformanceRating.weak) {
      newStability *= 0.5;
    }
    if (newStability < 0) newStability = 0.0;

    // Review State Tracking
    ReviewState newState = record.reviewState;
    switch (record.reviewState) {
      case ReviewState.newCard:
        newState = ReviewState.learning;
      case ReviewState.learning:
        newState = rating == PerformanceRating.weak
            ? ReviewState.learning
            : ReviewState.review;
      case ReviewState.review:
        newState = rating == PerformanceRating.weak
            ? ReviewState.relearning
            : ReviewState.review;
      case ReviewState.relearning:
        newState = rating == PerformanceRating.weak
            ? ReviewState.relearning
            : ReviewState.review;
    }

    return record.copyWith(
      difficulty: newDifficulty,
      stability: newStability,
      reviewState: newState,
    );
  }
}

// ─── FsrsPredictionUsecase (V3.4 Shadow Mode) ────────────────────────────────

/// FSRS shadow predictions — **analytics only** (D4). Never chained before
/// `saveReviewRecord`; production intervals come from SM-2 only.
class FsrsPredictionUsecase {
  const FsrsPredictionUsecase();

  AyahReviewRecord predict(
    AyahReviewRecord record,
    int actualElapsedDays, [
    DateTime? nowOverride,
  ]) {
    final now = nowOverride ?? DateTime.now().toUtc();

    // Retrievability Prediction
    final retrievability = math
        .exp(-(actualElapsedDays / math.max(record.stability, 1.0)))
        .clamp(0.0, 1.0);

    // Interval Prediction
    final predictedInterval = (record.stability * (11 - record.difficulty) / 5)
        .round()
        .clamp(1, 365);

    final predictedDueDate = now.add(Duration(days: predictedInterval));

    return record.copyWith(
      predictedRetrievability: retrievability,
      predictedFsrsIntervalDays: predictedInterval,
      predictedFsrsDueDate: predictedDueDate,
      predictedRecallProbability: retrievability, // Shadow field for future V4
    );
  }
}

// ─── FsrsComparisonUsecase (V3.5 Analytics) ───────────────────────────────────

/// Compares FSRS shadow predictions against the V3.2 Scheduler
class FsrsComparisonUsecase {
  const FsrsComparisonUsecase();

  AyahReviewRecord compare(AyahReviewRecord record) {
    final predictedFsrs = record.predictedFsrsIntervalDays ?? 1;

    final gap = predictedFsrs - record.intervalDays;
    final rawRatio = predictedFsrs / math.max(record.intervalDays, 1);
    final clampedRatio = rawRatio.clamp(0.0, 100.0);
    final earlier = record.intervalDays < predictedFsrs;

    return record.copyWith(
      schedulerVsFsrsGapDays: gap,
      schedulerVsFsrsRatio: clampedRatio,
      schedulerEarlierThanFsrs: earlier,
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
    this.sessionId,
    required this.surahId,
    required this.ayahNumber,
    required this.repeatsCompleted,
    this.missionType = KidsMissionType.newMemorization,
    this.ayahNumbers = const [],
    this.durationSeconds = 0,
    this.attemptCount = 1,
    this.hintCount = 0,
    this.masteryRating = PerformanceRating.excellent,
  });
  final String? sessionId;
  final int surahId;
  final int ayahNumber;
  final int repeatsCompleted;
  final KidsMissionType missionType;
  final List<int> ayahNumbers;
  final int durationSeconds;
  final int attemptCount;
  final int hintCount;
  final PerformanceRating masteryRating;
}

class AwardKidsPointsUsecase
    implements UseCase<KidsCompletionResult, AwardKidsPointsParams> {
  const AwardKidsPointsUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, KidsCompletionResult>> call(
    AwardKidsPointsParams params,
  ) => _repository.awardKidsPoints(
    sessionId: params.sessionId,
    surahId: params.surahId,
    ayahNumber: params.ayahNumber,
    repeatsCompleted: params.repeatsCompleted,
    missionType: params.missionType,
    ayahNumbers: params.ayahNumbers,
    durationSeconds: params.durationSeconds,
    attemptCount: params.attemptCount,
    hintCount: params.hintCount,
    masteryRating: params.masteryRating,
  );
}

class GetKidsJourneyParams {
  const GetKidsJourneyParams({required this.surahId});
  final int surahId;
}

class GetKidsJourneyUsecase
    implements UseCase<List<KidsJourneyStage>, GetKidsJourneyParams> {
  const GetKidsJourneyUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, List<KidsJourneyStage>>> call(
    GetKidsJourneyParams params,
  ) => _repository.getKidsJourney(surahId: params.surahId);
}

class SaveKidsSessionLogParams {
  const SaveKidsSessionLogParams({
    this.sessionId,
    required this.surahId,
    required this.ayahNumber,
    required this.repeatsCompleted,
    required this.pointsEarned,
    this.missionType = KidsMissionType.newMemorization,
    this.ayahNumbers = const [],
    this.durationSeconds = 0,
    this.attemptCount = 1,
    this.hintCount = 0,
    this.masteryRating = PerformanceRating.excellent,
  });
  final String? sessionId;
  final int surahId;
  final int ayahNumber;
  final int repeatsCompleted;
  final int pointsEarned;
  final KidsMissionType missionType;
  final List<int> ayahNumbers;
  final int durationSeconds;
  final int attemptCount;
  final int hintCount;
  final PerformanceRating masteryRating;
}

class SaveKidsSessionLogUsecase
    implements UseCase<KidsSessionLog, SaveKidsSessionLogParams> {
  const SaveKidsSessionLogUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, KidsSessionLog>> call(
    SaveKidsSessionLogParams params,
  ) => _repository.saveKidsSessionLog(
    sessionId: params.sessionId,
    surahId: params.surahId,
    ayahNumber: params.ayahNumber,
    repeatsCompleted: params.repeatsCompleted,
    pointsEarned: params.pointsEarned,
    missionType: params.missionType,
    ayahNumbers: params.ayahNumbers,
    durationSeconds: params.durationSeconds,
    attemptCount: params.attemptCount,
    hintCount: params.hintCount,
    masteryRating: params.masteryRating,
  );
}

class GetParentDashboardParams {
  const GetParentDashboardParams({required this.surahId});
  final int surahId;
}

class GetParentDashboardUsecase
    implements UseCase<ParentDashboard, GetParentDashboardParams> {
  const GetParentDashboardUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, ParentDashboard>> call(
    GetParentDashboardParams params,
  ) => _repository.getParentDashboard(surahId: params.surahId);
}

class ParentAccessUsecase {
  const ParentAccessUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  Future<Either<Failure, ParentSettings>> getSettings() =>
      _repository.getParentSettings();

  Future<Either<Failure, void>> saveSettings(ParentSettings settings) =>
      _repository.saveParentSettings(settings);

  Future<Either<Failure, bool>> verifyPin(String pin) =>
      _repository.verifyParentPin(pin);

  Future<Either<Failure, void>> setPin(String pin) =>
      _repository.setParentPin(pin);

  Future<Either<Failure, void>> reset() => _repository.resetParentAccess();

  Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(
    bool value,
  ) => _repository.setParentGuardianMode(value);

  Future<Either<Failure, List<ParentReward>>> saveReward(String title) =>
      _repository.saveParentReward(title);

  Future<Either<Failure, List<ParentReward>>> claimReward(String id) =>
      _repository.claimParentReward(id);
}

class ParentRemoteLinkUsecase {
  const ParentRemoteLinkUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  Future<Either<Failure, String>> createChildLinkToken() =>
      _repository.createChildLinkToken();

  Future<Either<Failure, void>> acceptChildLinkToken(String token) =>
      _repository.acceptChildLinkToken(token);

  Future<Either<Failure, MemorizationProfile>> acceptGuardianPairingCode(
    String token,
  ) => _repository.acceptGuardianPairingCode(token);

  Future<Either<Failure, void>> syncKidsProgressToCloud() =>
      _repository.syncKidsProgressToCloud();

  Future<Either<Failure, List<RemoteChildSummary>>> getRemoteChildren() =>
      _repository.getRemoteChildren();

  Future<Either<Failure, List<ParentReward>>> saveRemoteReward({
    required String childUserId,
    required String title,
  }) => _repository.saveRemoteParentReward(
    childUserId: childUserId,
    title: title,
  );

  /// Parent-initiated unlink: revokes the guardian link server-side so the
  /// child no longer appears in the parent's dashboard nor the parent in the
  /// child's guardian status.
  Future<Either<Failure, void>> removeChild(String childUserId) =>
      _repository.removeChild(childUserId);
}

// ─── GetCustomPlanUsecase ─────────────────────────────────────────────────────

class GetCustomPlanUsecase implements UseCaseNoParams<CustomMemorizationPlan?> {
  const GetCustomPlanUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> call() =>
      _repository.getCustomPlan();
}

class MarkDailyPlanAyahCompletedParams {
  const MarkDailyPlanAyahCompletedParams({
    required this.surahId,
    required this.ayahNumber,
  });

  final int surahId;
  final int ayahNumber;
}

/// Persists completion for an ayah in today's cached daily plan (B1).
class MarkDailyPlanAyahCompletedUsecase
    implements UseCase<bool, MarkDailyPlanAyahCompletedParams> {
  const MarkDailyPlanAyahCompletedUsecase(this._repository);

  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, bool>> call(MarkDailyPlanAyahCompletedParams params) =>
      _repository.markDailyPlanAyahCompleted(
        surahId: params.surahId,
        ayahNumber: params.ayahNumber,
      );
}

// ─── GetFamilyDashboardUsecase ────────────────────────────────────────────────

class GetFamilyDashboardUsecase implements UseCaseNoParams<FamilyDashboard> {
  const GetFamilyDashboardUsecase(this._repository);
  final MemorizationPlusRepository _repository;

  @override
  Future<Either<Failure, FamilyDashboard>> call() =>
      _repository.getFamilyDashboard();
}
