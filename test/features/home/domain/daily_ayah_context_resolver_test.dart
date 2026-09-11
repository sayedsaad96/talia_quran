import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/home/domain/entities/ayah_of_day.dart';
import 'package:talia_quran/features/home/domain/services/daily_ayah_context_resolver.dart';

void main() {
  DailyAyahContext resolveForHijri({
    required int month,
    required int day,
    String? userGoal,
  }) {
    final resolver = DailyAyahContextResolver(
      hijriDateFor: (_) => DailyAyahHijriDate(month: month, day: day),
    );
    return resolver.resolve(date: DateTime(2026, 9, 9), userGoal: userGoal);
  }

  test('gives Arafah and Eid priority over a user goal', () {
    expect(
      resolveForHijri(month: 12, day: 9, userGoal: 'memorization'),
      DailyAyahContext.arafah,
    );
    expect(
      resolveForHijri(month: 12, day: 10, userGoal: 'reading'),
      DailyAyahContext.eidAlAdha,
    );
  });

  test('distinguishes the Hajj days and Ramadan milestones', () {
    expect(resolveForHijri(month: 12, day: 3), DailyAyahContext.dhulHijjah);
    expect(resolveForHijri(month: 9, day: 1), DailyAyahContext.ramadanStart);
    expect(
      resolveForHijri(month: 9, day: 24),
      DailyAyahContext.lastTenNights,
    );
    expect(resolveForHijri(month: 9, day: 12), DailyAyahContext.ramadan);
  });

  test('uses Friday before the stored goal, then falls back to that goal', () {
    const noHijri = DailyAyahContextResolver(hijriDateFor: _noHijriDate);

    expect(
      noHijri.resolve(date: DateTime(2026, 9, 11), userGoal: 'azkar'),
      DailyAyahContext.friday,
    );
    expect(
      noHijri.resolve(date: DateTime(2026, 9, 9), userGoal: 'azkar'),
      DailyAyahContext.azkar,
    );
  });
}

DailyAyahHijriDate? _noHijriDate(DateTime _) => null;
