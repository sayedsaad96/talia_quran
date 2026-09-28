import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/settings/presentation/widgets/settings_prayer_tiles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
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
}
