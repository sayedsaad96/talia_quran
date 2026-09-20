/// "يوم الرحمة" (Mercy Day) — Talia's grace rule for broken streaks.
///
/// Instead of punishing a user who missed a single day, the streak is
/// mercifully re-lit. Mercy is bounded: it only covers exactly one missed
/// day, and it can fire at most once per [cooldownDays] so it stays a gift
/// rather than a loophole.
class StreakMercyPolicy {
  const StreakMercyPolicy({this.cooldownDays = 7});

  /// Minimum days between two mercy grants.
  final int cooldownDays;

  /// Whether a returning user's broken streak may be re-lit today.
  ///
  /// [missedDays] is the number of full days without activity between the
  /// last activity date and today (gap of 2 calendar days = 1 missed day).
  /// [lastMercyDate] is the last day mercy was granted (null = never).
  bool allowsMercy({
    required int missedDays,
    required DateTime? lastMercyDate,
    required DateTime today,
  }) {
    // Only a single missed day qualifies — longer absences reset the streak.
    if (missedDays != 1) return false;
    final last = lastMercyDate;
    if (last == null) return true;
    final lastNorm = DateTime(last.year, last.month, last.day);
    final todayNorm = DateTime(today.year, today.month, today.day);
    return todayNorm.difference(lastNorm).inDays >= cooldownDays;
  }
}
