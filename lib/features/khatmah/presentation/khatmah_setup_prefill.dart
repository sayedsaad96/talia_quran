import '../domain/entities/khatmah_plan.dart';
import '../domain/entities/khatmah_scheduling_engine.dart';

/// Setup choices carried over from a finished khatmah. The dedication is not
/// carried: the next khatmah is often for someone else.
class KhatmahSetupPrefill {
  const KhatmahSetupPrefill({
    required this.pagesPerDay,
    this.targetDays,
    this.wirdUnit = KhatmahWirdUnit.pages,
    this.seasonLink,
  });

  /// The next khatmah of a Ramadan series that must finish by the link's last
  /// day, or null when no day is left for it.
  static KhatmahSetupPrefill? nextRound(KhatmahPlan plan, DateTime today) {
    final link = plan.seasonLink;
    if (link == null || !link.hasNextRound) return null;
    final days = link.daysLeft(today);
    if (days < 1) return null;
    return KhatmahSetupPrefill(
      pagesPerDay: (KhatmahSchedulingEngine.totalPages / days).ceil(),
      targetDays: days,
      seasonLink: link.next(),
    );
  }

  factory KhatmahSetupPrefill.fromPlan(KhatmahPlan plan) =>
      plan.wirdUnit == KhatmahWirdUnit.juz
      ? const KhatmahSetupPrefill(
          pagesPerDay: 21,
          targetDays: 30,
          wirdUnit: KhatmahWirdUnit.juz,
        )
      : KhatmahSetupPrefill(pagesPerDay: plan.targetPagesPerDay);

  final int pagesPerDay;
  final int? targetDays;
  final KhatmahWirdUnit wirdUnit;

  /// Carried into the new plan so the series stays linked.
  final KhatmahSeasonLink? seasonLink;
}
