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
import '../../../../../core/memorization/plan_cloud_dirty_keys.dart';
import 'daily_plan_review_queue.dart';

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
      )).where(ReviewRecordFilters.isAdultCompatible).toList();

      // BUG-7 FIX: Read custom plan settings and apply them
      final customPlan = await _datasource.getCustomPlan();
      final effectiveNewPerDay = customPlan?.newAyahsPerDay ?? newAyahsPerDay;
      final nearRevisionLimit = customPlan?.nearRevisionCount ?? 10;
      final farRevisionLimit = customPlan?.farRevisionCount ?? 5;
      final reviewSelection = DailyPlanReviewQueue.select(
        records: allRecords,
        now: DateTime.now().toUtc(),
        nearLimit: nearRevisionLimit,
        farLimit: farRevisionLimit,
        retentionLimit: _retentionReviewLimit,
        includeNear: customPlan?.enableNearRevision != false,
        includeFar: customPlan?.enableFarRevision != false,
      );
      final weakRecovery = await _planAyahsForRecords(reviewSelection.weak);
      final nearRevision = await _planAyahsForRecords(reviewSelection.near);
      final farRevision = await _planAyahsForRecords(reviewSelection.far);
      final retentionReview = await _planAyahsForRecords(
        reviewSelection.retention,
      );

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

      final List<DailyPlanAyah> newAyahs = [];
      var planSurahId = currentSurahId;

      // New material remains direction-aware. Global reviews are selected
      // above, independently of this resume cursor.
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

          if (!reviewSelection.blocksNewMemorization &&
              (record == null || record.isNew)) {
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
          }
        }
        planSurahId = currentSurahId;
        if (newAyahs.isNotEmpty || reviewSelection.blocksNewMemorization) {
          break;
        }

        // Advance in the memorization direction
        if (isDescending) {
          currentSurahId--;
        } else {
          currentSurahId++;
        }
      }

      final bestPlan = DailyPlan(
        generatedAt: DateTime.now().toUtc(),
        surahId: planSurahId,
        newAyahs: newAyahs,
        weakRecovery: weakRecovery,
        nearRevision: nearRevision,
        farRevision: farRevision,
        completedAyahNums: const [],
        retentionReview: retentionReview,
      );

      // Cache the plan and mark it dirty so offline generates upload on reconnect.
      await _datasource.saveDailyPlan(DailyPlanModel.fromEntity(bestPlan));
      await _prefs.setBool(PlanCloudDirtyKeys.dailyPlan, true);

      return Right(bestPlan);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<List<DailyPlanAyah>> _planAyahsForRecords(
    Iterable<AyahReviewRecord> records,
  ) async {
    final selected = records.toList();
    final details = await Future.wait(
      selected
          .map((record) => record.surahId)
          .toSet()
          .map(_quranRepository.getSurahDetail),
    );
    final textByKey = <String, String>{};
    for (final result in details) {
      result.fold((_) {}, (detail) {
        for (final ayah in detail.ayahs) {
          textByKey['${ayah.surahId}:${ayah.numberInSurah}'] = ayah.text;
        }
      });
    }
    return selected
        .map(
          (record) => DailyPlanAyah(
            surahId: record.surahId,
            ayahNumber: record.ayahNumber,
            ayahText:
                textByKey['${record.surahId}:${record.ayahNumber}'] ??
                'النص غير متوفر',
            record: record,
          ),
        )
        .toList();
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
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, void>> saveDailyPlan(DailyPlan plan) async {
    try {
      await _datasource.saveDailyPlan(DailyPlanModel.fromEntity(plan));
      await _prefs.setBool(PlanCloudDirtyKeys.dailyPlan, true);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, bool>> markDailyPlanAyahCompleted({
    required int surahId,
    required int ayahNumber,
  }) async {
    try {
      final cachedResult = await getCachedDailyPlan();
      final folded = await cachedResult.fold<Future<Either<Failure, bool>>>(
        (failure) async => Left(failure),
        (plan) async {
          if (plan == null) {
            return const Right(false);
          }
          if (plan.isAyahCompleted(surahId, ayahNumber)) {
            return const Right(false);
          }

          final inRequired = plan.requiredAyahs.any(
            (ayah) => ayah.surahId == surahId && ayah.ayahNumber == ayahNumber,
          );
          final inRetention = plan.retentionReview.any(
            (ayah) => ayah.surahId == surahId && ayah.ayahNumber == ayahNumber,
          );
          if (!inRequired && !inRetention) return const Right(false);

          final saveResult = await saveDailyPlan(
            plan.withCompleted(ayahNumber, ayahSurahId: surahId),
          );
          return saveResult.fold(Left.new, (_) {
            _progressEvents.notify(ProgressChangedReason.dailyPlan);
            return const Right(true);
          });
        },
      );
      return folded;
    } catch (e) {
      return Left(CacheFailure.from(e));
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
