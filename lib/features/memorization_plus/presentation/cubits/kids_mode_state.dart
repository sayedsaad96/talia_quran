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
    required this.progress,
    required this.isPlaying,
    required this.currentLoop,
    required this.maxLoops,
    required this.isCompleted,
    this.newAwards = const [],
    this.mustListenFirst = false, // BUG-4 FIX: guard for listen-before-complete
    this.audioError,
    this.isBuffering = false, // true while audio URL is loading/buffering
    this.isRecording = false, // true during the mic-recording animation phase
    this.sessionStarsEarned = 0,
  });

  final int surahId;
  final int ayahNumber;
  final String ayahText;
  final KidsProgress progress;
  final bool isPlaying;
  final int currentLoop;
  final int maxLoops;
  final bool isCompleted;
  final List<CertificateAward> newAwards;
  final bool mustListenFirst;
  final String? audioError;

  /// True while just_audio is loading/buffering the audio URL.
  final bool isBuffering;

  /// True during the brief microphone-recording animation before completion.
  final bool isRecording;
  final int sessionStarsEarned;

  KidsModeLoaded copyWith({
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
    int? sessionStarsEarned,
  }) => KidsModeLoaded(
    surahId: surahId,
    ayahNumber: ayahNumber,
    ayahText: ayahText,
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
    sessionStarsEarned: sessionStarsEarned ?? this.sessionStarsEarned,
  );

  @override
  List<Object?> get props => [
    surahId,
    ayahNumber,
    progress,
    isPlaying,
    currentLoop,
    isCompleted,
    newAwards,
    mustListenFirst,
    audioError,
    isBuffering,
    isRecording,
    sessionStarsEarned,
  ];
}
