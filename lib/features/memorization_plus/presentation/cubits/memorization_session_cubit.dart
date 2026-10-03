import 'dart:async';
// lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart
//
// V2 Memorization Session Cubit — wraps V2SessionEngine and drives the
// Learning → Memorizing → Reciting → Remediation → Block Review flow.
//
// Follows the same STT + Audio patterns as HifzSessionCubit but delegates
// all domain logic to the pure V2SessionEngine.


import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:meta/meta.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/constants/speech_constants.dart';
import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../../core/memorization/learning_launch_context.dart';
import '../../../../core/memorization/review_passage_picker.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/memorization/review_record_filters.dart';
import '../../../../core/memorization/v2/hint_usage.dart';
import '../../../../core/memorization/v2/recitation_word_diff.dart';
import '../../../../core/memorization/v2/review_effect_outbox_processor.dart';
import '../../../../core/memorization/v2/review_outcome_committer.dart';
import '../../../../core/memorization/v2/recitation_evaluator.dart';
import '../../../../core/memorization/v2/listen_budget.dart';
import '../../../../core/memorization/v2/self_grade.dart';
import '../../../../core/memorization/v2/session_adapters.dart';
import '../../../../core/memorization/v2/session_engine.dart';
import '../../../../core/memorization/v2/session_phase.dart';
import '../../../../core/memorization/v2/session_state.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../core/services/audio_lifecycle_manager.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../../../memorization_plus/domain/entities/custom_memorization_plan.dart';
import '../../../memorization_plus/domain/services/plan_schedule_policy.dart';
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
    this.lastEvaluation,
    this.audioLoopMode = V2AudioLoopMode.off,
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

  /// Presentation-only snapshot of the most recent recitation evaluation,
  /// captured before the engine transition (a pass deliberately clears the
  /// engine's transient result while moving on). The result sheet and the
  /// word diff render from this; it never feeds back into domain logic.
  final V2EvaluationFeedback? lastEvaluation;

  /// Learner-selected repeat mode for the current ayah's audio.
  final V2AudioLoopMode audioLoopMode;

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
    V2EvaluationFeedback? lastEvaluation,
    bool clearLastEvaluation = false,
    V2AudioLoopMode? audioLoopMode,
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
      lastEvaluation: clearLastEvaluation
          ? null
          : (lastEvaluation ?? this.lastEvaluation),
      audioLoopMode: audioLoopMode ?? this.audioLoopMode,
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
    lastEvaluation,
    audioLoopMode,
  ];
}

/// Immutable, presentation-only feedback for the most recent recitation
/// attempt. Carries the engine's [result] plus the word-level diff so the
/// result sheet can render a colour-coded comparison.
final class V2EvaluationFeedback extends Equatable {
  const V2EvaluationFeedback({required this.result, required this.wordDiff});

  final V2RecitationResult result;
  final RecitationWordDiffResult wordDiff;

  @override
  List<Object?> get props => [result, wordDiff];
}

/// Learner-controlled audio loop mode for the current ayah.
enum V2AudioLoopMode { off, threeTimes, endless }

extension V2AudioLoopModeX on V2AudioLoopMode {
  int? get repeatCount => switch (this) {
    V2AudioLoopMode.off => 1,
    V2AudioLoopMode.threeTimes => 3,
    V2AudioLoopMode.endless => null,
  };
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
    double Function()? recitationPassThreshold,
  }) : _quranRepo = quranRepository,
       _recitationPassThreshold = recitationPassThreshold,
       _memRepo = memorizationRepository,
       _baseEngine = sessionEngine,
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
          unawaited(_handlePlaybackCompleted());
        }
      }
    });
  }

  final QuranRepository _quranRepo;
  final MemorizationPlusRepository _memRepo;
  final V2SessionEngine _baseEngine;

  /// The engine for the current session; stricter for a challenging plan.
  V2SessionEngine _engine;
  final V2SessionReviewAdapter _reviewAdapter;
  final V2SessionProgressAdapter _progressAdapter;
  final V2SessionGamificationAdapter _gamificationAdapter;

  /// Null only in existing unit-test construction. Production DI always
  /// supplies this and therefore never follows the non-atomic legacy path.
  final V2ReviewOutcomeCommitter? _reviewOutcomeCommitter;
  final V2ReviewEffectOutboxProcessor? _effectOutboxProcessor;
  final AppSessionService? _appSessionService;

  /// The user's "Accuracy level" pass threshold; null keeps the engine's.
  final double Function()? _recitationPassThreshold;

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
      // Speech recognition is unavailable on this device (e.g. no recogniser
      // installed). This is an expected, gracefully-handled degradation — the
      // session continues in manual-grade mode. Use warn, not error.
      TaliaLogger.w(
        'V2: Speech recognition unavailable on this device',
        e,
        stack,
      );
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (isClosed || state is! MSActive) return;
    final current = state as MSActive;
    emit(
      current.copyWith(
        isRecording: false,
        speechIssue: _classifySpeechIssue(error),
      ),
    );
  }

  /// Maps plugin recognizer errors to honest user-facing categories.
  ///
  /// Reporting every transient error as a permission denial sent users to
  /// fix permissions when the real cause was silence, a busy recognizer,
  /// or a network hiccup.
  V2SpeechIssue _classifySpeechIssue(SpeechRecognitionError error) {
    switch (error.errorMsg) {
      // Silence or no recognizable speech — reciting again is enough.
      case 'error_no_match':
      case 'error_speech_timeout':
        return V2SpeechIssue.noSpeech;
      // Recognizer-level permission failure. The pre-listen app permission
      // check normally catches this first; kept for residual races.
      case 'error_permission':
        return V2SpeechIssue.permissionPermanentlyDenied;
    }
    // Everything else (network, busy recognizer, server, audio, unknown)
    // is a temporary "unavailable" condition: the session continues in
    // manual-grade mode and the learner can retry recording.
    return V2SpeechIssue.unavailable;
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

  /// Remaining repeats for the current loop request; null = endless.
  int? _loopRemaining;
  int? _loopSurahId;
  int? _loopAyahNumber;

  /// Invalidates pending source loads and player setup when playback stops or
  /// a newer request takes its place.
  int _audioRequestId = 0;

  // ── Session lifecycle ────────────────────────────────────────────────────

  V2SessionState? _sessionState;
  LearningLaunchContext? _launchContext;
  bool _discardCommitted = false;
  bool _discardInFlight = false;

  /// Starts a new V2 memorization session.
  ///
  /// Loads surah ayahs, slices the block, creates initial engine state,
  /// and transitions to [V2SessionPhase.learning].
  Future<void> startSession({
    required int surahId,
    required int startAyah,
    int blockSize = 5,
    LearningLaunchContext? launchContext,
  }) async {
    emit(const MSLoading());
    _discardCommitted = false;
    _launchContext =
        launchContext ??
        LearningLaunchContext(
          ayah: AyahReference(surahId: surahId, ayahNumber: startAyah),
          intent: LearningIntent.memorize,
          origin: LearningOrigin.unknown,
        );
    // Effects are durable and account-scoped. Replaying a previously committed
    // receipt here heals an interrupted session without duplicating rewards.
    unawaited(_processPendingEffects());

    // Pass threshold: the "Accuracy level" setting, raised to the stricter
    // threshold of a challenging plan (M-U4). Read failures keep the default.
    _engine = _baseEngine;
    double? threshold;
    try {
      threshold = _recitationPassThreshold?.call();
    } catch (_) {}
    try {
      final planResult = await _memRepo.getCustomPlan();
      final plan = planResult.fold((_) => null, (value) => value);
      if (plan != null &&
          plan.isActive &&
          plan.targetUser == PlanTargetUser.adult &&
          plan.difficulty == MemorizationDifficulty.challenging) {
        final planThreshold = PlanSchedulePolicy.passThreshold(
          plan.difficulty,
        );
        threshold = threshold == null || threshold < planThreshold
            ? planThreshold
            : threshold;
      }
    } catch (_) {}
    if (threshold != null) {
      _engine = _baseEngine.withPassThreshold(threshold);
    }

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
    //
    // The checkpoint may only take over navigation when the requested ayah
    // belongs to the saved block and the saved intent matches — otherwise a
    // stale checkpoint would silently swallow the explicit target (plan item,
    // SmartCoach due ayah, review tap).
    final isReview = _launchContext!.intent == LearningIntent.review;
    final savedOpt = await _progressAdapter.loadIfExists(
      surahId,
      review: isReview,
    );
    final saved = savedOpt.fold(() => null, (s) => s);
    if (saved != null) {
      final savedPhase = _phaseFromPersistedIndex(saved.phaseIndex);
      if (savedPhase == V2SessionPhase.completed) {
        // The event and outbox row—not this resumable UI checkpoint—are the
        // durable proof of completion. Clearing the checkpoint lets a learner
        // begin the next block without replaying the old result.
        await _progressAdapter.clear(surahId, review: isReview);
      } else if (savedPhase != V2SessionPhase.created &&
          saved.blockAyahNumbers.isNotEmpty &&
          saved.blockAyahNumbers.contains(startAyah) &&
          _isResumableIntent(saved.launchContext.intent, isReview)) {
        _launchContext = saved.launchContext;
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
        unawaited(_saveProgress(_sessionState!));
        unawaited(
          _prefetchBlockAudio(
            _sessionState!.surahId,
            _sessionState!.blockAyahs,
          ),
        );
        return;
      } else {
        // Starting a different block in this lane replaces the stale
        // checkpoint explicitly. Clearing it first gives the new session its
        // own sessionId, so its outcomes are never mistaken for duplicates of
        // the old session's already-committed tasks.
        await _progressAdapter.clear(surahId, review: isReview);
      }
    }

    // Slice block: from startAyah (1-based) for blockSize ayahs. A review
    // covers the due passage around its target (N4): the following due
    // ayahs on the same page, each still recited and scheduled on its own.
    final startIndex = (startAyah - 1).clamp(0, allAyahs.length - 1);
    final List<Ayah> blockAyahs;
    if (isReview) {
      final passage = ReviewPassagePicker.pick(
        surahAyahs: allAyahs,
        startAyah: allAyahs[startIndex].numberInSurah,
        dueAyahNumbers: await _dueReviewAyahNumbers(surahId),
      );
      blockAyahs = passage.isEmpty ? [allAyahs[startIndex]] : passage;
    } else {
      final endIndex = (startIndex + blockSize).clamp(0, allAyahs.length);
      blockAyahs = allAyahs.sublist(startIndex, endIndex);
    }

    if (blockAyahs.isEmpty) {
      emit(const MSError(message: CubitMessageCodes.v2NoAyahsInRange));
      return;
    }

    // 3. Create initial engine state.
    _sessionState = V2SessionState.initial(
      surahId: surahId,
      blockAyahs: blockAyahs,
      blockReviewRequired: blockReviewRequired,
      isReview: isReview,
    );

    // 4. Reviews start at active recall (reciting); memorization starts at
    // learning (play audio for first ayah).
    _sessionState = isReview
        ? _engine.startReview(_sessionState!)
        : _engine.startLearning(_sessionState!);

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
    unawaited(_saveProgress(_sessionState!));

    // 6. Start audio prefetch for the block.
    unawaited(_prefetchBlockAudio(surahId, blockAyahs));
  }

  /// Adult ayahs of [surahId] due for review now. Any read failure yields
  /// none, so the review falls back to its single target ayah.
  Future<Set<int>> _dueReviewAyahNumbers(int surahId) async {
    try {
      final result = await _memRepo.getAllReviewRecords(
        scope: ReviewRecordReadScope.adult,
      );
      final now = DateTime.now().toUtc();
      return result.fold<Set<int>>(
        (_) => <int>{},
        (records) => {
          for (final record in records)
            if (record.surahId == surahId &&
                ReviewRecordFilters.isAdultCompatible(record) &&
                record.classifyAt(now).isVisibleForReview)
              record.ayahNumber,
        },
      );
    } catch (error, stack) {
      TaliaLogger.w('V2: review passage lookup failed', error, stack);
      return <int>{};
    }
  }

  Future<void> _saveProgress(V2SessionState sessionState) =>
      _progressAdapter.save(sessionState, launchContext: _launchContext);

  /// Explicitly abandons the resumable checkpoint. Real failed, unpassed
  /// ayahs become one weak review each before the checkpoint is removed.
  Future<bool> discardSession() async {
    if (_discardCommitted) return true;
    if (_discardInFlight) return false;
    final sessionState = _sessionState;
    if (sessionState == null) return true;

    _discardInFlight = true;
    try {
      final weakResult = await _reviewAdapter.recordAbandonedFailures(
        sessionState.failureTracker,
        passedAyahNumbers: sessionState.passedAyahNumbers,
      );
      if (weakResult.isLeft()) {
        _emitDiscardPersistenceIssue();
        return false;
      }
      await _progressAdapter.clear(
        sessionState.surahId,
        review: sessionState.isReview,
      );
      await _appSessionService?.clearLastRestorableLocation();
      _discardCommitted = true;
      return true;
    } catch (error, stack) {
      TaliaLogger.e('V2: Failed to discard session', error, stack);
      _emitDiscardPersistenceIssue();
      return false;
    } finally {
      _discardInFlight = false;
    }
  }

  void _emitDiscardPersistenceIssue() {
    if (state is! MSActive) return;
    emit(
      (state as MSActive).copyWith(
        persistenceIssue: CubitMessageCodes.hifzReviewSaveFailed,
      ),
    );
  }

  // ── Phase transitions (user-driven) ──────────────────────────────────────

  /// User is ready to memorize after listening.
  Future<void> advanceToMemorizing() async {
    _assertActive();
    _sessionState = _engine.startMemorizing(_sessionState!);
    _emitActive(clearLastEvaluation: true);
    await _saveProgress(_sessionState!);
  }

  /// User is ready to recite after memorizing (or after remediation).
  Future<void> advanceToReciting() async {
    _assertActive();
    // Stop audio if playing.
    if ((state as MSActive).isPlaying) await stopAudio();
    _sessionState = _engine.startReciting(_sessionState!);
    // A stale speech issue (e.g. a previous "no speech detected") must not
    // keep rendering in the reciting footer until the next recording.
    _emitActive(clearRecognizedText: true, clearSpeechIssue: true);
    await _saveProgress(_sessionState!);
  }

  /// Result-sheet "recite again" path: from remediation straight back into
  /// the reciting phase without a full memorizing detour (already covered by
  /// [V2SessionEngine.startReciting], which allows remediation → reciting).
  Future<void> retryRecitationFromRemediation() async {
    _assertActive();
    if (_sessionState!.phase != V2SessionPhase.remediation) return;
    if ((state as MSActive).isPlaying) await stopAudio();
    _sessionState = _engine.startReciting(_sessionState!);
    _emitActive(
      clearRecognizedText: true,
      clearLastEvaluation: true,
      clearSpeechIssue: true,
    );
    await _saveProgress(_sessionState!);
  }

  /// User requests a hint during memorizing.
  Future<void> useHint(V2HintLevel level) async {
    _assertActive();
    final updated = _engine.useHint(_sessionState!, level);
    if (!identical(updated, _sessionState)) {
      _sessionState = updated;
      _emitActive();
      await _saveProgress(_sessionState!);
    }
  }

  /// User acknowledges remediation and returns to memorizing.
  Future<void> completeRemediation() async {
    _assertActive();
    _sessionState = _engine.completeRemediation(_sessionState!);
    _emitActive(clearRecognizedText: true);
    await _saveProgress(_sessionState!);
  }

  /// User starts the block review after all ayahs passed individually.
  Future<void> startBlockReview() async {
    _assertActive();
    _sessionState = _engine.startBlockReview(_sessionState!);
    _emitActive(clearRecognizedText: true);
    await _saveProgress(_sessionState!);
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
      // Sized to the recitation so long block reviews are not cut off (A6).
      final budget = V2ListenBudget.forState(st.sessionState);
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
          listenFor: budget.listenFor,
          pauseFor: budget.pauseFor,
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
  Future<void> submitManualRecall([V2SelfGrade grade = V2SelfGrade.mastered]) =>
      _runEvaluationExclusive(() async {
        _assertActive();
        final st = state as MSActive;
        if (st.isRecording || st.isEvaluating) return;

        emit(st.copyWith(isEvaluating: true));
        await _evaluateCurrentRecitation(manualGrade: true, selfGrade: grade);
      });

  /// Self-graded block review (N5). A hesitation or a lapse is a failed
  /// block review: [stumbledAyahNumber] is remediated, as after an automatic
  /// failure, instead of the block silently passing.
  Future<void> submitManualBlockReview({
    V2SelfGrade grade = V2SelfGrade.mastered,
    int? stumbledAyahNumber,
  }) => _runEvaluationExclusive(() async {
    _assertActive();
    final st = state as MSActive;
    if (st.isRecording || st.isEvaluating) return;

    emit(st.copyWith(isEvaluating: true));
    await _evaluateCurrentRecitation(
      manualGrade: true,
      selfGrade: grade,
      stumbledAyahNumber: stumbledAyahNumber,
    );
  });

  // ── Audio playback ────────────────────────────────────────────────────────

  /// Plays audio for the current ayah.
  Future<void> playCurrentAyah() async {
    _assertActive();
    final st = state as MSActive;
    if (st.isPlaying) await stopAudio();

    final ayah = st.sessionState.currentAyah;
    final requestId = ++_audioRequestId;
    final targetSession = st.sessionState;
    _loopSurahId = st.sessionState.surahId;
    _loopAyahNumber = ayah.numberInSurah;
    _loopRemaining = (st.audioLoopMode.repeatCount ?? 1) - 1;
    try {
      final audioSource = await _audioCache.getAudioSource(
        st.sessionState.surahId,
        ayah.numberInSurah,
      );
      if (!_isCurrentAudioRequest(requestId, targetSession)) return;

      // AudioPlayer.play completes when playback finishes. Emit before it so
      // the listening control reflects playback as soon as the player starts.
      emit((state as MSActive).copyWith(isPlaying: true));
      await _startAudioPlayback(
        requestId: requestId,
        targetSession: targetSession,
        source: audioSource,
        context: 'play ayah audio',
      );
    } catch (e, stack) {
      TaliaLogger.e('V2: Failed to play ayah audio', e, stack);
      if (_isCurrentAudioRequest(requestId, targetSession)) {
        emit((state as MSActive).copyWith(isPlaying: false, audioFailed: true));
      }
    }
  }

  /// Cycles the learner's loop preference: off → 3× → endless → off.
  ///
  /// Changes apply from the next play request; the current playback finishes
  /// its pass undisturbed (audio-layer only, no session semantics).
  Future<void> cycleAudioLoopMode() async {
    _assertActive();
    final st = state as MSActive;
    final next = switch (st.audioLoopMode) {
      V2AudioLoopMode.off => V2AudioLoopMode.threeTimes,
      V2AudioLoopMode.threeTimes => V2AudioLoopMode.endless,
      V2AudioLoopMode.endless => V2AudioLoopMode.off,
    };
    emit(st.copyWith(audioLoopMode: next));
  }

  /// Replays the current ayah when a loop mode is active.
  Future<void> _handlePlaybackCompleted() async {
    final st = state is MSActive ? state as MSActive : null;
    if (st == null) {
      _loopRemaining = null;
      return;
    }

    final mode = st.audioLoopMode;
    final surahId = st.sessionState.surahId;
    final ayahNumber = st.sessionState.currentAyah.numberInSurah;

    // Ayah changed since the play request — drop pending repeats.
    if (_loopSurahId != surahId || _loopAyahNumber != ayahNumber) {
      _loopRemaining = null;
      emit(st.copyWith(isPlaying: false));
      return;
    }

    if (mode == V2AudioLoopMode.off) {
      _loopRemaining = null;
      emit(st.copyWith(isPlaying: false));
      return;
    }

    if (mode == V2AudioLoopMode.threeTimes) {
      final remaining = _loopRemaining ?? 0;
      if (remaining <= 0) {
        _loopRemaining = null;
        emit(st.copyWith(isPlaying: false));
        return;
      }
      _loopRemaining = remaining - 1;
    }

    final requestId = ++_audioRequestId;
    final targetSession = st.sessionState;
    try {
      final audioSource = await _audioCache.getAudioSource(surahId, ayahNumber);
      if (!_isCurrentAudioRequest(requestId, targetSession)) return;
      await _startAudioPlayback(
        requestId: requestId,
        targetSession: targetSession,
        source: audioSource,
        context: 'loop ayah audio',
      );
    } catch (e, stack) {
      TaliaLogger.e('V2: Failed to loop ayah audio', e, stack);
      _loopRemaining = null;
      if (_isCurrentAudioRequest(requestId, targetSession)) {
        emit((state as MSActive).copyWith(isPlaying: false, audioFailed: true));
      }
    }
  }

  /// Stops audio playback.
  Future<void> stopAudio() async {
    _audioRequestId++;
    await _player.stop();
    _loopRemaining = null;
    if (state is MSActive) {
      emit((state as MSActive).copyWith(isPlaying: false));
    }
  }

  bool _isCurrentAudioRequest(int requestId, V2SessionState targetSession) {
    final current = state;
    return !isClosed &&
        requestId == _audioRequestId &&
        current is MSActive &&
        identical(current.sessionState, targetSession);
  }

  Future<void> _startAudioPlayback({
    required int requestId,
    required V2SessionState targetSession,
    required String source,
    required String context,
  }) async {
    try {
      if (source.startsWith('http://') || source.startsWith('https://')) {
        await _player.setUrl(source);
      } else {
        await _player.setFilePath(source);
      }
      if (!_isCurrentAudioRequest(requestId, targetSession)) return;

      unawaited(
        _observeAudioPlayback(
          _player.play(),
          requestId: requestId,
          targetSession: targetSession,
          context: context,
        ),
      );
    } catch (e, stack) {
      TaliaLogger.e('V2: Failed to $context', e, stack);
      if (_isCurrentAudioRequest(requestId, targetSession)) {
        emit((state as MSActive).copyWith(isPlaying: false, audioFailed: true));
      }
    }
  }

  Future<void> _observeAudioPlayback(
    Future<void> playback, {
    required int requestId,
    required V2SessionState targetSession,
    required String context,
  }) async {
    try {
      await playback;
    } catch (e, stack) {
      TaliaLogger.e('V2: Failed to $context', e, stack);
      if (_isCurrentAudioRequest(requestId, targetSession)) {
        emit((state as MSActive).copyWith(isPlaying: false, audioFailed: true));
      }
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
    bool clearLastEvaluation = false,
  }) {
    final st = state as MSActive;
    emit(
      st.copyWith(
        sessionState: _sessionState!,
        clearRecognizedText: clearRecognizedText,
        clearSpeechIssue: clearSpeechIssue,
        clearPersistenceIssue: true,
        clearLastEvaluation: clearLastEvaluation,
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

  /// A checkpoint may only resume a request of the same kind. Legacy rows
  /// without a persisted launch context only match memorize requests, and
  /// review requests only match review checkpoints — a stale memorize
  /// session must never swallow a due-review tap.
  bool _isResumableIntent(LearningIntent? saved, bool requestedIsReview) {
    if (requestedIsReview) return saved == LearningIntent.review;
    return saved == null || saved == LearningIntent.memorize;
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
  Future<void> _evaluateCurrentRecitation({
    bool manualGrade = false,
    V2SelfGrade selfGrade = V2SelfGrade.mastered,
    int? stumbledAyahNumber,
  }) async {
    if (_sessionState == null || state is! MSActive) return;
    final spokenText = (state as MSActive).recognizedText;
    final previousState = _sessionState!;

    V2SessionState newState;
    V2RecitationResult? automaticEvidence;
    if (manualGrade) {
      switch (previousState.phase) {
        case V2SessionPhase.reciting:
          newState = _engine.submitManualRecall(
            previousState,
            grade: selfGrade,
          );
        case V2SessionPhase.blockReview:
          newState = _engine.submitManualBlockReview(
            previousState,
            grade: selfGrade,
            stumbledAyahNumber: stumbledAyahNumber,
          );
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
      automaticEvidence = _engine.evaluateBlockReviewAttempt(
        previousState,
        spokenText,
      );
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

    // Capture presentation feedback BEFORE the transition: a successful pass
    // clears the engine's transient result, so the result sheet needs its own
    // snapshot. Purely presentational — never persisted, never re-evaluated.
    final V2EvaluationFeedback? feedback;
    if (newState.lastRecitationResult == previousState.lastRecitationResult &&
        newState.phase == previousState.phase) {
      feedback = null; // no-attempt or ignored phase — nothing to show
    } else if (manualGrade) {
      feedback = null; // manual/self-grade has no similarity evidence to diff
    } else if (automaticEvidence != null && !automaticEvidence.isNoAttempt) {
      // Block review diffs against the joined block text; an individual
      // recitation diffs against the single current ayah.
      final targetText = previousState.phase == V2SessionPhase.blockReview
          ? previousState.blockAyahs.map((a) => a.text).join(' ')
          : previousState.currentAyah.text;
      feedback = V2EvaluationFeedback(
        result: automaticEvidence,
        wordDiff: const RecitationWordDiffer().diff(
          targetText: targetText,
          spokenText: spokenText,
        ),
      );
    } else {
      feedback = null;
    }

    // Never expose a progress transition before its review/checkpoint writes
    // succeed. This keeps the currently displayed state retryable after a
    // local-storage or SRS failure.
    final persisted = await _handlePostEvaluation(
      previousState,
      newState,
      manuallyAssessed: manualGrade,
      selfGrade: selfGrade,
      similarityScore: automaticEvidence?.similarityScore,
    );
    if (!persisted) {
      _restoreAfterPersistenceFailure(previousState);
      return;
    }

    if (newState.phase == V2SessionPhase.completed) {
      // Surface the block-review verdict (score + word diff) before the
      // completion screen takes over — the final gate gets the same
      // feedback moment as every individual ayah. The result sheet stays
      // open above the completion page until the learner acknowledges it.
      _sessionState = newState;
      emit(
        (state as MSActive).copyWith(
          sessionState: newState,
          isEvaluating: false,
          clearSpeechIssue: true,
          clearPersistenceIssue: true,
          lastEvaluation: feedback,
          clearLastEvaluation: feedback == null,
        ),
      );
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
        lastEvaluation: feedback,
        clearLastEvaluation: feedback == null,
      ),
    );
  }

  /// Persists records and handles phase transitions after evaluation.
  Future<bool> _handlePostEvaluation(
    V2SessionState previousState,
    V2SessionState newState, {
    bool manuallyAssessed = false,
    V2SelfGrade selfGrade = V2SelfGrade.mastered,
    double? similarityScore,
  }) async {
    final passedAyah = previousState.currentAyah;
    final newlyPassedAyahs = newState.passedAyahNumbers.difference(
      previousState.passedAyahNumbers,
    );
    final shouldRecordPass =
        previousState.phase == V2SessionPhase.reciting &&
        newlyPassedAyahs.contains(passedAyah.numberInSurah);
    // Includes a self-graded "forgot": it is failure evidence too.
    final isRecitationFailure =
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
            selfGrade: selfGrade,
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
      } else if (isRecitationFailure && _reviewOutcomeCommitter != null) {
        final taskId = previousState.phase == V2SessionPhase.blockReview
            ? 'block-review:${previousState.surahId}'
            : 'ayah:${previousState.surahId}:${passedAyah.numberInSurah}';
        await _reviewOutcomeCommitter.commitFailedAutomaticAttempt(
          previousState: previousState,
          nextState: newState,
          taskId: taskId,
          manuallyAssessed: manuallyAssessed,
          similarityScore: evidenceSimilarity,
        );
        unawaited(_processPendingEffects());
        return true;
      }

      // A terminal state is never checkpointed: resume would discard it and
      // falsely look completed if finalization failed. It is cleared only
      // after all required review writes succeed.
      if (newState.phase != V2SessionPhase.completed) {
        await _saveProgress(newState);
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
          await _progressAdapter.clear(
            finalState.surahId,
            review: finalState.isReview,
          );
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
      await _progressAdapter.clear(
        finalState.surahId,
        review: finalState.isReview,
      );
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
