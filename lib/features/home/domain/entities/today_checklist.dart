import 'package:equatable/equatable.dart';

enum TodayTaskKind { reading, memorize, review, azkar }

class TodayTask extends Equatable {
  const TodayTask({
    required this.kind,
    required this.route,
    required this.isComplete,
    this.current = 0,
    this.total = 0,
    this.detail,
  });

  final TodayTaskKind kind;
  final String route;
  final bool isComplete;
  final int current;
  final int total;
  final String? detail;

  @override
  List<Object?> get props => [kind, route, isComplete, current, total, detail];
}

class TodayChecklist extends Equatable {
  const TodayChecklist({required this.tasks});

  final List<TodayTask> tasks;

  int get completedCount => tasks.where((task) => task.isComplete).length;

  double get progress =>
      tasks.isEmpty ? 0 : completedCount / tasks.length;

  @override
  List<Object?> get props => [tasks];
}
