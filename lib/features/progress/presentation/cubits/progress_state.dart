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
  });
  final OverallProgress progress;
  final MemorizationPath? selectedPath;
  final bool isKids;
  final Map<String, int> activityCountsByDay;
  final DateTime? activityStartDate;

  @override
  List<Object?> get props => [
    progress,
    selectedPath,
    isKids,
    activityCountsByDay,
    activityStartDate,
  ];
}

class ProgressError extends ProgressState {
  const ProgressError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
