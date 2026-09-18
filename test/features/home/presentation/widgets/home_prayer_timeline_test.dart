import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_prayer_timeline.dart';

void main() {
  // ── shared fixtures ────────────────────────────────────────────────────────
  const city = PrayerCity(
    id: 'cairo',
    nameAr: 'القاهرة',
    nameEn: 'Cairo',
    latitude: 30.0444,
    longitude: 31.2357,
    timeZone: 'Africa/Cairo',
    countryId: 'eg',
    countryAr: 'مصر',
    countryEn: 'Egypt',
    defaultMethod: 'egyptian',
  );

  // now = 11:30 → Fajr (04:15) and Sunrise (05:40) are past; Dhuhr is next.
  final fixedNow = DateTime(2026, 9, 12, 11, 30);
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

  Widget buildHarness({
    PrayerTimesSnapshot? snap,
    Locale locale = const Locale('ar'),
    DateTime Function()? now,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: locale,
      home: Scaffold(
        body: HomePrayerTimeline(
          snapshot: snap ?? snapshot,
          skin: HomeSkin.forBrightness(Brightness.dark),
          hijriLabel: '٢٤ ربيع الأول ١٤٤٨',
          now: now ?? () => fixedNow,
        ),
      ),
    );
  }

  // ── tests ──────────────────────────────────────────────────────────────────

  testWidgets('renders all 6 station names in Arabic', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pump();

    expect(find.text('الفجر'),   findsOneWidget);
    expect(find.text('الشروق'), findsOneWidget);
    expect(find.text('الظهر'),   findsOneWidget);
    expect(find.text('العصر'),   findsOneWidget);
    expect(find.text('المغرب'),  findsOneWidget);
    expect(find.text('العشاء'),  findsOneWidget);
  });

  testWidgets('renders all 6 station names in English', (tester) async {
    await tester.pumpWidget(buildHarness(locale: const Locale('en')));
    await tester.pump();

    expect(find.text('Fajr'),    findsOneWidget);
    expect(find.text('Sunrise'), findsOneWidget);
    expect(find.text('Dhuhr'),   findsOneWidget);
    expect(find.text('Asr'),     findsOneWidget);
    expect(find.text('Maghrib'), findsOneWidget);
    expect(find.text('Isha'),    findsOneWidget);
  });

  testWidgets('city name is visible', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pump();
    expect(find.text('القاهرة'), findsOneWidget);
  });

  testWidgets('header shows next prayer countdown (dhuhr, 25 min)', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pump();
    // prayerTimelineNext AR: "أذان الظهر خلال 25 دقيقة"
    expect(find.textContaining('الظهر'), findsWidgets);
    expect(find.textContaining('25'), findsWidgets);
  });

  testWidgets('header shows hours and minutes when next prayer is > 60 min away',
      (tester) async {
    final longSnap = PrayerTimesSnapshot(
      city: city,
      nextName: 'fajr',
      nextTime: DateTime(2026, 9, 13, 5, 14),
      minutesUntil: 394, // 6 hours and 34 minutes
      fajr: DateTime(2026, 9, 13, 5, 14),
      sunrise: DateTime(2026, 9, 13, 6, 41),
      dhuhr: DateTime(2026, 9, 13, 12, 50),
      asr: DateTime(2026, 9, 13, 16, 18),
      maghrib: DateTime(2026, 9, 13, 18, 57),
      isha: DateTime(2026, 9, 13, 20, 15),
    );

    // Arabic test
    await tester.pumpWidget(buildHarness(snap: longSnap));
    await tester.pump();
    expect(find.textContaining('أذان الفجر خلال 6 ساعات و 34 دقيقة'), findsOneWidget);

    // English test
    await tester.pumpWidget(buildHarness(snap: longSnap, locale: const Locale('en')));
    await tester.pump();
    expect(find.textContaining('Fajr in 6h 34m'), findsOneWidget);
  });

  testWidgets('header uses sunrise-specific text when nextName is sunrise',
      (tester) async {
    final sunriseSnap = PrayerTimesSnapshot(
      city: city,
      nextName: 'sunrise',
      nextTime: DateTime(2026, 9, 12, 5, 40),
      minutesUntil: 10,
      fajr: DateTime(2026, 9, 12, 4, 15),
      sunrise: DateTime(2026, 9, 12, 5, 40),
      dhuhr: DateTime(2026, 9, 12, 11, 55),
      asr: DateTime(2026, 9, 12, 15, 25),
      maghrib: DateTime(2026, 9, 12, 18, 5),
      isha: DateTime(2026, 9, 12, 19, 25),
    );
    // now = 05:30, sunrise is next
    await tester.pumpWidget(
      buildHarness(snap: sunriseSnap, now: () => DateTime(2026, 9, 12, 5, 30)),
    );
    await tester.pump();
    // Header should NOT contain "أذان" for sunrise
    final headerWidgets = tester.widgetList<Text>(find.textContaining('الشروق'));
    for (final t in headerWidgets) {
      expect(t.data?.contains('أذان'), isFalse,
          reason: 'Sunrise header must not contain "أذان"');
    }
  });

  testWidgets('past stations are rendered with low opacity', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pump();

    // Fajr and Sunrise are past. Find their Opacity widgets.
    // We look for Opacity widgets with value 0.45 — there should be exactly 2
    // (one for Fajr, one for Sunrise).
    final opacities = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .where((o) => (o.opacity - 0.45).abs() < 0.01)
        .toList();
    expect(opacities.length, 2,
        reason: 'Fajr and Sunrise should be the only past stations');
  });

  testWidgets('tapping the timeline does not crash', (tester) async {
    HomePrayerTimeline.enableAnimations = false;
    addTearDown(() => HomePrayerTimeline.enableAnimations = true);

    await tester.pumpWidget(buildHarness());
    await tester.pump();

    // The widget is wrapped in a GestureDetector; tapping it opens the sheet.
    // In test environment Navigator.push is unavailable by default — we simply
    // verify no exception is thrown on tap.
    await tester.tap(find.byType(HomePrayerTimeline));
    await tester.pumpAndSettle();
    // No exception = pass
  });

  testWidgets('renders without overflow on narrow screen (320 px wide)',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.reset());

    await tester.pumpWidget(buildHarness());
    await tester.pump();

    // Expect no RenderFlex overflow errors logged
    expect(tester.takeException(), isNull);
  });

  testWidgets('no AnimationController errors when animations are disabled',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: buildHarness(),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
