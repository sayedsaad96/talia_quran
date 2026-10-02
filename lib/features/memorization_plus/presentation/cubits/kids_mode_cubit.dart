import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../../core/constants/speech_constants.dart';
import '../../../../core/memorization/kids_progress_cloud_merge.dart';
import '../../../../core/memorization/v2/hint_usage.dart';
import '../../../../core/memorization/v2/kids_review_outcome_committer.dart';
import '../../../../core/memorization/v2/recitation_evaluator.dart';
import '../../../../core/memorization/v2/session_adapters.dart';
import '../../../../core/memorization/v2/session_engine.dart';
import '../../../../core/memorization/v2/session_phase.dart';
import '../../../../core/memorization/v2/session_state.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/services/activity_event_recorder.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/services/audio_lifecycle_manager.dart';
import '../../../../core/services/streak_service.dart'; // RISK-5 FIX
import '../../../../core/utils/talia_logger.dart';
import '../../../home/domain/entities/activity_event.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/services/kids_daily_budget.dart';
import '../../domain/services/kids_recalled_words.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../features/quran/domain/repositories/quran_repository.dart';

part 'kids_mode_state.dart';

typedef KidsGuardianPinVerifier = Future<bool> Function(String pin);
typedef KidsSessionPolicyLoader = Future<KidsSessionPolicy> Function();

/// K15 — reads the local kids session log for the daily-limit gate.
/// Optional: when unavailable (or throwing) the limit fails open.
typedef KidsSessionLogsLoader = Future<List<KidsSessionLog>?> Function();

class KidsModeCubit extends Cubit<KidsModeState> {
  KidsModeCubit(
    this._getKidsProgress,
    this._getKidsJourney,
    this._awardPoints,
    this._achievementService,
    this._quranRepository,
    this._sessionEngine,
    this._reviewAdapter,
    this._streakService, [
    KidsRecitationRecorder? recitationRecorder,
    AppSessionService? appSessionService,
    KidsGuardianPinVerifier? guardianPinVerifier,
    KidsSessionPolicyLoader? sessionPolicyLoader,
    KidsSessionLogsLoader? kidsSessionLogsLoader,
    V2SessionProgressAdapter? progressAdapter,
    ActivityEventRecorder? activityRecorder,
    KidsReviewOutcomeCommitter? reviewOutcomeCommitter,
  ]) : _activityRecorder = activityRecorder,
       _reviewOutcomeCommitter = reviewOutcomeCommitter,
       _appSessionService = appSessionService,
       _guardianPinVerifier = guardianPinVerifier,
       _sessionPolicyLoader = sessionPolicyLoader,
       _kidsSessionLogsLoader = kidsSessionLogsLoader,
       _progressAdapter = progressAdapter,
       super(const KidsModeInitial()) {
    _recitationRecorder = recitationRecorder ?? KidsSpeechRecitationRecorder();
    AudioLifecycleManager.instance.register(_player);
    _playerSub = _player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        _onPlaybackCompleted();
      }
    });
    // Track buffering state separately so the UI shows a precise loading indicator
    _bufferingSub = _player.processingStateStream.listen((ps) {
      if (state is KidsModeLoaded) {
        final buffering =
            ps == ProcessingState.loading || ps == ProcessingState.buffering;
        emit((state as KidsModeLoaded).copyWith(isBuffering: buffering));
      }
    });
  }

  final GetKidsProgressUsecase _getKidsProgress;
  final GetKidsJourneyUsecase _getKidsJourney;
  final AwardKidsPointsUsecase _awardPoints;
  final AchievementService _achievementService;
  final QuranRepository _quranRepository;
  final V2SessionEngine _sessionEngine;
  final V2SessionReviewAdapter _reviewAdapter;
  final StreakService _streakService;
  final AppSessionService? _appSessionService;
  final KidsGuardianPinVerifier? _guardianPinVerifier;
  final KidsSessionPolicyLoader? _sessionPolicyLoader;
  final KidsSessionLogsLoader? _kidsSessionLogsLoader;
  final V2SessionProgressAdapter? _progressAdapter;
  final ActivityEventRecorder? _activityRecorder;
  final KidsReviewOutcomeCommitter? _reviewOutcomeCommitter;
  late final KidsRecitationRecorder _recitationRecorder;
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _playerSub;
  late final StreamSubscription<ProcessingState> _bufferingSub;

  // Evaluates recognized speech against the ayah text. The kids flow uses a
  // child-voice-tolerant pass threshold (STT is consistently harsher on
  // child voices); the adult path keeps the stricter default.
  final V2RecitationEvaluator _evaluator = const V2RecitationEvaluator(
    passThreshold: kKidsPassThreshold,
  );

  /// Stable id of one kids review task; a retried completion of the same
  /// ayah/mission must reuse it so the committer dedupes.
  static String kidsReviewTaskId(
    int surahId,
    int ayahNumber,
    KidsMissionType type,
  ) => '$surahId:$ayahNumber:${type.name}';

  int _loopCount = 0;
  final Set<String> _completionsInFlight = <String>{};

  /// Listen-before-recite repetitions, resolved from the age-band policy in
  /// [load] instead of a hard-coded constant, so younger children repeat the
  /// audio more (their auditory encoding is still developing) while older
  /// children need fewer conscious listens.
  @visibleForTesting
  int maxLoops = KidsSessionPolicy.forAge(5).maxListenRepetitions;
  DateTime? _sessionStartedAt;
  String? _sessionId;
  KidsMissionType _missionType = KidsMissionType.newMemorization;

  // Recording timer
  Timer? _recordingTimer;
  Completer<KidsRecitationCaptureResult>? _recordingCompleter;

  @visibleForTesting
  void debugSetLoopCount(int count) {
    _loopCount = count;
  }

  Future<void> load(
    int surahId,
    int ayahNumber,
    String ayahText, {
    KidsMissionType missionType = KidsMissionType.newMemorization,
  }) async {
    emit(const KidsModeLoading());

    final journeyResult = await _getKidsJourney(
      GetKidsJourneyParams(surahId: surahId),
    );
    final isUnlocked = journeyResult.fold(
      (_) => false,
      (stages) => stages.any(
        (stage) =>
            stage.isUnlocked &&
            ayahNumber >= stage.startAyah &&
            ayahNumber <= stage.endAyah,
      ),
    );
    if (!isUnlocked) {
      emit(const KidsModeError(CubitMessageCodes.kidsJourneyStageLocked));
      return;
    }

    String resolvedText = ayahText;
    if (resolvedText.isEmpty ||
        resolvedText == '...' ||
        resolvedText == 'النص غير متوفر') {
      try {
        final result = await _quranRepository.getSurahDetail(surahId);
        result.fold((_) {}, (detail) {
          resolvedText = detail.ayahs
              .firstWhere((a) => a.numberInSurah == ayahNumber)
              .text;
        });
      } catch (_) {}
      if (resolvedText.isEmpty ||
          resolvedText == '...' ||
          resolvedText == 'النص غير متوفر') {
        // A session built on a placeholder text can never pass recitation
        // evaluation and would trap the child in an unwinnable mission —
        // refuse to start it instead.
        emit(const KidsModeError(CubitMessageCodes.v2SurahLoadFailed));
        return;
      }
    }

    final progressResult = await _getKidsProgress();
    final progress = progressResult.fold(
      (_) => const KidsProgress.initial(),
      (p) => p,
    );

    final fallbackAyah = Ayah(
      number: ayahNumber,
      surahId: surahId,
      text: resolvedText,
      numberInSurah: ayahNumber,
    );
    var sessionState = missionType == KidsMissionType.resume
        ? await _restoreKidsSession(surahId, fallbackAyah)
        : null;
    final resumed = sessionState != null;
    // A `resume` request without a paused session (e.g. the stage page
    // opening an in-progress stage) is really a first pass or a review of
    // this ayah: resolve its original semantics now so a first pass earns
    // the canonical reward that advances the journey (N1).
    final effectiveMissionType = missionType == KidsMissionType.resume
        ? await _originalMissionTypeForResume(
            surahId,
            sessionState?.currentAyah.numberInSurah ?? ayahNumber,
          )
        : missionType;
    final policy = await _loadSessionPolicy();

    // K15 — daily session-limit gate. Only genuinely new work (new
    // memorization) counts against maxNewAyahs; a restored interrupted
    // session, a due SRS review, or a linked block review must always be
    // reachable regardless of how many sessions ran earlier today.
    if (!resumed && effectiveMissionType == KidsMissionType.newMemorization) {
      final budget = await _loadDailyBudget(policy);
      if (budget.newAyahLimitReached) {
        emit(
          KidsModeError(
            '${CubitMessageCodes.kidsDailySessionLimitPrefix}'
            '${policy.maxNewAyahs}',
          ),
        );
        return;
      }
    }

    // A review measures what stayed from before (K28): it starts in
    // hidden-text recall with no listening first; support comes only after a
    // missed recall or "remind me". New memorization follows the age-band
    // listen gate: a 5–7 year-old repeats the audio three times before
    // recall, an 8–12 year-old twice.
    final isReview = effectiveMissionType != KidsMissionType.newMemorization;
    maxLoops = isReview ? 0 : policy.maxListenRepetitions;
    final initialSession = V2SessionState.initial(
      surahId: surahId,
      blockAyahs: [fallbackAyah],
      // Kids missions are single-ayah blocks: a "block review" would only
      // repeat the recitation the child just passed, and no kids UI drives
      // startBlockReview — requiring it parks the session at
      // blockReviewPending and the celebration never fires.
      blockReviewRequired: false,
    );
    sessionState ??= isReview
        ? _sessionEngine.startReview(initialSession)
        : _sessionEngine.startLearning(initialSession);
    await _saveKidsSession(sessionState);

    final activeAyah = sessionState.currentAyah;
    final startedAt = DateTime.now().toUtc();
    _sessionStartedAt = startedAt;
    _sessionId =
        'kids_${startedAt.microsecondsSinceEpoch}_${surahId}_$ayahNumber';
    // A resumed session must not silently downgrade a fresh memorization to
    // a zero-point "resume" award (H3): restore the original semantics.
    _missionType = effectiveMissionType;

    emit(
      KidsModeLoaded(
        surahId: surahId,
        ayahNumber: activeAyah.numberInSurah,
        ayahText: activeAyah.text,
        sessionState: sessionState,
        progress: progress,
        isPlaying: false,
        currentLoop: 0,
        maxLoops: maxLoops,
        isCompleted: false,
        isReview: isReview,
      ),
    );
  }

  /// K15 — today's budget from the local session log, the same one the
  /// home and completion screens resolve missions with. Any read failure
  /// fails open (limit not enforced) so a storage glitch never locks a child
  /// out of learning.
  Future<KidsDailyBudget> _loadDailyBudget(KidsSessionPolicy policy) async {
    try {
      final logs = await _kidsSessionLogsLoader?.call();
      if (logs == null) return KidsDailyBudget.unlimited;
      return KidsDailyBudget.fromLogs(
        logs: logs,
        policy: policy,
        now: DateTime.now(),
      );
    } catch (_) {
      return KidsDailyBudget.unlimited;
    }
  }

  Future<KidsSessionPolicy> _loadSessionPolicy() async {
    try {
      return await _sessionPolicyLoader?.call() ?? KidsSessionPolicy.forAge(8);
    } catch (_) {
      return KidsSessionPolicy.forAge(8);
    }
  }

  /// Restores the award semantics of the mission the child originally
  /// started before the interruption (H3).
  ///
  /// The first pass of any kids ayah is always recorded as a canonical
  /// new-memorization log, so the presence of such a log means the ayah was
  /// already rewarded and the resumed run behaves like a review (zero
  /// points). Without it the child still earns the full reward they were
  /// interrupted away from. The award service's canonical-log idempotency
  /// makes a failed log read fail-open (full reward) and never double-award.
  Future<KidsMissionType> _originalMissionTypeForResume(
    int surahId,
    int ayahNumber,
  ) async {
    try {
      final logs = await _kidsSessionLogsLoader?.call();
      if (logs == null) return KidsMissionType.newMemorization;
      final alreadyRewarded = logs.any(
        (log) =>
            log.surahId == surahId &&
            log.ayahNumber == ayahNumber &&
            KidsSessionLogsCloudMerge.isCanonicalRewardLog(log),
      );
      return alreadyRewarded
          ? KidsMissionType.resume
          : KidsMissionType.newMemorization;
    } catch (_) {
      return KidsMissionType.newMemorization;
    }
  }

  Future<V2SessionState?> _restoreKidsSession(
    int surahId,
    Ayah fallbackAyah,
  ) async {
    final adapter = _progressAdapter;
    if (adapter == null) return null;
    try {
      final saved = (await adapter.loadIfExists(
        surahId,
      )).fold(() => null, (session) => session);
      if (saved == null) return null;
      final phaseIndex = saved.phaseIndex;
      if (phaseIndex < 0 || phaseIndex >= V2SessionPhase.values.length) {
        await adapter.clear(surahId);
        return null;
      }
      final phase = V2SessionPhase.values[phaseIndex];
      if (phase == V2SessionPhase.created || phase.isTerminal) {
        await adapter.clear(surahId);
        return null;
      }
      if (saved.blockAyahNumbers.isEmpty) {
        await adapter.clear(surahId);
        return null;
      }

      var allAyahs = <Ayah>[fallbackAyah];
      final surahResult = await _quranRepository.getSurahDetail(surahId);
      surahResult.fold((_) {}, (detail) => allAyahs = detail.ayahs);
      final availableNumbers = allAyahs
          .map((ayah) => ayah.numberInSurah)
          .toSet();
      if (!saved.blockAyahNumbers.every(availableNumbers.contains)) return null;
      final restored = V2SessionProgressAdapter.restore(saved, allAyahs);
      // Sessions persisted before the kids single-ayah completion fix can be
      // parked at blockReviewPending with the ayah already passed and
      // rewarded. Kids blocks are single-ayah, so promote such resumes to
      // the terminal phase instead of dead-ending the child again.
      if (restored.phase == V2SessionPhase.blockReviewPending) {
        return restored.copyWith(phase: V2SessionPhase.completed);
      }
      return restored;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveKidsSession(V2SessionState session) async {
    try {
      await _progressAdapter?.save(session);
    } catch (_) {
      // Resume is best-effort and must never block the child's active mission.
    }
  }

  Future<void> _clearKidsSession(int surahId) async {
    try {
      await _progressAdapter?.clear(surahId);
    } catch (_) {
      // Completion remains valid even when local resume cleanup fails.
    }
  }

  Future<void> playAudio() async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;
    // Playing during hidden-text recitation would give the answer away
    // (Product Rules, Phase 3); "remind me" is the honest way back (K28).
    if (st.sessionState.phase.textHidden) return;

    // An optional replay after the mandatory listen gate has opened must not
    // re-close the microphone or regress the loop progress dots (M1); only a
    // replay before completing the required listens restarts the sequence.
    if (_loopCount < maxLoops) {
      _loopCount = 0;
    }
    emit(
      st.copyWith(
        isPlaying: true,
        isBuffering: true,
        currentLoop: _loopCount < maxLoops ? 1 : maxLoops,
        clearAudioError: true,
      ),
    );
    await _playAyah(st.surahId, st.ayahNumber);
  }

  Future<void> _playAyah(int surahId, int ayahNumber) async {
    try {
      // Cache-first playback lets optional child-requested replays reuse the
      // same source without creating an automatic playback loop.
      final source = await AudioCacheService.instance.getAudioSource(
        surahId,
        ayahNumber,
      );
      await AudioCacheService.playFromSource(_player, source);
    } catch (_) {
      if (state is KidsModeLoaded) {
        emit(
          (state as KidsModeLoaded).copyWith(
            isPlaying: false,
            audioError: CubitMessageCodes.kidsAudioPlaybackFailed,
          ),
        );
      }
    }
  }

  void _onPlaybackCompleted() {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;

    _loopCount++;
    if (_loopCount < maxLoops) {
      emit(st.copyWith(currentLoop: _loopCount + 1, clearAudioError: true));
      _playAyah(st.surahId, st.ayahNumber);
    } else {
      emit(
        st.copyWith(
          isPlaying: false,
          currentLoop: maxLoops,
          clearAudioError: true,
        ),
      );
    }
  }

  Future<void> stopAudio() async {
    await _player.stop();
    if (state is KidsModeLoaded) {
      emit(
        (state as KidsModeLoaded).copyWith(
          isPlaying: false,
          isBuffering: false,
        ),
      );
    }
  }

  /// Hides the ayah so the child recalls it before reciting ("try from
  /// memory"). Hints are offered only in this phase (Product Rules §5), and
  /// a missed recitation returns here for another attempt (§14.8, K25).
  Future<void> tryFromMemory() async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;
    if (st.isCompleted || st.isRecording) return;
    if (_loopCount < maxLoops) {
      _flagListenFirst(st);
      return;
    }
    if (st.isPlaying) await stopAudio();
    if (isClosed || state is! KidsModeLoaded) return;
    final current = state as KidsModeLoaded;
    final session = switch (current.sessionState.phase) {
      V2SessionPhase.learning => _sessionEngine.startMemorizing(
        current.sessionState,
      ),
      V2SessionPhase.remediation => _sessionEngine.completeRemediation(
        current.sessionState,
      ),
      _ => null,
    };
    if (session == null) return;
    emit(current.copyWith(sessionState: session));
    await _saveKidsSession(session);
  }

  /// "Remind me": the child cannot recall the hidden ayah, so the text and
  /// audio come back as support. Recorded as a missed recall, so the rating
  /// and the next review stay honest (K28).
  Future<void> remindMe() async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;
    if (!st.isAwaitingRecitation) return;
    final session = _sessionEngine.requestReminder(st.sessionState);
    emit(
      st.copyWith(
        sessionState: session,
        clearRecordingError: true,
        lastMatchedWords: 0,
        lastTargetWords: 0,
      ),
    );
    await _saveKidsSession(session);
  }

  /// "Give me the start": reveals the ayah's first word while the child is
  /// recalling. Recorded once as a first-word hint, so a later pass rates
  /// average instead of excellent — honest evidence for the review schedule.
  Future<void> revealFirstWord() async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;
    if (!st.isRecallingFromMemory || st.firstWordRevealed) return;
    final session = _sessionEngine.useHint(
      st.sessionState,
      V2HintLevel.firstWord,
    );
    emit(st.copyWith(sessionState: session));
    await _saveKidsSession(session);
  }

  /// Shows the "listen first" warning briefly.
  void _flagListenFirst(KidsModeLoaded st) {
    emit(st.copyWith(mustListenFirst: true));
    Future.delayed(const Duration(seconds: 2), () {
      if (isClosed || state is! KidsModeLoaded) return;
      emit((state as KidsModeLoaded).copyWith(mustListenFirst: false));
    });
  }

  /// Records the child's recitation and evaluates it against the ayah text,
  /// using the shared ordered V2 evaluator and its explicit verdict bands.
  Future<void> startRecording() async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;
    if (st.isCompleted) return;

    if (_loopCount < maxLoops) {
      _flagListenFirst(st);
      return;
    }

    if (st.isPlaying) {
      await stopAudio();
    }

    // Move the shared engine into its hidden-text recall phase before opening
    // the microphone, so every unsuccessful attempt is tracked consistently.
    var recitingSession = st.sessionState;
    if (recitingSession.phase == V2SessionPhase.learning) {
      recitingSession = _sessionEngine.startMemorizing(recitingSession);
    }
    if (recitingSession.phase == V2SessionPhase.memorizing ||
        recitingSession.phase == V2SessionPhase.remediation) {
      recitingSession = _sessionEngine.startReciting(recitingSession);
    }

    // Prepare the completer so stopRecording() can signal early stop.
    _recordingCompleter = Completer<KidsRecitationCaptureResult>();

    emit(
      st.copyWith(
        sessionState: recitingSession,
        isRecording: true,
        recordingSeconds: 0,
        clearRecordingError: true,
        // Fresh attempt: stale word feedback from the previous try must not
        // linger on the screen.
        lastMatchedWords: 0,
        lastTargetWords: 0,
        clearRecalledWords: true,
      ),
    );
    await _saveKidsSession(recitingSession);

    // Per-second timer drives the recording duration indicator in the UI.
    var elapsedSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds++;
      if (state is KidsModeLoaded && (state as KidsModeLoaded).isRecording) {
        emit(
          (state as KidsModeLoaded).copyWith(recordingSeconds: elapsedSeconds),
        );
      }
    });

    final capture = await _recitationRecorder.capture(
      externalCompleter: _recordingCompleter,
    );

    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingCompleter = null;

    if (isClosed || state is! KidsModeLoaded) return;
    final current = state as KidsModeLoaded;

    // The guardian may have completed the session manually while the mic was
    // still open (M7); a finished session must never evaluate a late capture
    // or surface a confusing post-completion error.
    if (current.isCompleted) return;

    // ── Error cases (permission denied, mic unavailable) ──────────────────
    if (capture.isError) {
      emit(
        current.copyWith(
          isRecording: false,
          recordingSeconds: 0,
          recordingError: capture.messageCode,
        ),
      );
      return;
    }

    // ── Evaluate spoken words against the ayah text ───────────────────────
    final evalResult = _evaluator.evaluate(
      targetText: current.ayahText,
      spokenText: capture.recognizedWords,
    );

    if (evalResult.isNoAttempt) {
      // STT returned empty — mic was open but no words detected.
      emit(
        current.copyWith(
          isRecording: false,
          recordingSeconds: 0,
          recordingError: CubitMessageCodes.kidsRecordingNotCaptured,
          lastMatchedWords: 0,
          lastTargetWords: 0,
          silentAttempts: current.silentAttempts + 1,
        ),
      );
      return;
    }

    if (!evalResult.passed) {
      // Preserve the ordered verdict and escalate repeated failures in V2.
      final evaluatedSession = _sessionEngine.evaluateRecitation(
        current.sessionState,
        capture.recognizedWords,
      );
      // W2: carry the child-friendly word-level progress ("X of Y words")
      // alongside the generic mismatch so the UI can show how close the
      // recitation was instead of a bare failure.
      emit(
        current.copyWith(
          sessionState: evaluatedSession,
          isRecording: false,
          recordingSeconds: 0,
          recordingError: CubitMessageCodes.kidsRecitationMismatch,
          lastMatchedWords: evalResult.matchedWordCount,
          lastTargetWords: evalResult.targetWordCount,
          silentAttempts: 0,
          // K32: which ayah words were right — flags only, in memory.
          recalledWords: kidsRecalledWords(
            targetText: current.ayahText,
            spokenText: capture.recognizedWords,
          ),
        ),
      );
      await _saveKidsSession(evaluatedSession);
      return;
    }

    // ── Match confirmed — mark as complete ────────────────────────────────
    emit(
      current.copyWith(
        isRecording: false,
        recordingSeconds: 0,
        clearRecordingError: true,
        lastMatchedWords: 0,
        lastTargetWords: 0,
        clearRecalledWords: true,
      ),
    );

    await markCompleted(
      automaticSpokenText: capture.recognizedWords,
      automaticSimilarity: evalResult.similarityScore,
    );
  }

  /// Stops an in-progress recording manually (user pressed "Done").
  ///
  /// Signals the recorder to stop and flush whatever words were captured so
  /// far. Actual pass/fail is decided by [V2RecitationEvaluator] in
  /// [startRecording] — this method only triggers the early stop.
  Future<void> stopRecording() async {
    if (state is! KidsModeLoaded) return;
    if (!(state as KidsModeLoaded).isRecording) return;
    final recordingCompleter = _recordingCompleter;
    if (recordingCompleter == null || recordingCompleter.isCompleted) return;

    // Tell the recorder to stop listening and return whatever it has.
    await _recitationRecorder.stop();
    // Signal the completer with whatever words were recognized so far;
    // the evaluator in startRecording() will decide pass/fail.
    if (!recordingCompleter.isCompleted) {
      recordingCompleter.complete(
        const KidsRecitationCaptureResult.stoppedByUser(),
      );
    }
  }

  /// Guardian-verified fallback for genuine audio or speech-recognition faults.
  /// A recitation mismatch is pedagogical evidence and can never use this path.
  Future<bool> submitManualCompletion({String? guardianPin}) async {
    if (state is! KidsModeLoaded) return false;
    final st = state as KidsModeLoaded;
    if (st.isCompleted || !st.canUseGuardianFallback) return false;

    final verifier = _guardianPinVerifier;
    if (verifier == null || guardianPin == null || guardianPin.length != 4) {
      return false;
    }
    if (!await verifier(guardianPin)) return false;

    if (st.isRecording) {
      await _recitationRecorder.stop();
      _recordingTimer?.cancel();
      _recordingTimer = null;
      final pendingCapture = _recordingCompleter;
      _recordingCompleter = null;
      // Unblock the pending startRecording() await instead of letting it hang
      // until the STT timeout after the session has already completed (M7).
      if (pendingCapture != null && !pendingCapture.isCompleted) {
        pendingCapture.complete(
          const KidsRecitationCaptureResult.stoppedByUser(),
        );
      }
      emit(st.copyWith(isRecording: false, recordingSeconds: 0));
    }
    await markCompleted(manualGrade: true);
    return state is KidsModeLoaded && (state as KidsModeLoaded).isCompleted;
  }

  Future<void> markCompleted({
    bool manualGrade = false,
    String? automaticSpokenText,
    double? automaticSimilarity,
  }) async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;
    if (st.isCompleted) return;

    // Automatic completion is only valid when STT supplied actual words.
    // Reject invalid public calls before awards, reviews, streak, or XP.
    if (!manualGrade &&
        (automaticSpokenText == null || automaticSpokenText.trim().isEmpty)) {
      emit(
        st.copyWith(recordingError: CubitMessageCodes.kidsRecordingNotCaptured),
      );
      return;
    }

    // BUG-4 FIX: prevent completing without listening the required times.
    // The manual/self-grade route (V1-M8) bypasses this gate so a first-use
    // offline journey can still complete safely.
    if (!manualGrade && _loopCount < maxLoops) {
      // Emit a warning state so the UI can show a message
      emit(st.copyWith(mustListenFirst: true));
      // Clear the flag after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (isClosed || state is! KidsModeLoaded) return;
        emit((state as KidsModeLoaded).copyWith(mustListenFirst: false));
      });
      return;
    }

    final completionKey = '${st.surahId}_${st.ayahNumber}';
    if (_completionsInFlight.contains(completionKey)) return;
    _completionsInFlight.add(completionKey);

    try {
      final failureCount = st.sessionState.failureTracker.failureCountFor(
        st.surahId,
        st.ayahNumber,
      );
      final trackedHint = st.sessionState.hintTracker.levelFor(
        st.surahId,
        st.ayahNumber,
      );
      final effectiveHint = manualGrade ? V2HintLevel.fullAyah : trackedHint;
      final masteryRating = _masteryRatingFor(
        failureCount: failureCount,
        hintLevel: effectiveHint,
        // K31: STT tolerance (kKidsPassThreshold) lets a near match pass,
        // but only an exact recitation is evidence of excellent mastery.
        exactRecitation: manualGrade || (automaticSimilarity ?? 1.0) >= 1.0,
      );
      final startedAt = _sessionStartedAt ?? DateTime.now().toUtc();
      final durationSeconds = max(
        0,
        DateTime.now().toUtc().difference(startedAt).inSeconds,
      );

      // The review record is the source of truth for memorization progress.
      // Do not grant points or complete the session until it is durably saved;
      // otherwise a storage failure can reward progress that cannot be reviewed.
      String? awardSessionId = _sessionId;
      final committer = _reviewOutcomeCommitter;
      if (committer != null) {
        // Idempotent commit: a retry after an award failure reuses the stored
        // session id, so neither the SRS schedule nor the award repeats.
        try {
          final commit = await committer.commitPass(
            sessionState: st.sessionState,
            taskId: kidsReviewTaskId(st.surahId, st.ayahNumber, _missionType),
            rating: masteryRating,
            manuallyAssessed: manualGrade,
            similarityScore: automaticSimilarity,
          );
          awardSessionId =
              'kids_${commit.sessionId}_${st.surahId}_${st.ayahNumber}';
        } catch (error, stack) {
          TaliaLogger.w('Kids review commit failed', error, stack);
          emit(
            st.copyWith(recordingError: CubitMessageCodes.hifzReviewSaveFailed),
          );
          return;
        }
      } else {
        final reviewResult = await _reviewAdapter.recordPass(
          surahId: st.surahId,
          ayahNumber: st.ayahNumber,
          hintLevel: effectiveHint,
          createdByMode: ReviewRecordCreatedByMode.kidsMode,
          // One mastery measure for both SRS and the reward log (N4).
          rating: masteryRating,
        );
        final reviewFailure = reviewResult.fold(
          (failure) => failure,
          (_) => null,
        );
        if (reviewFailure != null) {
          emit(
            st.copyWith(recordingError: CubitMessageCodes.hifzReviewSaveFailed),
          );
          return;
        }
      }

      final result = await _awardPoints(
        AwardKidsPointsParams(
          completionAuthorized: true,
          sessionId: awardSessionId,
          surahId: st.surahId,
          ayahNumber: st.ayahNumber,
          repeatsCompleted: _loopCount,
          missionType: _missionType,
          ayahNumbers: [st.ayahNumber],
          durationSeconds: durationSeconds,
          attemptCount: failureCount + 1,
          hintCount: effectiveHint == V2HintLevel.none ? 0 : 1,
          masteryRating: masteryRating,
        ),
      );

      final completion = result.fold<KidsCompletionResult?>((f) {
        emit(KidsModeError(f.message));
        return null;
      }, (completion) => completion);
      if (completion == null) return;

      if (completion.alreadyCompleted) {
        final completedSession = _completeV2Session(
          st.sessionState,
          manualGrade: manualGrade,
          automaticSpokenText: automaticSpokenText,
        );
        await _recordSessionActivity();
        await _clearKidsSession(st.surahId);
        await _appSessionService?.clearLastRestorableLocation();
        emit(
          st.copyWith(
            progress: completion.progress,
            isCompleted: _sessionReachedCompletion(completedSession),
            sessionState: completedSession,
            // Completion always settles the mic flag — even when the session
            // finished while a capture was still in flight.
            isRecording: false,
            sessionStarsEarned: 0,
            clearRecordingError: true,
          ),
        );
        return;
      }

      final completedSession = _completeV2Session(
        st.sessionState,
        manualGrade: manualGrade,
        automaticSpokenText: automaticSpokenText,
      );

      await _recordSessionActivity(
        surahId: st.surahId,
        ayahNumber: st.ayahNumber,
      );
      await _clearKidsSession(st.surahId);

      final newAwards = await _achievementService.checkAndUnlockCertificates(
        isKids: true,
      );
      await _appSessionService?.clearLastRestorableLocation();
      emit(
        st.copyWith(
          progress: completion.progress,
          // K16: only a terminal V2 session completes the kids screen. A
          // blockReviewPending session awaits the linked review instead.
          isCompleted: _sessionReachedCompletion(completedSession),
          sessionState: completedSession,
          // Completion always settles the mic flag — even when the session
          // finished while a capture was still in flight.
          isRecording: false,
          newAwards: newAwards,
          sessionStarsEarned: completion.starsEarned,
          // K11: surface session points and any level-up on completion.
          sessionPointsEarned: completion.pointsEarned,
          leveledUpTo:
              completion.progress.currentLevel > st.progress.currentLevel
              ? completion.progress.currentLevel
              : null,
          // An earlier mic/recitation error must not outlive completion: the
          // page would keep showing it instead of opening the completion.
          clearRecordingError: true,
        ),
      );
    } finally {
      _completionsInFlight.remove(completionKey);
    }
  }

  PerformanceRating _masteryRatingFor({
    required int failureCount,
    required V2HintLevel hintLevel,
    bool exactRecitation = true,
  }) {
    if (hintLevel == V2HintLevel.fullAyah || failureCount >= 2) {
      return PerformanceRating.weak;
    }
    if (hintLevel == V2HintLevel.firstWord ||
        failureCount == 1 ||
        !exactRecitation) {
      return PerformanceRating.average;
    }
    return PerformanceRating.excellent;
  }

  Future<void> _recordSessionActivity({int? surahId, int? ayahNumber}) async {
    try {
      await _streakService.recordActivity(activityDelta: 1);
    } catch (_) {
      // Session completion remains valid when the streak service is unavailable.
    }
    if (surahId == null || ayahNumber == null) return;
    try {
      final now = DateTime.now();
      await _activityRecorder?.record(
        ActivityEvent(
          occurredAt: now,
          kind: ActivityEventKind.memorize,
          idempotencyKey:
              'memorize|kids|${ActivityEventRecorder.dayKey(now)}|$surahId:$ayahNumber',
          surahId: surahId,
          startAyah: ayahNumber,
          endAyah: ayahNumber,
        ),
      );
    } catch (_) {
      // The activity feed is supplementary to session persistence.
    }
  }

  V2SessionState _completeV2Session(
    V2SessionState session, {
    required bool manualGrade,
    String? automaticSpokenText,
  }) {
    var current = session;
    if (current.phase == V2SessionPhase.learning) {
      current = _sessionEngine.startMemorizing(current);
    }
    if (current.phase == V2SessionPhase.memorizing ||
        current.phase == V2SessionPhase.remediation) {
      current = _sessionEngine.startReciting(current);
    }
    if (current.phase == V2SessionPhase.reciting) {
      return manualGrade
          ? _sessionEngine.submitManualRecall(current)
          : _sessionEngine.evaluateRecitation(
              current,
              automaticSpokenText ?? '',
            );
    }
    return current;
  }

  /// The completion screen (stars, next-mission navigation) only fires when
  /// the V2 session actually reached its terminal phase. Kids sessions never
  /// require a block review (single-ayah blocks), so a passing recitation
  /// reaches [V2SessionPhase.completed] directly.
  bool _sessionReachedCompletion(V2SessionState session) =>
      session.phase == V2SessionPhase.completed;

  @override
  Future<void> close() async {
    final current = state;
    if (current is KidsModeLoaded && !current.isCompleted) {
      await _saveKidsSession(current.sessionState);
    }
    AudioLifecycleManager.instance.unregister(_player);
    _recordingTimer?.cancel();
    await _player.stop();
    await _playerSub.cancel();
    await _bufferingSub.cancel();
    await _player.dispose();
    await _recitationRecorder.dispose();
    return super.close();
  }
}

@visibleForTesting
abstract class KidsRecitationRecorder {
  Future<KidsRecitationCaptureResult> capture({
    Completer<KidsRecitationCaptureResult>? externalCompleter,
  });

  /// Stops an active recording session (if any).
  Future<void> stop() async {}

  Future<void> dispose() async {}
}

@visibleForTesting
class KidsRecitationCaptureResult {
  const KidsRecitationCaptureResult._({
    required this.recognizedWords,
    required this.isError,
    this.messageCode,
  });

  /// STT auto-finalized with recognized words.
  const KidsRecitationCaptureResult.captured({required String words})
    : this._(recognizedWords: words, isError: false);

  /// User pressed "Done" — carry whatever words were recognized so far
  /// and let [V2RecitationEvaluator] decide pass/fail.
  const KidsRecitationCaptureResult.stoppedByUser()
    : this._(recognizedWords: '', isError: false);

  const KidsRecitationCaptureResult.permissionDenied()
    : this._(
        recognizedWords: '',
        isError: true,
        messageCode: CubitMessageCodes.kidsMicPermissionDenied,
      );

  const KidsRecitationCaptureResult.unavailable()
    : this._(
        recognizedWords: '',
        isError: true,
        messageCode: CubitMessageCodes.kidsRecordingUnavailable,
      );

  /// The words recognized by STT (may be empty if nothing was spoken).
  final String recognizedWords;

  /// True only for hard errors (permission denied, mic unavailable).
  /// False for normal captures — even if [recognizedWords] is empty.
  final bool isError;

  final String? messageCode;
}

class KidsSpeechRecitationRecorder implements KidsRecitationRecorder {
  KidsSpeechRecitationRecorder({
    SpeechToText? speechToText,
    @visibleForTesting Future<bool> Function()? microphonePermission,
  }) : _speechToText = speechToText ?? SpeechToText(),
       _microphonePermission = microphonePermission;

  final SpeechToText _speechToText;
  final Future<bool> Function()? _microphonePermission;
  bool _speechEnabled = false;
  void Function(SpeechRecognitionError error)? _onSpeechError;

  // Tracks the latest words during an active session so stop() can flush them.
  String _latestRecognizedWords = '';

  @override
  Future<KidsRecitationCaptureResult> capture({
    Completer<KidsRecitationCaptureResult>? externalCompleter,
  }) async {
    _latestRecognizedWords = '';

    final permission = await _ensureMicrophonePermission();
    if (!permission) {
      _completeIfOpen(
        externalCompleter,
        const KidsRecitationCaptureResult.permissionDenied(),
      );
      return const KidsRecitationCaptureResult.permissionDenied();
    }

    if (!_speechEnabled) {
      _speechEnabled = await _initializeSpeech();
    }
    if (!_speechEnabled) {
      _completeIfOpen(
        externalCompleter,
        const KidsRecitationCaptureResult.unavailable(),
      );
      return const KidsRecitationCaptureResult.unavailable();
    }

    final internalCompleter = Completer<KidsRecitationCaptureResult>();

    void completeInternal(KidsRecitationCaptureResult result) {
      if (!internalCompleter.isCompleted) internalCompleter.complete(result);
    }

    _onSpeechError = (error) {
      // Silence ends the listen with an error on Android. It is a quiet
      // child, not a broken microphone: evaluate whatever was heard, and an
      // empty capture becomes "we did not hear you" (K21).
      final result = _isSilence(error)
          ? KidsRecitationCaptureResult.captured(words: _latestRecognizedWords)
          : const KidsRecitationCaptureResult.unavailable();
      completeInternal(result);
      _completeIfOpen(externalCompleter, result);
    };

    try {
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _latestRecognizedWords = result.recognizedWords.trim();
          // Only auto-complete on a *final* result so interim updates don't
          // close the session prematurely.
          if (result.finalResult) {
            completeInternal(
              KidsRecitationCaptureResult.captured(
                words: _latestRecognizedWords,
              ),
            );
          }
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          localeId: kArabicSpeechLocaleId,
        ),
      );
    } catch (_) {
      _completeIfOpen(
        externalCompleter,
        const KidsRecitationCaptureResult.unavailable(),
      );
      return const KidsRecitationCaptureResult.unavailable();
    }

    // Race: STT auto-finalizes OR user presses "Done" (externalCompleter).
    // On timeout, return whatever words were collected so far.
    final result =
        await Future.any([
          internalCompleter.future,
          if (externalCompleter != null) externalCompleter.future,
        ]).timeout(
          const Duration(seconds: 35),
          onTimeout: () async {
            await _speechToText.stop();
            return KidsRecitationCaptureResult.captured(
              words: _latestRecognizedWords,
            );
          },
        );

    // Always patch in the latest recognized words so the evaluator in
    // startRecording() has the most up-to-date text, regardless of which
    // completer fired (STT auto-final, user Done, or timeout).
    try {
      if (!result.isError) {
        return KidsRecitationCaptureResult.captured(
          words: _latestRecognizedWords,
        );
      }
      return result;
    } finally {
      _onSpeechError = null;
    }
  }

  @override
  Future<void> stop() => _speechToText.stop();

  void _completeIfOpen(
    Completer<KidsRecitationCaptureResult>? completer,
    KidsRecitationCaptureResult result,
  ) {
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  /// No recognizable speech — the same split as the adult session's
  /// speech-issue classification.
  static bool _isSilence(SpeechRecognitionError error) =>
      error.errorMsg == 'error_no_match' ||
      error.errorMsg == 'error_speech_timeout';

  Future<bool> _ensureMicrophonePermission() async {
    final override = _microphonePermission;
    if (override != null) return override();
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  Future<bool> _initializeSpeech() async {
    try {
      return await _speechToText.initialize(
        onError: (SpeechRecognitionError error) {
          _onSpeechError?.call(error);
        },
        onStatus: (status) {},
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> dispose() => _speechToText.cancel();
}
