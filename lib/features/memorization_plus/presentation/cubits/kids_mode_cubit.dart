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
import '../../../../core/memorization/v2/hint_usage.dart';
import '../../../../core/memorization/v2/recitation_evaluator.dart';
import '../../../../core/memorization/v2/session_adapters.dart';
import '../../../../core/memorization/v2/session_engine.dart';
import '../../../../core/memorization/v2/session_phase.dart';
import '../../../../core/memorization/v2/session_state.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/services/audio_lifecycle_manager.dart';
import '../../../../core/services/streak_service.dart'; // RISK-5 FIX
import '../../../quran/domain/entities/quran_entities.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../features/quran/domain/repositories/quran_repository.dart';

part 'kids_mode_state.dart';

typedef KidsGuardianPinVerifier = Future<bool> Function(String pin);
typedef KidsSessionPolicyLoader = Future<KidsSessionPolicy> Function();

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
    V2SessionProgressAdapter? progressAdapter,
  ]) : _appSessionService = appSessionService,
       _guardianPinVerifier = guardianPinVerifier,
       _sessionPolicyLoader = sessionPolicyLoader,
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
  final V2SessionProgressAdapter? _progressAdapter;
  late final KidsRecitationRecorder _recitationRecorder;
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _playerSub;
  late final StreamSubscription<ProcessingState> _bufferingSub;

  // Evaluates recognized speech against the ayah text — same logic as adult path.
  final V2RecitationEvaluator _evaluator = const V2RecitationEvaluator();

  int _loopCount = 0;
  final Set<String> _completionsInFlight = <String>{};
  static const int _maxLoops = 1;
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
      if (resolvedText.isEmpty || resolvedText == '...') {
        resolvedText = 'النص غير متوفر';
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
    if (sessionState == null) {
      final policy = await _loadSessionPolicy();
      sessionState = _sessionEngine.startLearning(
        V2SessionState.initial(
          surahId: surahId,
          blockAyahs: [fallbackAyah],
          blockReviewRequired: policy.blockReviewRequired,
        ),
      );
    }
    await _saveKidsSession(sessionState);

    final activeAyah = sessionState.currentAyah;
    final startedAt = DateTime.now().toUtc();
    _sessionStartedAt = startedAt;
    _sessionId =
        'kids_${startedAt.microsecondsSinceEpoch}_${surahId}_$ayahNumber';
    _missionType = resumed ? KidsMissionType.resume : missionType;

    emit(
      KidsModeLoaded(
        surahId: surahId,
        ayahNumber: activeAyah.numberInSurah,
        ayahText: activeAyah.text,
        sessionState: sessionState,
        progress: progress,
        isPlaying: false,
        currentLoop: 0,
        maxLoops: _maxLoops,
        isCompleted: false,
      ),
    );
  }

  Future<KidsSessionPolicy> _loadSessionPolicy() async {
    try {
      return await _sessionPolicyLoader?.call() ?? KidsSessionPolicy.forAge(8);
    } catch (_) {
      return KidsSessionPolicy.forAge(8);
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
      return V2SessionProgressAdapter.restore(saved, allAyahs);
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

    _loopCount = 0;
    emit(
      st.copyWith(
        isPlaying: true,
        isBuffering: true,
        currentLoop: 1,
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
    if (_loopCount < _maxLoops) {
      emit(st.copyWith(currentLoop: _loopCount + 1, clearAudioError: true));
      _playAyah(st.surahId, st.ayahNumber);
    } else {
      emit(
        st.copyWith(
          isPlaying: false,
          currentLoop: _maxLoops,
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

  /// Records the child's recitation and evaluates it against the ayah text,
  /// using the shared ordered V2 evaluator and its explicit verdict bands.
  Future<void> startRecording() async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;
    if (st.isCompleted) return;

    if (_loopCount < _maxLoops) {
      emit(st.copyWith(mustListenFirst: true));
      Future.delayed(const Duration(seconds: 2), () {
        if (isClosed || state is! KidsModeLoaded) return;
        emit((state as KidsModeLoaded).copyWith(mustListenFirst: false));
      });
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
      emit(
        current.copyWith(
          sessionState: evaluatedSession,
          isRecording: false,
          recordingSeconds: 0,
          recordingError: CubitMessageCodes.kidsRecitationMismatch,
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
      ),
    );

    await markCompleted(automaticSpokenText: capture.recognizedWords);
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
      _recordingCompleter = null;
      emit(st.copyWith(isRecording: false, recordingSeconds: 0));
    }
    await markCompleted(manualGrade: true);
    return state is KidsModeLoaded && (state as KidsModeLoaded).isCompleted;
  }

  Future<void> markCompleted({
    bool manualGrade = false,
    String? automaticSpokenText,
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
    if (!manualGrade && _loopCount < _maxLoops) {
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
      );
      final startedAt = _sessionStartedAt ?? DateTime.now().toUtc();
      final durationSeconds = max(
        0,
        DateTime.now().toUtc().difference(startedAt).inSeconds,
      );
      final result = await _awardPoints(
        AwardKidsPointsParams(
          sessionId: _sessionId,
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
        final reviewResult = await _reviewAdapter.recordPass(
          surahId: st.surahId,
          ayahNumber: st.ayahNumber,
          hintLevel: effectiveHint,
          createdByMode: ReviewRecordCreatedByMode.kidsMode,
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
            isCompleted: true,
            sessionState: completedSession,
            sessionStarsEarned: 0,
            clearRecordingError: true,
          ),
        );
        return;
      }

      final reviewResult = await _reviewAdapter.recordPass(
        surahId: st.surahId,
        ayahNumber: st.ayahNumber,
        hintLevel: effectiveHint,
        createdByMode: ReviewRecordCreatedByMode.kidsMode,
      );
      final reviewFailure = reviewResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (reviewFailure != null) {
        await _clearKidsSession(st.surahId);
        emit(
          st.copyWith(
            progress: completion.progress,
            isCompleted: true,
            sessionStarsEarned: completion.starsEarned,
            recordingError: CubitMessageCodes.hifzReviewSaveFailed,
          ),
        );
        return;
      }

      final completedSession = _completeV2Session(
        st.sessionState,
        manualGrade: manualGrade,
        automaticSpokenText: automaticSpokenText,
      );

      await _recordSessionActivity();
      await _clearKidsSession(st.surahId);

      final newAwards = await _achievementService.checkAndUnlockCertificates(
        isKids: true,
      );
      await _appSessionService?.clearLastRestorableLocation();
      emit(
        st.copyWith(
          progress: completion.progress,
          isCompleted: true,
          sessionState: completedSession,
          newAwards: newAwards,
          sessionStarsEarned: completion.starsEarned,
        ),
      );
    } finally {
      _completionsInFlight.remove(completionKey);
    }
  }

  PerformanceRating _masteryRatingFor({
    required int failureCount,
    required V2HintLevel hintLevel,
  }) {
    if (hintLevel == V2HintLevel.fullAyah || failureCount >= 2) {
      return PerformanceRating.weak;
    }
    if (hintLevel == V2HintLevel.firstWord || failureCount == 1) {
      return PerformanceRating.average;
    }
    return PerformanceRating.excellent;
  }

  Future<void> _recordSessionActivity() async {
    try {
      await _streakService.recordActivity(activityDelta: 1);
    } catch (_) {
      // Session completion remains valid when the streak service is unavailable.
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
  KidsSpeechRecitationRecorder({SpeechToText? speechToText})
    : _speechToText = speechToText ?? SpeechToText();

  final SpeechToText _speechToText;
  bool _speechEnabled = false;
  void Function(KidsRecitationCaptureResult result)? _onCaptureFailure;

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

    _onCaptureFailure = (result) {
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
      _onCaptureFailure = null;
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

  Future<bool> _ensureMicrophonePermission() async {
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
          _onCaptureFailure?.call(
            const KidsRecitationCaptureResult.unavailable(),
          );
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
