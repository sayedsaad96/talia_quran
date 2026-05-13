import 'package:equatable/equatable.dart';

class StreakEntity extends Equatable {
  const StreakEntity({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
    this.freezesAvailable = 0,
  });

  final int currentStreak;
  final DateTime? lastActivityDate;
  final int longestStreak;
  final int freezesAvailable;

  StreakEntity copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? freezesAvailable,
  }) => StreakEntity(
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    freezesAvailable: freezesAvailable ?? this.freezesAvailable,
  );

  @override
  List<Object?> get props => [
    currentStreak,
    longestStreak,
    lastActivityDate,
    freezesAvailable,
  ];
}
