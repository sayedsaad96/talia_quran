import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/memorization/progress_metrics_service.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/memorization/review_record_filters.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../entities/memorization_entities.dart';
import '../entities/plan_details.dart';
import '../navigation/memorization_navigation_resolver.dart';
import '../repositories/memorization_plus_repository.dart';

class GetPlanDetailsUseCase {
  const GetPlanDetailsUseCase(this._repository, this._quran, this._metrics);

  final MemorizationPlusRepository _repository;
  final QuranRepository _quran;
  final ProgressMetricsService _metrics;

  Future<Either<Failure, PlanDetails?>> call() async {
    try {
      final plan = _required(await _repository.getCustomPlan());
      if (plan == null || !plan.isActive || plan.isForChild) {
        return const Right(null);
      }
      final surahs = _required(await _quran.getSurahs());
      final counts = _scopeCounts(plan, surahs);
      final records = _scopedRecords(
        plan,
        counts,
        _required(
          await _repository.getAllReviewRecords(
            scope: ReviewRecordReadScope.adult,
          ),
        ),
      );
      final daily = _required(await _repository.getCachedDailyPlan());
      return Right(_details(plan, counts, records, daily));
    } on Failure catch (failure) {
      return Left(failure);
    } catch (error, stack) {
      // Any unexpected error (including StateError) must reach the Cubit as
      // a failure, never leave the page loading forever.
      return Left(CacheFailure.from(error, stack));
    }
  }

  Future<String> sessionLocation() =>
      MemorizationNavigationResolver(_repository).adultEntryLocation();

  T _required<T>(Either<Failure, T> outcome) =>
      outcome.fold((failure) => throw failure, (value) => value);

  Map<int, int> _scopeCounts(CustomMemorizationPlan plan, List<Surah> surahs) {
    final canonical = {for (final surah in surahs) surah.id: surah.ayahCount};
    if (plan.startSurahId < 1 ||
        plan.startSurahId > 114 ||
        plan.endSurahId < 1 ||
        plan.endSurahId > 114 ||
        plan.startAyah < 1 ||
        plan.startAyah > (canonical[plan.startSurahId] ?? 0)) {
      throw const CacheFailure();
    }
    final step = plan.startSurahId <= plan.endSurahId ? 1 : -1;
    final counts = <int, int>{};
    for (var id = plan.startSurahId; ; id += step) {
      final total = canonical[id];
      if (total == null || total < 1) throw const CacheFailure();
      counts[id] = total - (id == plan.startSurahId ? plan.startAyah - 1 : 0);
      if (id == plan.endSurahId) return counts;
    }
  }

  List<AyahReviewRecord> _scopedRecords(
    CustomMemorizationPlan plan,
    Map<int, int> counts,
    List<AyahReviewRecord> records,
  ) {
    final latest = <String, AyahReviewRecord>{};
    for (final record in records.where(
      ReviewRecordFilters.isAdultProductionCount,
    )) {
      final count = counts[record.surahId];
      final first = record.surahId == plan.startSurahId ? plan.startAyah : 1;
      if (count == null ||
          record.ayahNumber < first ||
          record.ayahNumber >= first + count) {
        continue;
      }
      final previous = latest[record.key];
      if (previous == null ||
          record.lastReviewedAt.isAfter(previous.lastReviewedAt)) {
        latest[record.key] = record;
      }
    }
    return latest.values.toList(growable: false);
  }

  PlanDetails _details(
    CustomMemorizationPlan plan,
    Map<int, int> counts,
    List<AyahReviewRecord> records,
    DailyPlan? daily,
  ) {
    final now = DateTime.now().toUtc();
    final total = counts.values.fold(0, (sum, count) => sum + count);
    final metrics = _metrics.calculate(
      records: records,
      now: now,
      surahAyahCounts: counts,
      totalAyahs: total,
      totalSurahs: counts.length,
    );
    final reviewed = records.where(ReviewRecordFilters.isStarted).toList()
      ..sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
    return PlanDetails(
      plan: plan,
      metrics: metrics,
      totalAyahs: total,
      dailyPlan: daily,
      nextReviewAt: reviewed.isEmpty ? null : reviewed.first.nextReviewDate,
      surahProgress: [
        for (final entry in counts.entries) _surahProgress(entry, records, now),
      ],
    );
  }

  PlanSurahProgress _surahProgress(
    MapEntry<int, int> scope,
    List<AyahReviewRecord> records,
    DateTime now,
  ) {
    final metrics = _metrics.calculate(
      records: records.where((record) => record.surahId == scope.key).toList(),
      now: now,
      totalAyahs: scope.value,
    );
    return PlanSurahProgress(
      surahId: scope.key,
      totalAyahs: scope.value,
      startedAyahs: metrics.startedAyahs,
      memorizedAyahs: metrics.memorizedAyahs,
    );
  }
}
