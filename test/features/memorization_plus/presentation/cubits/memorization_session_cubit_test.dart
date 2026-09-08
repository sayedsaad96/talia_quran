import 'dart:async';

// import 'package:bloc_test/bloc_test.dart'; // bloc_test is missing or unused
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';
import 'package:talia_quran/core/memorization/v2/session_adapters.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/services/audio_cache_service.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/v2_session_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';

import 'memorization_session_cubit_test.mocks.dart';

@GenerateMocks([
  QuranRepository,
  MemorizationPlusRepository,
  ScheduleNextReviewUsecase,
  V2SessionLocalDatasource,
  XpService,
  StreakService,
  AchievementService,
  AudioPlayer,
  SpeechToText,
  AudioCacheService,
])
void main() {
  // The cubit constructor touches AudioLifecycleManager, whose
  // AppLifecycleListener requires an initialized binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockQuranRepository mockQuranRepo;
  late MockMemorizationPlusRepository mockMemRepo;
  late V2SessionEngine realEngine;
  late MockScheduleNextReviewUsecase mockScheduler;
  late MockV2SessionLocalDatasource mockLocalDatasource;
  late MockXpService mockXPService;
  late MockStreakService mockStreakService;
  late MockAchievementService mockAchievementService;

  late V2SessionReviewAdapter realReviewAdapter;
  late V2SessionProgressAdapter realProgressAdapter;
  late V2SessionGamificationAdapter realGamificationAdapter;
  late MockAudioPlayer mockAudioPlayer;
  late MockSpeechToText mockSpeechToText;
  late MockAudioCacheService mockAudioCache;
  late MemorizationSessionCubit cubit;

  const defaultSurah = Surah(
    id: 1,
    nameAr: 'الفاتحة',
    nameEn: 'Al-Fatiha',
    ayahCount: 10,
    juz: 1,
    type: 'meccan',
    page: 1,
  );

  final defaultAyahs = List.generate(
    10,
    (index) => Ayah(
      surahId: 1,
      numberInSurah: index + 1,
      number: index + 1,
      juz: 1,
      page: 1,
      text: 'Ayah ${index + 1}',
    ),
  );

  setUp(() {
    mockQuranRepo = MockQuranRepository();
    mockMemRepo = MockMemorizationPlusRepository();
    realEngine = V2SessionEngine();
    mockScheduler = MockScheduleNextReviewUsecase();
    mockLocalDatasource = MockV2SessionLocalDatasource();
    when(mockLocalDatasource.currentOwnerId).thenReturn('test-owner');
    mockXPService = MockXpService();
    mockStreakService = MockStreakService();
    mockAchievementService = MockAchievementService();

    realReviewAdapter = V2SessionReviewAdapter(
      repository: mockMemRepo,
      scheduler: mockScheduler,
    );
    realProgressAdapter = V2SessionProgressAdapter(
      datasource: mockLocalDatasource,
    );
    realGamificationAdapter = V2SessionGamificationAdapter(
      xpService: mockXPService,
      streakService: mockStreakService,
      achievementService: mockAchievementService,
    );
    mockAudioPlayer = MockAudioPlayer();
    mockSpeechToText = MockSpeechToText();
    mockAudioCache = MockAudioCacheService();

    when(
      mockAudioPlayer.playerStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockSpeechToText.initialize(
        onError: anyNamed('onError'),
        onStatus: anyNamed('onStatus'),
      ),
    ).thenAnswer((_) async => true);
    when(
      mockMemRepo.getMemorizationProfile(),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    when(mockQuranRepo.getSurahDetail(1)).thenAnswer(
      (_) async => Right(SurahDetail(surah: defaultSurah, ayahs: defaultAyahs)),
    );
    when(mockLocalDatasource.getSession(1)).thenAnswer((_) async => null);
    when(mockLocalDatasource.saveSession(any)).thenAnswer((_) async {});
    when(
      mockAudioCache.prefetchSession(
        surahId: 1,
        ayahNumbers: anyNamed('ayahNumbers'),
      ),
    ).thenAnswer((_) async {});

    cubit = MemorizationSessionCubit(
      quranRepository: mockQuranRepo,
      memorizationRepository: mockMemRepo,
      sessionEngine: realEngine,
      reviewAdapter: realReviewAdapter,
      progressAdapter: realProgressAdapter,
      gamificationAdapter: realGamificationAdapter,
      audioPlayer: mockAudioPlayer,
      speechToText: mockSpeechToText,
      audioCacheService: mockAudioCache,
    );
  });

  tearDown(() {
    cubit.close();
  });

  void stubReviewWrite() {
    when(
      mockMemRepo.getReviewRecord(any, any, scope: anyNamed('scope')),
    ).thenAnswer((_) async => const Right(null));
    when(
      mockMemRepo.saveReviewRecord(any),
    ).thenAnswer((_) async => const Right(null));
    when(mockScheduler.schedule(any, any)).thenAnswer((invocation) {
      final record = invocation.positionalArguments[0] as AyahReviewRecord;
      final rating = invocation.positionalArguments[1] as PerformanceRating;
      return const ScheduleNextReviewUsecase().schedule(record, rating);
    });
  }

  group('startSession', () {
    test('emits MSActive when new session starts successfully', () async {
      when(
        mockMemRepo.getMemorizationProfile(),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      when(mockQuranRepo.getSurahDetail(1)).thenAnswer(
        (_) async =>
            Right(SurahDetail(surah: defaultSurah, ayahs: defaultAyahs)),
      );
      when(mockLocalDatasource.getSession(1)).thenAnswer((_) async => null);

      when(mockLocalDatasource.saveSession(any)).thenAnswer((_) async {});
      when(
        mockAudioCache.prefetchSession(
          surahId: 1,
          ayahNumbers: anyNamed('ayahNumbers'),
        ),
      ).thenAnswer((_) async {});

      await cubit.startSession(surahId: 1, startAyah: 1, blockSize: 5);

      expect(cubit.state, isA<MSActive>());
      final active = cubit.state as MSActive;
      expect(active.sessionState.phase, V2SessionPhase.learning);
    });
  });

  group('advanceToMemorizing', () {
    test('transitions to memorizing phase', () async {
      // Setup initial state
      when(
        mockMemRepo.getMemorizationProfile(),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      when(mockQuranRepo.getSurahDetail(1)).thenAnswer(
        (_) async =>
            Right(SurahDetail(surah: defaultSurah, ayahs: defaultAyahs)),
      );
      when(mockLocalDatasource.getSession(1)).thenAnswer((_) async => null);

      when(mockLocalDatasource.saveSession(any)).thenAnswer((_) async {});
      when(
        mockAudioCache.prefetchSession(
          surahId: 1,
          ayahNumbers: anyNamed('ayahNumbers'),
        ),
      ).thenAnswer((_) async {});

      await cubit.startSession(surahId: 1, startAyah: 1, blockSize: 5);

      await cubit.advanceToMemorizing();

      expect(cubit.state, isA<MSActive>());
      expect(
        (cubit.state as MSActive).sessionState.phase,
        V2SessionPhase.memorizing,
      );
    });
  });

  group('useHint', () {
    test('persists hint usage so resume restores the hint level', () async {
      await _startSession(cubit);
      await cubit.advanceToMemorizing();

      await cubit.useHint(V2HintLevel.firstWord);

      final saved =
          verify(mockLocalDatasource.saveSession(captureAny)).captured.last
              as IsarV2Session;
      expect(saved.hintLevels[1], V2HintLevel.firstWord.index);

      when(mockLocalDatasource.getSession(1)).thenAnswer((_) async => saved);
      await cubit.startSession(surahId: 1, startAyah: 1, blockSize: 5);

      expect(cubit.state, isA<MSActive>());
      final restored = (cubit.state as MSActive).sessionState;
      expect(restored.hintTracker.levelFor(1, 1), V2HintLevel.firstWord);
    });
  });

  group('post-evaluation SRS writes', () {
    test(
      'REGRESSION: real engine transitions persist every automatic pass in blocks 1, 5, and 7',
      () async {
        // The engine deliberately clears lastRecitationResult while it moves
        // from one ayah to the next. This exercises that real transition so a
        // Cubit that keys persistence from the cleared UI result loses the
        // first N-1 review records.
        for (final blockSize in [1, 5, 7]) {
          clearInteractions(mockMemRepo);
          stubReviewWrite();

          await cubit.startSession(
            surahId: 1,
            startAyah: 1,
            blockSize: blockSize,
          );

          for (var ayahNumber = 1; ayahNumber <= blockSize; ayahNumber++) {
            await cubit.advanceToMemorizing();
            await cubit.advanceToReciting();
            await cubit.evaluateCurrentRecitationForTesting('Ayah $ayahNumber');
          }

          final recorded = verify(
            mockMemRepo.saveReviewRecord(captureAny),
          ).captured.cast<AyahReviewRecord>();
          expect(
            recorded.map((record) => record.ayahNumber).toList(),
            List<int>.generate(blockSize, (index) => index + 1),
            reason:
                'a passed ayah must be scheduled once even when the engine '
                'clears its ephemeral recitation result before the next ayah',
          );

          await cubit.close();
          cubit = MemorizationSessionCubit(
            quranRepository: mockQuranRepo,
            memorizationRepository: mockMemRepo,
            sessionEngine: realEngine,
            reviewAdapter: realReviewAdapter,
            progressAdapter: realProgressAdapter,
            gamificationAdapter: realGamificationAdapter,
            audioPlayer: mockAudioPlayer,
            speechToText: mockSpeechToText,
            audioCacheService: mockAudioCache,
          );
        }
      },
    );

    test(
      'REGRESSION: a failed review-record read does not fabricate a fresh SRS baseline',
      () async {
        stubReviewWrite();
        when(
          mockMemRepo.getReviewRecord(any, any, scope: anyNamed('scope')),
        ).thenAnswer((_) async => const Left(CacheFailure()));

        final outcome = await realReviewAdapter.recordPass(
          surahId: 1,
          ayahNumber: 1,
          hintLevel: V2HintLevel.none,
        );

        expect(outcome.isLeft(), isTrue);
        verifyNever(mockMemRepo.saveReviewRecord(any));
      },
    );

    test(
      'REGRESSION: an SRS failure leaves the completed ayah resumable and grants no rewards',
      () async {
        stubReviewWrite();
        final childProfile = MemorizationProfile(
          schemaVersion: 1,
          selectedPath: MemorizationPath.child,
          guardianLinkStatus: GuardianLinkStatus.none,
          guardianOnboardingStatus: GuardianOnboardingStatus.required,
          isParentGuardian: false,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          childAge: 7,
        );
        when(
          mockMemRepo.getMemorizationProfile(),
        ).thenAnswer((_) async => Right(childProfile));
        when(
          mockMemRepo.getReviewRecord(any, any, scope: anyNamed('scope')),
        ).thenAnswer((_) async => const Left(CacheFailure()));

        await cubit.startSession(surahId: 1, startAyah: 1, blockSize: 1);
        await cubit.advanceToMemorizing();
        await cubit.advanceToReciting();
        await cubit.evaluateCurrentRecitationForTesting('Ayah 1');

        expect(cubit.state, isA<MSActive>());
        final active = cubit.state as MSActive;
        expect(active.sessionState.phase, V2SessionPhase.reciting);
        expect(active.sessionState.passedAyahNumbers, isEmpty);
        verifyNever(mockLocalDatasource.clearSession(1));
        verifyNever(mockXPService.addXp(any));
        verifyNever(
          mockStreakService.recordActivity(
            activityDelta: anyNamed('activityDelta'),
          ),
        );
      },
    );

    test(
      'REGRESSION: a checkpoint write failure keeps the pre-evaluation state and never completes',
      () async {
        stubReviewWrite();
        await cubit.startSession(surahId: 1, startAyah: 1, blockSize: 1);
        await cubit.advanceToMemorizing();
        await cubit.advanceToReciting();

        when(
          mockLocalDatasource.saveSession(any),
        ).thenThrow(StateError('Isar checkpoint unavailable'));

        await cubit.evaluateCurrentRecitationForTesting('Ayah 1');

        expect(cubit.state, isA<MSActive>());
        final active = cubit.state as MSActive;
        expect(active.sessionState.phase, V2SessionPhase.reciting);
        expect(active.sessionState.passedAyahNumbers, isEmpty);
        expect(active.persistenceIssue, isNotNull);
        verifyNever(mockLocalDatasource.clearSession(1));
        verifyNever(mockXPService.addXp(any));
        verifyNever(
          mockStreakService.recordActivity(
            activityDelta: anyNamed('activityDelta'),
          ),
        );
      },
    );

    test(
      'records the review before checkpointing a newly passed ayah',
      () async {
        await _startSession(cubit);
        stubReviewWrite();

        final previous = (cubit.state as MSActive).sessionState.copyWith(
          phase: V2SessionPhase.reciting,
        );
        final next = previous.copyWith(
          phase: V2SessionPhase.learning,
          passedAyahNumbers: {1},
          lastRecitationResult: const V2RecitationResult(
            passed: true,
            similarityScore: 1,
            normalizedTarget: 'ayah 1',
            normalizedSpoken: 'ayah 1',
          ),
        );

        final events = <String>[];
        when(mockLocalDatasource.saveSession(any)).thenAnswer((
          invocation,
        ) async {
          final session = invocation.positionalArguments.first as IsarV2Session;
          events.add('save:${session.passedAyahNumbersCsv}');
        });
        when(mockMemRepo.saveReviewRecord(any)).thenAnswer((_) async {
          events.add('recordPass');
          return const Right(null);
        });

        await cubit.handlePostEvaluationForTesting(previous, next);

        expect(events, ['recordPass', 'save:1']);
      },
    );

    test(
      'skips recordPass when the ayah already passed in this session',
      () async {
        await _startSession(cubit);
        stubReviewWrite();

        final previous = (cubit.state as MSActive).sessionState.copyWith(
          phase: V2SessionPhase.reciting,
          passedAyahNumbers: {1},
        );
        final next = previous.copyWith(
          lastRecitationResult: const V2RecitationResult(
            passed: true,
            similarityScore: 1,
            normalizedTarget: 'ayah 1',
            normalizedSpoken: 'ayah 1',
          ),
        );

        await cubit.handlePostEvaluationForTesting(previous, next);

        verifyNever(mockMemRepo.saveReviewRecord(any));
      },
    );
  });

  group('V1-M8 honest assessment outcomes', () {
    Future<void> moveToReciting() async {
      await cubit.startSession(surahId: 1, startAyah: 1, blockSize: 1);
      expect(cubit.state, isA<MSActive>());
      await cubit.advanceToMemorizing();
      await cubit.advanceToReciting();
      expect(
        (cubit.state as MSActive).sessionState.phase,
        V2SessionPhase.reciting,
      );
    }

    test('automatic STT keeps its score and automatic method', () async {
      stubReviewWrite();
      await moveToReciting();

      await cubit.evaluateCurrentRecitationForTesting('Ayah 1');

      final result =
          (cubit.state as MSActive).sessionState.lastRecitationResult;
      expect(result?.assessmentMethod, V2AssessmentMethod.automatic);
      expect(result?.similarityScore, 1.0);
      expect(result?.normalizedSpoken, isNotEmpty);
      verify(mockMemRepo.saveReviewRecord(any)).called(1);
    });

    test(
      'no-speech fallback records a manual result without a fake score',
      () async {
        stubReviewWrite();
        await moveToReciting();

        await cubit.evaluateCurrentRecitationForTesting('');

        final noSpeech = cubit.state as MSActive;
        expect(noSpeech.speechIssue, V2SpeechIssue.noSpeech);
        expect(noSpeech.sessionState.lastRecitationResult, isNull);
        verifyNever(mockMemRepo.saveReviewRecord(any));

        await cubit.submitManualRecall();

        final result =
            (cubit.state as MSActive).sessionState.lastRecitationResult;
        expect(result?.assessmentMethod, V2AssessmentMethod.manual);
        expect(result?.similarityScore, isNull);
        expect(result?.normalizedSpoken, isEmpty);
        expect((cubit.state as MSActive).speechIssue, isNull);
        verify(mockMemRepo.saveReviewRecord(any)).called(1);
      },
    );

    test('rapid duplicate manual callbacks persist one review only', () async {
      stubReviewWrite();
      await moveToReciting();

      final first = cubit.submitManualRecall();
      final duplicate = cubit.submitManualRecall();
      await Future.wait([first, duplicate]);

      final result =
          (cubit.state as MSActive).sessionState.lastRecitationResult;
      expect(result?.assessmentMethod, V2AssessmentMethod.manual);
      verify(mockMemRepo.saveReviewRecord(any)).called(1);
    });
  });

  group('resume corruption guard', () {
    test(
      'REGRESSION: a corrupt persisted phase index resumes safely without bypassing review',
      () async {
        final corrupt = IsarV2Session.create(
          surahId: 1,
          blockAyahNumbers: const [1, 2],
          currentAyahIndex: 99,
          phaseIndex: 999,
          passedAyahNumbers: const {1},
          failureCounts: const {},
          hintLevels: const {},
          blockReviewRequired: true,
        );
        when(
          mockLocalDatasource.getSession(1),
        ).thenAnswer((_) async => corrupt);

        await cubit.startSession(surahId: 1, startAyah: 1, blockSize: 2);

        expect(cubit.state, isA<MSActive>());
        final restored = (cubit.state as MSActive).sessionState;
        expect(restored.phase, V2SessionPhase.learning);
        expect(restored.currentAyah.numberInSurah, 2);
        expect(restored.passedAyahNumbers, {1});
      },
    );
  });
}

Future<void> _startSession(MemorizationSessionCubit cubit) async {
  await cubit.startSession(surahId: 1, startAyah: 1, blockSize: 5);
  expect(cubit.state, isA<MSActive>());
}
