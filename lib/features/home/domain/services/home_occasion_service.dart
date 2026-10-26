import 'package:hijri/hijri_calendar.dart';

import '../../../../core/seasons/season_calendar.dart';

enum HomeOccasion { none, friday, ramadan, lastTenNights }

class HomeOccasionContext {
  const HomeOccasionContext({
    required this.hijriLabel,
    required this.gregorianLabel,
    required this.occasion,
    required this.greetingPeriod,
  });

  final String hijriLabel;
  final String gregorianLabel;
  final HomeOccasion occasion;
  final String greetingPeriod;
}

class HomeOccasionService {
  const HomeOccasionService({DateTime Function()? now, this._hijriOffsetDays})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// The user's Hijri date adjustment (`HijriDateAdjustment.days`).
  final int Function()? _hijriOffsetDays;

  HomeOccasionContext current({required bool isArabic}) {
    final now = _now();
    final gregorianLabel = '${now.day} / ${now.month} / ${now.year}';
    var hijriLabel = gregorianLabel;
    var occasion = now.weekday == DateTime.friday
        ? HomeOccasion.friday
        : HomeOccasion.none;
    try {
      HijriCalendar.setLocal(isArabic ? 'ar' : 'en');
      final hijri = HijriCalendar.fromDate(
        now.add(Duration(days: _hijriOffsetDays?.call() ?? 0)),
      );
      hijriLabel = hijri.toFormat('dd MMMM yyyy');
    } catch (_) {}
    // One season engine decides the strip and the cards.
    occasion = _occasion(now, _hijriOffsetDays?.call() ?? 0);
    return HomeOccasionContext(
      hijriLabel: hijriLabel,
      gregorianLabel: gregorianLabel,
      occasion: occasion,
      greetingPeriod: _greeting(now.hour),
    );
  }

  HomeOccasion _occasion(DateTime now, int adjustmentDays) {
    final seasons = seasonsAt(now, adjustmentDays: adjustmentDays);
    for (final season in seasons) {
      if (season.id != SeasonId.ramadan) continue;
      if (season.stage != SeasonStage.active) break;
      // Day 21's evening begins the last ten nights.
      return (season.day ?? 0) >= 21
          ? HomeOccasion.lastTenNights
          : HomeOccasion.ramadan;
    }
    if (now.weekday == DateTime.friday) return HomeOccasion.friday;
    return HomeOccasion.none;
  }

  String _greeting(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }
}
