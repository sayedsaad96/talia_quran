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

    test(
      'Review Quiz opens the highest-priority due ayah across surahs',
      () async {
        final resolver = MemorizationNavigationResolver(
          _FakeRepository(
            cachedPlan: _dailyPlan(2),
            reviewRecords: [_dueAdultWeakRecord(surahId: 36, ayahNumber: 3)],
          ),
        );

        final targets = await resolver.resolve();
        final uri = Uri.parse(targets.reviewQuizLocation);

        expect(uri.queryParameters['surahId'], '36');
        expect(uri.queryParameters['startAyah'], '3');
        expect(uri.queryParameters['intent'], 'review');
        expect(uri.queryParameters['origin'], 'smartCoach');
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
      'due kids review takes priority over the latest journey log',
      () async {
        final resolver = MemorizationNavigationResolver(
          _FakeRepository(
            kidsLogs: [
              _kidsLog(surahId: 114, completedAt: DateTime.utc(2026, 1, 2)),
            ],
            reviewRecords: [_dueKidsRecord(surahId: 112, ayahNumber: 2)],
          ),
        );

        final targets = await resolver.resolve();

        expect(
          Uri.parse(targets.kidsHomeLocation).queryParameters['surahId'],
          '112',
        );
      },
    );
    test('uses the parent-selected starting surah for a new child', () async {
      const resolver = MemorizationNavigationResolver(
        _FakeRepository(parentSettings: ParentSettings(startingSurahId: 112)),
      );

      final targets = await resolver.resolve();

      expect(
        Uri.parse(targets.kidsHomeLocation).queryParameters['surahId'],
        '112',
      );
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
        expect(targets.todayPlanLocation, isNot(contains('surahId=1')));
        expect(targets.reviewQuizLocation, isNot(contains('surahId=1')));
      },
    );

    test('a new child starts the kids journey at Al-Fatiha (K27)', () async {
      const resolver = MemorizationNavigationResolver(_FakeRepository());

      final targets = await resolver.resolve();

      expect(
        Uri.parse(targets.kidsJourneyLocation).queryParameters['surahId'],
        '1',
      );
      expect(
        Uri.parse(targets.kidsHomeLocation).queryParameters['surahId'],
        '1',
      );
    });

    group('kidsMissionAfterCompletion', () {
      const stage = KidsJourneyStage(
        stageNumber: 1,
        surahId: 114,
        startAyah: 1,
        endAyah: 6,
        completedAyahs: [1, 2],
        status: KidsJourneyStageStatus.current,
      );
      KidsSessionLog todayLog(String id, KidsMissionType type) =>
          KidsSessionLog(
            id: id,
            surahId: 114,
            ayahNumber: 1,
            repeatsCompleted: 2,
            pointsEarned: 10,
            completedAt: DateTime.now(),
            missionType: type,
          );

      test('ends the day instead of offering a refused mission (N3)', () async {
        final resolver = MemorizationNavigationResolver(
          _FakeRepository(
            kidsStages: const [stage],
            // Default age-8 policy: two new ayahs per day, both done.
            kidsLogs: [
              todayLog('a', KidsMissionType.newMemorization),
              todayLog('b', KidsMissionType.newMemorization),
            ],
          ),
        );

        final outcome = await resolver.kidsMissionAfterCompletion(
          surahId: 114,
          completedAyah: 2,
        );

        expect(outcome.mission, isNull);
        expect(outcome.dailyGoalCap, 2);
      });

      test('honours the spent review budget like home does (N2)', () async {
        final resolver = MemorizationNavigationResolver(
          _FakeRepository(
            kidsStages: const [stage],
            reviewRecords: [_dueKidsRecord(surahId: 114, ayahNumber: 1)],
            // Default age-8 policy: three due reviews per day, all done.
            kidsLogs: [
              todayLog('a', KidsMissionType.dueReview),
              todayLog('b', KidsMissionType.dueReview),
              todayLog('c', KidsMissionType.dueReview),
            ],
          ),
        );

        final outcome = await resolver.kidsMissionAfterCompletion(
          surahId: 114,
          completedAyah: 2,
        );

        expect(outcome.mission?.type, KidsMissionType.newMemorization);
        expect(outcome.mission?.startAyah, 3);
        expect(outcome.dailyGoalCap, isNull);
      });

      test('says so when today reached the session goal (K36)', () async {
        KidsSessionLog timed(String id, int seconds) => KidsSessionLog(
          id: id,
          surahId: 114,
          ayahNumber: 1,
          repeatsCompleted: 2,
          pointsEarned: 10,
          completedAt: DateTime.now(),
          durationSeconds: seconds,
        );
        MemorizationNavigationResolver resolverWith(int seconds) =>
            MemorizationNavigationResolver(
              _FakeRepository(
                kidsStages: const [stage],
                kidsLogs: [timed('a', seconds)],
                parentSettings: const ParentSettings(sessionGoalMinutes: 6),
              ),
            );

        final reached = await resolverWith(
          400,
        ).kidsMissionAfterCompletion(surahId: 114, completedAyah: 2);
        final notYet = await resolverWith(
          100,
        ).kidsMissionAfterCompletion(surahId: 114, completedAyah: 2);

        expect(reached.sessionGoalReached, isTrue);
        // A gentle note only: the next mission stays available.
        expect(reached.mission, isNotNull);
        expect(notYet.sessionGoalReached, isFalse);
      });

      test(
        'continues at the real frontier past memorized surahs (K17)',
        () async {
          KidsJourneyStage done(int surahId) => KidsJourneyStage(
            stageNumber: 1,
            surahId: surahId,
            startAyah: 1,
            endAyah: 3,
            completedAyahs: const [1, 2, 3],
            status: KidsJourneyStageStatus.completed,
          );
          final resolver = MemorizationNavigationResolver(
            _FakeRepository(
              kidsStagesBySurah: {
                114: [done(114)],
                113: [done(113)],
                112: const [
                  KidsJourneyStage(
                    stageNumber: 1,
                    surahId: 112,
                    startAyah: 1,
                    endAyah: 4,
                    completedAyahs: [1, 2],
                    status: KidsJourneyStageStatus.current,
                  ),
                ],
              },
            ),
          );

          // A due review of 114:2 just finished; 113 is already memorized.
          final outcome = await resolver.kidsMissionAfterCompletion(
            surahId: 114,
            completedAyah: 2,
          );

          expect(outcome.mission?.surahId, 112);
          expect(outcome.mission?.startAyah, 3);
        },
      );
    });

    test(
      'a newer review in an old surah does not move kids home (K17)',
      () async {
        final resolver = MemorizationNavigationResolver(
          _FakeRepository(
            kidsLogs: [
              _kidsLog(surahId: 112, completedAt: DateTime.utc(2026, 1, 1)),
              KidsSessionLog(
                id: 'review',
                surahId: 114,
                ayahNumber: 2,
                repeatsCompleted: 2,
                pointsEarned: 5,
                completedAt: DateTime.utc(2026, 1, 2),
                missionType: KidsMissionType.dueReview,
              ),
            ],
          ),
        );

        final targets = await resolver.resolve();

        expect(
          Uri.parse(targets.kidsHomeLocation).queryParameters['surahId'],
          '112',
        );
      },
    );

    test(
      'a spent kids review budget hands the home surah back to the journey',
      () async {
        final resolver = MemorizationNavigationResolver(
          _FakeRepository(
            reviewRecords: [_dueKidsRecord(surahId: 112, ayahNumber: 2)],
            kidsLogs: [
              for (final id in ['a', 'b', 'c'])
                KidsSessionLog(
                  id: id,
                  surahId: 114,
                  ayahNumber: 1,
                  repeatsCompleted: 2,
                  pointsEarned: 5,
                  completedAt: DateTime.now(),
                  missionType: KidsMissionType.dueReview,
                ),
            ],
          ),
        );

        final targets = await resolver.resolve();

        expect(
          Uri.parse(targets.kidsHomeLocation).queryParameters['surahId'],
          '114',
        );
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

AyahReviewRecord _dueKidsRecord({
  required int surahId,
  required int ayahNumber,
}) => AyahReviewRecord(
  surahId: surahId,
  ayahNumber: ayahNumber,
  strengthLevel: 6,
  intervalDays: 1,
  lastReviewedAt: DateTime.utc(2025, 12, 1),
  nextReviewDate: DateTime.utc(2025, 12, 2),
  totalReviews: 1,
  lastRating: PerformanceRating.average,
  createdByMode: ReviewRecordCreatedByMode.kidsMode,
);

AyahReviewRecord _dueAdultWeakRecord({
  required int surahId,
  required int ayahNumber,
}) => AyahReviewRecord(
  surahId: surahId,
  ayahNumber: ayahNumber,
  strengthLevel: 1,
  intervalDays: 1,
  lastReviewedAt: DateTime.utc(2025, 12, 1),
  nextReviewDate: DateTime.utc(2025, 12, 2),
  totalReviews: 4,
  lastRating: PerformanceRating.weak,
  createdByMode: ReviewRecordCreatedByMode.v2Session,
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
    this.reviewRecords = const [],
    this.parentSettings = const ParentSettings(),
    this.kidsStages = const [],
    this.kidsStagesBySurah,
  });

  final DailyPlan? cachedPlan;
  final CustomMemorizationPlan? customPlan;
  final List<KidsSessionLog> kidsLogs;
  final List<AyahReviewRecord> reviewRecords;
  final ParentSettings parentSettings;
  final List<KidsJourneyStage> kidsStages;
  final Map<int, List<KidsJourneyStage>>? kidsStagesBySurah;

  @override
  Future<Either<Failure, List<KidsJourneyStage>>> getKidsJourney({
    required int surahId,
  }) async => Right(kidsStagesBySurah?[surahId] ?? kidsStages);

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async =>
      Right(cachedPlan);

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async =>
      Right(customPlan);

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async => Right(reviewRecords);

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async =>
      Right(kidsLogs);
  @override
  Future<Either<Failure, ParentSettings>> getParentSettings() async =>
      Right(parentSettings);

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async =>
      const Left(CacheFailure('No profile'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> hasPendingCloudWork() async => false;
}
