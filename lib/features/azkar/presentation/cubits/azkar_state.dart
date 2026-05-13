part of 'azkar_cubit.dart';

abstract class AzkarState extends Equatable {
  const AzkarState();
  @override
  List<Object?> get props => [];
}

class AzkarInitial extends AzkarState {
  const AzkarInitial();
}

class AzkarLoading extends AzkarState {
  const AzkarLoading();
}

class AzkarLoaded extends AzkarState {
  const AzkarLoaded({
    required this.category,
    required this.sessions,
    required this.currentIndex,
    this.allDone = false,
  });

  final AzkarCategory category;
  final List<ZikrSession> sessions;
  final int currentIndex;
  final bool allDone;

  ZikrSession get current => sessions[currentIndex];
  int get completedCount => sessions.where((s) => s.isDone).length;

  AzkarLoaded copyWith({
    AzkarCategory? category,
    List<ZikrSession>? sessions,
    int? currentIndex,
    bool? allDone,
  }) => AzkarLoaded(
    category: category ?? this.category,
    sessions: sessions ?? this.sessions,
    currentIndex: currentIndex ?? this.currentIndex,
    allDone: allDone ?? this.allDone,
  );

  @override
  List<Object?> get props => [category, sessions, currentIndex, allDone];
}

class AzkarError extends AzkarState {
  const AzkarError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
