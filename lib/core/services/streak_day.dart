import 'streak_mercy_policy.dart';

/// Result of applying one day's activity to the streak.
final class StreakDayTransition {
  const StreakDayTransition({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastMercyDay,
    required this.isNewDay,
    required this.isNewRecord,
    required this.mercyApplied,
  });

  final int currentStreak;
  final int longestStreak;
  final DateTime? lastMercyDay;

  /// False when activity was already recorded for [StreakDay.of] today.
  final bool isNewDay;
  final bool isNewRecord;
  final bool mercyApplied;
}

/// The single streak-day rule shared by every writer (reading, khatmah and
/// the memorization outbox).
///
/// A streak day is the learner's *local* calendar day — reading at 01:00 in
/// Cairo belongs to that day, not to the previous UTC day. Days are stored
/// as UTC-midnight values carrying the local calendar fields, and are read
/// back by those fields without any time-zone conversion.
abstract final class StreakDay {
  static const StreakMercyPolicy _mercyPolicy = StreakMercyPolicy();

  /// The streak day [moment] falls on in the device's local calendar.
  static DateTime of(DateTime moment) {
    final local = moment.toLocal();
    return DateTime.utc(local.year, local.month, local.day);
  }

  /// Normalizes a stored day by its calendar fields (no zone conversion).
  static DateTime stored(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  /// `YYYYMMDD` key for the daily-activity heatmap.
  static int dayKey(DateTime day) =>
      day.year * 10000 + day.month * 100 + day.day;

  static StreakDayTransition transition({
    required int currentStreak,
    required int longestStreak,
    required DateTime? lastDay,
    required DateTime? lastMercyDay,
    required DateTime today,
  }) {
    final day = stored(today);
    final last = lastDay == null ? null : stored(lastDay);
    if (last != null && !last.isBefore(day)) {
      return StreakDayTransition(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastMercyDay: lastMercyDay,
        isNewDay: false,
        isNewRecord: false,
        mercyApplied: false,
      );
    }

    var next = 1;
    var mercyApplied = false;
    var mercyDay = lastMercyDay;
    if (last != null) {
      final missedDays = day.difference(last).inDays - 1;
      if (missedDays == 0) {
        next = currentStreak + 1;
      } else if (_mercyPolicy.allowsMercy(
        missedDays: missedDays,
        lastMercyDate: lastMercyDay,
        today: day,
      )) {
        // "يوم الرحمة": one missed day is forgiven at most once per week.
        next = currentStreak + 1;
        mercyApplied = true;
        mercyDay = day;
      }
    }
    final isNewRecord = next > longestStreak;
    return StreakDayTransition(
      currentStreak: next,
      longestStreak: isNewRecord ? next : longestStreak,
      lastMercyDay: mercyDay,
      isNewDay: true,
      isNewRecord: isNewRecord,
      mercyApplied: mercyApplied,
    );
  }
}
