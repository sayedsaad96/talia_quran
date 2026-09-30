import '../domain/entities/khatmah_plan.dart';

/// Setup choices carried over from a finished khatmah. The dedication is not
/// carried: the next khatmah is often for someone else.
class KhatmahSetupPrefill {
  const KhatmahSetupPrefill({
    required this.pagesPerDay,
    this.targetDays,
    this.wirdUnit = KhatmahWirdUnit.pages,
  });

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
}
