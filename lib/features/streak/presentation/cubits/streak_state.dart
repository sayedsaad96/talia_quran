part of 'streak_cubit.dart';

abstract class StreakState extends Equatable {
  const StreakState();
  @override
  List<Object?> get props => [];
}

class StreakInitial extends StreakState {
  const StreakInitial();
}

class StreakLoaded extends StreakState {
  const StreakLoaded({required this.streak});
  final StreakEntity streak;
  @override
  List<Object?> get props => [streak];
}

class StreakError extends StreakState {
  const StreakError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
