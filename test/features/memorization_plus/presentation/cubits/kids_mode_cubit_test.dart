import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/review_record_identity.dart';
import 'package:talia_quran/core/memorization/v2/kids_review_outcome_committer.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/kids_streak_store.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_evidence_event.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/v2/session_adapters.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/v2_session_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import '../../../../helpers/isar_test_core.dart';

import 'memorization_session_cubit_test.mocks.dart'
    show MockAudioPlayer, MockSpeechToText;


Future<void> _initializeKidsResumeIsarCoreForTests() => initializeIsarCoreForTests();

Future<V2SessionProgressAdapter> _openKidsResumeAdapter() async {
  await _initializeKidsResumeIsarCoreForTests();
  final tempDir = await Directory.systemTemp.createTemp('talia_kids_resume_');
  final isar = await Isar.open(
    [IsarV2SessionSchema],
    directory: tempDir.path,
    name: 'kids_resume_${DateTime.now().microsecondsSinceEpoch}',
  );
  addTearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });
  return V2SessionProgressAdapter(
    datasource: V2SessionLocalDatasource(isar),
    audience: MemorizationAudience.kids,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KidsModeCubit', () {
    late _FakeMemorizationPlusRepository repository;
    late _FakeAchievementService achievementService;
    late _UnusedQuranRepository quranRepository;
    late _FakeStreakService streakService;
    late KidsModeCubit cubit;

    KidsModeCubit buildCubit({
      required KidsRecitationRecorder recorder,
      KidsSessionPolicy? policy,
      QuranRepository? quran,
      V2SessionProgressAdapter? progressAdapter,
      List<KidsSessionLog>? kidsSessionLogs,
      V2SessionEngine? engine,
      AudioPlayer? audioPlayer,
      KidsAudioSourceLoader? audioSourceLoader,
    }) => KidsModeCubit(
      GetKidsProgressUsecase(repository),
      GetKidsJourneyUsecase(repository),
      AwardKidsPointsUsecase(repository),
      achievementService,
      quran ?? quranRepository,
      engine ?? V2SessionEngine(),
      V2SessionReviewAdapter(
        repository: repository,
        scheduler: const ScheduleNextReviewUsecase(),
      ),
      streakService,
      recorder,
      null,
      (pin) async => pin == '1234',
      policy == null ? null : () async => policy,
      kidsSessionLogs == null ? null : () async => kidsSessionLogs,
      progressAdapter,
      null,
      null,
      audioPlayer,
      audioSourceLoader,
    );

    setUp(() {
      repository = _FakeMemorizationPlusRepository();
      achievementService = _FakeAchievementService();
      quranRepository = _UnusedQuranRepository();
      streakService = _FakeStreakService();

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

        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(
            result: const KidsRecitationCaptureResult.unavailable(),
          ),
        );
        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);
        await cubit.startRecording();
        final firstCompletion = cubit.submitManualCompletion(
          guardianPin: '1234',
        );
        await Future<void>.delayed(Duration.zero);
        final duplicateCompletion = cubit.submitManualCompletion(
          guardianPin: '1234',
        );
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
        expect(repository.repeatsCompletedCalls, [3]);
        expect(repository.markCalls, 1);
        expect(streakService.recordCalls, 1);
        expect(repository.awardLogWrites, 1);
        expect(repository.saveLogCalls, 0);
        expect(achievementService.checkCalls, 1);
      },
    );

    test('restores and clears an interrupted kids V2 session', () async {
      await _initializeKidsResumeIsarCoreForTests();
      final tempDir = await Directory.systemTemp.createTemp(
        'talia_kids_resume_',
      );
      final isar = await Isar.open(
        [IsarV2SessionSchema],
        directory: tempDir.path,
        name: 'kids_resume_${DateTime.now().microsecondsSinceEpoch}',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      });
      final adapter = V2SessionProgressAdapter(
        datasource: V2SessionLocalDatasource(isar),
        audience: MemorizationAudience.kids,
      );
      await adapter.save(
        V2SessionState.initial(
          surahId: 114,
          blockAyahs: const [
            Ayah(number: 1, surahId: 114, text: 'ayah text', numberInSurah: 1),
          ],
          blockReviewRequired: false,
        ).copyWith(phase: V2SessionPhase.reciting),
      );
      repository.awardCompleter = Completer()
        ..complete(
          const Right(
            KidsCompletionResult(
              progress: KidsProgress.initial(),
              pointsEarned: 0,
              starsEarned: 1,
              alreadyCompleted: true,
            ),
          ),
        );

      await cubit.close();
      cubit = buildCubit(
        recorder: _FakeKidsRecitationRecorder(),
        quran: const _ResumeQuranRepository(),
        progressAdapter: adapter,
      );
      await cubit.load(
        114,
        1,
        'ayah text',
        missionType: KidsMissionType.resume,
      );

      final resumed = cubit.state as KidsModeLoaded;
      expect(resumed.sessionState.phase, V2SessionPhase.reciting);
      // Default policy (age 8) requires two conscious listens before reciting.
      cubit.debugSetLoopCount(2);
      await cubit.markCompleted(automaticSpokenText: 'ayah text');

      expect((cubit.state as KidsModeLoaded).isCompleted, isTrue);
      // The interrupted ayah was never rewarded, so the resumed session
      // keeps its original fresh-memorization award semantics (H3).
      expect(repository.lastMissionType, KidsMissionType.newMemorization);
      final savedAfterCompletion = await adapter.loadIfExists(114);
      expect(savedAfterCompletion.fold(() => false, (_) => true), isFalse);
    });

    test(
      'resuming an already-rewarded ayah earns reduced review points',
      () async {
        repository.awardCompleter = Completer()
          ..complete(
            const Right(
              KidsCompletionResult(
                progress: KidsProgress.initial(),
                pointsEarned: 5,
                starsEarned: 0,
                alreadyCompleted: false,
              ),
            ),
          );
        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(),
          kidsSessionLogs: [
            KidsSessionLog(
              id: 'earlier-reward',
              surahId: 114,
              ayahNumber: 1,
              repeatsCompleted: 2,
              pointsEarned: 10,
              completedAt: DateTime.now().toUtc(),
              missionType: KidsMissionType.newMemorization,
            ),
          ],
        );

        await cubit.load(
          114,
          1,
          'ayah text',
          missionType: KidsMissionType.resume,
        );
        cubit.debugSetLoopCount(3);

        await cubit.markCompleted(automaticSpokenText: 'ayah text');

        // The canonical reward log proves the ayah was already paid out, so
        // the resumed run behaves like a review: reduced points, never a
        // second full reward.
        expect(repository.lastMissionType, KidsMissionType.resume);
        final loaded = cubit.state as KidsModeLoaded;
        expect(loaded.isCompleted, isTrue);
        expect(loaded.sessionPointsEarned, 5);
      },
    );

    test(
      'a session whose ayah text cannot be loaded refuses to start',
      () async {
        // The placeholder text can never pass recitation evaluation; a
        // session built on it would trap the child in an unwinnable mission.
        await cubit.load(114, 1, 'النص غير متوفر');

        expect(cubit.state, isA<KidsModeError>());
        expect(
          (cubit.state as KidsModeError).message,
          CubitMessageCodes.v2SurahLoadFailed,
        );
        expect(repository.awardCalls, 0);
      },
    );

    test(
      'three repeated mismatches unlock the guardian-verified completion',
      () async {
        repository.awardCompleter = Completer()
          ..complete(
            const Right(
              KidsCompletionResult(
                progress: KidsProgress.initial(),
                pointsEarned: 10,
                starsEarned: 1,
                alreadyCompleted: false,
              ),
            ),
          );
        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(
            result: const KidsRecitationCaptureResult.captured(
              words: 'different words',
            ),
          ),
          policy: KidsSessionPolicy.forAge(6),
        );

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);

        await cubit.startRecording();
        var state = cubit.state as KidsModeLoaded;
        expect(state.canUseGuardianFallback, isFalse); // first mismatch

        await cubit.startRecording();
        await cubit.startRecording();
        state = cubit.state as KidsModeLoaded;
        expect(state.recordingError, CubitMessageCodes.kidsRecitationMismatch);
        expect(state.canUseGuardianFallback, isTrue); // escape valve opened

        expect(await cubit.submitManualCompletion(guardianPin: '1234'), isTrue);
        expect((cubit.state as KidsModeLoaded).isCompleted, isTrue);
        // A stale error would stop the page from opening the completion
        // screen and strand the child on the finished ayah.
        expect((cubit.state as KidsModeLoaded).recordingError, isNull);
      },
    );

    test(
      'manual completion during an active recording finishes silently',
      () async {
        repository.awardCompleter = Completer()
          ..complete(
            const Right(
              KidsCompletionResult(
                progress: KidsProgress.initial(),
                pointsEarned: 10,
                starsEarned: 1,
                alreadyCompleted: false,
              ),
            ),
          );
        await cubit.close();
        final recorder = _PrecompletedKidsRecitationRecorder();
        cubit = buildCubit(
          recorder: recorder,
          policy: KidsSessionPolicy.forAge(6),
        );

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);

        final recording = cubit.startRecording();
        await recorder.captureStarted.future;

        // The session completes (guardian-verified flow) while the mic is
        // still open.
        await cubit.markCompleted(manualGrade: true);

        // The late capture resolves with wrong words, but a finished session
        // must never evaluate a stale capture or emit a confusing error.
        recorder.finishCapture.complete(
          const KidsRecitationCaptureResult.captured(
            words: 'totally wrong words',
          ),
        );
        await recording;

        final state = cubit.state as KidsModeLoaded;
        expect(state.isCompleted, isTrue);
        expect(state.recordingError, isNull);
        expect(state.isRecording, isFalse);
      },
    );

    test(
      'a session parked at blockReviewPending completes on resume',
      () async {
        await _initializeKidsResumeIsarCoreForTests();
        final tempDir = await Directory.systemTemp.createTemp(
          'talia_kids_resume_pending_',
        );
        final isar = await Isar.open(
          [IsarV2SessionSchema],
          directory: tempDir.path,
          name: 'kids_resume_pending_${DateTime.now().microsecondsSinceEpoch}',
        );
        addTearDown(() async {
          await isar.close(deleteFromDisk: true);
          if (tempDir.existsSync()) await tempDir.delete(recursive: true);
        });
        final adapter = V2SessionProgressAdapter(
          datasource: V2SessionLocalDatasource(isar),
          audience: MemorizationAudience.kids,
        );
        await adapter.save(
          V2SessionState.initial(
            surahId: 114,
            blockAyahs: const [
              Ayah(
                number: 1,
                surahId: 114,
                text: 'ayah text',
                numberInSurah: 1,
              ),
            ],
            blockReviewRequired: true,
          ).copyWith(
            phase: V2SessionPhase.blockReviewPending,
            passedAyahNumbers: const {1},
          ),
        );
        repository.awardCompleter = Completer()
          ..complete(
            const Right(
              KidsCompletionResult(
                progress: KidsProgress.initial(),
                pointsEarned: 5,
                starsEarned: 0,
                alreadyCompleted: false,
              ),
            ),
          );

        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(
            result: const KidsRecitationCaptureResult.captured(
              words: 'ayah text',
            ),
          ),
          quran: const _ResumeQuranRepository(),
          progressAdapter: adapter,
          kidsSessionLogs: [
            KidsSessionLog(
              id: 'already-rewarded',
              surahId: 114,
              ayahNumber: 1,
              repeatsCompleted: 2,
              pointsEarned: 10,
              completedAt: DateTime.now().toUtc(),
              missionType: KidsMissionType.newMemorization,
            ),
          ],
        );

        await cubit.load(
          114,
          1,
          'ayah text',
          missionType: KidsMissionType.resume,
        );

        var state = cubit.state as KidsModeLoaded;
        // The pre-fix session was parked after a passed, already-rewarded
        // ayah — resuming it must promote straight to the terminal phase.
        expect(state.sessionState.phase, V2SessionPhase.completed);
        expect(state.isCompleted, isFalse); // celebration needs one recite

        cubit.debugSetLoopCount(2);
        await cubit.markCompleted(automaticSpokenText: 'ayah text');

        state = cubit.state as KidsModeLoaded;
        expect(state.isCompleted, isTrue);
        expect(repository.lastMissionType, KidsMissionType.resume);
      },
    );
    test(
      'review record failure keeps the kids session retryable without awards',
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

        await cubit.markCompleted(automaticSpokenText: 'ayah text');

        expect(cubit.state, isA<KidsModeLoaded>());
        final loaded = cubit.state as KidsModeLoaded;
        expect(loaded.isCompleted, isFalse);
        expect(loaded.recordingError, CubitMessageCodes.hifzReviewSaveFailed);
        expect(repository.markCalls, 1);
        expect(repository.awardCalls, 0);
        expect(repository.awardLogWrites, 0);
        expect(repository.saveLogCalls, 0);
        expect(streakService.recordCalls, 0);
        expect(achievementService.checkCalls, 0);
      },
    );

    group('completed listen progress', () {
      late MockAudioPlayer player;
      late StreamController<PlayerState> playback;
      late StreamController<ProcessingState> processing;
      late Completer<String> source;

      KidsModeLoaded getLoaded() => cubit.state as KidsModeLoaded;

      Future<void> finishListen() async {
        playback.add(PlayerState(true, ProcessingState.completed));
        await Future<void>.delayed(Duration.zero);
      }

      setUp(() async {
        await cubit.close();
        playback = StreamController<PlayerState>.broadcast(sync: true);
        processing = StreamController<ProcessingState>.broadcast(sync: true);
        source = Completer<String>();
        player = MockAudioPlayer();
        when(player.playerStateStream).thenAnswer((_) => playback.stream);
        when(player.processingStateStream).thenAnswer((_) => processing.stream);
        when(player.setUrl(any)).thenAnswer((_) async => Duration.zero);
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(),
          policy: KidsSessionPolicy.forAge(6),
          audioPlayer: player,
          audioSourceLoader: (_, _) => source.future,
        );
        await cubit.load(114, 1, 'ayah text');
        addTearDown(playback.close);
        addTearDown(processing.close);
      });

      test(
        'buffering and the active final listen earn no early stars',
        () async {
          final playing = cubit.playAudio();
          expect(getLoaded().currentLoop, 0);
          expect(getLoaded().isBuffering, isTrue);
          source.complete('https://example.test/ayah.mp3');
          await playing;
          for (var completed = 1; completed <= 2; completed++) {
            await finishListen();
            expect(getLoaded().currentLoop, completed);
            expect(getLoaded().isPlaying, isTrue);
          }
          await cubit.tryFromMemory();
          expect(getLoaded().isRecallingFromMemory, isFalse);
          await finishListen();
          expect(getLoaded().currentLoop, 3);
          expect(getLoaded().isPlaying, isFalse);
          expect(getLoaded().isBuffering, isFalse);
          await cubit.tryFromMemory();
          expect(getLoaded().isRecallingFromMemory, isTrue);
        },
      );

      test(
        'stop preserves completions and rejects a shutdown completion',
        () async {
          source.complete('https://example.test/ayah.mp3');
          await cubit.playAudio();
          await finishListen();
          when(player.stop()).thenAnswer((_) async {
            playback.add(PlayerState(false, ProcessingState.completed));
          });
          await cubit.stopAudio();
          expect(getLoaded().currentLoop, 1);
          expect(getLoaded().isPlaying, isFalse);
          expect(getLoaded().isBuffering, isFalse);
          playback.add(PlayerState(false, ProcessingState.completed));
          expect(getLoaded().currentLoop, 1);
          await cubit.playAudio();
          expect(getLoaded().currentLoop, 0);
          when(player.stop()).thenAnswer((_) async {});
        },
      );

      test('failure before the first listen earns no star', () async {
        final playing = cubit.playAudio();
        source.completeError(StateError('audio unavailable'));
        await playing;
        expect(getLoaded().currentLoop, 0);
        expect(
          getLoaded().audioError,
          CubitMessageCodes.kidsAudioPlaybackFailed,
        );
        expect(getLoaded().isPlaying, isFalse);
        expect(getLoaded().isBuffering, isFalse);
        playback.add(PlayerState(false, ProcessingState.completed));
        expect(getLoaded().currentLoop, 0);
      });

      test(
        'stopping while buffering never starts the resolved source',
        () async {
          final playing = cubit.playAudio();
          await cubit.stopAudio();
          source.complete('https://example.test/ayah.mp3');
          await playing;
          expect(getLoaded().currentLoop, 0);
          expect(getLoaded().isPlaying, isFalse);
          verifyNever(player.setUrl(any));
          verifyNever(player.play());
        },
      );

      for (final fails in [false, true]) {
        test(
          'replay ignores a stale source ${fails ? 'failure' : 'success'}',
          () async {
            final firstSource = source;
            final firstPlaying = cubit.playAudio();
            await cubit.stopAudio();
            source = Completer<String>();
            final replay = cubit.playAudio();
            source.complete('https://example.test/replay.mp3');
            await replay;
            if (fails) {
              firstSource.completeError(StateError('stale source failed'));
            } else {
              firstSource.complete('https://example.test/stale.mp3');
            }
            await firstPlaying;
            expect(getLoaded().currentLoop, 0);
            expect(getLoaded().isPlaying, isTrue);
            expect(getLoaded().audioError, isNull);
            verify(player.setUrl('https://example.test/replay.mp3')).called(1);
            verifyNever(player.setUrl('https://example.test/stale.mp3'));
          },
        );
      }

      test('replay waits for the player shutdown to finish', () async {
        final firstSource = source;
        final firstPlaying = cubit.playAudio();
        final shutdown = Completer<void>();
        when(player.stop()).thenAnswer((_) => shutdown.future);
        final stopping = cubit.stopAudio();
        source = Completer<String>();
        final replay = cubit.playAudio();
        expect(getLoaded().isPlaying, isFalse);
        verifyNever(player.setUrl(any));
        shutdown.complete();
        await stopping;
        source.complete('https://example.test/replay.mp3');
        await replay;
        firstSource.complete('https://example.test/stale.mp3');
        await firstPlaying;
        expect(getLoaded().isPlaying, isTrue);
        verify(player.setUrl('https://example.test/replay.mp3')).called(1);
        verifyNever(player.setUrl('https://example.test/stale.mp3'));
      });

      test('late buffering cannot revive a stopped session', () async {
        source.complete('https://example.test/ayah.mp3');
        await cubit.playAudio();
        await cubit.stopAudio();
        processing.add(ProcessingState.buffering);
        expect(getLoaded().isBuffering, isFalse);
      });

      test(
        'closing rejects a shutdown completion without another listen',
        () async {
          source.complete('https://example.test/ayah.mp3');
          await cubit.playAudio();
          when(player.stop()).thenAnswer((_) async {
            playback.add(PlayerState(false, ProcessingState.completed));
          });
          await cubit.close();
          expect(getLoaded().currentLoop, 0);
          verify(player.setUrl('https://example.test/ayah.mp3')).called(1);
          when(player.stop()).thenAnswer((_) async {});
        },
      );

      test(
        'a later playback failure preserves only completed listens',
        () async {
          source.complete('https://example.test/ayah.mp3');
          await cubit.playAudio();
          when(player.setUrl(any)).thenThrow(StateError('source failed'));
          await finishListen();
          expect(getLoaded().currentLoop, 1);
          expect(getLoaded().isPlaying, isFalse);
          expect(getLoaded().isBuffering, isFalse);
          expect(
            getLoaded().audioError,
            CubitMessageCodes.kidsAudioPlaybackFailed,
          );
          playback.add(PlayerState(false, ProcessingState.completed));
          expect(getLoaded().currentLoop, 1);
        },
      );

      test('optional replays keep the fulfilled listen gate open', () async {
        source.complete('https://example.test/ayah.mp3');
        await cubit.playAudio();
        for (var completed = 0; completed < 3; completed++) {
          await finishListen();
        }
        await cubit.playAudio();
        expect(getLoaded().currentLoop, 3);
        await cubit.stopAudio();
        expect(getLoaded().currentLoop, 3);
        await cubit.playAudio();
        await finishListen();
        expect(getLoaded().currentLoop, 3);
        expect(getLoaded().isPlaying, isFalse);
        await cubit.tryFromMemory();
        expect(getLoaded().isRecallingFromMemory, isTrue);
      });
    });

    test('load defaults to the age-8 policy listen repetitions', () async {
      await cubit.load(114, 1, 'ayah text');

      final loaded = cubit.state as KidsModeLoaded;
      // Default policy resolves to age 8 → two conscious listens.
      expect(loaded.maxLoops, 2);
    });
    test('listen repetitions follow the age-band policy', () async {
      // Older band (8–12) repeats twice per policy before reciting.
      await cubit.close();
      cubit = buildCubit(
        recorder: _FakeKidsRecitationRecorder(),
        policy: KidsSessionPolicy.forAge(8),
      );
      await cubit.load(114, 1, 'ayah text');
      expect((cubit.state as KidsModeLoaded).maxLoops, 2);

      // Younger band (5–7) needs more listens, not fewer.
      await cubit.close();
      cubit = buildCubit(
        recorder: _FakeKidsRecitationRecorder(),
        policy: KidsSessionPolicy.forAge(6),
      );
      await cubit.load(114, 1, 'ayah text');
      expect((cubit.state as KidsModeLoaded).maxLoops, 3);
    });
    test(
      'recording stays locked until every required listen is completed',
      () async {
        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(
            result: const KidsRecitationCaptureResult.captured(
              words: 'ayah text',
            ),
          ),
          policy: KidsSessionPolicy.forAge(8),
        );

        await cubit.load(114, 1, 'ayah text');
        // One of two required listens done → recording must be refused.
        cubit.debugSetLoopCount(1);
        await cubit.startRecording();
        expect((cubit.state as KidsModeLoaded).recordingError, isNull);
        expect((cubit.state as KidsModeLoaded).mustListenFirst, isTrue);
        expect(repository.awardCalls, 0);
      },
    );
    test('kids single-ayah sessions never require a block review', () async {
      await cubit.close();
      cubit = buildCubit(
        recorder: _FakeKidsRecitationRecorder(),
        policy: KidsSessionPolicy.forAge(8),
      );

      await cubit.load(114, 1, 'ayah text');

      final loaded = cubit.state as KidsModeLoaded;
      // Kids blocks are single-ayah: a block review would only repeat the
      // recitation the child just passed, and no kids UI drives it — so the
      // session must complete directly instead of dead-ending.
      expect(loaded.sessionState.blockReviewRequired, isFalse);
    });
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
      'daily new-memorization limit blocks the second fresh session (K15)',
      () async {
        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(),
          policy: KidsSessionPolicy.forAge(5), // maxNewAyahs = 1
          kidsSessionLogs: [
            KidsSessionLog(
              id: 'earlier-today',
              surahId: 114,
              ayahNumber: 1,
              repeatsCompleted: 1,
              pointsEarned: 10,
              completedAt:
                  DateTime.now(), // always "today", even just past midnight
              missionType: KidsMissionType.newMemorization,
            ),
          ],
        );

        await cubit.load(114, 2, 'ayah text');

        expect(cubit.state, isA<KidsModeError>());
        expect(
          (cubit.state as KidsModeError).message,
          "${CubitMessageCodes.kidsDailySessionLimitPrefix}1",
        );
      },
    );

    test(
      'resume and reviews stay reachable after the daily new-ayah cap (K15)',
      () async {
        await cubit.close();
        final logs = [
          KidsSessionLog(
            id: 'earlier-today',
            surahId: 114,
            ayahNumber: 1,
            repeatsCompleted: 1,
            pointsEarned: 10,
            completedAt:
                DateTime.now(), // always "today", even just past midnight
            missionType: KidsMissionType.newMemorization,
          ),
        ];
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(),
          policy: KidsSessionPolicy.forAge(5), // maxNewAyahs = 1 already hit
          kidsSessionLogs: logs,
        );

        // Due review (SRS-first priority) must never be blocked by the cap.
        await cubit.load(
          113,
          2,
          'due review text',
          missionType: KidsMissionType.dueReview,
        );
        expect(cubit.state, isA<KidsModeLoaded>());

        // Re-opening an already-rewarded ayah is review work, never new
        // memorization, so the cap never blocks it.
        await cubit.load(
          114,
          1,
          'ayah text',
          missionType: KidsMissionType.resume,
        );
        expect(cubit.state, isA<KidsModeLoaded>());
      },
    );

    test(
      'a restored interrupted session stays reachable after the daily cap',
      () async {
        final adapter = await _openKidsResumeAdapter();
        await adapter.save(
          V2SessionState.initial(
            surahId: 114,
            blockAyahs: const [
              Ayah(
                number: 1,
                surahId: 114,
                text: 'ayah text',
                numberInSurah: 1,
              ),
            ],
            blockReviewRequired: false,
          ).copyWith(phase: V2SessionPhase.reciting),
        );
        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(),
          quran: const _ResumeQuranRepository(),
          progressAdapter: adapter,
          policy: KidsSessionPolicy.forAge(5), // maxNewAyahs = 1 already hit
          kidsSessionLogs: [
            KidsSessionLog(
              id: 'earlier-today',
              surahId: 114,
              ayahNumber: 2,
              repeatsCompleted: 1,
              pointsEarned: 10,
              completedAt:
                  DateTime.now(), // always "today", even just past midnight
              missionType: KidsMissionType.newMemorization,
            ),
          ],
        );

        await cubit.load(
          114,
          1,
          'ayah text',
          missionType: KidsMissionType.resume,
        );

        expect(cubit.state, isA<KidsModeLoaded>());
        expect(
          (cubit.state as KidsModeLoaded).sessionState.phase,
          V2SessionPhase.reciting,
        );
      },
    );

    test('resume without a saved session on a never-rewarded ayah is new '
        'memorization (N1)', () async {
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
      await cubit.close();
      cubit = buildCubit(
        recorder: _FakeKidsRecitationRecorder(),
        kidsSessionLogs: const [],
      );

      // The stage page opens an in-progress stage with `resume`; with no
      // paused session this is the child's first pass on the next ayah.
      await cubit.load(
        114,
        1,
        'ayah text',
        missionType: KidsMissionType.resume,
      );
      cubit.debugSetLoopCount(3);
      await cubit.markCompleted(automaticSpokenText: 'ayah text');

      // Only a canonical new-memorization log advances the journey, so a
      // first pass must never be downgraded to a zero-star review award.
      expect(repository.lastMissionType, KidsMissionType.newMemorization);
    });

    test(
      'resume without a saved session is gated by the daily new-ayah cap (N1)',
      () async {
        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(),
          policy: KidsSessionPolicy.forAge(5), // maxNewAyahs = 1 already hit
          kidsSessionLogs: [
            KidsSessionLog(
              id: 'earlier-today',
              surahId: 114,
              ayahNumber: 1,
              repeatsCompleted: 1,
              pointsEarned: 10,
              completedAt:
                  DateTime.now(), // always "today", even just past midnight
              missionType: KidsMissionType.newMemorization,
            ),
          ],
        );

        await cubit.load(
          114,
          2,
          'ayah text',
          missionType: KidsMissionType.resume,
        );

        expect(cubit.state, isA<KidsModeError>());
        expect(
          (cubit.state as KidsModeError).message,
          "${CubitMessageCodes.kidsDailySessionLimitPrefix}1",
        );
      },
    );

    test(
      'ages eight to twelve complete directly after passing the single-ayah block',
      () async {
        await cubit.close();
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
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(
            result: const KidsRecitationCaptureResult.captured(
              words: 'ayah text',
            ),
          ),
          policy: KidsSessionPolicy.forAge(8),
        );

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(2); // satisfy the age-8 listen gate
        await cubit.startRecording();

        final state = cubit.state as KidsModeLoaded;
        // Kids blocks are single-ayah, so no block review is required: the
        // session reaches its terminal phase and the celebration fires.
        expect(state.sessionState.phase, V2SessionPhase.completed);
        expect(state.isCompleted, isTrue);
      },
    );

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

    group('silent attempts and the guardian bypass (K21)', () {
      const silence = KidsRecitationCaptureResult.stoppedByUser();

      test('one quiet attempt does not open the guardian bypass', () async {
        await cubit.close();
        cubit = buildCubit(recorder: _FakeKidsRecitationRecorder());

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);
        await cubit.startRecording();

        final state = cubit.state as KidsModeLoaded;
        expect(
          state.recordingError,
          CubitMessageCodes.kidsRecordingNotCaptured,
        );
        expect(state.canUseGuardianFallback, isFalse);
        expect(
          await cubit.submitManualCompletion(guardianPin: '1234'),
          isFalse,
        );
        expect(repository.awardCalls, 0);
      });

      test('repeated silence opens it (STT may not hear the child)', () async {
        await cubit.close();
        cubit = buildCubit(recorder: _FakeKidsRecitationRecorder());

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);
        for (
          var attempt = 0;
          attempt < KidsModeLoaded.kGuardianFallbackAfterSilentAttempts;
          attempt++
        ) {
          await cubit.startRecording();
        }

        expect((cubit.state as KidsModeLoaded).canUseGuardianFallback, isTrue);
      });

      test('a heard attempt restarts the silence count', () async {
        await cubit.close();
        final recorder = _MutableKidsRecitationRecorder();
        cubit = buildCubit(recorder: recorder);

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);
        recorder.result = silence;
        await cubit.startRecording();
        recorder.result = const KidsRecitationCaptureResult.captured(
          words: 'different words',
        );
        await cubit.startRecording();
        recorder.result = silence;
        await cubit.startRecording();

        final state = cubit.state as KidsModeLoaded;
        expect(
          state.recordingError,
          CubitMessageCodes.kidsRecordingNotCaptured,
        );
        expect(state.canUseGuardianFallback, isFalse);
      });
    });

    group('try from memory and "give me the start" (K25)', () {
      KidsModeCubit passingCubit() {
        repository.awardCompleter = Completer()
          ..complete(
            Right(
              KidsCompletionResult(
                progress: const KidsProgress.initial().addPoints(10),
                pointsEarned: 10,
                starsEarned: 1,
                alreadyCompleted: false,
              ),
            ),
          );
        return buildCubit(
          recorder: _FakeKidsRecitationRecorder(
            result: const KidsRecitationCaptureResult.captured(
              words: 'ayah text',
            ),
          ),
          policy: KidsSessionPolicy.forAge(6),
        );
      }

      test('trying from memory hides the ayah after the listens', () async {
        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);

        await cubit.tryFromMemory();

        final state = cubit.state as KidsModeLoaded;
        expect(state.sessionState.phase, V2SessionPhase.memorizing);
        expect(state.isRecallingFromMemory, isTrue);
        expect(state.firstWordRevealed, isFalse);
      });

      test('trying from memory waits for the required listens', () async {
        await cubit.load(114, 1, 'ayah text');

        await cubit.tryFromMemory();

        final state = cubit.state as KidsModeLoaded;
        expect(state.sessionState.phase, V2SessionPhase.learning);
        expect(state.mustListenFirst, isTrue);
      });

      test('the first word is offered only while recalling', () async {
        await cubit.load(114, 1, 'first second third');
        cubit.debugSetLoopCount(3);

        await cubit.revealFirstWord();
        expect((cubit.state as KidsModeLoaded).firstWordRevealed, isFalse);

        await cubit.tryFromMemory();
        await cubit.revealFirstWord();

        final state = cubit.state as KidsModeLoaded;
        expect(state.firstWordRevealed, isTrue);
        expect(state.firstWord, 'first');
        expect(
          state.sessionState.hintTracker.levelFor(114, 1),
          V2HintLevel.firstWord,
        );
      });

      test(
        'a pass after the hint is average with no excellence bonus',
        () async {
          await cubit.close();
          cubit = passingCubit();

          await cubit.load(114, 1, 'ayah text');
          cubit.debugSetLoopCount(3);
          await cubit.tryFromMemory();
          await cubit.revealFirstWord();
          await cubit.startRecording();

          expect((cubit.state as KidsModeLoaded).isCompleted, isTrue);
          expect(repository.lastMasteryRating, PerformanceRating.average);
          expect(
            repository.lastSavedReview?.lastRating,
            PerformanceRating.average,
          );
          expect(repository.lastHintCount, 1);
        },
      );

      test('a pass without the hint stays excellent', () async {
        await cubit.close();
        cubit = passingCubit();

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);
        await cubit.tryFromMemory();
        await cubit.startRecording();

        expect(repository.lastMasteryRating, PerformanceRating.excellent);
        expect(repository.lastHintCount, 0);
      });

      test('after a missed try the child recalls again with help', () async {
        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(
            result: const KidsRecitationCaptureResult.captured(
              words: 'different words',
            ),
          ),
        );

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);
        await cubit.tryFromMemory();
        await cubit.startRecording();
        expect(
          (cubit.state as KidsModeLoaded).sessionState.phase,
          V2SessionPhase.remediation,
        );

        await cubit.tryFromMemory();
        await cubit.revealFirstWord();

        final state = cubit.state as KidsModeLoaded;
        expect(state.sessionState.phase, V2SessionPhase.memorizing);
        expect(state.firstWordRevealed, isTrue);
      });
    });

    group('recalled words after a miss (K32)', () {
      test('a miss marks the words the child got right', () async {
        await cubit.close();
        final recorder = _MutableKidsRecitationRecorder()
          ..result = const KidsRecitationCaptureResult.captured(
            words: 'ayah wrong',
          );
        cubit = buildCubit(recorder: recorder);

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);
        await cubit.tryFromMemory();
        await cubit.startRecording();

        expect((cubit.state as KidsModeLoaded).recalledWords, [true, false]);
      });

      test('a new attempt clears the old marks', () async {
        await cubit.close();
        final recorder = _MutableKidsRecitationRecorder()
          ..result = const KidsRecitationCaptureResult.captured(
            words: 'ayah wrong',
          );
        cubit = buildCubit(recorder: recorder);

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);
        await cubit.tryFromMemory();
        await cubit.startRecording();
        recorder.result = const KidsRecitationCaptureResult.stoppedByUser();
        await cubit.tryFromMemory();
        await cubit.startRecording();

        expect((cubit.state as KidsModeLoaded).recalledWords, isNull);
      });
    });

    group('only an exact recitation is excellent (K31)', () {
      KidsModeCubit fuzzyCubit(String words) {
        repository.awardCompleter = Completer()
          ..complete(
            Right(
              KidsCompletionResult(
                progress: const KidsProgress.initial().addPoints(10),
                pointsEarned: 10,
                starsEarned: 1,
                alreadyCompleted: false,
              ),
            ),
          );
        return buildCubit(
          recorder: _FakeKidsRecitationRecorder(
            result: KidsRecitationCaptureResult.captured(words: words),
          ),
          policy: KidsSessionPolicy.forAge(6),
          engine: V2SessionEngine().withPassThreshold(kKidsPassThreshold),
        );
      }

      test(
        'a near-exact pass is average, without the excellence bonus',
        () async {
          await cubit.close();
          cubit = fuzzyCubit('one two three four wrong'); // 4/5 = 0.8

          await cubit.load(114, 1, 'one two three four five');
          cubit.debugSetLoopCount(3);
          await cubit.tryFromMemory();
          await cubit.startRecording();

          expect((cubit.state as KidsModeLoaded).isCompleted, isTrue);
          expect(repository.lastMasteryRating, PerformanceRating.average);
        },
      );

      test('an exact pass stays excellent', () async {
        await cubit.close();
        cubit = fuzzyCubit('one two three four five');

        await cubit.load(114, 1, 'one two three four five');
        cubit.debugSetLoopCount(3);
        await cubit.tryFromMemory();
        await cubit.startRecording();

        expect(repository.lastMasteryRating, PerformanceRating.excellent);
      });
    });

    group('reviews start with recall (K28)', () {
      KidsModeCubit reviewCubit({
        String words = 'ayah text',
        List<KidsSessionLog>? logs,
      }) {
        repository.awardCompleter = Completer()
          ..complete(
            const Right(
              KidsCompletionResult(
                progress: KidsProgress.initial(),
                pointsEarned: 5,
                starsEarned: 0,
                alreadyCompleted: false,
              ),
            ),
          );
        return buildCubit(
          recorder: _FakeKidsRecitationRecorder(
            result: KidsRecitationCaptureResult.captured(words: words),
          ),
          policy: KidsSessionPolicy.forAge(6),
          kidsSessionLogs: logs,
        );
      }

      for (final type in [
        KidsMissionType.dueReview,
        KidsMissionType.linkedReview,
      ]) {
        test('${type.name} opens hidden, with no listening first', () async {
          await cubit.close();
          cubit = reviewCubit();

          await cubit.load(114, 1, 'ayah text', missionType: type);

          final state = cubit.state as KidsModeLoaded;
          expect(state.sessionState.phase, V2SessionPhase.reciting);
          expect(state.isReview, isTrue);
          expect(state.maxLoops, 0);
        });
      }

      test(
        'an already memorized ayah reopened from its house is a review',
        () async {
          await cubit.close();
          cubit = reviewCubit(
            logs: [
              KidsSessionLog(
                id: 'memorized',
                surahId: 114,
                ayahNumber: 1,
                repeatsCompleted: 3,
                pointsEarned: 10,
                completedAt: DateTime.utc(2026, 1, 1),
              ),
            ],
          );

          await cubit.load(
            114,
            1,
            'ayah text',
            missionType: KidsMissionType.resume,
          );

          final state = cubit.state as KidsModeLoaded;
          expect(state.isReview, isTrue);
          expect(state.sessionState.phase, V2SessionPhase.reciting);
        },
      );

      test('new memorization still starts by listening', () async {
        await cubit.close();
        cubit = reviewCubit();

        await cubit.load(114, 1, 'ayah text');

        final state = cubit.state as KidsModeLoaded;
        expect(state.isReview, isFalse);
        expect(state.sessionState.phase, V2SessionPhase.learning);
        expect(state.maxLoops, 3);
      });

      test('a recall straight from memory is excellent', () async {
        await cubit.close();
        cubit = reviewCubit();

        await cubit.load(
          114,
          1,
          'ayah text',
          missionType: KidsMissionType.dueReview,
        );
        await cubit.startRecording();

        expect((cubit.state as KidsModeLoaded).isCompleted, isTrue);
        expect(repository.lastMasteryRating, PerformanceRating.excellent);
        expect(repository.lastMissionType, KidsMissionType.dueReview);
      });

      test('the recitation cannot be played before trying', () async {
        await cubit.close();
        cubit = reviewCubit();

        await cubit.load(
          114,
          1,
          'ayah text',
          missionType: KidsMissionType.dueReview,
        );
        await cubit.playAudio();

        expect((cubit.state as KidsModeLoaded).isPlaying, isFalse);
      });

      test('"remind me" shows the ayah and counts a missed recall', () async {
        await cubit.close();
        cubit = reviewCubit();

        await cubit.load(
          114,
          1,
          'ayah text',
          missionType: KidsMissionType.dueReview,
        );
        await cubit.remindMe();

        final reminded = cubit.state as KidsModeLoaded;
        expect(reminded.sessionState.phase, V2SessionPhase.remediation);
        expect(reminded.sessionState.failureTracker.failureCountFor(114, 1), 1);

        await cubit.tryFromMemory();
        await cubit.revealFirstWord();
        await cubit.startRecording();

        expect((cubit.state as KidsModeLoaded).isCompleted, isTrue);
        expect(repository.lastMasteryRating, PerformanceRating.average);
      });

      test('recitation between attempts awaits the mic, never stuck', () async {
        await cubit.close();
        cubit = reviewCubit();

        await cubit.load(
          114,
          1,
          'ayah text',
          missionType: KidsMissionType.dueReview,
        );

        // Also the phase a near miss leaves new memorization in.
        final state = cubit.state as KidsModeLoaded;
        expect(state.isAwaitingRecitation, isTrue);
        expect(state.copyWith(isRecording: true).isAwaitingRecitation, isFalse);
      });
    });

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

      // Younger policy (5–7) completes without the linked block review, so
      // the session reaches its terminal phase right after the recitation.
      cubit = buildCubit(
        recorder: _FakeKidsRecitationRecorder(
          result: const KidsRecitationCaptureResult.captured(
            words: 'ayah text',
          ),
        ),
        policy: KidsSessionPolicy.forAge(6),
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
      expect(repository.lastSessionId, isNotEmpty);
      expect(repository.lastMissionType, KidsMissionType.newMemorization);
      expect(repository.lastAttemptCount, 1);
      expect(repository.lastHintCount, 0);
      expect(repository.lastMasteryRating, PerformanceRating.excellent);
    });

    test('recitation mismatch never enables guardian completion', () async {
      await cubit.close();
      cubit = buildCubit(
        recorder: _FakeKidsRecitationRecorder(
          result: const KidsRecitationCaptureResult.captured(
            words: 'different words',
          ),
        ),
      );

      await cubit.load(114, 1, 'ayah text');
      cubit.debugSetLoopCount(3);
      await cubit.startRecording();

      final before = cubit.state as KidsModeLoaded;
      expect(before.recordingError, CubitMessageCodes.kidsRecitationMismatch);
      expect(before.canUseGuardianFallback, isFalse);

      final accepted = await cubit.submitManualCompletion(guardianPin: '1234');

      expect(accepted, isFalse);
      expect(repository.awardCalls, 0);
      expect(repository.markCalls, 0);
    });

    test(
      'a near-miss recitation carries word feedback that a clean retry clears',
      () async {
        repository.awardCompleter = Completer()
          ..complete(
            Right(
              KidsCompletionResult(
                progress: const KidsProgress.initial().addPoints(10),
                pointsEarned: 10,
                starsEarned: 1,
                alreadyCompleted: false,
              ),
            ),
          );
        await cubit.close();
        final recorder = _MutableKidsRecitationRecorder();
        cubit = buildCubit(
          recorder: recorder,
          policy: KidsSessionPolicy.forAge(6),
        );

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);

        // First attempt: partially correct recitation ("ayah word" vs the
        // two-word target "ayah text") — one of two words right.
        recorder.result = const KidsRecitationCaptureResult.captured(
          words: 'ayah word',
        );
        await cubit.startRecording();

        var state = cubit.state as KidsModeLoaded;
        expect(state.recordingError, CubitMessageCodes.kidsRecitationMismatch);
        expect(state.lastMatchedWords, 1);
        expect(state.lastTargetWords, 2);
        expect(state.hasWordFeedback, isTrue);

        // Second attempt: perfect recitation — the celebration replaces the
        // stale feedback, which must not linger on the completion state.
        recorder.result = const KidsRecitationCaptureResult.captured(
          words: 'ayah text',
        );
        await cubit.startRecording();

        state = cubit.state as KidsModeLoaded;
        expect(state.isCompleted, isTrue);
        expect(state.lastMatchedWords, 0);
        expect(state.lastTargetWords, 0);
        expect(state.hasWordFeedback, isFalse);
      },
    );

    test('two misses then a clean pass schedule the same rating as the reward '
        '(N4)', () async {
      repository.awardCompleter = Completer()
        ..complete(
          const Right(
            KidsCompletionResult(
              progress: KidsProgress.initial(),
              pointsEarned: 10,
              starsEarned: 1,
              alreadyCompleted: false,
            ),
          ),
        );
      await cubit.close();
      final recorder = _MutableKidsRecitationRecorder();
      cubit = buildCubit(
        recorder: recorder,
        policy: KidsSessionPolicy.forAge(6),
      );

      await cubit.load(114, 1, 'ayah text');
      cubit.debugSetLoopCount(3);
      recorder.result = const KidsRecitationCaptureResult.captured(
        words: 'different words',
      );
      await cubit.startRecording();
      await cubit.startRecording();
      recorder.result = const KidsRecitationCaptureResult.captured(
        words: 'ayah text',
      );
      await cubit.startRecording();

      // The attempt revealed real difficulty: SRS must see the same weak
      // mastery the reward log records, not an "excellent" derived from
      // the hint level alone.
      expect(repository.lastMasteryRating, PerformanceRating.weak);
      expect(repository.lastSavedReview?.lastRating, PerformanceRating.weak);
    });

    test('three mismatches escalate the ayah to weak remediation', () async {
      await cubit.close();
      cubit = buildCubit(
        recorder: _FakeKidsRecitationRecorder(
          result: const KidsRecitationCaptureResult.captured(
            words: 'different words',
          ),
        ),
      );

      await cubit.load(114, 1, 'ayah text');
      // Satisfy the default age-8 policy (two listens) before reciting.
      cubit.debugSetLoopCount(2);

      await cubit.startRecording();
      await cubit.startRecording();
      await cubit.startRecording();

      final loaded = cubit.state as KidsModeLoaded;
      expect(loaded.sessionState.failureTracker.failureCountFor(114, 1), 3);
      expect(loaded.sessionState.failureTracker.isWeak(114, 1), isTrue);
      expect(
        loaded.sessionState.lastRecitationResult?.verdict,
        RecitationVerdict.remediate,
      );
    });
    test(
      'technical STT failure requires PIN and records a weak review',
      () async {
        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(
            result: const KidsRecitationCaptureResult.unavailable(),
          ),
          // Younger policy (5–7) lets the session complete without a linked
          // block review (see K16).
          policy: KidsSessionPolicy.forAge(6),
        );
        repository.awardCompleter = Completer()
          ..complete(
            const Right(
              KidsCompletionResult(
                progress: KidsProgress.initial(),
                pointsEarned: 10,
                starsEarned: 1,
                alreadyCompleted: false,
              ),
            ),
          );

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);
        await cubit.startRecording();

        expect((cubit.state as KidsModeLoaded).canUseGuardianFallback, isTrue);
        expect(
          await cubit.submitManualCompletion(guardianPin: '9999'),
          isFalse,
        );
        expect(repository.awardCalls, 0);

        expect(await cubit.submitManualCompletion(guardianPin: '1234'), isTrue);
        expect(repository.lastSavedReview?.lastRating, PerformanceRating.weak);
        expect(repository.lastMasteryRating, PerformanceRating.weak);
        expect(repository.lastHintCount, 1);
        expect((cubit.state as KidsModeLoaded).isCompleted, isTrue);
      },
    );
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

        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(
            result: const KidsRecitationCaptureResult.unavailable(),
          ),
          // Younger policy (5–7) lets the session complete without a linked
          // block review (see K16).
          policy: KidsSessionPolicy.forAge(6),
        );
        await cubit.load(114, 1, 'canonical ayah text');
        cubit.debugSetLoopCount(3);
        await cubit.startRecording();
        await cubit.submitManualCompletion(guardianPin: '1234');

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
        expect(repository.repeatsCompletedCalls, [3]);
      },
    );

    test(
      'review of an already-completed ayah earns reduced review points',
      () async {
        repository.awardCompleter = Completer()
          ..complete(
            const Right(
              KidsCompletionResult(
                progress: KidsProgress.initial(),
                pointsEarned: 5,
                starsEarned: 0,
                alreadyCompleted: false,
              ),
            ),
          );

        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(),
          policy: KidsSessionPolicy.forAge(6),
        );
        await cubit.load(
          114,
          1,
          'ayah text',
          missionType: KidsMissionType.dueReview,
        );
        cubit.debugSetLoopCount(3);

        await cubit.markCompleted(automaticSpokenText: 'ayah text');

        expect(cubit.state, isA<KidsModeLoaded>());
        final loaded = cubit.state as KidsModeLoaded;
        // A review pass is real work: the celebration fires with the reduced
        // review reward so review days show visible progress.
        expect(loaded.isCompleted, isTrue);
        expect(loaded.sessionPointsEarned, 5);
        expect(loaded.sessionStarsEarned, 0);
        expect(loaded.recordingError, isNull);
        expect(repository.awardCalls, 1);
        expect(repository.markCalls, 1);
        expect(repository.lastMissionType, KidsMissionType.dueReview);
        expect(streakService.recordCalls, 1);
      },
    );

    test(
      'markCompleted records activity in the kids streak, not the adult one',
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

        await cubit.markCompleted(automaticSpokenText: 'ayah text');

        expect(streakService.recordCalls, 1);
        final state = cubit.state as KidsModeLoaded;
        expect(state.progress.currentStreak, 5);
      },
    );
  });

  group('KidsModeCubit kids committer', () {
    late _FakeMemorizationPlusRepository repository;
    late Isar isar;
    late Directory tempDir;
    const owner = FixedRecordOwnerProvider('owner-a');
    final cubits = <KidsModeCubit>[];

    KidsModeCubit build({KidsReviewOutcomeCommitter? committer}) {
      final cubit = KidsModeCubit(
        GetKidsProgressUsecase(repository),
        GetKidsJourneyUsecase(repository),
        AwardKidsPointsUsecase(repository),
        _FakeAchievementService(),
        const _ResumeQuranRepository(),
        V2SessionEngine(),
        V2SessionReviewAdapter(
          repository: repository,
          scheduler: const ScheduleNextReviewUsecase(),
        ),
        _FakeStreakService(),
        _FakeKidsRecitationRecorder(),
        null,
        (pin) async => pin == '1234',
        null,
        null,
        V2SessionProgressAdapter(
          datasource: V2SessionLocalDatasource(isar, owner: owner),
          audience: MemorizationAudience.kids,
        ),
        null,
        committer,
      );
      cubits.add(cubit);
      return cubit;
    }

    KidsReviewOutcomeCommitter buildCommitter() => KidsReviewOutcomeCommitter(
      isar: isar,
      owner: owner,
      scheduler: const ScheduleNextReviewUsecase(),
    );

    Future<IsarAyahReviewRecord?> kidsRecord() =>
        isar.isarAyahReviewRecords.getByCompositeKey(
          const ReviewRecordIdentity(
            ownerUserId: 'owner-a',
            audience: ReviewRecordReadScope.kids,
            surahId: 114,
            ayahNumber: 1,
          ).storageKey,
        );

    setUp(() async {
      repository = _FakeMemorizationPlusRepository();
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
      await _initializeKidsResumeIsarCoreForTests();
      tempDir = await Directory.systemTemp.createTemp('talia_kids_commit_');
      isar = await Isar.open(
        [
          IsarAyahReviewRecordSchema,
          IsarV2SessionSchema,
          IsarReviewEvidenceEventSchema,
          IsarReviewEffectOutboxSchema,
        ],
        directory: tempDir.path,
        name: 'kids_commit_${DateTime.now().microsecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      for (final cubit in cubits) {
        await cubit.close();
      }
      cubits.clear();
      await isar.close(deleteFromDisk: true);
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('completion goes through the kids committer', () async {
      final cubit = build(committer: buildCommitter());
      await cubit.load(114, 1, 'ayah text');
      await cubit.markCompleted(manualGrade: true);

      expect((cubit.state as KidsModeLoaded).isCompleted, isTrue);
      expect((await kidsRecord())!.totalReviews, 1);
      expect(repository.markCalls, 0, reason: 'legacy recordPass bypassed');
      final evidence = await isar.isarReviewEvidenceEvents.where().findAll();
      expect(evidence, hasLength(1));
      expect(
        repository.lastSessionId,
        'kids_${evidence.single.sessionId}_114_1',
      );
    });

    test('award failure then retry does not reschedule', () async {
      final committer = buildCommitter();
      repository.awardFailuresRemaining = 1;
      final first = build(committer: committer);
      await first.load(114, 1, 'ayah text');
      await first.markCompleted(manualGrade: true);
      expect(first.state, isA<KidsModeError>());
      final firstId = repository.lastSessionId;
      expect((await kidsRecord())!.totalReviews, 1);

      final second = build(committer: committer);
      await second.load(
        114,
        1,
        'ayah text',
        missionType: KidsMissionType.resume,
      );
      await second.markCompleted(manualGrade: true);

      expect((second.state as KidsModeLoaded).isCompleted, isTrue);
      expect((await kidsRecord())!.totalReviews, 1);
      expect(await isar.isarReviewEvidenceEvents.count(), 1);
      expect(repository.awardCalls, 2);
      expect(repository.lastSessionId, firstId);
      expect(repository.awardedSessionIds, [firstId]);
    });

    test('without a committer the legacy recordPass path runs', () async {
      final cubit = build();
      await cubit.load(114, 1, 'ayah text');
      await cubit.markCompleted(manualGrade: true);

      expect((cubit.state as KidsModeLoaded).isCompleted, isTrue);
      expect(repository.markCalls, 1);
      expect(await isar.isarReviewEvidenceEvents.count(), 0);
    });
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
  AyahReviewRecord? lastSavedReview;
  String? lastSessionId;
  KidsMissionType? lastMissionType;
  int? lastAttemptCount;
  int? lastHintCount;
  PerformanceRating? lastMasteryRating;
  int awardFailuresRemaining = 0;
  final awardedSessionIds = <String?>[];

  @override
  Future<Either<Failure, KidsProgress>> getKidsProgress() async =>
      const Right(KidsProgress.initial());

  @override
  Future<Either<Failure, List<KidsJourneyStage>>> getKidsJourney({
    required int surahId,
  }) async {
    // Some phase-4 tests load another surah (e.g. 113 for a due review);
    // only assert 114 when that is actually the requested surah.
    if (surahId == 114) {
      expect(surahId, 114);
    }
    getJourneyCalls++;
    return Right(journey);
  }

  @override
  Future<Either<Failure, KidsCompletionResult>> awardKidsPoints({
    bool completionAuthorized = false,
    String? sessionId,
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
    KidsMissionType missionType = KidsMissionType.newMemorization,
    List<int> ayahNumbers = const [],
    int durationSeconds = 0,
    int attemptCount = 1,
    int hintCount = 0,
    PerformanceRating masteryRating = PerformanceRating.excellent,
  }) async {
    expect(completionAuthorized, isTrue);
    expect(surahId, 114);
    expect(ayahNumber, 1);
    expect(ayahNumbers, [1]);
    expect(durationSeconds, greaterThanOrEqualTo(0));
    lastSessionId = sessionId;
    lastMissionType = missionType;
    lastAttemptCount = attemptCount;
    lastHintCount = hintCount;
    lastMasteryRating = masteryRating;
    repeatsCompletedCalls.add(repeatsCompleted);
    awardCalls++;
    if (awardFailuresRemaining > 0) {
      awardFailuresRemaining--;
      return const Left(CacheFailure('award failed'));
    }
    final result = await awardCompleter!.future;
    result.fold((_) {}, (completion) {
      if (!completion.alreadyCompleted) {
        awardLogWrites++;
        awardedSessionIds.add(sessionId);
      }
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
    lastSavedReview = record;
    markCalls++;
    final failure = reviewWriteFailure;
    if (failure != null) return Left(failure);
    return const Right(null);
  }

  @override
  Future<Either<Failure, KidsSessionLog>> saveKidsSessionLog({
    String? sessionId,
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
    required int pointsEarned,
    KidsMissionType missionType = KidsMissionType.newMemorization,
    List<int> ayahNumbers = const [],
    int durationSeconds = 0,
    int attemptCount = 1,
    int hintCount = 0,
    PerformanceRating masteryRating = PerformanceRating.excellent,
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

class _ResumeQuranRepository implements QuranRepository {
  const _ResumeQuranRepository();

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async {
    return const Right(
      SurahDetail(
        surah: Surah(
          id: 114,
          nameAr: 'الناس',
          nameEn: 'An-Nas',
          ayahCount: 6,
          juz: 30,
          type: 'meccan',
          page: 604,
        ),
        ayahs: [
          Ayah(number: 1, surahId: 114, text: 'ayah text', numberInSurah: 1),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStreakService implements KidsStreakStore {
  int recordCalls = 0;

  @override
  Future<void> recordActivity({int activityDelta = 1}) async {
    expect(activityDelta, 1);
    recordCalls++;
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

/// Recorder whose capture result can change between attempts — models a
/// child improving between tries.
class _MutableKidsRecitationRecorder implements KidsRecitationRecorder {
  KidsRecitationCaptureResult result =
      const KidsRecitationCaptureResult.stoppedByUser();

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
