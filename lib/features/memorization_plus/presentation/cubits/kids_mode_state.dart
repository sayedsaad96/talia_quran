part of 'kids_mode_cubit.dart';

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

  KidsModeLoaded copyWith({
    KidsProgress? progress,
    bool? isPlaying,
    int? currentLoop,
    bool? isCompleted,
    List<CertificateAward>? newAwards,
  }) => KidsModeLoaded(
    surahId: surahId,
    ayahNumber: ayahNumber,
    ayahText: ayahText,
    progress: progress ?? this.progress,
    isPlaying: isPlaying ?? this.isPlaying,
    currentLoop: currentLoop ?? this.currentLoop,
    maxLoops: maxLoops,
    isCompleted: isCompleted ?? this.isCompleted,
    newAwards: newAwards ?? const [],
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
  ];
}
