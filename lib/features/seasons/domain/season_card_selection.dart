import '../../../core/seasons/season_calendar.dart';
import 'season_windows.dart';

/// Which season wins the single generic home card when several overlap.
/// Ramadan has its own card and is never chosen here.
const List<SeasonId> seasonCardPriority = [
  SeasonId.eidFitr,
  SeasonId.eidAdha,
  SeasonId.dhulHijjahTen,
  SeasonId.ashura,
  SeasonId.hijriNewYear,
  SeasonId.shawwalSix,
  SeasonId.shabanPrep,
  SeasonId.whiteDays,
  SeasonId.friday,
  SeasonId.monThu,
];

/// The seasons that share one switch in the seasons settings page (the Eid
/// row also drives the six of Shawwal; the Dhul-Hijjah row also drives Eid
/// al-Adha). «إخفاء هذا الموسم» turns the whole group off.
List<SeasonId> seasonSwitchGroup(SeasonId id) => switch (id) {
  SeasonId.eidFitr ||
  SeasonId.shawwalSix => const [SeasonId.eidFitr, SeasonId.shawwalSix],
  SeasonId.dhulHijjahTen ||
  SeasonId.eidAdha => const [SeasonId.dhulHijjahTen, SeasonId.eidAdha],
  _ => [id],
};

/// Days on which a voluntary fast is not offered as a reminder: all of
/// Ramadan, 1 Shawwal, and 10-13 Dhul-Hijjah (Eid and the days after it).
bool isFastingNotOffered(int hijriMonth, int hijriDay) =>
    hijriMonth == 9 ||
    (hijriMonth == 10 && hijriDay == 1) ||
    (hijriMonth == 12 && hijriDay >= 10 && hijriDay <= 13);

/// The season whose card shows on [now], or null. Only seasons the user has
/// left visible are considered. The New Year invite is left to the Hijri year
/// recap card (no duplicate), and fasting-style reminders (white days,
/// Monday/Thursday) are not offered on days when a voluntary fast is not
/// offered.
ActiveSeason? selectSeasonCard(
  DateTime now, {
  required int adjustmentDays,
  required bool Function(SeasonId id) isVisible,
}) {
  final active = seasonsAt(now, adjustmentDays: adjustmentDays);
  ({int year, int month, int day})? hijri;
  try {
    hijri = hijriOfCivil(now, adjustmentDays);
  } catch (_) {
    hijri = null;
  }
  bool allowed(ActiveSeason s) {
    if (s.id == SeasonId.ramadan || !isVisible(s.id)) return false;
    if (s.id == SeasonId.hijriNewYear && s.stage == SeasonStage.invite) {
      return false;
    }
    final needsFastDay = s.id == SeasonId.whiteDays || s.id == SeasonId.monThu;
    if (needsFastDay && hijri != null) {
      // The white days invite is the eve of the 13th.
      final target = s.id == SeasonId.whiteDays && s.stage == SeasonStage.invite
          ? hijriOfCivil(
              DateTime(now.year, now.month, now.day + 1),
              adjustmentDays,
            )
          : hijri;
      if (isFastingNotOffered(target.month, target.day)) return false;
    }
    return true;
  }

  for (final id in seasonCardPriority) {
    for (final s in active) {
      if (s.id == id && allowed(s)) return s;
    }
  }
  return null;
}
