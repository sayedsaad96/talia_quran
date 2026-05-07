import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../features/quran/domain/repositories/quran_repository.dart';
import '../../../../features/quran/domain/entities/quran_entities.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';
import '../datasources/memorization_plus_local_datasource.dart';
import '../models/memorization_models.dart';

class MemorizationPlusRepositoryImpl implements MemorizationPlusRepository {
  MemorizationPlusRepositoryImpl(this._datasource, this._quranRepository);

  final MemorizationPlusLocalDatasource _datasource;

  /// For surah ayah counts
  final QuranRepository _quranRepository;

  final _scheduler = const ScheduleNextReviewUsecase();

  // ─── Track ──────────────────────────────────────────────────────────────────
  @override
  Either<Failure, MemorizationTrack?> getSelectedTrack() {
    try {
      final raw = _datasource.getSelectedTrack();
      if (raw == null) return const Right(null);
      final track = MemorizationTrack.values.firstWhere(
        (t) => t.name == raw,
        orElse: () => MemorizationTrack.adults,
      );
      return Right(track);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveSelectedTrack(
    MemorizationTrack track,
  ) async {
    try {
      await _datasource.saveSelectedTrack(track.name);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Daily plan ─────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, DailyPlan>> generateDailyPlan({
    required int surahId,
    required int newAyahsPerDay,
  }) async {
    try {
      final allRecords = await _datasource.getAllReviewRecords();

      int currentSurahId = surahId;
      DailyPlan? bestPlan;

      while (currentSurahId <= 114) {
        final surahRecords = {
          for (final r in allRecords.where((r) => r.surahId == currentSurahId))
            r.ayahNumber: r,
        };

        int totalAyahs = 7; // fallback
        List<Ayah> ayahs = [];
        final surahResult = await _quranRepository.getSurahDetail(
          currentSurahId,
        );
        surahResult.fold((_) {}, (detail) {
          totalAyahs = detail.surah.ayahCount;
          ayahs = detail.ayahs;
        });

        final List<DailyPlanAyah> newAyahs = [];
        final List<DailyPlanAyah> nearRevision = [];
        final List<DailyPlanAyah> farRevision = [];

        for (int i = 1; i <= totalAyahs; i++) {
          final record = surahRecords[i];

          String ayahText = 'النص غير متوفر';
          try {
            ayahText = ayahs.firstWhere((a) => a.numberInSurah == i).text;
          } catch (_) {}

          if (record == null || record.isNew) {
            if (newAyahs.length < newAyahsPerDay) {
              newAyahs.add(
                DailyPlanAyah(
                  surahId: currentSurahId,
                  ayahNumber: i,
                  ayahText: ayahText,
                  record: record,
                ),
              );
            }
          } else if (record.isDue) {
            final planAyah = DailyPlanAyah(
              surahId: currentSurahId,
              ayahNumber: i,
              ayahText: ayahText,
              record: record,
            );
            if (record.isNearRevision) {
              nearRevision.add(planAyah);
            } else if (record.isFarRevision) {
              farRevision.add(planAyah);
            }
          }
        }

        bestPlan = DailyPlan(
          generatedAt: DateTime.now(),
          surahId: currentSurahId,
          newAyahs: newAyahs,
          nearRevision: nearRevision,
          farRevision: farRevision,
          completedAyahNums: const [],
        );

        if (bestPlan.totalItems > 0) {
          break; // Found active items
        }

        currentSurahId++;
      }

      bestPlan ??= DailyPlan(
        generatedAt: DateTime.now(),
        surahId: 114,
        newAyahs: const [],
        nearRevision: const [],
        farRevision: const [],
        completedAyahNums: const [],
      );

      // Cache the plan
      await _datasource.saveDailyPlan(DailyPlanModel.fromEntity(bestPlan));

      return Right(bestPlan);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async {
    try {
      final cached = await _datasource.getCachedDailyPlan();
      if (cached == null) return const Right(null);

      // If plan is from a previous day, treat as stale
      final today = DateTime.now();
      final sameDay =
          cached.generatedAt.year == today.year &&
          cached.generatedAt.month == today.month &&
          cached.generatedAt.day == today.day;

      return Right(sameDay ? cached : null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveDailyPlan(DailyPlan plan) async {
    try {
      await _datasource.saveDailyPlan(DailyPlanModel.fromEntity(plan));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Review records ─────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, AyahReviewRecord?>> getReviewRecord(
    int surahId,
    int ayahNumber,
  ) async {
    try {
      final record = await _datasource.getReviewRecord(surahId, ayahNumber);
      return Right(record);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords() async {
    try {
      final records = await _datasource.getAllReviewRecords();
      return Right(records);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveReviewRecord(
    AyahReviewRecord record,
  ) async {
    try {
      await _datasource.saveReviewRecord(
        AyahReviewRecordModel.fromEntity(record),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Evaluation ─────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, AyahReviewRecord>> evaluateAyah({
    required int surahId,
    required int ayahNumber,
    required PerformanceRating rating,
  }) async {
    try {
      final existing = await _datasource.getReviewRecord(surahId, ayahNumber);

      final current =
          existing ?? AyahReviewRecordModel.initial(surahId, ayahNumber);

      final updated = _scheduler.schedule(current, rating);
      await _datasource.saveReviewRecord(
        AyahReviewRecordModel.fromEntity(updated),
      );

      return Right(updated);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AyahReviewRecord>> markAyahMemorized({
    required int surahId,
    required int ayahNumber,
  }) async {
    try {
      final existing = await _datasource.getReviewRecord(surahId, ayahNumber);
      final current =
          existing ?? AyahReviewRecordModel.initial(surahId, ayahNumber);
      final now = DateTime.now();
      final intervalDays = current.intervalDays < 30
          ? 30
          : current.intervalDays;

      final updated = current.copyWith(
        strengthLevel: current.strengthLevel < 6 ? 6 : current.strengthLevel,
        intervalDays: intervalDays,
        lastReviewedAt: now,
        nextReviewDate: now.add(Duration(days: intervalDays)),
        totalReviews: current.totalReviews + 1,
        lastRating: PerformanceRating.excellent,
      );

      await _datasource.saveReviewRecord(
        AyahReviewRecordModel.fromEntity(updated),
      );
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Kids progress ───────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, KidsProgress>> getKidsProgress() async {
    try {
      final progress = await _datasource.getKidsProgress();
      return Right(progress);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveKidsProgress(KidsProgress progress) async {
    try {
      await _datasource.saveKidsProgress(
        KidsProgressModel.fromEntity(progress),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, KidsProgress>> awardKidsPoints({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
  }) async {
    try {
      final current = await _datasource.getKidsProgress();
      // Points: 10 base + 2 per extra repeat
      final points = 10 + ((repeatsCompleted - 1) * 2).clamp(0, 20);
      final updated = current.addPoints(points);
      await _datasource.saveKidsProgress(KidsProgressModel.fromEntity(updated));
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Custom memorization plan ──────────────────────────────────────────────

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async {
    try {
      final plan = await _datasource.getCustomPlan();
      return Right(plan);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveCustomPlan(
    CustomMemorizationPlan plan,
  ) async {
    try {
      await _datasource.saveCustomPlan(
        CustomMemorizationPlanModel.fromEntity(plan),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomPlan() async {
    try {
      await _datasource.deleteCustomPlan();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
