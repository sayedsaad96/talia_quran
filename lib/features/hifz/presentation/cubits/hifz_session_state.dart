part of 'hifz_session_cubit.dart';

abstract class HifzSessionState extends Equatable {
  const HifzSessionState();
  @override
  List<Object?> get props => [];
}

class HifzSessionInitial extends HifzSessionState {
  const HifzSessionInitial();
}

class HifzSessionLoading extends HifzSessionState {
  const HifzSessionLoading();
}

class HifzSessionLoaded extends HifzSessionState {
  const HifzSessionLoaded({
    required this.surah,
    required this.ayahs,
    required this.progressMap,
    required this.currentIndex,
    this.isRecording = false,
    this.isPlaying = false,
    this.recognizedText = '',
    this.similarityScore,
    this.isEvaluating = false,
    this.audioError,
  });
  
  final Surah surah;
  final List<Ayah> ayahs;
  final Map<int, AyahProgressModel> progressMap;
  
  // Single Ayah interaction states
  final int currentIndex; // points to the index in the `ayahs` list
  final bool isRecording;
  final bool isPlaying;
  final String recognizedText;
  final double? similarityScore;
  final bool isEvaluating;
  final String? audioError;

  HifzSessionLoaded copyWith({
    Surah? surah,
    List<Ayah>? ayahs,
    Map<int, AyahProgressModel>? progressMap,
    int? currentIndex,
    bool? isRecording,
    bool? isPlaying,
    String? recognizedText,
    double? similarityScore,
    bool clearScore = false,
    bool? isEvaluating,
    String? audioError,
    bool clearAudioError = false,
  }) {
    return HifzSessionLoaded(
      surah: surah ?? this.surah,
      ayahs: ayahs ?? this.ayahs,
      progressMap: progressMap ?? this.progressMap,
      currentIndex: currentIndex ?? this.currentIndex,
      isRecording: isRecording ?? this.isRecording,
      isPlaying: isPlaying ?? this.isPlaying,
      recognizedText: recognizedText ?? this.recognizedText,
      similarityScore: clearScore ? null : (similarityScore ?? this.similarityScore),
      isEvaluating: isEvaluating ?? this.isEvaluating,
      audioError: clearAudioError ? null : (audioError ?? this.audioError),
    );
  }

  @override
  List<Object?> get props => [
        surah,
        ayahs,
        progressMap,
        currentIndex,
        isRecording,
        isPlaying,
        recognizedText,
        similarityScore,
        isEvaluating,
        audioError,
      ];
}

class HifzSessionError extends HifzSessionState {
  const HifzSessionError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

/// Emitted (briefly) when one or more certificates are newly earned.
class CertificatesEarned extends HifzSessionState {
  const CertificatesEarned({
    required this.awards,
    required this.previousState,
  });
  final List<CertificateAward> awards;
  final HifzSessionLoaded previousState;
  @override
  List<Object?> get props => [awards, previousState];
}
