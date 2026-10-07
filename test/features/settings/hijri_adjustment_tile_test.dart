import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/hijri_date_adjustment.dart';
import 'package:talia_quran/core/theme/app_theme.dart';
import 'package:talia_quran/features/home/domain/services/home_occasion_service.dart';
import 'package:talia_quran/features/settings/presentation/widgets/settings_hijri_adjustment_tile.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await getIt.reset();
    getIt.registerSingleton(HijriDateAdjustment(prefs));
    getIt.registerSingleton(
      HomeOccasionService(
        now: () => DateTime(2027, 3, 1, 9),
        hijriOffsetDays: () => getIt<HijriDateAdjustment>().days,
      ),
    );
  });

  tearDown(() => getIt.reset());

  testWidgets('choosing +1 persists and moves the preview a day', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(body: HijriAdjustmentTile()),
      ),
    );

    final before = tester
        .widget<Text>(find.byKey(const ValueKey('hijri-adjustment-preview')))
        .data;

    await tester.tap(find.text('+1'));
    await tester.pumpAndSettle();

    expect(prefs.getInt(HijriDateAdjustment.preferenceKey), 1);
    final expected = HomeOccasionService(
      now: () => DateTime(2027, 3, 2, 9),
    ).current(isArabic: false).hijriLabel;
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('hijri-adjustment-preview')))
          .data,
      'Today: $expected',
    );
    expect(before, isNot('Today: $expected'));
  });
}
