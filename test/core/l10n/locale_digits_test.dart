import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/extensions/context_extensions.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/digit_material_localizations.dart';
import 'package:talia_quran/core/l10n/locale_cubit.dart';

void main() {
  testWidgets(
    'locale switching reshapes UI and picker digits while retaining values',
    (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'ar'});
      final prefs = await SharedPreferences.getInstance();
      final cubit = LocaleCubit(prefs)..loadLocale();
      addTearDown(cubit.close);
      Future<void> render() async {
        await tester.pumpWidget(
          MaterialApp(
            locale: cubit.state,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              DigitMaterialLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) {
                final material = MaterialLocalizations.of(context);
                return Scaffold(
                  body: Column(
                    children: [
                      Text(context.numText(120)),
                      Text(context.digitText('01:09')),
                      Text(material.formatDecimal(24)),
                      Text(
                        material.formatTimeOfDay(
                          const TimeOfDay(hour: 13, minute: 9),
                        ),
                      ),
                      Text(material.formatYear(DateTime(2026))),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await render();
      for (final digits in ['١٢٠', '٠١:٠٩', '٢٤', '٢٠٢٦']) {
        expect(find.text(digits), findsOneWidget);
      }
      await cubit.setLocale(const Locale('en'));
      await render();
      for (final digits in ['120', '01:09', '24', '2026']) {
        expect(find.text(digits), findsOneWidget);
      }
      final restored = LocaleCubit(prefs)..loadLocale();
      expect(restored.state.languageCode, 'en');
      await restored.close();
    },
  );

  test('localized date input accepts either digit script', () async {
    final material = await DigitMaterialLocalizations.delegate.load(
      const Locale('ar'),
    );
    final date = DateTime(2026, 10, 3);
    final arabic = material.formatCompactDate(date);
    expect(arabic, contains('٢٠٢٦'));
    expect(material.parseCompactDate(arabic), date);
  });
}
