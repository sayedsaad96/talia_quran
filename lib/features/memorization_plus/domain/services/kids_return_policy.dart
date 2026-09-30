/// K33 — three or more local days since the last session deserve a warm
/// welcome (with no streak-loss wording). A day or two away is ordinary
/// life; a child who never practised is new, not returning.
bool kidsIsReturningAfterBreak(DateTime? lastSessionAt, DateTime now) {
  if (lastSessionAt == null) return false;
  final last = lastSessionAt.toLocal();
  final today = now.toLocal();
  final daysAway = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(last.year, last.month, last.day)).inDays;
  return daysAway >= 3;
}
