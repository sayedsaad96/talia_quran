import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/presentation/widgets/azkar_index_sheet.dart';

Zikr _zikr(String text) => Zikr(
  id: text,
  text: text,
  transliteration: '',
  translation: '',
  totalCount: 1,
  category: AzkarCategory.morning,
);

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  group('azkarIndexTitle', () {
    test('returns a short text unchanged', () {
      expect(azkarIndexTitle(_zikr('سُبْحَانَ اللَّهِ')), 'سُبْحَانَ اللَّهِ');
    });

    test('collapses line breaks and whitespace', () {
      expect(azkarIndexTitle(_zikr('أول\n\n  ثان')), 'أول ثان');
    });

    test('truncates long text on a letter boundary and adds an ellipsis', () {
      const long =
          'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ';
      final title = azkarIndexTitle(_zikr(long));

      expect(title.endsWith('…'), isTrue);
      expect(title.characters.length, 41);
      // A cut must never leave a diacritic without its letter.
      expect(RegExp(r'^[ً-ٟ]').hasMatch(title.characters.first), isFalse);
    });
  });

  testWidgets('lists rows with text titles and reports the tapped index', (
    tester,
  ) async {
    int? tapped;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAzkarIndexSheet(
              context,
              entries: const [
                AzkarIndexEntry(
                  title: 'الذكر الأول',
                  subtitle: 'سنن أبي داود · 0 من 3',
                  done: false,
                  selected: true,
                ),
                AzkarIndexEntry(
                  title: 'الذكر الثاني',
                  subtitle: 'سنن أبي داود · 1 من 1',
                  done: true,
                  selected: false,
                ),
              ],
              onSelected: (index) => tapped = index,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('الذكر الأول'), findsOneWidget);
    expect(find.text('الذكر الثاني'), findsOneWidget);
    expect(find.byIcon(TaliaIcons.checkCircleFilled), findsOneWidget);

    await tester.tap(find.text('الذكر الثاني'));
    await tester.pumpAndSettle();

    expect(tapped, 1);
    expect(find.text('الذكر الثاني'), findsNothing); // sheet closed
  });
}
