import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/plan_details.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/get_plan_details_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class PlanDetailsFixtureRepository extends Mock
    implements MemorizationPlusRepository {}

class _FixtureQuran extends Mock implements QuranRepository {}

class PlanDetailsFixtureHarness {
  PlanDetailsFixtureHarness() {
    final details = planDetailsFixture();
    when(
      () => repository.getCustomPlan(),
    ).thenAnswer((_) async => Right(details.plan));
    when(
      () => repository.getCachedDailyPlan(),
    ).thenAnswer((_) async => Right(details.dailyPlan));
    when(
      () => repository.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
    ).thenAnswer((_) async => Right(_records(DateTime.now().toUtc())));
    when(() => _quran.getSurahs()).thenAnswer(
      (_) async => const Right([
        Surah(
          id: 67,
          nameAr: 'الملك',
          nameEn: 'Al-Mulk',
          ayahCount: 30,
          juz: 29,
          type: 'meccan',
          page: 562,
        ),
      ]),
    );
  }
  final repository = PlanDetailsFixtureRepository();
  final _quran = _FixtureQuran();
  GetPlanDetailsUseCase get read =>
      GetPlanDetailsUseCase(repository, _quran, const ProgressMetricsService());
}

PlanDetails planDetailsFixture() {
  final now = DateTime.now().toUtc();
  final records = _records(now);
  return PlanDetails(
    plan: CustomMemorizationPlan(
      name: 'Saved plan',
      startSurahId: 67,
      endSurahId: 67,
      startAyah: 1,
      newAyahsPerDay: 3,
      availableDaysPerWeek: 7,
      sessionMinutes: 30,
      difficulty: MemorizationDifficulty.easy,
      enableNearRevision: true,
      enableFarRevision: false,
      nearRevisionCount: 5,
      farRevisionCount: 3,
      createdAt: now,
    ),
    metrics: const ProgressMetricsService().calculate(
      records: records,
      now: now,
      totalAyahs: 30,
      totalSurahs: 1,
      surahAyahCounts: const {67: 30},
    ),
    totalAyahs: 30,
    nextReviewAt: now.add(const Duration(days: 2)),
    surahProgress: const [
      PlanSurahProgress(
        surahId: 67,
        totalAyahs: 30,
        startedAyahs: 2,
        memorizedAyahs: 1,
      ),
    ],
    dailyPlan: DailyPlan(
      generatedAt: now,
      surahId: 67,
      newAyahs: [
        for (var number = 3; number <= 5; number++)
          DailyPlanAyah(
            surahId: 67,
            ayahNumber: number,
            ayahText: '',
            record: null,
          ),
      ],
      nearRevision: const [],
      farRevision: const [],
      completedAyahNums: const [],
    ),
  );
}

List<AyahReviewRecord> _records(DateTime now) => [
  for (var number = 1; number <= 2; number++)
    AyahReviewRecord(
      surahId: 67,
      ayahNumber: number,
      strengthLevel: number == 1 ? 6 : 3,
      totalReviews: 4,
      intervalDays: 2,
      lastReviewedAt: now,
      nextReviewDate: now.add(const Duration(days: 2)),
      lastRating: PerformanceRating.average,
      createdByMode: ReviewRecordCreatedByMode.v2Session,
    ),
];
