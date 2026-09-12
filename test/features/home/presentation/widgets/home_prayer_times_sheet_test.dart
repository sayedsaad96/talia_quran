import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_night_header.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_prayer_times_sheet.dart';

void main() {
  const city = PrayerCity(
    id: 'cairo',
    nameAr: 'القاهرة',
    nameEn: 'Cairo',
    latitude: 30.0444,
    longitude: 31.2357,
  );

  final now = DateTime(2026, 9, 12, 11, 30);
  final snapshot = PrayerTimesSnapshot(
    city: city,
    nextName: 'dhuhr',
    nextTime: DateTime(2026, 9, 12, 11, 55),
    minutesUntil: 25,
    fajr: DateTime(2026, 9, 12, 4, 15),
    sunrise: DateTime(2026, 9, 12, 5, 40),
    dhuhr: DateTime(2026, 9, 12, 11, 55),
    asr: DateTime(2026, 9, 12, 15, 25),
    maghrib: DateTime(2026, 9, 12, 18, 5),
    isha: DateTime(2026, 9, 12, 19, 25),
  );

  Widget createHarness({
    required PrayerTimesSnapshot snapshot,
    required String hijriLabel,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: const Locale('ar'),
      home: Scaffold(
        body: HomePrayerTimesSheet(
          snapshot: snapshot,
          hijriLabel: hijriLabel,
          skin: HomeSkin.forBrightness(Brightness.light),
          now: () => now,
        ),
      ),
    );
  }

  testWidgets('renders all 6 prayer times, Hijri date, weekday, and city', (tester) async {
    await tester.pumpWidget(createHarness(
      snapshot: snapshot,
      hijriLabel: '٢٤ ربيع الأول ١٤٤٨',
    ));
    await tester.pumpAndSettle();

    expect(find.text('مواقيت الصلاة'), findsOneWidget);
    expect(find.text('القاهرة'), findsOneWidget);
    expect(find.textContaining('٢٤ ربيع الأول ١٤٤٨'), findsOneWidget);
    expect(find.text('السبت'), findsOneWidget);

    // All 6 prayer names
    expect(find.text('الفجر'), findsOneWidget);
    expect(find.text('الشروق'), findsOneWidget);
    expect(find.text('الظهر'), findsOneWidget);
    expect(find.text('العصر'), findsOneWidget);
    expect(find.text('المغرب'), findsOneWidget);
    expect(find.text('العشاء'), findsOneWidget);

    // Highlight for Dhuhr countdown
    expect(find.text('25 د'), findsOneWidget);
  });

  testWidgets('renders all 6 prayer times and city in en', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(
          body: HomePrayerTimesSheet(
            snapshot: snapshot,
            hijriLabel: '24 Rabi al-Awwal 1448',
            skin: HomeSkin.forBrightness(Brightness.light),
            now: () => now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prayer Times'), findsOneWidget);
    expect(find.text('Cairo'), findsOneWidget);
    expect(find.text('Saturday'), findsOneWidget);
    expect(find.text('Fajr'), findsOneWidget);
    expect(find.text('Sunrise'), findsOneWidget);
    expect(find.text('Dhuhr'), findsOneWidget);
    expect(find.text('Asr'), findsOneWidget);
    expect(find.text('Maghrib'), findsOneWidget);
    expect(find.text('Isha'), findsOneWidget);
    expect(find.text('25 min'), findsOneWidget);
  });

  testWidgets('tapping HomePrayerChip opens HomePrayerTimesSheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        locale: const Locale('ar'),
        home: Scaffold(
          body: Center(
            child: HomePrayerChip(
              snapshot: snapshot,
              skin: HomeSkin.forBrightness(Brightness.light),
              hijriLabel: '٢٤ ربيع الأول ١٤٤٨',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomePrayerChip), findsOneWidget);
    await tester.tap(find.byType(HomePrayerChip));
    await tester.pumpAndSettle();

    expect(find.byType(HomePrayerTimesSheet), findsOneWidget);
    expect(find.text('مواقيت الصلاة'), findsOneWidget);
  });
}
