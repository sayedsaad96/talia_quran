import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/pending_ayah_resolver.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/memorization_navigation_resolver.dart';

void main() {
  const resolver = PendingAyahResolver();
  final t = DateTime.utc(2026, 1, 1);

  group('PendingAyahResolver', () {
    test('continueDailyPlan uses first pending ayah from cached plan', () {
      final now = DateTime.now().toUtc();
      final target = resolver.resolve(
        PendingAyahResolverInput(
          surahId: 67,
          intent: PendingAyahIntent.continueDailyPlan,
          cachedDailyPlan: DailyPlan(
            generatedAt: now,
            surahId: 67,
            newAyahs: const [
              DailyPlanAyah(
                surahId: 67,
                ayahNumber: 7,
                ayahText: 'text',
                record: null,
              ),
            ],
            nearRevision: const [
              DailyPlanAyah(
                surahId: 67,
                ayahNumber: 1,
                ayahText: 'text',
                record: null,
              ),
            ],
            farRevision: const [],
            completedAyahNums: const [1, 2, 3, 4, 5, 6],
          ),
          reviewRecords: const [],
        ),
      );

      expect(target.startAyah, 7);
      expect(target.intent, PendingAyahIntent.continueDailyPlan);
    });

    test('practiceSurah uses first unstarted ayah when surah ayah count known',
        () {
      final target = resolver.resolve(
        PendingAyahResolverInput(
          surahId: 2,
          intent: PendingAyahIntent.practiceSurah,
          surahAyahCount: 286,
          reviewRecords: [
            AyahReviewRecord(
              surahId: 2,
              ayahNumber: 1,
              strengthLevel: 6,
              intervalDays: 30,
              lastReviewedAt: t,
              nextReviewDate: t,
              totalReviews: 3,
              lastRating: PerformanceRating.excellent,
              createdByMode: ReviewRecordCreatedByMode.v2Session,
            ),
          ],
        ),
      );

      expect(target.startAyah, 2);
    });

    test('reviewSession prefers first due ayah in surah', () {
      final now = DateTime.now().toUtc();
      final target = resolver.resolve(
        PendingAyahResolverInput(
          surahId: 67,
          intent: PendingAyahIntent.reviewSession,
          reviewRecords: [
            AyahReviewRecord(
              surahId: 67,
              ayahNumber: 5,
              strengthLevel: 3,
              intervalDays: 1,
              lastReviewedAt: now.subtract(const Duration(days: 2)),
              nextReviewDate: now.subtract(const Duration(days: 1)),
              totalReviews: 2,
              lastRating: PerformanceRating.average,
              createdByMode: ReviewRecordCreatedByMode.v2Session,
            ),
          ],
        ),
      );

      expect(target.startAyah, 5);
    });
  });

  group('MemorizationNavigationResolver pending ayah (B5)', () {
    test('today plan location includes pending startAyah from cached plan',
        () async {
      final nav = MemorizationNavigationResolver(
        _FakeRepository(
          cachedPlan: DailyPlan(
            generatedAt: DateTime.utc(2026, 7, 8),
            surahId: 2,
            newAyahs: const [
              DailyPlanAyah(
                surahId: 2,
                ayahNumber: 4,
                ayahText: 'text',
                record: null,
              ),
            ],
            nearRevision: const [],
            farRevision: const [],
            completedAyahNums: const [1, 2, 3],
          ),
        ),
      );

      final targets = await nav.resolve();

      expect(targets.todayPlanLocation, contains('surahId=2'));
      expect(targets.todayPlanLocation, contains('startAyah=4'));
    });

    test('practiceSurahSessionLocation resolves learning ayah for Hifz tile',
        () async {
      final nav = MemorizationNavigationResolver(_FakeRepository());

      final route = await nav.practiceSurahSessionLocation(
        114,
        surahAyahCount: 6,
      );

      expect(route, contains('surahId=114'));
      expect(route, contains('startAyah=1'));
    });
  });
}

class _FakeRepository implements MemorizationPlusRepository {
  _FakeRepository({this.cachedPlan});

  final DailyPlan? cachedPlan;

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async =>
      Right(cachedPlan);

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async =>
      const Right([]);

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async =>
      const Left(CacheFailure('No profile'));

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async =>
      const Right(null);

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async =>
      const Right([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
