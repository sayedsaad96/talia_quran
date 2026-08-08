import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/error/app_failure.dart';
import '../../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../../core/memorization/review_record_filters.dart';
import '../../../../../core/progress/progress_changed_reason.dart';
import '../../../../../core/progress/progress_events_bus.dart';
import '../../../../quran/domain/entities/quran_entities.dart';
import '../../../../quran/domain/repositories/quran_repository.dart';
import '../../../domain/entities/memorization_entities.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import '../../models/memorization_models.dart';
import 'memorization_production_sync_service.dart';

/// Daily-plan domain: generates today's memorization plan (direction-aware,
/// custom-plan aware), serves the cached plan with same-day staleness handling,
/// persists plan saves/reads and marks individual ayahs completed.
class MemorizationDailyPlanService {
  MemorizationDailyPlanService(
    this._datasource,
    this._quranRepository,
    this._prefs,
    this._progressEvents,
  );

  final MemorizationPlusLocalDatasource _datasource;
  final QuranRepository _quranRepository;
  final SharedPreferences _prefs;
  final ProgressEventsBus _progressEvents;

  static const _retentionReviewLimit = 3;

  /// Builds today's plan and persists it to the local cache.
  Future<Either<Failure, DailyPlan>> generateDailyPlan({
    required int surahId,
    required int newAyahsPerDay,
  }) async {
    try {
      final allRecords = (await _datasource.getAllReviewRecords(
        scope: ReviewRecordReadScope.adult,
      ))
          .where(ReviewRecordFilters.isAdultCompatible)
          .toList();

      // BUG-7 FIX: Read custom plan settings and apply them
      final customPlan = await _datasource.getCustomPlan();
      final effectiveNewPerDay = customPlan?.newAyahsPerDay ?? newAyahsPerDay;
      final nearRevisionLimit = customPlan?.nearRevisionCount ?? 10;
      final farRevisionLimit = customPlan?.farRevisionCount ?? 5;

      // Direction-aware memorization:
      //   startSurahId = where memorization BEGINS  (the "من" surah)
      //   endSurahId   = where memorization ENDS    (the "إلى" surah)
      //
      //   If startSurahId <= endSurahId → ASCENDING  (e.g. Al-Fatiha 1 → An-Nas 114)
      //   If startSurahId >  endSurahId → DESCENDING (e.g. An-Nas 114 → An-Naba 78)
      final planStartSurahId = customPlan?.startSurahId ?? surahId;
      final planEndSurahId = customPlan?.endSurahId ?? planStartSurahId;
      final isDescending = planStartSurahId > planEndSurahId;

      // Honour a cached/caller surahId as a resume point if it lies within range.
      int currentSurahId = planStartSurahId;
      final lo = isDescending ? planEndSurahId : planStartSurahId;
      final hi = isDescending ? planStartSurahId : planEndSurahId;
      if (surahId >= lo && surahId <= hi && surahId != planStartSurahId) {
        currentSurahId = surahId;
      }

      DailyPlan? bestPlan;

      // Direction-aware loop
      while (isDescending
          ? currentSurahId >= planEndSurahId
          : currentSurahId <= planEndSurahId) {
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
        final List<DailyPlanAyah> retentionReview = [];

        // startAyah applies only to the first surah in the memorization order
        // (i.e. startSurahId itself), not to any other surah in the range.
        final firstAyah =
            customPlan != null && currentSurahId == customPlan.startSurahId
            ? customPlan.startAyah.clamp(1, totalAyahs)
            : 1;

        for (int i = firstAyah; i <= totalAyahs; i++) {
          final record = surahRecords[i];

          String ayahText = 'النص غير متوفر';
          try {
            ayahText = ayahs.firstWhere((a) => a.numberInSurah == i).text;
          } catch (_) {}

          if (record == null || record.isNew) {
            if (newAyahs.length < effectiveNewPerDay) {
              newAyahs.add(
                DailyPlanAyah(
                  surahId: currentSurahId,
                  ayahNumber: i,
                  ayahText: ayahText,
                  record: record,
                ),
              );
            }
          } else {
            final classification = record.reviewClassification;
            if (!classification.isDue) continue;
            final planAyah = DailyPlanAyah(
              surahId: currentSurahId,
              ayahNumber: i,
              ayahText: ayahText,
              record: record,
            );
            // BUG-7 FIX: apply custom plan revision limits
            if (customPlan?.enableNearRevision != false &&
                classification.isNearRevision &&
                nearRevision.length < nearRevisionLimit) {
              nearRevision.add(planAyah);
            } else if (customPlan?.enableFarRevision != false &&
                classification.isFarRevision &&
                farRevision.length < farRevisionLimit) {
              farRevision.add(planAyah);
            }
          }
        }

        final retentionCandidates =
            surahRecords.values
                .where(ReviewRecordFilters.isDailyPlanRetentionEligible)
                .toList()
              ..sort(ReviewRecordFilters.compareMemorizedDue);
        for (final record in retentionCandidates.take(_retentionReviewLimit)) {
          String ayahText = 'النص غير متوفر';
          try {
            ayahText = ayahs
                .firstWhere((a) => a.numberInSurah == record.ayahNumber)
                .text;
          } catch (_) {}
          retentionReview.add(
            DailyPlanAyah(
              surahId: currentSurahId,
              ayahNumber: record.ayahNumber,
              ayahText: ayahText,
              record: record,
            ),
          );
        }

        bestPlan = DailyPlan(
          // UTC so the same-day stale check in getCachedDailyPlan is timezone-safe.
          generatedAt: DateTime.now().toUtc(),
          surahId: currentSurahId,
          newAyahs: newAyahs,
          nearRevision: nearRevision,
          farRevision: farRevision,
          completedAyahNums: const [],
          retentionReview: retentionReview,
        );

        if (bestPlan.totalItems > 0 || bestPlan.hasRetentionReview) {
          break;
        }

        // Advance in the memorization direction
        if (isDescending) {
          currentSurahId--;
        } else {
          currentSurahId++;
        }
      }

      bestPlan ??= DailyPlan(
        generatedAt: DateTime.now().toUtc(),
        surahId: planEndSurahId,
        newAyahs: const [],
        nearRevision: const [],
        farRevision: const [],
        completedAyahNums: const [],
        retentionReview: const [],
      );

      // Cache the plan
      await _datasource.saveDailyPlan(DailyPlanModel.fromEntity(bestPlan));

      return Right(bestPlan);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async {
    try {
      final cached = await _datasource.getCachedDailyPlan();
      final now = DateTime.now().toUtc();
      if (cached != null && _isSameUtcDay(cached.generatedAt, now)) {
        return Right(cached);
      }

      // First access of the day (or missing cache): regenerate for active adult plans.
      final customPlan = await _datasource.getCustomPlan();
      final hasActiveAdultPlan =
          customPlan != null &&
          customPlan.isActive &&
          customPlan.targetUser == PlanTargetUser.adult;
      if (!hasActiveAdultPlan) {
        return const Right(null);
      }

      final resumeSurahId = cached?.surahId;
      final surahId =
          resumeSurahId != null &&
              _isSurahInCustomPlanRange(resumeSurahId, customPlan)
          ? resumeSurahId
          : customPlan.startSurahId;

      final generated = await generateDailyPlan(
        surahId: surahId,
        newAyahsPerDay: customPlan.newAyahsPerDay,
      );
      return generated.map((plan) => plan);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> saveDailyPlan(DailyPlan plan) async {
    try {
      await _datasource.saveDailyPlan(DailyPlanModel.fromEntity(plan));
      await _prefs.setBool(
        MemorizationProductionSyncService.dailyPlanCloudDirtyKey,
        true,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> markDailyPlanAyahCompleted({
    required int surahId,
    required int ayahNumber,
  }) async {
    try {
      final cachedResult = await getCachedDailyPlan();
      return cachedResult.fold<Future<Either<Failure, bool>>>(
        (failure) async => Left(failure),
        (plan) async {
          if (plan == null || plan.surahId != surahId) {
            return const Right(false);
          }
          if (plan.isCompleted(ayahNumber)) return const Right(false);

          final inRequired = plan.requiredAyahs.any(
            (ayah) => ayah.ayahNumber == ayahNumber,
          );
          final inRetention = plan.retentionReview.any(
            (ayah) => ayah.ayahNumber == ayahNumber,
          );
          if (!inRequired && !inRetention) return const Right(false);

          final saveResult = await saveDailyPlan(
            plan.withCompleted(ayahNumber),
          );
          return saveResult.fold(Left.new, (_) {
            _progressEvents.notify(ProgressChangedReason.dailyPlan);
            return const Right(true);
          });
        },
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  bool _isSameUtcDay(DateTime a, DateTime b) {
    final au = a.toUtc();
    final bu = b.toUtc();
    return au.year == bu.year && au.month == bu.month && au.day == bu.day;
  }

  bool _isSurahInCustomPlanRange(int surahId, CustomMemorizationPlan plan) {
    final lo = plan.startSurahId <= plan.endSurahId
        ? plan.startSurahId
        : plan.endSurahId;
    final hi = plan.startSurahId <= plan.endSurahId
        ? plan.endSurahId
        : plan.startSurahId;
    return surahId >= lo && surahId <= hi;
  }
}
