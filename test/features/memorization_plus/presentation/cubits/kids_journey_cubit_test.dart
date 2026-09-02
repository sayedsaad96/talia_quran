import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
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
  });
}
