import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/widgets/memorization_ayah_display.dart';

void main() {
  group('highlightWordSpans (K32)', () {
    test(
      'reassembles the original text exactly, marks and spacing included',
      () {
        const text = 'قُلْ هُوَ  ٱللَّهُ ۖ أَحَدٌ';
        final spans = highlightWordSpans(text, [
          true,
          false,
          true,
          false,
          true,
        ], highlight: const TextStyle(backgroundColor: Colors.green));

        expect(spans.map((span) => (span as TextSpan).text).join(), text);
      },
    );

    test('styles only the recalled words', () {
      const highlight = TextStyle(backgroundColor: Colors.green);
      final spans = highlightWordSpans('a b', [
        true,
        false,
      ], highlight: highlight).cast<TextSpan>();

      expect(spans.firstWhere((s) => s.text == 'a').style, highlight);
      expect(spans.firstWhere((s) => s.text == 'b').style, isNull);
    });

    test('a flag count that does not match the words yields nothing', () {
      expect(
        highlightWordSpans('a b', [true], highlight: const TextStyle()),
        isEmpty,
      );
    });
  });

  testWidgets('highlighted display renders the very same ayah text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MemorizationAyahDisplay(
            text: 'a b',
            surahId: 114,
            ayahNumber: 1,
            textColor: Colors.black,
            decorationColor: Colors.brown,
            referenceColor: Colors.green,
            wordHighlights: [true, false],
            highlightColor: Colors.green,
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(
      find.byKey(const Key('memorization-ayah-text')),
    );
    expect(text.textSpan?.toPlainText(), 'a b');
  });
}
