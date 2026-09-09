import '../../features/streak/domain/entities/streak_entity.dart';

class StreakRisk {
  const StreakRisk({
    required this.isAtRisk,
    required this.freezesAvailable,
    required this.hasActivityToday,
    required this.currentStreak,
  });

  final bool isAtRisk;
  final int freezesAvailable;
  final bool hasActivityToday;
  final int currentStreak;

  static const none = StreakRisk(
    isAtRisk: false,
    freezesAvailable: 0,
    hasActivityToday: false,
    currentStreak: 0,
  );
}

/// A streak is at risk when the user has an active streak, has not recorded
/// activity today, and local time is at or past [riskHour] (default 20:00).
class StreakRiskEvaluator {
  const StreakRiskEvaluator({this.riskHour = 20, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final int riskHour;
  final DateTime Function() _now;

  StreakRisk evaluate(StreakEntity streak, {DateTime? now}) {
    final moment = now ?? _now();
    final today = DateTime(moment.year, moment.month, moment.day);
    final last = streak.lastActivityDate;
    final hasActivityToday = last != null &&
        DateTime(last.toLocal().year, last.toLocal().month, last.toLocal().day) ==
            today;
    final isAtRisk = streak.currentStreak > 0 &&
        !hasActivityToday &&
        moment.hour >= riskHour;
    return StreakRisk(
      isAtRisk: isAtRisk,
      freezesAvailable: streak.freezesAvailable,
      hasActivityToday: hasActivityToday,
      currentStreak: streak.currentStreak,
    );
  }
}
