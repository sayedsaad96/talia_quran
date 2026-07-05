import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

import 'kids_journey_cubit_test.mocks.dart';

@GenerateMocks([
  GetKidsJourneyUsecase,
  GetKidsProgressUsecase,
  ParentRemoteLinkUsecase,
  QuranRepository,
])
void main() {
  late MockGetKidsJourneyUsecase mockGetJourney;
  late MockGetKidsProgressUsecase mockGetProgress;
  late MockParentRemoteLinkUsecase mockRemoteLink;
  late MockQuranRepository mockQuranRepo;
  late KidsJourneyCubit cubit;

  setUp(() {
    mockGetJourney = MockGetKidsJourneyUsecase();
    mockGetProgress = MockGetKidsProgressUsecase();
    mockRemoteLink = MockParentRemoteLinkUsecase();
    mockQuranRepo = MockQuranRepository();

    cubit = KidsJourneyCubit(
      mockGetJourney,
      mockGetProgress,
      mockRemoteLink,
      mockQuranRepo,
    );
  });

  tearDown(() {
    cubit.close();
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
            ),
          ]),
        );

        await cubit.load(surahId: tSurahId);
        await expectation;
      },
    );
  });

  group('createRemoteLinkQr', () {
    const tToken = 'abc-123';

    test('does nothing if state is not KidsJourneyLoaded', () async {
      await cubit.createRemoteLinkQr();
      verifyNever(mockRemoteLink.createChildLinkToken());
    });

    test('emits states correctly when successful', () async {
      const initialState = KidsJourneyLoaded(
        surahId: 1,
        stages: [],
        progress: KidsProgress.initial(),
        surahName: 'test',
      );
      cubit.emit(initialState);

      when(
        mockRemoteLink.createChildLinkToken(),
      ).thenAnswer((_) async => const Right(tToken));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          initialState.copyWith(isCreatingLink: true, clearMessage: true),
          initialState.copyWith(
            isCreatingLink: false,
            qrPayload: 'talia-kids-link:$tToken',
            message: 'تم إنشاء رمز الربط. صالح لمدة 10 دقائق.',
          ),
        ]),
      );

      await cubit.createRemoteLinkQr();
      await expectation;
    });

    test('emits states correctly when fails', () async {
      const initialState = KidsJourneyLoaded(
        surahId: 1,
        stages: [],
        progress: KidsProgress.initial(),
        surahName: 'test',
      );
      cubit.emit(initialState);

      when(
        mockRemoteLink.createChildLinkToken(),
      ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          initialState.copyWith(isCreatingLink: true, clearMessage: true),
          initialState.copyWith(
            isCreatingLink: false,
            message: 'Network error',
            clearQrPayload: true,
          ),
        ]),
      );

      await cubit.createRemoteLinkQr();
      await expectation;
    });
  });
}
