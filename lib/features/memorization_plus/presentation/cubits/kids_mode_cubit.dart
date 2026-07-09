import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../../core/constants/speech_constants.dart';
import '../../../../core/memorization/v2/hint_usage.dart';
import '../../../../core/memorization/v2/session_adapters.dart';
import '../../../../core/memorization/v2/session_engine.dart';
import '../../../../core/memorization/v2/session_phase.dart';
import '../../../../core/memorization/v2/session_state.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/services/streak_service.dart'; // RISK-5 FIX
import '../../../../core/services/xp_service.dart'; // RISK-5 FIX
import '../../../quran/domain/entities/quran_entities.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../features/quran/domain/repositories/quran_repository.dart';

part 'kids_mode_state.dart';

class KidsModeCubit extends Cubit<KidsModeState> {
  KidsModeCubit(
    this._getKidsProgress,
    this._awardPoints,
    this._saveKidsSessionLog,
    this._achievementService,
    this._quranRepository,
    this._sessionEngine,
    this._reviewAdapter,
    this._streakService, // RISK-5 FIX
    this._xpService, [ // RISK-5 FIX
    KidsRecitationRecorder? recitationRecorder,
    AppSessionService? appSessionService,
  ]) : _appSessionService = appSessionService,
       super(const KidsModeInitial()) {
    _recitationRecorder = recitationRecorder ?? KidsSpeechRecitationRecorder();
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
  final AwardKidsPointsUsecase _awardPoints;
  final SaveKidsSessionLogUsecase _saveKidsSessionLog;
  final AchievementService _achievementService;
  final QuranRepository _quranRepository;
  final V2SessionEngine _sessionEngine;
  final V2SessionReviewAdapter _reviewAdapter;
  final StreakService _streakService; // RISK-5 FIX
  final XpService _xpService; // RISK-5 FIX
  final AppSessionService? _appSessionService;
  late final KidsRecitationRecorder _recitationRecorder;
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _playerSub;
  late final StreamSubscription<ProcessingState> _bufferingSub;

  int _loopCount = 0;
  final Set<String> _completionsInFlight = <String>{};
  static const int _maxLoops = 3;

  // Recording timer
  Timer? _recordingTimer;
  Completer<KidsRecitationCaptureResult>? _recordingCompleter;

  @visibleForTesting
  void debugSetLoopCount(int count) {
    _loopCount = count;
  }

  Future<void> load(int surahId, int ayahNumber, String ayahText) async {
    emit(const KidsModeLoading());

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

    final sessionState = _sessionEngine.startLearning(
      V2SessionState.initial(
        surahId: surahId,
        blockAyahs: [
          Ayah(
            number: ayahNumber,
            surahId: surahId,
            text: resolvedText,
            numberInSurah: ayahNumber,
          ),
        ],
        blockReviewRequired: false,
      ),
    );

    emit(
      KidsModeLoaded(
        surahId: surahId,
        ayahNumber: ayahNumber,
        ayahText: resolvedText,
        sessionState: sessionState,
        progress: progress,
        isPlaying: false,
        currentLoop: 0,
        maxLoops: _maxLoops,
        isCompleted: false,
      ),
    );
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
      // Cache-first playback: reuses the same cache the adult V2 path uses, so
      // the 3× loop below plays the 2nd/3rd iterations from disk instead of
      // re-downloading. Source URL is identical (AudioCacheService builds it
      // via QuranAudioService.buildUrl internally).
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

  /// Records the child's recitation, then finalises completion only after
  /// speech recognition captures actual recited words.
  Future<void> startRecording() async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;
    if (st.isCompleted) return;

    if (_loopCount < _maxLoops) {
      emit(st.copyWith(mustListenFirst: true));
      Future.delayed(const Duration(seconds: 2), () {
        if (state is KidsModeLoaded) {
          emit((state as KidsModeLoaded).copyWith(mustListenFirst: false));
        }
      });
      return;
    }

    if (st.isPlaying) {
      await stopAudio();
    }

    // Prepare the completer so stopRecording() can resolve it early
    _recordingCompleter = Completer<KidsRecitationCaptureResult>();

    emit(
      st.copyWith(
        isRecording: true,
        recordingSeconds: 0,
        clearRecordingError: true,
      ),
    );

    // Start a per-second timer for the recording indicator
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
    if (!capture.hasSpeech) {
      emit(
        current.copyWith(
          isRecording: false,
          recordingSeconds: 0,
          recordingError: capture.messageCode,
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        isRecording: false,
        recordingSeconds: 0,
        clearRecordingError: true,
      ),
    );

    await markCompleted();
  }

  /// Stops an in-progress recording manually and accepts whatever was captured.
  Future<void> stopRecording() async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;
    if (!st.isRecording) return;

    // Signal the recorder to stop and treat as captured (user decided they
    // finished reciting, so we accept it regardless of speech recognition).
    _recordingCompleter?.complete(
      const KidsRecitationCaptureResult.capturedByUser(),
    );
    await _recitationRecorder.stop();
  }

  Future<void> markCompleted() async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;
    if (st.isCompleted) return;

    // BUG-4 FIX: prevent completing without listening the required times
    if (_loopCount < _maxLoops) {
      // Emit a warning state so the UI can show a message
      emit(st.copyWith(mustListenFirst: true));
      // Clear the flag after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (state is KidsModeLoaded) {
          emit((state as KidsModeLoaded).copyWith(mustListenFirst: false));
        }
      });
      return;
    }

    final completionKey = '${st.surahId}_${st.ayahNumber}';
    if (_completionsInFlight.contains(completionKey)) return;
    _completionsInFlight.add(completionKey);

    try {
      final result = await _awardPoints(
        AwardKidsPointsParams(
          surahId: st.surahId,
          ayahNumber: st.ayahNumber,
          repeatsCompleted: _loopCount,
        ),
      );

      final completion = result.fold<KidsCompletionResult?>((f) {
        emit(KidsModeError(f.message));
        return null;
      }, (completion) => completion);
      if (completion == null) return;

      if (completion.alreadyCompleted) {
        await _appSessionService?.clearLastRestorableLocation();
        emit(
          st.copyWith(
            progress: completion.progress,
            isCompleted: true,
            sessionStarsEarned: 0,
          ),
        );
        return;
      }

      final completedSession = _completeV2Session(st.sessionState);
      await _reviewAdapter.recordPass(
        surahId: st.surahId,
        ayahNumber: st.ayahNumber,
        hintLevel: V2HintLevel.none,
        createdByMode: ReviewRecordCreatedByMode.kidsMode,
      );

      // RISK-5 FIX: record streak & XP from Kids Mode — same as Hifz & Adults
      try {
        await _streakService.recordActivity(activityDelta: 1);
        await _xpService.addXp('ayah_memorized');
      } catch (_) {
        // Non-critical
      }

      await _saveKidsSessionLog(
        SaveKidsSessionLogParams(
          surahId: st.surahId,
          ayahNumber: st.ayahNumber,
          repeatsCompleted: _loopCount,
          pointsEarned: completion.pointsEarned,
        ),
      );

      final newAwards = await _achievementService.checkAndUnlockCertificates();
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

  V2SessionState _completeV2Session(V2SessionState session) {
    var current = session;
    if (current.phase == V2SessionPhase.learning) {
      current = _sessionEngine.startMemorizing(current);
    }
    if (current.phase == V2SessionPhase.memorizing ||
        current.phase == V2SessionPhase.remediation) {
      current = _sessionEngine.startReciting(current);
    }
    if (current.phase == V2SessionPhase.reciting) {
      return _sessionEngine.evaluateRecitation(
        current,
        current.currentAyah.text,
      );
    }
    return current;
  }

  @override
  Future<void> close() async {
    _recordingTimer?.cancel();
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
    required this.hasSpeech,
    required this.messageCode,
  });

  const KidsRecitationCaptureResult.captured()
    : this._(hasSpeech: true, messageCode: null);

  /// User pressed "done" manually — treat as a successful capture.
  const KidsRecitationCaptureResult.capturedByUser()
    : this._(hasSpeech: true, messageCode: null);

  const KidsRecitationCaptureResult.permissionDenied()
    : this._(
        hasSpeech: false,
        messageCode: CubitMessageCodes.kidsMicPermissionDenied,
      );

  const KidsRecitationCaptureResult.unavailable()
    : this._(
        hasSpeech: false,
        messageCode: CubitMessageCodes.kidsRecordingUnavailable,
      );

  const KidsRecitationCaptureResult.notCaptured()
    : this._(
        hasSpeech: false,
        messageCode: CubitMessageCodes.kidsRecordingNotCaptured,
      );

  final bool hasSpeech;
  final String? messageCode;
}

class KidsSpeechRecitationRecorder implements KidsRecitationRecorder {
  KidsSpeechRecitationRecorder({SpeechToText? speechToText})
    : _speechToText = speechToText ?? SpeechToText();

  final SpeechToText _speechToText;
  bool _speechEnabled = false;

  @override
  Future<KidsRecitationCaptureResult> capture({
    Completer<KidsRecitationCaptureResult>? externalCompleter,
  }) async {
    final permission = await _ensureMicrophonePermission();
    if (!permission) {
      externalCompleter?.complete(
        const KidsRecitationCaptureResult.permissionDenied(),
      );
      return const KidsRecitationCaptureResult.permissionDenied();
    }

    if (!_speechEnabled) {
      _speechEnabled = await _initializeSpeech();
    }
    if (!_speechEnabled) {
      externalCompleter?.complete(
        const KidsRecitationCaptureResult.unavailable(),
      );
      return const KidsRecitationCaptureResult.unavailable();
    }

    final internalCompleter = Completer<KidsRecitationCaptureResult>();
    var recognizedWords = '';

    void completeIfNeeded(KidsRecitationCaptureResult result) {
      if (!internalCompleter.isCompleted) {
        internalCompleter.complete(result);
      }
      if (externalCompleter != null && !externalCompleter.isCompleted) {
        externalCompleter.complete(result);
      }
    }

    try {
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          recognizedWords = result.recognizedWords.trim();
          if (result.finalResult && recognizedWords.isNotEmpty) {
            completeIfNeeded(const KidsRecitationCaptureResult.captured());
          }
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
          localeId: kArabicSpeechLocaleId,
        ),
      );
    } catch (_) {
      externalCompleter?.complete(
        const KidsRecitationCaptureResult.unavailable(),
      );
      return const KidsRecitationCaptureResult.unavailable();
    }

    // Race: internal speech result OR external stop signal (user pressed done)
    final result =
        await Future.any([
          internalCompleter.future,
          if (externalCompleter != null) externalCompleter.future,
        ]).timeout(
          const Duration(seconds: 12),
          onTimeout: () async {
            await _speechToText.stop();
            return recognizedWords.isEmpty
                ? const KidsRecitationCaptureResult.notCaptured()
                : const KidsRecitationCaptureResult.captured();
          },
        );

    return result;
  }

  @override
  Future<void> stop() => _speechToText.stop();

  Future<bool> _ensureMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  Future<bool> _initializeSpeech() {
    return _speechToText.initialize(
      onError: (SpeechRecognitionError error) {},
      onStatus: (status) {},
    );
  }

  @override
  Future<void> dispose() => _speechToText.cancel();
}
