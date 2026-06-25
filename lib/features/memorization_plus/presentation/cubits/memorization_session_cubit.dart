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
import '../../../../core/memorization/v2/hint_usage.dart';
import '../../../../core/memorization/v2/session_adapters.dart';
import '../../../../core/memorization/v2/session_engine.dart';
import '../../../../core/memorization/v2/session_phase.dart';
import '../../../../core/memorization/v2/session_state.dart';
import '../../../../core/services/audio_cache_service.dart';
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
  });

  final V2SessionState sessionState;
  final bool isRecording;
  final bool isPlaying;
  final String recognizedText;
  final bool isEvaluating;

  /// Non-null when STT encounters a permission or availability error.
  final V2SpeechIssue? speechIssue;

  MSActive copyWith({
    V2SessionState? sessionState,
    bool? isRecording,
    bool? isPlaying,
    String? recognizedText,
    bool clearRecognizedText = false,
    bool? isEvaluating,
    V2SpeechIssue? speechIssue,
    bool clearSpeechIssue = false,
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
  }) : _quranRepo = quranRepository,
       _memRepo = memorizationRepository,
       _engine = sessionEngine,
       _reviewAdapter = reviewAdapter,
       _progressAdapter = progressAdapter,
       _gamificationAdapter = gamificationAdapter,
       super(const MSInitial()) {
    _initSpeech();
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

  // ── STT ──────────────────────────────────────────────────────────────────

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

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
    if (status == 'notListening' || status == 'done') {
      TaliaLogger.d('V2: Speech status: $status');
    }
  }

  // ── Audio ────────────────────────────────────────────────────────────────

  final AudioPlayer _player = AudioPlayer();
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
      emit(const MSError(message: 'فشل في تحميل بيانات السورة'));
      return;
    }

    final allAyahs = surahResult.fold(
      (_) => <Ayah>[],
      (detail) => detail.ayahs,
    );

    // Resume check: if a persisted session exists for this surah and is in a
    // restorable phase, rehydrate it instead of starting fresh. Terminal
    // (completed) and pre-start (created) phases are never restored — a stale
    // completed row is cleared defensively to avoid double gamification awards.
    final savedOpt = await _progressAdapter.loadIfExists(surahId);
    final saved = savedOpt.fold(() => null, (s) => s);
    if (saved != null) {
      final savedPhase = V2SessionPhase.values[saved.phaseIndex];
      if (savedPhase == V2SessionPhase.completed) {
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
        unawaited(_prefetchBlockAudio(_sessionState!.surahId, _sessionState!.blockAyahs));
        return;
      }
    }

    // Slice block: from startAyah (1-based) for blockSize ayahs.
    final startIndex = (startAyah - 1).clamp(0, allAyahs.length - 1);
    final endIndex = (startIndex + blockSize).clamp(0, allAyahs.length);
    final blockAyahs = allAyahs.sublist(startIndex, endIndex);

    if (blockAyahs.isEmpty) {
      emit(const MSError(message: 'لا توجد آيات في النطاق المحدد'));
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
  void useHint(V2HintLevel level) {
    _assertActive();
    final updated = _engine.useHint(_sessionState!, level);
    if (!identical(updated, _sessionState)) {
      _sessionState = updated;
      _emitActive();
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
  Future<void> stopRecording() async {
    _assertActive();
    final st = state as MSActive;
    if (!st.isRecording) return;

    await _speechToText.stop();
    emit(st.copyWith(isRecording: false, isEvaluating: true));

    // Brief UI delay for "Evaluating..." feedback.
    await Future.delayed(const Duration(milliseconds: 500));
    await _evaluateCurrentRecitation();
  }

  // ── Audio playback ────────────────────────────────────────────────────────

  /// Plays audio for the current ayah.
  Future<void> playCurrentAyah() async {
    _assertActive();
    final st = state as MSActive;
    if (st.isPlaying) await stopAudio();

    final ayah = st.sessionState.currentAyah;
    try {
      final audioSource = await AudioCacheService.instance.getAudioSource(
        st.sessionState.surahId,
        ayah.numberInSurah,
      );
      await AudioCacheService.playFromSource(_player, audioSource);
      emit(st.copyWith(isPlaying: true));
    } catch (e, stack) {
      TaliaLogger.e('V2: Failed to play ayah audio', e, stack);
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
  Future<void> close() {
    _playerStateSub?.cancel();
    _player.dispose();
    _speechToText.cancel();
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
      ),
    );
  }

  /// Evaluates the current recitation based on session phase.
  Future<void> _evaluateCurrentRecitation() async {
    if (_sessionState == null || state is! MSActive) return;
    final spokenText = (state as MSActive).recognizedText;
    final previousState = _sessionState!;

    V2SessionState newState;
    if (previousState.phase == V2SessionPhase.reciting) {
      newState = _engine.evaluateRecitation(previousState, spokenText);
    } else if (previousState.phase == V2SessionPhase.blockReview) {
      newState = _engine.evaluateBlockReview(previousState, spokenText);
    } else {
      // Not a recitation phase — ignore.
      emit((state as MSActive).copyWith(isEvaluating: false));
      return;
    }

    _sessionState = newState;
    emit(
      (state as MSActive).copyWith(sessionState: newState, isEvaluating: false),
    );

    // Handle post-evaluation side effects.
    await _handlePostEvaluation(previousState, newState);
  }

  /// Persists records and handles phase transitions after evaluation.
  Future<void> _handlePostEvaluation(
    V2SessionState previousState,
    V2SessionState newState,
  ) async {
    final lastResult = newState.lastRecitationResult;

    // Record only the ayah that just passed individual recitation.
    if (previousState.phase == V2SessionPhase.reciting &&
        lastResult != null &&
        lastResult.passed) {
      final passedAyah = previousState.currentAyah;
      await _reviewAdapter.recordPass(
        surahId: previousState.surahId,
        ayahNumber: passedAyah.numberInSurah,
        hintLevel: previousState.hintTracker.levelFor(
          previousState.surahId,
          passedAyah.numberInSurah,
        ),
      );
    }

    // Block review completed — persist all records + gamification.
    if (newState.phase == V2SessionPhase.completed) {
      await _onBlockCompleted(newState);
    }

    // Save session state for resume (unless completed).
    if (newState.phase != V2SessionPhase.completed) {
      await _progressAdapter.save(newState);
    }
  }

  /// Called when the session reaches the completed phase.
  Future<void> _onBlockCompleted(V2SessionState finalState) async {
    // Signal weak ayahs to Smart Coach.
    await _reviewAdapter.recordWeakAyahs(finalState.failureTracker);

    // Gamification (streak, XP, certificates).
    final awards = await _gamificationAdapter.onBlockCompleted(finalState);

    // Clear persisted session.
    await _progressAdapter.clear(finalState.surahId);

    emit(MSCompleted(finalState: finalState, awards: awards));
  }

  /// Prefetches audio for all ayahs in the block.
  Future<void> _prefetchBlockAudio(int surahId, List<Ayah> blockAyahs) async {
    final numbers = blockAyahs.map((a) => a.numberInSurah).toList();
    await AudioCacheService.instance.prefetchSession(
      surahId: surahId,
      ayahNumbers: numbers,
    );
  }
}
