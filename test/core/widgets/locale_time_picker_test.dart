import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/core/l10n/digit_material_localizations.dart';
import 'package:talia_quran/core/widgets/locale_time_picker.dart';

void main() {
  testWidgets(
    'Arabic keyboard time accepts either digit script and preserves PM',
    (tester) async {
      TimeOfDay? selected;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            DigitMaterialLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('open'),
                onPressed: () async => selected = await showLocaleTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 13, minute: 9),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('٠٩'), findsWidgets);
      await tester.tap(find.byIcon(TaliaIcons.keyboard));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '٢');
      await tester.enterText(fields.at(1), '35');
      expect(find.text('٣٥'), findsOneWidget);
      final dialogContext = tester.element(find.byType(AlertDialog).last);
      final ok = MaterialLocalizations.of(dialogContext).okButtonLabel;
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog).last,
          matching: find.text(ok),
        ),
      );
      await tester.pumpAndSettle();
      expect(selected, const TimeOfDay(hour: 14, minute: 35));
    },
  );
}
