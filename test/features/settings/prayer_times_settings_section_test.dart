import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/settings/presentation/widgets/settings_prayer_tiles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // A cached asset future from an earlier test's fake clock never
    // completes in the next test; each test reads the cities afresh.
    rootBundle.evict(PrayerTimesService.citiesAsset);
    await getIt.reset();
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<PrayerTimesService>(PrayerTimesService(prefs));
  });

  tearDown(() => getIt.reset());

  testWidgets('selecting a country does not silently confirm its first city', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrayerTimesSettingsSection(isDark: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final service = getIt<PrayerTimesService>();
    expect(service.selectedCityId, isNull);
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Egypt').last);
    await tester.pumpAndSettle();
    expect(service.selectedCityId, isNull);

    await tester.tap(find.byType(DropdownButton<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cairo').last);
    await tester.pumpAndSettle();
    expect(service.selectedCityId, 'cairo');

    final countryDropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>).first,
    );
    expect(countryDropdown.items?.map((item) => item.value), contains('jo'));
    countryDropdown.onChanged?.call('jo');
    await tester.pumpAndSettle();

    expect(service.selectedCityId, isNull);
    expect(await service.current(isArabic: false), isNull);
  });

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrayerTimesSettingsSection(isDark: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a city whose default is a newer method keeps a valid picker', (
    tester,
  ) async {
    // Doha follows the Qatar method, which the old picker did not list. The
    // automatic state is seeded directly: asset reads hang in a test body.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrayerTimesService.cityIdKey, 'doha');
    await prefs.setString(PrayerTimesService.methodKey, 'qatar');
    await prefs.setBool(PrayerTimesService.methodManualKey, false);
    await pumpSection(tester);

    expect(tester.takeException(), isNull);
    final methodDropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>).at(2),
    );
    expect(
      methodDropdown.items?.map((item) => item.value),
      containsAll(['qatar', 'kuwait', 'dubai', 'singapore', 'turkey']),
    );
  });

  testWidgets('the Asr madhab can be chosen and returned to automatic', (
    tester,
  ) async {
    final service = getIt<PrayerTimesService>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrayerTimesService.cityIdKey, 'karachi');
    await pumpSection(tester);

    final madhab = find.byKey(const Key('prayer_madhab_dropdown'));
    await tester.ensureVisible(madhab);
    await tester.tap(madhab);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Majority (Shafi'i, Maliki, Hanbali)").last);
    await tester.pumpAndSettle();

    expect(service.isMadhabManual, isTrue);
    expect(service.manualMadhab, PrayerTimesService.shafiMadhab);

    await tester.tap(madhab);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic by city').last);
    await tester.pumpAndSettle();

    // Back to automatic: Karachi's Hanafi default applies again (resolution
    // itself is covered by prayer_times_service_test).
    expect(service.isMadhabManual, isFalse);
    expect(service.manualMadhab, isNull);
  });

  testWidgets('a place outside the list can be saved by its coordinates', (
    tester,
  ) async {
    PrayerTimesSettingsSection.deviceTimeZone = () async => 'Africa/Algiers';
    addTearDown(() {
      PrayerTimesSettingsSection.deviceTimeZone = () async => 'UTC';
    });
    await pumpSection(tester);

    final countryDropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>).first,
    );
    countryDropdown.onChanged?.call(PrayerTimesService.customCityId);
    await tester.pumpAndSettle();

    // Arabic-keyboard digits and decimal mark are accepted.
    await tester.enterText(
      find.byKey(const Key('prayer_custom_latitude')),
      '٣٦٫٧٥٣٨',
    );
    await tester.enterText(
      find.byKey(const Key('prayer_custom_longitude')),
      '3.0588',
    );
    await tester.tap(find.byKey(const Key('prayer_custom_save')));
    await tester.pumpAndSettle();

    final service = getIt<PrayerTimesService>();
    expect(service.selectedCityId, PrayerTimesService.customCityId);
    expect(service.customCity!.latitude, closeTo(36.7538, 1e-9));
    expect(service.customCity!.timeZone, 'Africa/Algiers');
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Location saved'), findsOneWidget);
  });

  testWidgets('out-of-range coordinates are not saved', (tester) async {
    PrayerTimesSettingsSection.deviceTimeZone = () async => 'Africa/Algiers';
    await pumpSection(tester);

    tester
        .widget<DropdownButton<String>>(
          find.byType(DropdownButton<String>).first,
        )
        .onChanged
        ?.call(PrayerTimesService.customCityId);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('prayer_custom_latitude')),
      '120',
    );
    await tester.enterText(
      find.byKey(const Key('prayer_custom_longitude')),
      '3',
    );
    await tester.tap(find.byKey(const Key('prayer_custom_save')));
    await tester.pumpAndSettle();

    expect(getIt<PrayerTimesService>().selectedCityId, isNull);
    expect(find.textContaining('Check the coordinates'), findsOneWidget);
  });
}

