import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_child_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_home_mission.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_adventure_regions.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_daily_missions.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

import 'kids_journey_cubit_test.mocks.dart';

@GenerateMocks([GetKidsJourneyUsecase, GetKidsProgressUsecase, QuranRepository])
void main() {
  late MockGetKidsJourneyUsecase mockGetJourney;
  late MockGetKidsProgressUsecase mockGetProgress;
  late MockQuranRepository mockQuranRepo;
  late KidsJourneyCubit cubit;

  setUp(() {
    mockGetJourney = MockGetKidsJourneyUsecase();
    mockGetProgress = MockGetKidsProgressUsecase();
    mockQuranRepo = MockQuranRepository();

    cubit = KidsJourneyCubit(mockGetJourney, mockGetProgress, mockQuranRepo);
  });

  tearDown(() {
    cubit.close();
  });

  test('completed surah has no current stage', () {
    const state = KidsJourneyLoaded(
      surahId: 114,
      stages: [
        KidsJourneyStage(
          stageNumber: 1,
          surahId: 114,
          startAyah: 1,
          endAyah: 6,
          completedAyahs: [1, 2, 3, 4, 5, 6],
          status: KidsJourneyStageStatus.completed,
        ),
      ],
      progress: KidsProgress.initial(),
    );

    expect(state.currentStage, isNull);
  });

  test('review stage is selected before a current memorization stage', () {
    const state = KidsJourneyLoaded(
      surahId: 114,
      stages: [
        KidsJourneyStage(
          stageNumber: 1,
          surahId: 114,
          startAyah: 1,
          endAyah: 3,
          completedAyahs: [1, 2, 3],
          status: KidsJourneyStageStatus.needsReview,
        ),
        KidsJourneyStage(
          stageNumber: 2,
          surahId: 114,
          startAyah: 4,
          endAyah: 6,
          completedAyahs: [],
          status: KidsJourneyStageStatus.current,
        ),
      ],
      progress: KidsProgress.initial(),
    );

    expect(state.currentStage?.status, KidsJourneyStageStatus.needsReview);
  });

  group('load', () {
    const tSurahId = 1;
    const tSurahName = 'الفاتحة';
    const tSurah = Surah(
      id: 1,
      nameAr: tSurahName,
      nameEn: tSurahName,
      ayahCount: 7,
      juz: 1,
      type: 'meccan',
      page: 1,
    );
    const tSurahDetail = SurahDetail(surah: tSurah, ayahs: []);
    const tStages = <KidsJourneyStage>[
      KidsJourneyStage(
        stageNumber: 1,
        surahId: 1,
        startAyah: 1,
        endAyah: 3,
        completedAyahs: [],
        status: KidsJourneyStageStatus.current,
      ),
    ];
    const tProgress = KidsProgress(
      totalPoints: 100,
      currentLevel: 1,
      currentStreak: 2,
      starsEarned: 5,
      ayahsCompleted: 3,
      lastSessionAt: null,
    );

    test(
      'places an interrupted kids session before new memorization',
      () async {
        await cubit.close();
        cubit = KidsJourneyCubit(
          mockGetJourney,
          mockGetProgress,
          mockQuranRepo,
          resumeMissionLoader: () async => const KidsNextMission(
            type: KidsMissionType.resume,
            surahId: 113,
            ayahNumbers: [2],
          ),
        );
        when(mockGetJourney(any)).thenAnswer((_) async => const Right(tStages));
        when(mockGetProgress()).thenAnswer((_) async => const Right(tProgress));
        when(
          mockQuranRepo.getSurahDetail(tSurahId),
        ).thenAnswer((_) async => const Right(tSurahDetail));

        await cubit.load(surahId: tSurahId);

        final loaded = cubit.state as KidsJourneyLoaded;
        expect(loaded.nextMission?.type, KidsMissionType.resume);
        expect(loaded.nextMission?.surahId, 113);
        expect(loaded.nextMission?.startAyah, 2);
      },
    );
    test(
      'emits [KidsJourneyLoading, KidsJourneyLoaded] when successful',
      () async {
        when(mockGetJourney(any)).thenAnswer((_) async => const Right(tStages));
        when(mockGetProgress()).thenAnswer((_) async => const Right(tProgress));
        when(
          mockQuranRepo.getSurahDetail(tSurahId),
        ).thenAnswer((_) async => const Right(tSurahDetail));

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const KidsJourneyLoading(),
            const KidsJourneyLoaded(
              surahId: tSurahId,
              stages: tStages,
              progress: tProgress,
              surahName: tSurahName,
              nextMission: KidsNextMission(
                type: KidsMissionType.newMemorization,
                surahId: tSurahId,
                ayahNumbers: [1],
              ),
            ),
          ]),
        );

        await cubit.load(surahId: tSurahId);
        await expectation;
      },
    );

    test(
      'emits [KidsJourneyLoading, KidsJourneyError] when journey fails',
      () async {
        when(
          mockGetJourney(any),
        ).thenAnswer((_) async => const Left(CacheFailure('Journey error')));
        when(mockGetProgress()).thenAnswer((_) async => const Right(tProgress));

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const KidsJourneyLoading(),
            const KidsJourneyError('Journey error'),
          ]),
        );

        await cubit.load(surahId: tSurahId);
        await expectation;
      },
    );

    test(
      'emits [KidsJourneyLoading, KidsJourneyError] when progress fails',
      () async {
        when(mockGetJourney(any)).thenAnswer((_) async => const Right(tStages));
        when(
          mockGetProgress(),
        ).thenAnswer((_) async => const Left(CacheFailure('Progress error')));

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const KidsJourneyLoading(),
            const KidsJourneyError('Progress error'),
          ]),
        );

        await cubit.load(surahId: tSurahId);
        await expectation;
      },
    );

    test('a used-up new-ayah quota reports the day as complete (N3)', () async {
      await cubit.close();
      cubit = KidsJourneyCubit(
        mockGetJourney,
        mockGetProgress,
        mockQuranRepo,
        sessionLogsLoader: () async => [
          KidsSessionLog(
            id: 'today',
            surahId: tSurahId,
            ayahNumber: 1,
            repeatsCompleted: 3,
            pointsEarned: 10,
            completedAt: DateTime.now(),
            missionType: KidsMissionType.newMemorization,
          ),
        ],
        policyLoader: () async => KidsSessionPolicy.forAge(6),
      );
      when(mockGetJourney(any)).thenAnswer((_) async => const Right(tStages));
      when(mockGetProgress()).thenAnswer((_) async => const Right(tProgress));
      when(
        mockQuranRepo.getSurahDetail(tSurahId),
      ).thenAnswer((_) async => const Right(tSurahDetail));

      await cubit.load(surahId: tSurahId);

      final loaded = cubit.state as KidsJourneyLoaded;
      // No mission the session gate would refuse; home shows day-complete.
      expect(loaded.nextMission, isNull);
      expect(loaded.dailyGoalCap, 1);
      expect(loaded.dailyGoalReached, isTrue);
    });

    group('current region', () {
      const stage113 = <KidsJourneyStage>[
        KidsJourneyStage(
          stageNumber: 1,
          surahId: 113,
          startAyah: 1,
          endAyah: 5,
          completedAyahs: [],
          status: KidsJourneyStageStatus.current,
        ),
      ];

      Surah surah(int id, int count) => Surah(
        id: id,
        nameAr: 's$id',
        nameEn: 's$id',
        ayahCount: count,
        juz: 30,
        type: 'meccan',
        page: 604,
      );

      KidsSessionLog log(int surahId, int ayah) => KidsSessionLog(
        id: '$surahId-$ayah',
        surahId: surahId,
        ayahNumber: ayah,
        repeatsCompleted: 3,
        pointsEarned: 10,
        completedAt: DateTime(2026, 10, 1),
        missionType: KidsMissionType.newMemorization,
      );

      Future<KidsJourneyLoaded> loadFor(
        int surahId, {
        KidsJourneySessionLogsLoader? logs,
        bool stubSurahs = true,
      }) async {
        await cubit.close();
        cubit = KidsJourneyCubit(
          mockGetJourney,
          mockGetProgress,
          mockQuranRepo,
          sessionLogsLoader: logs,
        );
        when(
          mockGetJourney(any),
        ).thenAnswer((_) async => const Right(stage113));
        when(mockGetProgress()).thenAnswer((_) async => const Right(tProgress));
        when(
          mockQuranRepo.getSurahDetail(any),
        ).thenAnswer((_) async => const Right(tSurahDetail));
        if (stubSurahs) {
          when(mockQuranRepo.getSurahs()).thenAnswer(
            (_) async => Right([surah(114, 6), surah(113, 5), surah(1, 7)]),
          );
        }
        await cubit.load(surahId: surahId);
        return cubit.state as KidsJourneyLoaded;
      }

      test('counts memorized surahs of the journey surah region', () async {
        final loaded = await loadFor(
          113,
          logs: () async => [for (var a = 1; a <= 6; a++) log(114, a)],
        );
        expect(loaded.currentRegion?.region.id, KidsRegionId.palmOasis);
        expect(loaded.currentRegion?.memorized, 1);
        expect(loaded.currentRegion?.total, 6);
      });

      test('is null when the surah is off the kids path', () async {
        final loaded = await loadFor(2, logs: () async => const []);
        expect(loaded.currentRegion, isNull);
      });

      test('is null when the surah list cannot be loaded', () async {
        final loaded = await loadFor(
          113,
          logs: () async => const [],
          stubSurahs: false,
        );
        expect(loaded.currentRegion, isNull);
      });

      test('is null when session logs are unreadable', () async {
        final loaded = await loadFor(
          113,
          logs: () async => throw StateError('storage'),
        );
        expect(loaded.currentRegion, isNull);
      });
    });

    group('daily missions', () {
      Future<KidsJourneyCubit> build({
        KidsReadingPagesLoader? readingPagesLoader,
        KidsHomeMissionsLoader? homeMissionsLoader,
        KidsChildPolicyReader? childPolicyReader,
        KidsChildPolicyRefresh? childPolicyRefresh,
        bool withTodayLog = true,
      }) async {
        await cubit.close();
        when(mockGetJourney(any)).thenAnswer((_) async => const Right(tStages));
        when(mockGetProgress()).thenAnswer((_) async => const Right(tProgress));
        when(
          mockQuranRepo.getSurahDetail(tSurahId),
        ).thenAnswer((_) async => const Right(tSurahDetail));
        return cubit = KidsJourneyCubit(
          mockGetJourney,
          mockGetProgress,
          mockQuranRepo,
          sessionLogsLoader: () async => [
            if (withTodayLog)
              KidsSessionLog(
                id: 'today',
                surahId: tSurahId,
                ayahNumber: 1,
                repeatsCompleted: 3,
                pointsEarned: 10,
                completedAt: DateTime.now(),
                missionType: KidsMissionType.newMemorization,
              ),
          ],
          readingPagesLoader: readingPagesLoader,
          homeMissionsLoader: homeMissionsLoader,
          childPolicyReader: childPolicyReader,
          childPolicyRefresh: childPolicyRefresh,
        );
      }

      test("learning and reading are completed by today's work", () async {
        final c = await build(readingPagesLoader: () async => {5});

        await c.load(surahId: tSurahId, followFrontier: true);

        final loaded = c.state as KidsJourneyLoaded;
        expect(loaded.dailyMissions.map((m) => m.kind), [
          KidsDailyMissionKind.learning,
          KidsDailyMissionKind.reading,
        ]);
        expect(
          loaded.dailyMissions.map((m) => m.status),
          everyElement(KidsDailyMissionStatus.completed),
        );
      });

      test('a loader error omits the reading mission (fail-open)', () async {
        final c = await build(
          readingPagesLoader: () async => throw StateError('prefs'),
        );

        await c.load(surahId: tSurahId, followFrontier: true);

        final loaded = c.state as KidsJourneyLoaded;
        expect(loaded, isA<KidsJourneyLoaded>());
        expect(
          loaded.dailyMissions.map((m) => m.kind),
          isNot(contains(KidsDailyMissionKind.reading)),
        );
      });

      KidsHomeMission homeMission(
        String id,
        KidsHomeMissionStatus status,
        DateTime createdAt,
      ) => KidsHomeMission(
        id: id,
        title: 'مهمة $id',
        status: status,
        createdAt: createdAt,
      );

      test('the oldest non-acknowledged home mission becomes the card', () async {
        final c = await build(
          readingPagesLoader: () async => {5},
          homeMissionsLoader: () async => [
            homeMission(
              '3',
              KidsHomeMissionStatus.assigned,
              DateTime(2026, 10, 3),
            ),
            homeMission(
              '1',
              KidsHomeMissionStatus.acknowledged,
              DateTime(2026, 9, 1),
            ),
            homeMission(
              '2',
              KidsHomeMissionStatus.reported,
              DateTime(2026, 10, 2),
            ),
          ],
        );

        await c.load(surahId: tSurahId, followFrontier: true);

        final loaded = c.state as KidsJourneyLoaded;
        final home = loaded.dailyMissions.last;
        expect(home.kind, KidsDailyMissionKind.home);
        expect(home.homeMissionId, '2');
        expect(home.status, KidsDailyMissionStatus.completed);
      });

      test('a failing home loader shows no home card and no error', () async {
        final c = await build(
          readingPagesLoader: () async => {5},
          homeMissionsLoader: () async => throw StateError('storage'),
        );

        await c.load(surahId: tSurahId, followFrontier: true);

        final loaded = c.state as KidsJourneyLoaded;
        expect(
          loaded.dailyMissions.map((m) => m.kind),
          isNot(contains(KidsDailyMissionKind.home)),
        );
      });

      test('only acknowledged missions means no home card', () async {
        final c = await build(
          readingPagesLoader: () async => {5},
          homeMissionsLoader: () async => [
            homeMission(
              '1',
              KidsHomeMissionStatus.acknowledged,
              DateTime(2026, 9, 1),
            ),
          ],
        );

        await c.load(surahId: tSurahId, followFrontier: true);

        final loaded = c.state as KidsJourneyLoaded;
        expect(
          loaded.dailyMissions.map((m) => m.kind),
          isNot(contains(KidsDailyMissionKind.home)),
        );
      });

      group('guardian policy (P3 Task 7)', () {
        List<KidsHomeMission> assigned() => [
          homeMission(
            '1',
            KidsHomeMissionStatus.assigned,
            DateTime(2026, 10, 2),
          ),
        ];

        test('one daily suggestion shows only the learning card', () async {
          final c = await build(
            readingPagesLoader: () async => {5},
            homeMissionsLoader: () async => assigned(),
            childPolicyReader: () =>
                const KidsChildPolicy(maxDailySuggestions: 1),
          );

          await c.load(surahId: tSurahId, followFrontier: true);

          final loaded = c.state as KidsJourneyLoaded;
          expect(loaded.dailyMissions.map((m) => m.kind), [
            KidsDailyMissionKind.learning,
          ]);
        });

        test('home missions disabled hides an assigned mission', () async {
          final c = await build(
            readingPagesLoader: () async => {5},
            homeMissionsLoader: () async => assigned(),
            childPolicyReader: () =>
                const KidsChildPolicy(homeMissionsEnabled: false),
          );

          await c.load(surahId: tSurahId, followFrontier: true);

          final loaded = c.state as KidsJourneyLoaded;
          expect(loaded.dailyMissions.map((m) => m.kind), [
            KidsDailyMissionKind.learning,
            KidsDailyMissionKind.reading,
          ]);
        });

        test('without a reader the default policy keeps all three', () async {
          final c = await build(
            readingPagesLoader: () async => {5},
            homeMissionsLoader: () async => assigned(),
          );

          await c.load(surahId: tSurahId, followFrontier: true);

          final loaded = c.state as KidsJourneyLoaded;
          expect(loaded.dailyMissions.map((m) => m.kind), [
            KidsDailyMissionKind.learning,
            KidsDailyMissionKind.reading,
            KidsDailyMissionKind.home,
          ]);
        });

        test('the home load refreshes the policy before applying it', () async {
          var policy = const KidsChildPolicy();
          final c = await build(
            readingPagesLoader: () async => {5},
            homeMissionsLoader: () async => assigned(),
            childPolicyReader: () => policy,
            childPolicyRefresh: () async {
              policy = const KidsChildPolicy(maxDailySuggestions: 1);
            },
          );

          await c.load(surahId: tSurahId, followFrontier: true);

          final loaded = c.state as KidsJourneyLoaded;
          expect(loaded.dailyMissions, hasLength(1));
        });

        test('a failing refresh keeps the last known policy', () async {
          final c = await build(
            readingPagesLoader: () async => {5},
            homeMissionsLoader: () async => assigned(),
            childPolicyReader: () =>
                const KidsChildPolicy(maxDailySuggestions: 2),
            childPolicyRefresh: () async => throw StateError('prefs'),
          );

          await c.load(surahId: tSurahId, followFrontier: true);

          final loaded = c.state as KidsJourneyLoaded;
          expect(loaded.dailyMissions, hasLength(2));
        });

        test('a throwing reader falls back to the default policy', () async {
          final c = await build(
            readingPagesLoader: () async => {5},
            homeMissionsLoader: () async => assigned(),
            childPolicyReader: () => throw StateError('di'),
          );

          await c.load(surahId: tSurahId, followFrontier: true);

          final loaded = c.state as KidsJourneyLoaded;
          expect(loaded.dailyMissions, hasLength(3));
        });
      });

      test('no loader means no reading mission', () async {
        final c = await build();

        await c.load(surahId: tSurahId, followFrontier: true);

        final loaded = c.state as KidsJourneyLoaded;
        expect(
          loaded.dailyMissions.map((m) => m.kind),
          isNot(contains(KidsDailyMissionKind.reading)),
        );
      });
    });

    test('an unreadable session log never reports the day complete', () async {
      await cubit.close();
      cubit = KidsJourneyCubit(
        mockGetJourney,
        mockGetProgress,
        mockQuranRepo,
        sessionLogsLoader: () async => throw StateError('storage'),
        policyLoader: () async => KidsSessionPolicy.forAge(6),
      );
      when(mockGetJourney(any)).thenAnswer((_) async => const Right(tStages));
      when(mockGetProgress()).thenAnswer((_) async => const Right(tProgress));
      when(
        mockQuranRepo.getSurahDetail(tSurahId),
      ).thenAnswer((_) async => const Right(tSurahDetail));

      await cubit.load(surahId: tSurahId);

      final loaded = cubit.state as KidsJourneyLoaded;
      expect(loaded.nextMission?.type, KidsMissionType.newMemorization);
      expect(loaded.dailyGoalReached, isFalse);
    });

    test('resolves a due review as the single next mission', () async {
      final dueRecord = AyahReviewRecord(
        surahId: tSurahId,
        ayahNumber: 1,
        strengthLevel: 1,
        intervalDays: 1,
        lastReviewedAt: DateTime.utc(2020, 1, 1),
        nextReviewDate: DateTime.utc(2020, 1, 2),
        totalReviews: 1,
        lastRating: PerformanceRating.average,
        createdByMode: ReviewRecordCreatedByMode.kidsMode,
      );
      cubit = KidsJourneyCubit(
        mockGetJourney,
        mockGetProgress,
        mockQuranRepo,
        reviewRecordsLoader: () async => [dueRecord],
      );
      when(mockGetJourney(any)).thenAnswer((_) async => const Right(tStages));
      when(mockGetProgress()).thenAnswer((_) async => const Right(tProgress));
      when(
        mockQuranRepo.getSurahDetail(tSurahId),
      ).thenAnswer((_) async => const Right(tSurahDetail));

      await cubit.load(surahId: tSurahId);

      final loaded = cubit.state as KidsJourneyLoaded;
      expect(loaded.nextMission?.type, KidsMissionType.dueReview);
      expect(loaded.nextMission?.ayahNumbers, const [1]);
    });

    test(
      'emits [KidsJourneyLoading, KidsJourneyLoaded] with null surahName if quranRepo fails',
      () async {
        when(mockGetJourney(any)).thenAnswer((_) async => const Right(tStages));
        when(mockGetProgress()).thenAnswer((_) async => const Right(tProgress));
        when(
          mockQuranRepo.getSurahDetail(tSurahId),
        ).thenAnswer((_) async => const Left(CacheFailure()));

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const KidsJourneyLoading(),
            const KidsJourneyLoaded(
              surahId: tSurahId,
              stages: tStages,
              progress: tProgress,
              surahName: null,
              nextMission: KidsNextMission(
                type: KidsMissionType.newMemorization,
                surahId: tSurahId,
                ayahNumbers: [1],
              ),
            ),
          ]),
        );

        await cubit.load(surahId: tSurahId);
        await expectation;
      },
    );

    group('journey continuation (K17/K18)', () {
      KidsJourneyStage done(int surahId) => KidsJourneyStage(
        stageNumber: 1,
        surahId: surahId,
        startAyah: 1,
        endAyah: 3,
        completedAyahs: const [1, 2, 3],
        status: KidsJourneyStageStatus.completed,
      );
      KidsSessionLog newToday() => KidsSessionLog(
        id: 'today',
        surahId: 114,
        ayahNumber: 3,
        repeatsCompleted: 3,
        pointsEarned: 10,
        completedAt: DateTime.now(),
        missionType: KidsMissionType.newMemorization,
      );

      void stubJourneys(Map<int, List<KidsJourneyStage>> bySurah) {
        when(mockGetJourney(any)).thenAnswer((invocation) async {
          final params =
              invocation.positionalArguments.first as GetKidsJourneyParams;
          return Right(bySurah[params.surahId] ?? const []);
        });
        when(mockGetProgress()).thenAnswer((_) async => const Right(tProgress));
        when(
          mockQuranRepo.getSurahDetail(any),
        ).thenAnswer((_) async => const Left(CacheFailure()));
      }

      test('a finished surah continues at the real frontier', () async {
        stubJourneys({
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
        });

        await cubit.load(surahId: 114);

        final loaded = cubit.state as KidsJourneyLoaded;
        expect(loaded.nextMission?.surahId, 112);
        expect(loaded.nextMission?.ayahNumbers, const [3]);
      });

      test(
        'a surah finished on a capped day is a day end, not the journey end',
        () async {
          await cubit.close();
          cubit = KidsJourneyCubit(
            mockGetJourney,
            mockGetProgress,
            mockQuranRepo,
            sessionLogsLoader: () async => [newToday()],
            policyLoader: () async => KidsSessionPolicy.forAge(6),
          );
          stubJourneys({
            114: [done(114)],
          });

          await cubit.load(surahId: 114);

          final loaded = cubit.state as KidsJourneyLoaded;
          expect(loaded.nextMission, isNull);
          expect(loaded.dailyGoalCap, 1);
        },
      );

      test('home follows the journey past a finished surah (K20)', () async {
        const open113 = KidsJourneyStage(
          stageNumber: 1,
          surahId: 113,
          startAyah: 1,
          endAyah: 5,
          completedAyahs: [1],
          status: KidsJourneyStageStatus.current,
        );
        stubJourneys({
          114: [done(114)],
          113: const [open113],
        });

        await cubit.load(surahId: 114, followFrontier: true);

        final loaded = cubit.state as KidsJourneyLoaded;
        expect(loaded.surahId, 113);
        expect(loaded.stages, const [open113]);
        expect(loaded.currentStage, open113);
        expect(loaded.nextMission?.surahId, 113);
        expect(loaded.nextMission?.ayahNumbers, const [2]);
      });

      test('the map keeps the surah it was opened for', () async {
        stubJourneys({
          114: [done(114)],
          113: const [
            KidsJourneyStage(
              stageNumber: 1,
              surahId: 113,
              startAyah: 1,
              endAyah: 5,
              completedAyahs: [],
              status: KidsJourneyStageStatus.current,
            ),
          ],
        });

        await cubit.load(surahId: 114);

        final loaded = cubit.state as KidsJourneyLoaded;
        expect(loaded.surahId, 114);
        expect(loaded.nextMission?.surahId, 113);
      });

      test('names the surah of a review mission elsewhere (K20)', () async {
        await cubit.close();
        cubit = KidsJourneyCubit(
          mockGetJourney,
          mockGetProgress,
          mockQuranRepo,
          reviewRecordsLoader: () async => [
            AyahReviewRecord(
              surahId: 112,
              ayahNumber: 2,
              strengthLevel: 3,
              intervalDays: 1,
              lastReviewedAt: DateTime.utc(2026, 1, 1),
              nextReviewDate: DateTime.utc(2026, 1, 2),
              totalReviews: 1,
              lastRating: PerformanceRating.average,
              createdByMode: ReviewRecordCreatedByMode.kidsMode,
            ),
          ],
        );
        stubJourneys({
          114: const [
            KidsJourneyStage(
              stageNumber: 1,
              surahId: 114,
              startAyah: 1,
              endAyah: 6,
              completedAyahs: [1],
              status: KidsJourneyStageStatus.current,
            ),
          ],
        });
        when(mockQuranRepo.getSurahDetail(112)).thenAnswer(
          (_) async => const Right(
            SurahDetail(
              surah: Surah(
                id: 112,
                nameAr: 'الإخلاص',
                nameEn: 'Al-Ikhlas',
                ayahCount: 4,
                juz: 30,
                type: 'meccan',
                page: 604,
              ),
              ayahs: [],
            ),
          ),
        );

        await cubit.load(surahId: 114, followFrontier: true);

        final loaded = cubit.state as KidsJourneyLoaded;
        expect(loaded.surahId, 114);
        expect(loaded.nextMission?.surahId, 112);
        expect(loaded.missionSurahName, 'الإخلاص');
      });

      test('a finished journey is never reported as a capped day', () async {
        await cubit.close();
        cubit = KidsJourneyCubit(
          mockGetJourney,
          mockGetProgress,
          mockQuranRepo,
          sessionLogsLoader: () async => [newToday()],
          policyLoader: () async => KidsSessionPolicy.forAge(6),
        );
        stubJourneys({
          78: [done(78)],
        });

        await cubit.load(surahId: 78);

        final loaded = cubit.state as KidsJourneyLoaded;
        expect(loaded.nextMission, isNull);
        expect(loaded.dailyGoalCap, isNull);
      });
    });
  });

  group('missionStage', () {
    const needsReview = KidsJourneyStage(
      stageNumber: 1,
      surahId: 114,
      startAyah: 1,
      endAyah: 3,
      completedAyahs: [1, 2, 3],
      status: KidsJourneyStageStatus.needsReview,
    );
    const current = KidsJourneyStage(
      stageNumber: 2,
      surahId: 114,
      startAyah: 4,
      endAyah: 6,
      completedAyahs: [],
      status: KidsJourneyStageStatus.current,
    );

    test('describes the stage the new mission really opens (K19)', () {
      const state = KidsJourneyLoaded(
        surahId: 114,
        stages: [needsReview, current],
        progress: KidsProgress.initial(),
        nextMission: KidsNextMission(
          type: KidsMissionType.newMemorization,
          surahId: 114,
          ayahNumbers: [4],
        ),
      );

      expect(state.missionStage, current);
    });

    test('falls back to the current stage without a mission', () {
      const state = KidsJourneyLoaded(
        surahId: 114,
        stages: [needsReview, current],
        progress: KidsProgress.initial(),
      );

      expect(state.missionStage, needsReview);
    });

    test('has no stage for a mission in another surah', () {
      const state = KidsJourneyLoaded(
        surahId: 114,
        stages: [needsReview],
        progress: KidsProgress.initial(),
        nextMission: KidsNextMission(
          type: KidsMissionType.newMemorization,
          surahId: 113,
          ayahNumbers: [1],
        ),
      );

      expect(state.missionStage, isNull);
    });
  });
}
