import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/memorization_navigation_resolver.dart';

void main() {
  group('MemorizationNavigationResolver', () {
    test(
      'adult Today Plan and Review Quiz use active cached plan surah',
      () async {
        final resolver = MemorizationNavigationResolver(
          _FakeRepository(cachedPlan: _dailyPlan(2)),
        );

        final targets = await resolver.resolve();

        expect(targets.todayPlanLocation, contains('surahId=2'));
        expect(targets.reviewQuizLocation, contains('surahId=2'));
        expect(targets.todayPlanLocation, isNot(contains('surahId=1')));
        expect(targets.reviewQuizLocation, isNot(contains('surahId=1')));
      },
    );

    test('kids Journey uses latest active kids session surah', () async {
      final resolver = MemorizationNavigationResolver(
        _FakeRepository(
          kidsLogs: [
            _kidsLog(surahId: 2, completedAt: DateTime.utc(2026, 1, 1)),
            _kidsLog(surahId: 114, completedAt: DateTime.utc(2026, 1, 2)),
          ],
        ),
      );

      final targets = await resolver.resolve();

      final uri = Uri.parse(targets.kidsJourneyLocation);
      expect(uri.queryParameters['surahId'], '114');
    });

    test(
      'missing current plan routes safely instead of forcing Surah 1',
      () async {
        const resolver = MemorizationNavigationResolver(_FakeRepository());

        final targets = await resolver.resolve();

        expect(targets.todayPlanLocation, AppRoutes.memorizationPlusCustomPlan);
        expect(
          targets.reviewQuizLocation,
          AppRoutes.memorizationPlusCustomPlan,
        );
        expect(targets.kidsJourneyLocation, AppRoutes.memorizationPlusKidsHome);
        expect(targets.todayPlanLocation, isNot(contains('surahId=1')));
        expect(targets.reviewQuizLocation, isNot(contains('surahId=1')));
        expect(targets.kidsJourneyLocation, isNot(contains('surahId=1')));
      },
    );

    test('custom adult plan opens both Today Plan and Review Quiz', () async {
      final resolver = MemorizationNavigationResolver(
        _FakeRepository(customPlan: _customPlan(3, PlanTargetUser.adult)),
      );

      final targets = await resolver.resolve();

      expect(
        Uri.parse(targets.todayPlanLocation).queryParameters['surahId'],
        '3',
      );
      expect(
        Uri.parse(targets.reviewQuizLocation).queryParameters['surahId'],
        '3',
      );
    });
  });
}

DailyPlan _dailyPlan(int surahId) => DailyPlan(
  generatedAt: DateTime.utc(2026, 1, 1),
  surahId: surahId,
  newAyahs: const [],
  nearRevision: const [],
  farRevision: const [],
  completedAyahNums: const [],
);

KidsSessionLog _kidsLog({
  required int surahId,
  required DateTime completedAt,
}) => KidsSessionLog(
  id: '$surahId',
  surahId: surahId,
  ayahNumber: 1,
  repeatsCompleted: 3,
  pointsEarned: 10,
  completedAt: completedAt,
);

CustomMemorizationPlan _customPlan(int surahId, PlanTargetUser targetUser) =>
    CustomMemorizationPlan(
      name: 'Plan',
      startSurahId: surahId,
      endSurahId: surahId,
      newAyahsPerDay: 3,
      availableDaysPerWeek: 5,
      sessionMinutes: 10,
      difficulty: MemorizationDifficulty.easy,
      enableNearRevision: true,
      enableFarRevision: true,
      nearRevisionCount: 3,
      farRevisionCount: 3,
      startAyah: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      targetUser: targetUser,
    );

class _FakeRepository implements MemorizationPlusRepository {
  const _FakeRepository({
    this.cachedPlan,
    this.customPlan,
    this.kidsLogs = const [],
  });

  final DailyPlan? cachedPlan;
  final CustomMemorizationPlan? customPlan;
  final List<KidsSessionLog> kidsLogs;

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async =>
      Right(cachedPlan);

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async =>
      Right(customPlan);

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async =>
      const Right([]);

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async =>
      Right(kidsLogs);

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async =>
      const Left(CacheFailure('No profile'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> hasPendingCloudWork() async => false;
}
