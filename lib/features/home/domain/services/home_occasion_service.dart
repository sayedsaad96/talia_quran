import 'package:hijri/hijri_calendar.dart';

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
  const HomeOccasionService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  HomeOccasionContext current({required bool isArabic}) {
    final now = _now();
    final gregorianLabel = '${now.day} / ${now.month} / ${now.year}';
    var hijriLabel = gregorianLabel;
    var occasion = now.weekday == DateTime.friday
        ? HomeOccasion.friday
        : HomeOccasion.none;
    try {
      HijriCalendar.setLocal(isArabic ? 'ar' : 'en');
      final hijri = HijriCalendar.fromDate(now);
      hijriLabel = hijri.toFormat('dd MMMM yyyy');
      occasion = _occasion(now, hijri);
    } catch (_) {}
    return HomeOccasionContext(
      hijriLabel: hijriLabel,
      gregorianLabel: gregorianLabel,
      occasion: occasion,
      greetingPeriod: _greeting(now.hour),
    );
  }

  HomeOccasion _occasion(DateTime now, HijriCalendar hijri) {
    if (hijri.hMonth == 9 && hijri.hDay >= 21) return HomeOccasion.lastTenNights;
    if (hijri.hMonth == 9) return HomeOccasion.ramadan;
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
