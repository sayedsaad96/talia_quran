import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/home/domain/services/home_occasion_service.dart';

void main() {
  test('current() returns Hijri context for September 2026 without throwing', () {
    final service = HomeOccasionService(now: () => DateTime(2026, 9, 8, 10));
    final context = service.current(isArabic: true);
    expect(context.greetingPeriod, 'morning');
    expect(context.gregorianLabel, '8 / 9 / 2026');
    expect(context.hijriLabel, isNotEmpty);
  });

  test('Friday is surfaced even if Hijri conversion fails', () {
    final service = HomeOccasionService(now: () => DateTime(2026, 9, 11, 8));
    final context = service.current(isArabic: false);
    expect(context.occasion, HomeOccasion.friday);
  });
}
