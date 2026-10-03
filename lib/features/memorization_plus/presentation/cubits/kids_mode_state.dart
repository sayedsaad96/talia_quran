part of 'kids_mode_cubit.dart';

@immutable
abstract class KidsModeState extends Equatable {
  const KidsModeState();
  @override
  List<Object?> get props => [];
}

class KidsModeInitial extends KidsModeState {
  const KidsModeInitial();
}

class KidsModeLoading extends KidsModeState {
  const KidsModeLoading();
}

class KidsModeError extends KidsModeState {
  const KidsModeError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class KidsModeLoaded extends KidsModeState {
  const KidsModeLoaded({
    required this.surahId,
    required this.ayahNumber,
    required this.ayahText,
    required this.sessionState,
    required this.progress,
    required this.isPlaying,
    required this.currentLoop,
    required this.maxLoops,
    required this.isCompleted,
    this.newAwards = const [],
    this.mustListenFirst = false, // BUG-4 FIX: guard for listen-before-complete
    this.audioError,
    this.isBuffering = false, // true while audio URL is loading/buffering
    this.isRecording = false, // true while microphone capture is active
    this.recordingSeconds = 0, // seconds elapsed since recording started
    this.recordingError,
    this.sessionStarsEarned = 0,
    this.sessionPointsEarned = 0,
    this.leveledUpTo,
    this.lastMatchedWords = 0,
    this.lastTargetWords = 0,
    this.silentAttempts = 0,
    this.isReview = false,
    this.recalledWords,
  });

  final int surahId;
  final int ayahNumber;
  final String ayahText;
  final V2SessionState sessionState;
  final KidsProgress progress;
  final bool isPlaying;

  /// Completed required listens, capped at [maxLoops]; never the active ordinal.
  final int currentLoop;
  final int maxLoops;
  final bool isCompleted;
  final List<CertificateAward> newAwards;
  final bool mustListenFirst;
  final String? audioError;

  /// True while just_audio is loading/buffering the audio URL.
  final bool isBuffering;

  /// True while microphone capture is active.
  final bool isRecording;

  /// Seconds elapsed since recording started (for the timer display).
  final int recordingSeconds;
  final String? recordingError;
  final int sessionStarsEarned;

  /// Points earned by this session (K11), surfaced on the completion screen.
  final int sessionPointsEarned;

  /// New level when this session triggered a level-up (K11); null otherwise.
  final int? leveledUpTo;

  /// Words the child got right in the latest failed recitation — the
  /// child-friendly "X of Y words" progress feedback. Both zero hides the
  /// feedback banner.
  final int lastMatchedWords;

  /// Total words in the latest evaluated recitation target.
  final int lastTargetWords;

  /// Consecutive recordings in which no words were heard. Reset by any
  /// attempt the recognizer actually heard (K21).
  final int silentAttempts;

  /// A review of an ayah the child already memorized: the session starts in
  /// hidden-text recall, with no listening first (K28).
  final bool isReview;

  /// K32 — after a missed recitation, one flag per ayah word: recited right
  /// or not. Null when there is nothing to show. Never the spoken text.
  final List<bool>? recalledWords;

  /// The text is hidden and the child may record: a review before its first
  /// attempt, or a near miss that keeps new memorization in recitation.
  bool get isAwaitingRecitation =>
      sessionState.phase == V2SessionPhase.reciting &&
      !isRecording &&
      !isCompleted;

  /// True when the latest mismatch carries usable, genuinely encouraging
  /// word-level feedback — "you got X of Y" only makes sense when the child
  /// actually got some words right.
  bool get hasWordFeedback =>
      recordingError == CubitMessageCodes.kidsRecitationMismatch &&
      lastMatchedWords > 0 &&
      lastTargetWords > 0;

  /// The child is recalling the hidden ayah before reciting — the only
  /// phase where "give me the start" is offered (Product Rules §5, K25).
  bool get isRecallingFromMemory =>
      sessionState.phase == V2SessionPhase.memorizing;

  /// "Give me the start" was used for this ayah. Hints never decrease
  /// within a session, so the first word stays revealed on later tries.
  bool get firstWordRevealed =>
      sessionState.hintTracker.levelFor(surahId, ayahNumber).index >=
      V2HintLevel.firstWord.index;

  /// The ayah's first word, taken verbatim from the displayed text.
  String get firstWord => ayahText.trim().split(RegExp(r'\s+')).first;

  /// After this many repeated recitation mismatches the guardian-verified
  /// completion becomes available even though the failure is pedagogical —
  /// a child-voice STT false-negative loop must never trap the child in an
  /// unfailable mission.
  static const int kGuardianFallbackAfterMismatches = 3;

  /// Silence is usually a quiet child, not a fault — one retry comes first.
  /// Repeated silence may mean the recognizer cannot hear this child's
  /// voice, so the guardian may then confirm the recitation (K21).
  static const int kGuardianFallbackAfterSilentAttempts = 2;

  /// True for technical failures, once the same recitation mismatch has
  /// repeated [kGuardianFallbackAfterMismatches] times, or once silence has
  /// repeated [kGuardianFallbackAfterSilentAttempts] times. A single textual
  /// mismatch or quiet attempt is never eligible for guardian override.
  bool get canUseGuardianFallback =>
      audioError != null ||
      recordingError == CubitMessageCodes.kidsMicPermissionDenied ||
      recordingError == CubitMessageCodes.kidsRecordingUnavailable ||
      (recordingError == CubitMessageCodes.kidsRecordingNotCaptured &&
          silentAttempts >= kGuardianFallbackAfterSilentAttempts) ||
      (recordingError == CubitMessageCodes.kidsRecitationMismatch &&
          sessionState.failureTracker.failureCountFor(surahId, ayahNumber) >=
              kGuardianFallbackAfterMismatches);

  KidsModeLoaded copyWith({
    V2SessionState? sessionState,
    KidsProgress? progress,
    bool? isPlaying,
    int? currentLoop,
    bool? isCompleted,
    List<CertificateAward>? newAwards,
    bool? mustListenFirst,
    String? audioError,
    bool clearAudioError = false,
    bool? isBuffering,
    bool? isRecording,
    int? recordingSeconds,
    String? recordingError,
    bool clearRecordingError = false,
    int? sessionStarsEarned,
    int? sessionPointsEarned,
    int? leveledUpTo,
    bool clearLevelUpTo = false,
    int? lastMatchedWords,
    int? lastTargetWords,
    int? silentAttempts,
    List<bool>? recalledWords,
    bool clearRecalledWords = false,
  }) => KidsModeLoaded(
    surahId: surahId,
    ayahNumber: ayahNumber,
    ayahText: ayahText,
    sessionState: sessionState ?? this.sessionState,
    progress: progress ?? this.progress,
    isPlaying: isPlaying ?? this.isPlaying,
    currentLoop: currentLoop ?? this.currentLoop,
    maxLoops: maxLoops,
    isCompleted: isCompleted ?? this.isCompleted,
    newAwards: newAwards ?? this.newAwards,
    mustListenFirst: mustListenFirst ?? this.mustListenFirst,
    audioError: clearAudioError ? null : audioError ?? this.audioError,
    isBuffering: isBuffering ?? this.isBuffering,
    isRecording: isRecording ?? this.isRecording,
    recordingSeconds: recordingSeconds ?? this.recordingSeconds,
    recordingError: clearRecordingError
        ? null
        : recordingError ?? this.recordingError,
    sessionStarsEarned: sessionStarsEarned ?? this.sessionStarsEarned,
    sessionPointsEarned: sessionPointsEarned ?? this.sessionPointsEarned,
    leveledUpTo: clearLevelUpTo ? null : (leveledUpTo ?? this.leveledUpTo),
    lastMatchedWords: lastMatchedWords ?? this.lastMatchedWords,
    lastTargetWords: lastTargetWords ?? this.lastTargetWords,
    isReview: isReview,
    silentAttempts: silentAttempts ?? this.silentAttempts,
    recalledWords: clearRecalledWords
        ? null
        : recalledWords ?? this.recalledWords,
  );

  @override
  List<Object?> get props => [
    surahId,
    ayahNumber,
    sessionState,
    progress,
    isPlaying,
    currentLoop,
    isCompleted,
    newAwards,
    mustListenFirst,
    audioError,
    isBuffering,
    isRecording,
    recordingSeconds,
    recordingError,
    sessionStarsEarned,
    sessionPointsEarned,
    leveledUpTo,
    lastMatchedWords,
    lastTargetWords,
    silentAttempts,
    isReview,
    recalledWords,
  ];
}
