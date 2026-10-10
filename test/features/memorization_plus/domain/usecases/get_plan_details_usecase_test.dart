import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/get_plan_details_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class _Repository extends Mock implements MemorizationPlusRepository {}

class _Quran extends Mock implements QuranRepository {}

void main() {
  late _Repository repository;
  late _Quran quran;
  late GetPlanDetailsUseCase read;
  final now = DateTime.now().toUtc();
  final plan = CustomMemorizationPlan(
    name: 'scope',
    startSurahId: 114,
    endSurahId: 112,
    startAyah: 5,
    newAyahsPerDay: 3,
    availableDaysPerWeek: 7,
    sessionMinutes: 30,
    difficulty: MemorizationDifficulty.easy,
    enableNearRevision: true,
    enableFarRevision: true,
    nearRevisionCount: 5,
    farRevisionCount: 3,
    createdAt: now,
  );
  final surahs =
      (jsonDecode(File('assets/data/surahs.json').readAsStringSync()) as List)
          .cast<Map<String, dynamic>>()
          .map(
            (row) => Surah(
              id: row['id'] as int,
              nameAr: row['nameAr'] as String,
              nameEn: row['nameEn'] as String,
              ayahCount: row['ayahCount'] as int,
              juz: row['juz'] as int,
              type: row['type'] as String,
              page: row['page'] as int,
            ),
          )
          .toList();
  AyahReviewRecord record(
    int surah,
    int ayah, {
    int strength = 6,
    int reviews = 4,
    ReviewRecordCreatedByMode source = ReviewRecordCreatedByMode.v2Session,
    DateTime? reviewedAt,
    bool due = false,
  }) => AyahReviewRecord(
    surahId: surah,
    ayahNumber: ayah,
    strengthLevel: strength,
    totalReviews: reviews,
    lastReviewedAt: reviewedAt ?? now,
    nextReviewDate: due
        ? now.subtract(const Duration(days: 2))
        : now.add(const Duration(days: 3)),
    intervalDays: 3,
    lastRating: PerformanceRating.average,
    createdByMode: source,
  );

  setUp(() {
    repository = _Repository();
    quran = _Quran();
    read = GetPlanDetailsUseCase(
      repository,
      quran,
      const ProgressMetricsService(),
    );
    when(() => repository.getCustomPlan()).thenAnswer((_) async => Right(plan));
    when(() => quran.getSurahs()).thenAnswer((_) async => Right(surahs));
    when(
      () => repository.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => repository.getCachedDailyPlan(),
    ).thenAnswer((_) async => const Right(null));
  });

  test(
    'descending range respects start offset and excludes unrelated or child progress',
    () async {
      when(
        () =>
            repository.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
      ).thenAnswer(
        (_) async => Right([
          record(114, 5),
          record(113, 1, strength: 3, due: true),
          record(114, 1),
          record(112, 5),
          record(111, 1),
          record(
            114,
            5,
            source: ReviewRecordCreatedByMode.kidsMode,
            reviewedAt: now.add(const Duration(days: 1)),
          ),
          record(112, 1, source: ReviewRecordCreatedByMode.migration),
        ]),
      );
      final details = (await read()).getOrElse(() => null)!;
      expect(details.totalAyahs, 11);
      expect(details.surahProgress.map((s) => s.surahId), [114, 113, 112]);
      expect(details.metrics.memorizedAyahs, 1);
      expect(details.metrics.learningAyahs, 1);
      expect(details.unstartedAyahs, 9);
      expect(details.remainingAyahs, 10);
      expect(details.metrics.retentionRate, .5);
      expect(details.metrics.dueReviews, 1);
      expect(details.metrics.overdueReviews, 1);
      expect(details.surahProgress.first.startedAyahs, 1);
    },
  );

  test('ascending scope includes only canonical target ayahs', () async {
    when(() => repository.getCustomPlan()).thenAnswer(
      (_) async => Right(
        plan.copyWith(startSurahId: 112, endSurahId: 114, startAyah: 3),
      ),
    );
    final details = (await read()).getOrElse(() => null)!;
    expect(details.totalAyahs, 13);
    expect(details.surahProgress.map((s) => s.surahId), [112, 113, 114]);
    expect(details.metrics.startedAyahs, 0);
    expect(details.metrics.retentionRate, 0);
    expect(details.nextReviewAt, isNull);
  });

  test('latest adult duplicate counts once and can reduce mastery', () async {
    when(
      () => repository.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
    ).thenAnswer(
      (_) async => Right([
        record(114, 5, reviewedAt: now.subtract(const Duration(days: 1))),
        record(114, 5, strength: 2, reviews: 5),
        record(113, 1, reviews: 0),
      ]),
    );
    final details = (await read()).getOrElse(() => null)!;
    expect(details.metrics.startedAyahs, 1);
    expect(details.metrics.memorizedAyahs, 0);
    expect(details.metrics.learningAyahs, 1);
    expect(details.metrics.totalReviewEvents, 5);
  });

  for (final absent in [
    null,
    plan.copyWith(isActive: false),
    plan.copyWith(targetUser: PlanTargetUser.child),
  ]) {
    test(
      'missing, inactive or child plan never reads adult progress ($absent)',
      () async {
        when(
          () => repository.getCustomPlan(),
        ).thenAnswer((_) async => Right(absent));
        expect((await read()).getOrElse(() => null), isNull);
        verifyNever(() => quran.getSurahs());
      },
    );
  }

  test(
    'failed daily read is an error rather than invented zero progress',
    () async {
      when(
        () => repository.getCachedDailyPlan(),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      expect((await read()).isLeft(), isTrue);
    },
  );

  test(
    'invalid start ayah or incomplete canonical metadata is rejected',
    () async {
      when(
        () => repository.getCustomPlan(),
      ).thenAnswer((_) async => Right(plan.copyWith(startAyah: 7)));
      expect((await read()).isLeft(), isTrue);
      when(
        () => repository.getCustomPlan(),
      ).thenAnswer((_) async => Right(plan));
      when(() => quran.getSurahs()).thenAnswer(
        (_) async => Right(surahs.where((s) => s.id != 113).toList()),
      );
      expect((await read()).isLeft(), isTrue);
    },
  );
}
