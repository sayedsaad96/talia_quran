import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/v2/session_adapters.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_result.dart';
import 'package:talia_quran/features/xp/domain/entities/xp_gain_result.dart';

import 'memorization_session_cubit_test.mocks.dart' show MockSpeechToText;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KidsModeCubit', () {
    late _FakeMemorizationPlusRepository repository;
    late _FakeAchievementService achievementService;
    late _UnusedQuranRepository quranRepository;
    late _FakeStreakService streakService;
    late _FakeXpService xpService;
    late KidsModeCubit cubit;

    KidsModeCubit buildCubit({required KidsRecitationRecorder recorder}) =>
        KidsModeCubit(
          GetKidsProgressUsecase(repository),
          GetKidsJourneyUsecase(repository),
          AwardKidsPointsUsecase(repository),
          achievementService,
          quranRepository,
          V2SessionEngine(),
          V2SessionReviewAdapter(
            repository: repository,
            scheduler: const ScheduleNextReviewUsecase(),
          ),
          streakService,
          xpService,
          recorder,
        );

    setUp(() {
      repository = _FakeMemorizationPlusRepository();
      achievementService = _FakeAchievementService();
      quranRepository = _UnusedQuranRepository();
      streakService = _FakeStreakService();
      xpService = _FakeXpService();

      cubit = buildCubit(recorder: _FakeKidsRecitationRecorder());
    });

    tearDown(() async {
      await cubit.close();
    });

    test(
      'rapid duplicate manual completion calls award side effects once',
      () async {
        final awardCompleter =
            Completer<Either<Failure, KidsCompletionResult>>();
        repository.awardCompleter = awardCompleter;

        await cubit.load(114, 1, 'ayah text');
        final firstCompletion = cubit.submitManualCompletion();
        await Future<void>.delayed(Duration.zero);
        final duplicateCompletion = cubit.submitManualCompletion();
        await Future<void>.delayed(Duration.zero);

        expect(repository.awardCalls, 1);

        awardCompleter.complete(
          Right(
            KidsCompletionResult(
              progress: const KidsProgress.initial().addPoints(14),
              pointsEarned: 14,
              starsEarned: 1,
              alreadyCompleted: false,
            ),
          ),
        );

        await Future.wait([firstCompletion, duplicateCompletion]);

        expect(repository.awardCalls, 1);
        expect(repository.repeatsCompletedCalls, [0]);
        expect(repository.markCalls, 1);
        expect(streakService.recordCalls, 1);
        expect(xpService.addCalls, 1);
        expect(repository.awardLogWrites, 1);
        expect(repository.saveLogCalls, 0);
        expect(achievementService.checkCalls, 1);
      },
    );

    test(
      'review record failure still awards points then emits error',
      () async {
        repository.reviewWriteFailure = const CacheFailure(
          'review write failed',
        );
        repository.awardCompleter = Completer()
          ..complete(
            const Right(
              KidsCompletionResult(
                progress: KidsProgress.initial(),
                pointsEarned: 14,
                starsEarned: 1,
                alreadyCompleted: false,
              ),
            ),
          );

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);

        await cubit.submitManualCompletion();

        expect(cubit.state, isA<KidsModeLoaded>());
        final loaded = cubit.state as KidsModeLoaded;
        expect(loaded.isCompleted, isTrue);
        expect(loaded.recordingError, CubitMessageCodes.hifzReviewSaveFailed);
        expect(repository.markCalls, 1);
        expect(repository.awardCalls, 1);
        expect(repository.awardLogWrites, 1);
        expect(repository.saveLogCalls, 0);
      },
    );

    test('load rejects an ayah in a locked journey stage', () async {
      repository.journey = const [
        KidsJourneyStage(
          stageNumber: 1,
          surahId: 114,
          startAyah: 1,
          endAyah: 5,
          completedAyahs: [],
          status: KidsJourneyStageStatus.current,
        ),
        KidsJourneyStage(
          stageNumber: 2,
          surahId: 114,
          startAyah: 6,
          endAyah: 6,
          completedAyahs: [],
          status: KidsJourneyStageStatus.locked,
        ),
      ];

      await cubit.load(114, 6, 'ayah text');

      expect(cubit.state, isA<KidsModeError>());
      expect(repository.getJourneyCalls, 1);
    });

    test(
      'startRecording does not complete when no recitation is captured',
      () async {
        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(
            result: const KidsRecitationCaptureResult.stoppedByUser(),
          ),
        );

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);

        await cubit.startRecording();

        final state = cubit.state as KidsModeLoaded;
        expect(state.isCompleted, isFalse);
        expect(state.isRecording, isFalse);
        expect(
          state.recordingError,
          CubitMessageCodes.kidsRecordingNotCaptured,
        );
        expect(repository.awardCalls, 0);
        expect(repository.markCalls, 0);
        expect(repository.saveLogCalls, 0);
      },
    );

    test(
      'stopRecording ignores a capture signal that already completed',
      () async {
        await cubit.close();
        final recorder = _PrecompletedKidsRecitationRecorder();
        cubit = buildCubit(recorder: recorder);

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);

        final recording = cubit.startRecording();
        await recorder.captureStarted.future;

        Object? stopError;
        try {
          await cubit.stopRecording();
        } catch (error) {
          stopError = error;
        }
        recorder.finishCapture.complete(
          const KidsRecitationCaptureResult.unavailable(),
        );
        await recording;

        expect(stopError, isNull);
        final state = cubit.state as KidsModeLoaded;
        expect(state.isRecording, isFalse);
        expect(
          state.recordingError,
          CubitMessageCodes.kidsRecordingUnavailable,
        );
      },
    );

    test('startRecording completes after recitation is captured', () async {
      repository.awardCompleter = Completer()
        ..complete(
          Right(
            KidsCompletionResult(
              progress: const KidsProgress.initial().addPoints(14),
              pointsEarned: 14,
              starsEarned: 1,
              alreadyCompleted: false,
            ),
          ),
        );

      cubit = buildCubit(
        recorder: _FakeKidsRecitationRecorder(
          result: const KidsRecitationCaptureResult.captured(
            words: 'ayah text',
          ),
        ),
      );

      await cubit.load(114, 1, 'ayah text');
      cubit.debugSetLoopCount(3);

      await cubit.startRecording();

      final state = cubit.state as KidsModeLoaded;
      expect(state.isCompleted, isTrue);
      expect(
        state.sessionState.lastRecitationResult?.assessmentMethod,
        V2AssessmentMethod.automatic,
      );
      expect(state.sessionState.lastRecitationResult?.similarityScore, 1.0);
      expect(
        state.sessionState.lastRecitationResult?.normalizedSpoken,
        isNotEmpty,
      );
      expect(repository.awardCalls, 1);
      expect(repository.markCalls, 1);
      expect(repository.awardLogWrites, 1);
      expect(repository.saveLogCalls, 0);
    });

    test(
      'automatic completion with missing transcript does not award or complete',
      () async {
        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);

        await cubit.markCompleted();
        await cubit.markCompleted(automaticSpokenText: '   ');

        final state = cubit.state as KidsModeLoaded;
        expect(state.isCompleted, isFalse);
        expect(
          state.recordingError,
          CubitMessageCodes.kidsRecordingNotCaptured,
        );
        expect(state.sessionState.lastRecitationResult, isNull);
        expect(repository.awardCalls, 0);
        expect(repository.markCalls, 0);
        expect(repository.awardLogWrites, 0);
        expect(streakService.recordCalls, 0);
        expect(xpService.addCalls, 0);
      },
    );
    test(
      'manual completion records manual outcome without fake transcript',
      () async {
        repository.awardCompleter = Completer()
          ..complete(
            const Right(
              KidsCompletionResult(
                progress: KidsProgress.initial(),
                pointsEarned: 14,
                starsEarned: 1,
                alreadyCompleted: false,
              ),
            ),
          );

        await cubit.load(114, 1, 'canonical ayah text');
        await cubit.submitManualCompletion();

        final loaded = cubit.state as KidsModeLoaded;
        expect(loaded.isCompleted, isTrue);
        expect(
          loaded.sessionState.lastRecitationResult?.assessmentMethod,
          V2AssessmentMethod.manual,
        );
        expect(
          loaded.sessionState.lastRecitationResult?.similarityScore,
          isNull,
        );
        expect(
          loaded.sessionState.lastRecitationResult?.normalizedSpoken,
          isEmpty,
        );
        expect(repository.repeatsCompletedCalls, [0]);
      },
    );

    test(
      'replay of an already-completed ayah does not record SRS pass',
      () async {
        repository.awardCompleter = Completer()
          ..complete(
            const Right(
              KidsCompletionResult(
                progress: KidsProgress.initial(),
                pointsEarned: 0,
                starsEarned: 0,
                alreadyCompleted: true,
              ),
            ),
          );

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);

        await cubit.submitManualCompletion();

        expect(cubit.state, isA<KidsModeLoaded>());
        final loaded = cubit.state as KidsModeLoaded;
        expect(loaded.isCompleted, isFalse);
        expect(loaded.sessionStarsEarned, 0);
        expect(
          loaded.recordingError,
          CubitMessageCodes.kidsAyahAlreadyCompleted,
        );
        expect(repository.awardCalls, 1);
        expect(repository.markCalls, 0);
        expect(streakService.recordCalls, 0);
        expect(xpService.addCalls, 0);
      },
    );

    test(
      'markCompleted records StreakService activity as the single streak source',
      () async {
        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);

        repository.awardCompleter = Completer()
          ..complete(
            const Right(
              KidsCompletionResult(
                progress: KidsProgress(
                  totalPoints: 14,
                  currentLevel: 1,
                  currentStreak: 5,
                  starsEarned: 1,
                  ayahsCompleted: 1,
                  lastSessionAt: null,
                ),
                pointsEarned: 14,
                starsEarned: 1,
                alreadyCompleted: false,
              ),
            ),
          );

        await cubit.submitManualCompletion();

        expect(streakService.recordCalls, 1);
        final state = cubit.state as KidsModeLoaded;
        expect(state.progress.currentStreak, 5);
      },
    );
  });

  group('KidsSpeechRecitationRecorder', () {
    const permissionChannel = MethodChannel(
      'flutter.baseflow.com/permissions/methods',
    );

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(permissionChannel, (call) async {
            if (call.method == 'checkPermissionStatus') return 1;
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(permissionChannel, null);
    });

    test('returns unavailable when speech initialization throws', () async {
      final speechToText = MockSpeechToText();
      when(
        speechToText.initialize(
          onError: anyNamed('onError'),
          onStatus: anyNamed('onStatus'),
        ),
      ).thenThrow(
        PlatformException(
          code: 'recognizerNotAvailable',
          message: 'Speech recognition not available on this device',
        ),
      );
      final recorder = KidsSpeechRecitationRecorder(speechToText: speechToText);
      final externalCompleter = Completer<KidsRecitationCaptureResult>();

      final result = await recorder.capture(
        externalCompleter: externalCompleter,
      );

      expect(result.isError, isTrue);
      expect(result.messageCode, CubitMessageCodes.kidsRecordingUnavailable);
      final signaledResult = await externalCompleter.future;
      expect(signaledResult.isError, isTrue);
      expect(
        signaledResult.messageCode,
        CubitMessageCodes.kidsRecordingUnavailable,
      );
    });
  });
}

KidsSessionLog _sessionLog() => KidsSessionLog(
  id: '114_1',
  surahId: 114,
  ayahNumber: 1,
  repeatsCompleted: 3,
  pointsEarned: 14,
  completedAt: DateTime.now().toUtc(),
);

class _FakeMemorizationPlusRepository implements MemorizationPlusRepository {
  Completer<Either<Failure, KidsCompletionResult>>? awardCompleter;
  List<KidsJourneyStage> journey = const [
    KidsJourneyStage(
      stageNumber: 1,
      surahId: 114,
      startAyah: 1,
      endAyah: 6,
      completedAyahs: [],
      status: KidsJourneyStageStatus.current,
    ),
  ];
  int awardCalls = 0;
  int getJourneyCalls = 0;
  int markCalls = 0;
  int awardLogWrites = 0;
  int saveLogCalls = 0;
  final repeatsCompletedCalls = <int>[];
  Failure? reviewWriteFailure;

  @override
  Future<Either<Failure, KidsProgress>> getKidsProgress() async =>
      const Right(KidsProgress.initial());

  @override
  Future<Either<Failure, List<KidsJourneyStage>>> getKidsJourney({
    required int surahId,
  }) async {
    expect(surahId, 114);
    getJourneyCalls++;
    return Right(journey);
  }

  @override
  Future<Either<Failure, KidsCompletionResult>> awardKidsPoints({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
  }) async {
    expect(surahId, 114);
    expect(ayahNumber, 1);
    repeatsCompletedCalls.add(repeatsCompleted);
    awardCalls++;
    final result = await awardCompleter!.future;
    result.fold((_) {}, (completion) {
      if (!completion.alreadyCompleted) awardLogWrites++;
    });
    return result;
  }

  @override
  Future<Either<Failure, AyahReviewRecord?>> getReviewRecord(
    int surahId,
    int ayahNumber, {
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async {
    expect(surahId, 114);
    expect(ayahNumber, 1);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveReviewRecord(
    AyahReviewRecord record,
  ) async {
    expect(record.surahId, 114);
    expect(record.ayahNumber, 1);
    expect(record.createdByMode, ReviewRecordCreatedByMode.kidsMode);
    markCalls++;
    final failure = reviewWriteFailure;
    if (failure != null) return Left(failure);
    return const Right(null);
  }

  @override
  Future<Either<Failure, KidsSessionLog>> saveKidsSessionLog({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
    required int pointsEarned,
  }) async {
    expect(surahId, 114);
    expect(ayahNumber, 1);
    expect(repeatsCompleted, 3);
    expect(pointsEarned, 14);
    saveLogCalls++;
    return Right(_sessionLog());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> hasPendingCloudWork() async => false;
}

class _FakeAchievementService implements AchievementService {
  int checkCalls = 0;

  @override
  Future<List<CertificateAward>> checkAndUnlockCertificates({
    required bool isKids,
  }) async {
    checkCalls++;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedQuranRepository implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStreakService implements StreakService {
  int recordCalls = 0;

  @override
  Future<StreakResult> recordActivity({int activityDelta = 1}) async {
    expect(activityDelta, 1);
    recordCalls++;
    return const StreakResult.sameDay();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeXpService implements XpService {
  int addCalls = 0;

  @override
  Future<XpGainResult> addXp(String eventKey) async {
    expect(eventKey, 'ayah_memorized');
    addCalls++;
    return const XpGainResult.zero();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeKidsRecitationRecorder implements KidsRecitationRecorder {
  _FakeKidsRecitationRecorder({
    this.result = const KidsRecitationCaptureResult.stoppedByUser(),
  });

  final KidsRecitationCaptureResult result;

  @override
  Future<KidsRecitationCaptureResult> capture({
    Completer<KidsRecitationCaptureResult>? externalCompleter,
  }) async => result;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _PrecompletedKidsRecitationRecorder implements KidsRecitationRecorder {
  final captureStarted = Completer<void>();
  final finishCapture = Completer<KidsRecitationCaptureResult>();

  @override
  Future<KidsRecitationCaptureResult> capture({
    Completer<KidsRecitationCaptureResult>? externalCompleter,
  }) {
    externalCompleter!.complete(
      const KidsRecitationCaptureResult.unavailable(),
    );
    captureStarted.complete();
    return finishCapture.future;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
