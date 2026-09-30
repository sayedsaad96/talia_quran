part of 'progress_cubit.dart';

@immutable
abstract class ProgressState extends Equatable {
  const ProgressState();
  @override
  List<Object?> get props => [];
}

class ProgressInitial extends ProgressState {
  const ProgressInitial();
}

class ProgressLoading extends ProgressState {
  const ProgressLoading();
}

class ProgressLoaded extends ProgressState {
  const ProgressLoaded({
    required this.progress,
    this.selectedPath,
    this.isKids = false,
    this.activityCountsByDay = const {},
    this.activityStartDate,
    this.totalXp = 0,
    this.xpLevelProgress = 0,
  });
  final OverallProgress progress;
  final MemorizationPath? selectedPath;
  final bool isKids;
  final Map<String, int> activityCountsByDay;
  final DateTime? activityStartDate;
  final int totalXp;

  /// Progress from the current XP level to the next one, 0..1.
  final double xpLevelProgress;

  ProgressLoaded copyWith({int? totalXp, double? xpLevelProgress}) {
    return ProgressLoaded(
      progress: progress,
      selectedPath: selectedPath,
      isKids: isKids,
      activityCountsByDay: activityCountsByDay,
      activityStartDate: activityStartDate,
      totalXp: totalXp ?? this.totalXp,
      xpLevelProgress: xpLevelProgress ?? this.xpLevelProgress,
    );
  }

  @override
  List<Object?> get props => [
    progress,
    selectedPath,
    isKids,
    activityCountsByDay,
    activityStartDate,
    totalXp,
    xpLevelProgress,
  ];
}

class ProgressError extends ProgressState {
  const ProgressError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
