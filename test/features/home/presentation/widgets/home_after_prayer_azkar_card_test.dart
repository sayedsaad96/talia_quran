import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/azkar/domain/services/after_prayer_azkar_window.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_after_prayer_azkar_card.dart';

void main() {
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
  DateTime at(int h, int m) => DateTime(2026, 10, 16, h, m);
  final snapshot = PrayerTimesSnapshot(
    city: city,
    nextName: 'asr',
    nextTime: at(15, 30),
    minutesUntil: 100,
    fajr: at(5, 0),
    sunrise: at(6, 20),
    dhuhr: at(12, 0),
    asr: at(15, 30),
    maghrib: at(18, 0),
    isha: at(19, 20),
  );

  late SharedPreferences prefs;
  String? openedSub;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    openedSub = null;
  });
  tearDown(() {
    if (getIt.isRegistered<ExperienceFlags>()) {
      getIt.unregister<ExperienceFlags>();
    }
  });

  void flag(bool on) {
    getIt.registerSingleton<ExperienceFlags>(
      ExperienceFlags(
        (key) =>
            key == ExperienceFeature.afterPrayerAzkar.storageKey ? on : null,
      ),
    );
  }

  Widget harness({
    PrayerTimesSnapshot? snap,
    DateTime? now,
    List<String> ids = const ['a', 'b'],
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: HomeAfterPrayerAzkarCard(
              skin: HomeSkin.forBrightness(Brightness.light),
              snapshot: snap ?? snapshot,
              now: () => now ?? at(12, 20),
              prefs: prefs,
              loadIds: () async => ids,
            ),
          ),
        ),
        GoRoute(
          path: '/azkar/:category',
          builder: (_, state) {
            openedSub = state.uri.queryParameters['sub'];
            return const Scaffold(body: Text('azkar-page'));
          },
        ),
      ],
    );
    return MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  const cardKey = ValueKey('home_after_prayer_azkar_card');

  testWidgets('hidden when the flag is off', (tester) async {
    flag(false);
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(find.byKey(cardKey), findsNothing);
  });

  testWidgets('hidden with no window, no snapshot times or no records', (
    tester,
  ) async {
    flag(true);
    await tester.pumpWidget(harness(now: at(14, 0)));
    await tester.pumpAndSettle();
    expect(find.byKey(cardKey), findsNothing);

    await tester.pumpWidget(
      harness(
        snap: PrayerTimesSnapshot(
          city: city,
          nextName: 'asr',
          nextTime: at(15, 30),
          minutesUntil: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(cardKey), findsNothing);

    await tester.pumpWidget(harness(ids: const []));
    await tester.pumpAndSettle();
    expect(find.byKey(cardKey), findsNothing);
  });

  testWidgets(
    'shows in the window; tapping opens the subcategory and hides the card',
    (tester) async {
      flag(true);
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      expect(find.byKey(cardKey), findsOneWidget);
      expect(find.text('After Dhuhr prayer'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('azkar-page'), findsOneWidget);
      expect(openedSub, afterPrayerAzkarSubcategory);
      expect(prefs.getBool('after_prayer_azkar_done_2026-10-16_dhuhr'), isTrue);
    },
  );

  testWidgets('done state hides the card for this prayer', (tester) async {
    flag(true);
    await prefs.setBool('after_prayer_azkar_done_2026-10-16_dhuhr', true);
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(find.byKey(cardKey), findsNothing);
  });

  testWidgets('opening clears done keys from earlier days', (tester) async {
    flag(true);
    await prefs.setBool('after_prayer_azkar_done_2026-10-15_isha', true);
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(prefs.containsKey('after_prayer_azkar_done_2026-10-15_isha'), false);
  });
}
