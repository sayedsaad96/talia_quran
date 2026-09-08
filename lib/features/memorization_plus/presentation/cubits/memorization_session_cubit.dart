// lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart
//
// V2 Memorization Session Cubit — wraps V2SessionEngine and drives the
// Learning → Memorizing → Reciting → Remediation → Block Review flow.
//
// Follows the same STT + Audio patterns as HifzSessionCubit but delegates
// all domain logic to the pure V2SessionEngine.

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:meta/meta.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/constants/speech_constants.dart';
import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../../core/memorization/v2/hint_usage.dart';
import '../../../../core/memorization/v2/review_effect_outbox_processor.dart';
import '../../../../core/memorization/v2/review_outcome_committer.dart';
import '../../../../core/memorization/v2/recitation_evaluator.dart';
import '../../../../core/memorization/v2/session_adapters.dart';
import '../../../../core/memorization/v2/session_engine.dart';
import '../../../../core/memorization/v2/session_phase.dart';
import '../../../../core/memorization/v2/session_state.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../core/services/audio_lifecycle_manager.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/repositories/quran_repository.dart';

// ─── State ──────────────────────────────────────────────────────────────────

/// Base state for the V2 Memorization Session.
@immutable
abstract class MemorizationSessionState extends Equatable {
  const MemorizationSessionState();

  @override
  List<Object?> get props => [];
}

class MSInitial extends MemorizationSessionState {
  const MSInitial();
}

class MSLoading extends MemorizationSessionState {
  const MSLoading();
}

class MSError extends MemorizationSessionState {
  const MSError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class MSActive extends MemorizationSessionState {
  const MSActive({
    required this.sessionState,
    required this.isRecording,
    required this.isPlaying,
    required this.recognizedText,
    required this.isEvaluating,
    this.speechIssue,
    this.persistenceIssue,
    this.audioFailed = false,
  });

  final V2SessionState sessionState;
  final bool isRecording;
  final bool isPlaying;
  final String recognizedText;
  final bool isEvaluating;

  /// Non-null when STT encounters a permission or availability error.
  final V2SpeechIssue? speechIssue;

  /// A durable review/checkpoint write failed. The state remains retryable.
  final String? persistenceIssue;
  final bool audioFailed;

  MSActive copyWith({
    V2SessionState? sessionState,
    bool? isRecording,
    bool? isPlaying,
    String? recognizedText,
    bool clearRecognizedText = false,
    bool? isEvaluating,
    V2SpeechIssue? speechIssue,
    bool clearSpeechIssue = false,
    String? persistenceIssue,
    bool clearPersistenceIssue = false,
    bool? audioFailed,
  }) {
    return MSActive(
      sessionState: sessionState ?? this.sessionState,
      isRecording: isRecording ?? this.isRecording,
      isPlaying: isPlaying ?? this.isPlaying,
      recognizedText: clearRecognizedText
          ? ''
          : (recognizedText ?? this.recognizedText),
      isEvaluating: isEvaluating ?? this.isEvaluating,
      speechIssue: clearSpeechIssue ? null : (speechIssue ?? this.speechIssue),
      persistenceIssue: clearPersistenceIssue
          ? null
          : (persistenceIssue ?? this.persistenceIssue),
      audioFailed: audioFailed ?? this.audioFailed,
    );
  }

  @override
  List<Object?> get props => [
    sessionState,
    isRecording,
    isPlaying,
    recognizedText,
    isEvaluating,
    speechIssue,
    persistenceIssue,
    audioFailed,
  ];
}

class MSCompleted extends MemorizationSessionState {
  const MSCompleted({required this.finalState, required this.awards});

  final V2SessionState finalState;
  final List<CertificateAward> awards;

  @override
  List<Object?> get props => [finalState, awards];
}

// ─── Speech issue enum (standalone to avoid coupling to Hifz) ──────────────

enum V2SpeechIssue {
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
  noSpeech,
}

// ─── Cubit ─────────────────────────────────────────────────────────────────

class MemorizationSessionCubit extends Cubit<MemorizationSessionState> {
  MemorizationSessionCubit({
    required QuranRepository quranRepository,
    required MemorizationPlusRepository memorizationRepository,
    required V2SessionEngine sessionEngine,
    required V2SessionReviewAdapter reviewAdapter,
    required V2SessionProgressAdapter progressAdapter,
    required V2SessionGamificationAdapter gamificationAdapter,
    V2ReviewOutcomeCommitter? reviewOutcomeCommitter,
    V2ReviewEffectOutboxProcessor? effectOutboxProcessor,
    AudioPlayer? audioPlayer,
    SpeechToText? speechToText,
    AudioCacheService? audioCacheService,
    AppSessionService? appSessionService,
  }) : _quranRepo = quranRepository,
       _memRepo = memorizationRepository,
       _engine = sessionEngine,
       _reviewAdapter = reviewAdapter,
       _progressAdapter = progressAdapter,
       _gamificationAdapter = gamificationAdapter,
       _reviewOutcomeCommitter = reviewOutcomeCommitter,
       _effectOutboxProcessor = effectOutboxProcessor,
       _player = audioPlayer ?? AudioPlayer(),
       _speechToText = speechToText ?? SpeechToText(),
       _audioCache = audioCacheService ?? AudioCacheService.instance,
       _appSessionService = appSessionService,
       super(const MSInitial()) {
    _initSpeech();
    AudioLifecycleManager.instance.register(_player);
    _playerStateSub = _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        if (state is MSActive) {
          emit((state as MSActive).copyWith(isPlaying: false));
        }
      }
    });
  }

  final QuranRepository _quranRepo;
  final MemorizationPlusRepository _memRepo;
  final V2SessionEngine _engine;
  final V2SessionReviewAdapter _reviewAdapter;
  final V2SessionProgressAdapter _progressAdapter;
  final V2SessionGamificationAdapter _gamificationAdapter;

  /// Null only in existing unit-test construction. Production DI always
  /// supplies this and therefore never follows the non-atomic legacy path.
  final V2ReviewOutcomeCommitter? _reviewOutcomeCommitter;
  final V2ReviewEffectOutboxProcessor? _effectOutboxProcessor;
  final AppSessionService? _appSessionService;

  // ── STT ──────────────────────────────────────────────────────────────────

  final SpeechToText _speechToText;
  bool _speechEnabled = false;
  bool _evaluationInFlight = false;

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
      );
    } catch (e, stack) {
      _speechEnabled = false;
      TaliaLogger.e('V2: Failed to initialize speech recognition', e, stack);
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (isClosed || state is! MSActive) return;
    final current = state as MSActive;
    emit(
      current.copyWith(
        isRecording: false,
        speechIssue: error.permanent
            ? V2SpeechIssue.unavailable
            : V2SpeechIssue.permissionDenied,
      ),
    );
  }

  void _handleSpeechStatus(String status) {
    if (status != 'notListening' && status != 'done') return;
    TaliaLogger.d('V2: Speech status: $status');
    if (state is MSActive && (state as MSActive).isRecording) {
      unawaited(stopRecording());
    }
  }

  // ── Audio ────────────────────────────────────────────────────────────────

  final AudioPlayer _player;
  final AudioCacheService _audioCache;
  StreamSubscription<PlayerState>? _playerStateSub;

  // ── Session lifecycle ────────────────────────────────────────────────────

  V2SessionState? _sessionState;

  /// Starts a new V2 memorization session.
  ///
  /// Loads surah ayahs, slices the block, creates initial engine state,
  /// and transitions to [V2SessionPhase.learning].
  Future<void> startSession({
    required int surahId,
    required int startAyah,
    int blockSize = 5,
  }) async {
    emit(const MSLoading());
    // Effects are durable and account-scoped. Replaying a previously committed
    // receipt here heals an interrupted session without duplicating rewards.
    unawaited(_processPendingEffects());

    // 1. Determine blockReviewRequired from profile.
    bool blockReviewRequired = true; // safe default
    final profileResult = await _memRepo.getMemorizationProfile();
    profileResult.fold(
      (_) => blockReviewRequired = true,
      (profile) => blockReviewRequired = profile.isBlockReviewRequired,
    );

    // 2. Load surah detail to get all ayahs.
    final surahResult = await _quranRepo.getSurahDetail(surahId);
    if (surahResult.isLeft()) {
      emit(const MSError(message: CubitMessageCodes.v2SurahLoadFailed));
      return;
    }

    final allAyahs = surahResult.fold(
      (_) => <Ayah>[],
      (detail) => detail.ayahs,
    );

    // Resume check: if a persisted session exists for this surah and is in a
    // restorable phase, rehydrate it instead of starting fresh. A terminal
    // checkpoint is safe to clear here only because the production committer
    // has already durably written its evidence and completion effect.
    final savedOpt = await _progressAdapter.loadIfExists(surahId);
    final saved = savedOpt.fold(() => null, (s) => s);
    if (saved != null) {
      final savedPhase = _phaseFromPersistedIndex(saved.phaseIndex);
      if (savedPhase == V2SessionPhase.completed) {
        // The event and outbox row—not this resumable UI checkpoint—are the
        // durable proof of completion. Clearing the checkpoint lets a learner
        // begin the next block without replaying the old result.
        await _progressAdapter.clear(surahId);
      } else if (savedPhase != V2SessionPhase.created &&
          saved.blockAyahNumbers.isNotEmpty) {
        _sessionState = V2SessionProgressAdapter.restore(saved, allAyahs);
        emit(
          MSActive(
            sessionState: _sessionState!,
            isRecording: false,
            isPlaying: false,
            recognizedText: '',
            isEvaluating: false,
          ),
        );
        unawaited(_progressAdapter.save(_sessionState!));
        unawaited(
          _prefetchBlockAudio(
            _sessionState!.surahId,
            _sessionState!.blockAyahs,
          ),
        );
        return;
      }
    }

    // Slice block: from startAyah (1-based) for blockSize ayahs.
    final startIndex = (startAyah - 1).clamp(0, allAyahs.length - 1);
    final endIndex = (startIndex + blockSize).clamp(0, allAyahs.length);
    final blockAyahs = allAyahs.sublist(startIndex, endIndex);

    if (blockAyahs.isEmpty) {
      emit(const MSError(message: CubitMessageCodes.v2NoAyahsInRange));
      return;
    }

    // 3. Create initial engine state.
    _sessionState = V2SessionState.initial(
      surahId: surahId,
      blockAyahs: blockAyahs,
      blockReviewRequired: blockReviewRequired,
    );

    // 4. Transition to learning (play audio for first ayah).
    _sessionState = _engine.startLearning(_sessionState!);

    emit(
      MSActive(
        sessionState: _sessionState!,
        isRecording: false,
        isPlaying: false,
        recognizedText: '',
        isEvaluating: false,
      ),
    );

    // 5. Save session state for resume.
    unawaited(_progressAdapter.save(_sessionState!));

    // 6. Start audio prefetch for the block.
    unawaited(_prefetchBlockAudio(surahId, blockAyahs));
  }

  // ── Phase transitions (user-driven) ──────────────────────────────────────

  /// User is ready to memorize after listening.
  Future<void> advanceToMemorizing() async {
    _assertActive();
    _sessionState = _engine.startMemorizing(_sessionState!);
    _emitActive();
    await _progressAdapter.save(_sessionState!);
  }

  /// User is ready to recite after memorizing (or after remediation).
  Future<void> advanceToReciting() async {
    _assertActive();
    // Stop audio if playing.
    if ((state as MSActive).isPlaying) await stopAudio();
    _sessionState = _engine.startReciting(_sessionState!);
    _emitActive(clearRecognizedText: true);
    await _progressAdapter.save(_sessionState!);
  }

  /// User requests a hint during memorizing.
  Future<void> useHint(V2HintLevel level) async {
    _assertActive();
    final updated = _engine.useHint(_sessionState!, level);
    if (!identical(updated, _sessionState)) {
      _sessionState = updated;
      _emitActive();
      await _progressAdapter.save(_sessionState!);
    }
  }

  /// User acknowledges remediation and returns to memorizing.
  Future<void> completeRemediation() async {
    _assertActive();
    _sessionState = _engine.completeRemediation(_sessionState!);
    _emitActive(clearRecognizedText: true);
    await _progressAdapter.save(_sessionState!);
  }

  /// User starts the block review after all ayahs passed individually.
  Future<void> startBlockReview() async {
    _assertActive();
    _sessionState = _engine.startBlockReview(_sessionState!);
    _emitActive(clearRecognizedText: true);
    await _progressAdapter.save(_sessionState!);
  }

  // ── STT recording ────────────────────────────────────────────────────────

  /// Starts STT recording for recitation or block review.
  Future<void> startRecording() async {
    _assertActive();
    final st = state as MSActive;
    if (st.isRecording || st.isEvaluating) return;

    if (st.isPlaying) await stopAudio();

    // Permission check.
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        emit(
          st.copyWith(
            speechIssue: status.isPermanentlyDenied
                ? V2SpeechIssue.permissionPermanentlyDenied
                : V2SpeechIssue.permissionDenied,
          ),
        );
        return;
      }
    }

    if (!_speechEnabled) await _initSpeech();

    if (_speechEnabled) {
      emit(
        st.copyWith(
          isRecording: true,
          recognizedText: '',
          clearSpeechIssue: true,
          clearRecognizedText: true,
        ),
      );
      await _speechToText.listen(
        onResult: (result) {
          if (state is MSActive) {
            emit(
              (state as MSActive).copyWith(
                recognizedText: result.recognizedWords,
              ),
            );
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: kArabicSpeechLocaleId,
          pauseFor: const Duration(seconds: 5),
        ),
      );
    } else {
      emit(st.copyWith(speechIssue: V2SpeechIssue.unavailable));
    }
  }

  /// Stops STT and evaluates the recitation.
  Future<void> stopRecording() => _runEvaluationExclusive(() async {
    _assertActive();
    final st = state as MSActive;
    if (!st.isRecording) return;

    await _speechToText.stop();
    emit(st.copyWith(isRecording: false, isEvaluating: true));

    // Brief UI delay for "Evaluating..." feedback.
    await Future.delayed(const Duration(milliseconds: 500));
    await _evaluateCurrentRecitation();
  });

  /// V1-M8 — manual/self-grade route.
  ///
  /// The learner explicitly confirms they recited the current ayah (or block)
  /// from memory. Used when the microphone is denied, the recognizer is
  /// unavailable, or recognition keeps failing. No automatic score is
  /// fabricated; review scheduling behaves exactly like a normal pass.
  Future<void> submitManualRecall() => _runEvaluationExclusive(() async {
    _assertActive();
    final st = state as MSActive;
    if (st.isRecording || st.isEvaluating) return;

    emit(st.copyWith(isEvaluating: true));
    await _evaluateCurrentRecitation(manualGrade: true);
  });

  // ── Audio playback ────────────────────────────────────────────────────────

  /// Plays audio for the current ayah.
  Future<void> playCurrentAyah() async {
    _assertActive();
    final st = state as MSActive;
    if (st.isPlaying) await stopAudio();

    final ayah = st.sessionState.currentAyah;
    try {
      final audioSource = await _audioCache.getAudioSource(
        st.sessionState.surahId,
        ayah.numberInSurah,
      );
      await AudioCacheService.playFromSource(_player, audioSource);
      emit(st.copyWith(isPlaying: true));
    } catch (e, stack) {
      TaliaLogger.e('V2: Failed to play ayah audio', e, stack);
      if (state is MSActive) {
        emit((state as MSActive).copyWith(isPlaying: false, audioFailed: true));
      }
    }
  }

  /// Stops audio playback.
  Future<void> stopAudio() async {
    await _player.stop();
    if (state is MSActive) {
      emit((state as MSActive).copyWith(isPlaying: false));
    }
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────

  @override
  Future<void> close() async {
    AudioLifecycleManager.instance.unregister(_player);
    // Cleanup must never throw: speech_to_text.cancel() fails on platforms
    // without speech support or when initialize() never completed, and a
    // throwing close() surfaces as an unhandled error on session exit.
    try {
      await _player.stop();
    } catch (error, stack) {
      TaliaLogger.w('Session player stop failed', error, stack);
    }
    await _playerStateSub?.cancel();
    try {
      await _player.dispose();
    } catch (error, stack) {
      TaliaLogger.w('Session player dispose failed', error, stack);
    }
    try {
      await _speechToText.cancel();
    } catch (error, stack) {
      TaliaLogger.w('Speech cancellation failed', error, stack);
    }
    return super.close();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  void _assertActive() {
    assert(state is MSActive, 'Cubit must be in MSActive state');
  }

  void _emitActive({
    bool clearRecognizedText = false,
    bool clearSpeechIssue = false,
  }) {
    final st = state as MSActive;
    emit(
      st.copyWith(
        sessionState: _sessionState!,
        clearRecognizedText: clearRecognizedText,
        clearSpeechIssue: clearSpeechIssue,
        clearPersistenceIssue: true,
      ),
    );
  }

  V2SessionPhase? _phaseFromPersistedIndex(int phaseIndex) {
    if (phaseIndex >= 0 && phaseIndex < V2SessionPhase.values.length) {
      return V2SessionPhase.values[phaseIndex];
    }
    TaliaLogger.w(
      'V2: persisted phaseIndex=$phaseIndex is invalid; restoring from learning',
    );
    // Null is deliberately restorable. restore() falls back to learning, a
    // safe phase that cannot skip recitation or block review.
    return null;
  }

  Future<void> _runEvaluationExclusive(
    Future<void> Function() operation,
  ) async {
    if (_evaluationInFlight) return;
    _evaluationInFlight = true;
    try {
      await operation();
    } finally {
      _evaluationInFlight = false;
    }
  }

  /// Evaluates the current recitation based on session phase.
  Future<void> _evaluateCurrentRecitation({bool manualGrade = false}) async {
    if (_sessionState == null || state is! MSActive) return;
    final spokenText = (state as MSActive).recognizedText;
    final previousState = _sessionState!;

    V2SessionState newState;
    V2RecitationResult? automaticEvidence;
    if (manualGrade) {
      switch (previousState.phase) {
        case V2SessionPhase.reciting:
          newState = _engine.submitManualRecall(previousState);
        case V2SessionPhase.blockReview:
          newState = _engine.submitManualBlockReview(previousState);
        default:
          // Not a recitation phase — ignore.
          emit((state as MSActive).copyWith(isEvaluating: false));
          return;
      }
    } else if (previousState.phase == V2SessionPhase.reciting) {
      automaticEvidence = _engine.evaluateRecitationAttempt(
        previousState,
        spokenText,
      );
      newState = _engine.evaluateRecitation(previousState, spokenText);
    } else if (previousState.phase == V2SessionPhase.blockReview) {
      newState = _engine.evaluateBlockReview(previousState, spokenText);
    } else {
      // Not a recitation phase — ignore.
      emit((state as MSActive).copyWith(isEvaluating: false));
      return;
    }

    final noSpeech =
        !manualGrade &&
        spokenText.trim().isEmpty &&
        newState.phase == previousState.phase &&
        newState.lastRecitationResult == previousState.lastRecitationResult;

    // Never expose a progress transition before its review/checkpoint writes
    // succeed. This keeps the currently displayed state retryable after a
    // local-storage or SRS failure.
    final persisted = await _handlePostEvaluation(
      previousState,
      newState,
      manuallyAssessed: manualGrade,
      similarityScore: automaticEvidence?.similarityScore,
    );
    if (!persisted) {
      _restoreAfterPersistenceFailure(previousState);
      return;
    }

    if (newState.phase == V2SessionPhase.completed) {
      final completed = await _onBlockCompleted(newState);
      if (!completed) _restoreAfterPersistenceFailure(previousState);
      return;
    }

    _sessionState = newState;
    emit(
      (state as MSActive).copyWith(
        sessionState: newState,
        isEvaluating: false,
        speechIssue: noSpeech ? V2SpeechIssue.noSpeech : null,
        clearSpeechIssue: manualGrade || !noSpeech,
        clearPersistenceIssue: true,
      ),
    );
  }

  /// Persists records and handles phase transitions after evaluation.
  Future<bool> _handlePostEvaluation(
    V2SessionState previousState,
    V2SessionState newState, {
    bool manuallyAssessed = false,
    double? similarityScore,
  }) async {
    final passedAyah = previousState.currentAyah;
    final newlyPassedAyahs = newState.passedAyahNumbers.difference(
      previousState.passedAyahNumbers,
    );
    final shouldRecordPass =
        previousState.phase == V2SessionPhase.reciting &&
        newlyPassedAyahs.contains(passedAyah.numberInSurah);
    final isAutomaticRecitationFailure =
        !manuallyAssessed &&
        (previousState.phase == V2SessionPhase.reciting ||
            previousState.phase == V2SessionPhase.blockReview) &&
        newState.failureTracker.totalFailures >
            previousState.failureTracker.totalFailures;
    // Individual-pass transitions intentionally clear their transient result
    // while moving to the next ayah. Block-review failures retain it, so use
    // the direct pre-transition metric when available and the persisted metric
    // otherwise.
    final evidenceSimilarity =
        similarityScore ?? newState.lastRecitationResult?.similarityScore;

    try {
      if (shouldRecordPass) {
        final committer = _reviewOutcomeCommitter;
        if (committer != null) {
          await committer.commitAutomaticPass(
            previousState: previousState,
            nextState: newState,
            taskId: 'ayah:${previousState.surahId}:${passedAyah.numberInSurah}',
            manuallyAssessed: manuallyAssessed,
            similarityScore: evidenceSimilarity,
          );
          // The completion screen owns terminal processing so certificate
          // awards are delivered with that screen rather than racing a
          // fire-and-forget processor call.
          if (newState.phase != V2SessionPhase.completed) {
            unawaited(_processPendingEffects());
          }
          return true;
        }
        // Compatibility only for historical unit tests that construct this
        // Cubit without DI. App production registers a committer and cannot
        // take this two-store path.
        final result = await _reviewAdapter.recordPass(
          surahId: previousState.surahId,
          ayahNumber: passedAyah.numberInSurah,
          hintLevel: previousState.hintTracker.levelFor(
            previousState.surahId,
            passedAyah.numberInSurah,
          ),
        );
        if (result.isLeft()) return false;
      } else if (newState.phase == V2SessionPhase.completed &&
          _reviewOutcomeCommitter != null) {
        await _reviewOutcomeCommitter.commitBlockReviewCompletion(
          previousState: previousState,
          nextState: newState,
          taskId: 'block-review:${previousState.surahId}',
          manuallyAssessed: manuallyAssessed,
          similarityScore: evidenceSimilarity,
        );
        return true;
      } else if (isAutomaticRecitationFailure &&
          _reviewOutcomeCommitter != null) {
        final taskId = previousState.phase == V2SessionPhase.blockReview
            ? 'block-review:${previousState.surahId}'
            : 'ayah:${previousState.surahId}:${passedAyah.numberInSurah}';
        await _reviewOutcomeCommitter.commitFailedAutomaticAttempt(
          previousState: previousState,
          nextState: newState,
          taskId: taskId,
          similarityScore: evidenceSimilarity,
        );
        unawaited(_processPendingEffects());
        return true;
      }

      // A terminal state is never checkpointed: resume would discard it and
      // falsely look completed if finalization failed. It is cleared only
      // after all required review writes succeed.
      if (newState.phase != V2SessionPhase.completed) {
        await _progressAdapter.save(newState);
      }
      return true;
    } catch (error, stack) {
      TaliaLogger.e('V2: Failed to persist recitation outcome', error, stack);
      return false;
    }
  }

  /// Called when the session reaches the completed phase.
  Future<bool> _onBlockCompleted(V2SessionState finalState) async {
    try {
      if (_reviewOutcomeCommitter != null) {
        // A terminal checkpoint and a completion receipt were committed before
        // this UI transition. Effects stay deferred to the durable Outbox;
        // clearing the UI checkpoint cannot lose them.
        try {
          await _progressAdapter.clear(finalState.surahId);
          await _appSessionService?.clearLastRestorableLocation();
        } catch (error, stack) {
          // A stale checkpoint is recoverable because its evidence/effects are
          // already durable. Completion itself must not be reported as failed
          // or cause the learner to repeat a committed recitation.
          TaliaLogger.w(
            'V2: terminal checkpoint cleanup deferred',
            error,
            stack,
          );
        }
        final awards = await _processPendingEffects();
        emit(MSCompleted(finalState: finalState, awards: awards));
        return true;
      }
      final weakResult = await _reviewAdapter.recordWeakAyahs(
        finalState.failureTracker,
        passedAyahNumbers: finalState.passedAyahNumbers,
      );
      if (weakResult.isLeft()) return false;

      // Do this before any repeatable gamification effects. If it fails, keep
      // the in-flight session visible rather than granting a false completion.
      await _progressAdapter.clear(finalState.surahId);
      await _appSessionService?.clearLastRestorableLocation();

      final awards = await _gamificationAdapter.onBlockCompleted(finalState);
      emit(MSCompleted(finalState: finalState, awards: awards));
      return true;
    } catch (error, stack) {
      TaliaLogger.e('V2: Failed to finalize completed block', error, stack);
      return false;
    }
  }

  void _restoreAfterPersistenceFailure(V2SessionState durableState) {
    _sessionState = durableState;
    if (state is! MSActive) return;
    emit(
      (state as MSActive).copyWith(
        sessionState: durableState,
        isRecording: false,
        isEvaluating: false,
        persistenceIssue: CubitMessageCodes.hifzReviewSaveFailed,
      ),
    );
  }

  Future<List<CertificateAward>> _processPendingEffects() async {
    final processor = _effectOutboxProcessor;
    if (processor == null) return const [];
    try {
      return await processor.processPending();
    } catch (error, stack) {
      // Evidence and receipts remain durable; a later app entry can retry.
      TaliaLogger.w('V2: Deferred review effects remain pending', error, stack);
      return const [];
    }
  }

  /// Exposed for B8 regression tests only.
  @visibleForTesting
  Future<void> onBlockCompletedForTesting(V2SessionState finalState) async {
    await _onBlockCompleted(finalState);
  }

  @visibleForTesting
  Future<void> evaluateCurrentRecitationForTesting([String? spokenText]) =>
      _runEvaluationExclusive(() async {
        if (spokenText != null && state is MSActive) {
          emit((state as MSActive).copyWith(recognizedText: spokenText));
        }
        await _evaluateCurrentRecitation();
      });

  @visibleForTesting
  Future<void> handlePostEvaluationForTesting(
    V2SessionState previousState,
    V2SessionState newState,
  ) async {
    await _handlePostEvaluation(previousState, newState);
  }

  /// Prefetches audio for all ayahs in the block.
  Future<void> _prefetchBlockAudio(int surahId, List<Ayah> blockAyahs) async {
    final numbers = blockAyahs.map((a) => a.numberInSurah).toList();
    await _audioCache.prefetchSession(surahId: surahId, ayahNumbers: numbers);
  }
}
