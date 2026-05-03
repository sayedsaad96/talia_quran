import 'package:equatable/equatable.dart';

class StreakResult extends Equatable {
  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.isNewActivity,
    this.isNewRecord = false,
    this.milestoneReached,
  });

  /// Used when same day — no change in Streak
  const StreakResult.sameDay()
      : currentStreak = 0,
        longestStreak = 0,
        isNewActivity = false,
        isNewRecord = false,
        milestoneReached = null;

  final int currentStreak;
  final int longestStreak;
  final bool isNewActivity;
  final bool isNewRecord;
  final int? milestoneReached; // null or milestone number (3, 7, 14, 30 ...)

  @override
  List<Object?> get props =>
      [currentStreak, longestStreak, isNewActivity, isNewRecord, milestoneReached];
}
