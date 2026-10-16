import 'package:equatable/equatable.dart';

import '../../../../core/seasons/season_calendar.dart';
import 'khatmah_plan.dart';
import 'khatmah_scheduling_engine.dart';

/// Ramadan khatmah presets. They only fill the existing setup inputs; the
/// plan itself is created by the unchanged scheduling engine.
enum RamadanKhatmahTemplate { oneInMonth, twoInMonth, splitByPrayers }

final class KhatmahTemplateParams extends Equatable {
  const KhatmahTemplateParams({
    required this.targetDays,
    required this.pagesPerDay,
    required this.wirdUnit,
    required this.portionsPerDay,
  });

  final int targetDays;
  final int pagesPerDay;
  final KhatmahWirdUnit wirdUnit;

  /// 1, or 5 when the daily wird is shown split over the prayers.
  final int portionsPerDay;

  @override
  List<Object?> get props => [
    targetDays,
    pagesPerDay,
    wirdUnit,
    portionsPerDay,
  ];
}

/// Ramadan days available to a plan that starts [today]. In the invite phase
/// the plan starts today and gets the full month; during Ramadan it ends on
/// the last Ramadan day. Always at least 1.
int ramadanDaysRemaining(RamadanInfo info, DateTime today) {
  final last = info.lastDay;
  if (info.phase == RamadanPhase.invite || last == null) {
    return info.monthLength < 1 ? 1 : info.monthLength;
  }
  final t = DateTime(today.year, today.month, today.day);
  final days =
      DateTime.utc(
        last.year,
        last.month,
        last.day,
      ).difference(DateTime.utc(t.year, t.month, t.day)).inDays +
      1;
  return days < 1 ? 1 : days;
}

KhatmahTemplateParams paramsFor(
  RamadanKhatmahTemplate t,
  RamadanInfo info,
  DateTime today,
) {
  final days = ramadanDaysRemaining(info, today);
  const total = KhatmahSchedulingEngine.totalPages;
  switch (t) {
    case RamadanKhatmahTemplate.oneInMonth:
    case RamadanKhatmahTemplate.splitByPrayers:
      return KhatmahTemplateParams(
        targetDays: days,
        pagesPerDay: (total / days).ceil(),
        wirdUnit: KhatmahWirdUnit.juz,
        portionsPerDay: t == RamadanKhatmahTemplate.splitByPrayers ? 5 : 1,
      );
    case RamadanKhatmahTemplate.twoInMonth:
      final half = (days / 2).ceil();
      return KhatmahTemplateParams(
        targetDays: half,
        pagesPerDay: (total / half).ceil(),
        wirdUnit: KhatmahWirdUnit.pages,
        portionsPerDay: 1,
      );
  }
}

/// Splits pages [from]..[to] (inclusive) into at most [count] contiguous,
/// near-equal portions with no gaps or overlap. Empty portions are dropped.
List<({int from, int to})> splitPagesIntoPortions(int from, int to, int count) {
  if (to < from || count < 1) return const [];
  final n = to - from + 1;
  final base = n ~/ count;
  final extra = n % count;
  final out = <({int from, int to})>[];
  var cursor = from;
  for (var i = 0; i < count; i++) {
    final size = base + (i < extra ? 1 : 0);
    if (size == 0) continue;
    out.add((from: cursor, to: cursor + size - 1));
    cursor += size;
  }
  return out;
}
