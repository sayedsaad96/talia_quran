import 'package:equatable/equatable.dart';

/// Latest family activity snapshot a linked child device published through
/// `publish_child_family_activity`, as returned in the dashboard's
/// `activity_snapshot`. Absent (null on [RemoteChildSummary]) until the child
/// device publishes one, which must not be read as "no activity".
class RemoteChildActivity extends Equatable {
  const RemoteChildActivity({
    required this.updatedAt,
    required this.dayKey,
    required this.currentStreak,
    required this.longestStreak,
    required this.activeDaysLast30,
    required this.totalXp,
    required this.readPagesCount,
    required this.todayActivityCount,
    required this.todayReadPagesCount,
  });

  /// Server time the snapshot was last accepted.
  final DateTime updatedAt;

  /// Child-local calendar day (`yyyy-MM-dd`) the "today" counters refer to.
  final String dayKey;
  final int currentStreak;
  final int longestStreak;
  final int activeDaysLast30;
  final int totalXp;
  final int readPagesCount;
  final int todayActivityCount;
  final int todayReadPagesCount;

  /// Whether the "today" counters describe [now]'s calendar day.
  bool isForDay(DateTime now) {
    final local = now.toLocal();
    final key =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    return key == dayKey;
  }

  @override
  List<Object?> get props => [
    updatedAt,
    dayKey,
    currentStreak,
    longestStreak,
    activeDaysLast30,
    totalXp,
    readPagesCount,
    todayActivityCount,
    todayReadPagesCount,
  ];
}
