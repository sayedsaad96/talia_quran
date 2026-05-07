import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../entities/memorization_entities.dart';

abstract class MemorizationPlusRepository {
  // ─── Track selection ────────────────────────────────────────────────────────
  Either<Failure, MemorizationTrack?> getSelectedTrack();
  Future<Either<Failure, void>> saveSelectedTrack(MemorizationTrack track);

  // ─── Daily plan ─────────────────────────────────────────────────────────────
  Future<Either<Failure, DailyPlan>> generateDailyPlan({
    required int surahId,
    required int newAyahsPerDay,
  });

  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan();
  Future<Either<Failure, void>> saveDailyPlan(DailyPlan plan);

  // ─── Review records ─────────────────────────────────────────────────────────
  Future<Either<Failure, AyahReviewRecord?>> getReviewRecord(
    int surahId,
    int ayahNumber,
  );
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords();
  Future<Either<Failure, void>> saveReviewRecord(AyahReviewRecord record);

  // ─── Evaluation ─────────────────────────────────────────────────────────────
  Future<Either<Failure, AyahReviewRecord>> evaluateAyah({
    required int surahId,
    required int ayahNumber,
    required PerformanceRating rating,
  });
  Future<Either<Failure, AyahReviewRecord>> markAyahMemorized({
    required int surahId,
    required int ayahNumber,
  });

  // ─── Kids progress ──────────────────────────────────────────────────────────
  Future<Either<Failure, KidsProgress>> getKidsProgress();
  Future<Either<Failure, void>> saveKidsProgress(KidsProgress progress);
  Future<Either<Failure, KidsProgress>> awardKidsPoints({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
  });

  // ─── Custom memorization plan ──────────────────────────────────────────────
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan();
  Future<Either<Failure, void>> saveCustomPlan(CustomMemorizationPlan plan);
  Future<Either<Failure, void>> deleteCustomPlan();
}
