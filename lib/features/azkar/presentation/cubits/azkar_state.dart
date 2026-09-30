part of 'azkar_cubit.dart';

@immutable
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
    this.canUndoCompletion = false,
  });

  final AzkarCategory category;
  final List<ZikrSession> sessions;
  final int currentIndex;
  final bool allDone;

  /// True only right after the tap that completed the last zikr in this
  /// session, so the completion screen can offer to take that tap back. A wird
  /// that was already complete when opened never offers it.
  final bool canUndoCompletion;

  ZikrSession get current => sessions[currentIndex];
  int get completedCount => sessions.where((s) => s.isDone).length;

  AzkarLoaded copyWith({
    AzkarCategory? category,
    List<ZikrSession>? sessions,
    int? currentIndex,
    bool? allDone,
    bool? canUndoCompletion,
  }) => AzkarLoaded(
    category: category ?? this.category,
    sessions: sessions ?? this.sessions,
    currentIndex: currentIndex ?? this.currentIndex,
    allDone: allDone ?? this.allDone,
    canUndoCompletion: canUndoCompletion ?? this.canUndoCompletion,
  );

  @override
  List<Object?> get props => [
    category,
    sessions,
    currentIndex,
    allDone,
    canUndoCompletion,
  ];
}

class AzkarError extends AzkarState {
  const AzkarError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
