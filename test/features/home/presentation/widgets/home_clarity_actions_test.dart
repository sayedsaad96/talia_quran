import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_clarity_actions.dart';

void main() {
  PrayerTimesSnapshot snapshot(String next, DateTime nextTime) {
    DateTime at(int hour) => DateTime(2026, 10, 25, hour);
    return PrayerTimesSnapshot(
      city: const PrayerCity(
        id: 'city',
        nameAr: 'مدينة',
        nameEn: 'City',
        latitude: 0,
        longitude: 0,
        timeZone: 'Africa/Cairo',
        countryId: 'country',
        countryAr: 'بلد',
        countryEn: 'Country',
        defaultMethod: 'muslim_world_league',
      ),
      nextName: next,
      nextTime: nextTime,
      minutesUntil: 0,
      fajr: at(5),
      sunrise: at(6),
      dhuhr: at(12),
      asr: at(15),
      maghrib: at(18),
      isha: at(21),
    );
  }

  Future<String> label(WidgetTester tester, PrayerTimesSnapshot s) async {
    late String result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            result = clarityNextPrayerLabel(context, s);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('shows the localized prayer name, never the raw key', (
    tester,
  ) async {
    final text = await label(
      tester,
      snapshot('maghrib', DateTime(2026, 10, 25, 18)),
    );
    expect(text, contains('المغرب'));
    expect(text, isNot(contains('maghrib')));
  });

  testWidgets('between Fajr and sunrise it points to Dhuhr', (tester) async {
    final text = await label(
      tester,
      snapshot('sunrise', DateTime(2026, 10, 25, 6)),
    );
    expect(text, contains('الظهر'));
    expect(text, isNot(contains('الشروق')));
  });
}
