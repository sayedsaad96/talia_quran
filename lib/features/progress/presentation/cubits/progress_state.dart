part of 'progress_cubit.dart';

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
  const ProgressLoaded({required this.progress});
  final OverallProgress progress;
  @override
  List<Object?> get props => [progress];
}

class ProgressError extends ProgressState {
  const ProgressError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
