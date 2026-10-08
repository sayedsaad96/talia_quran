import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:talia_quran/core/utils/quran_ayah_display_text.dart';

void main() {
  group('QuranAyahDisplayText', () {
    test('removes the matching Arabic ayah number from the end', () {
      expect(
        QuranAyahDisplayText.withoutTrailingNumber(
          'وَمِمَّا رَزَقْنَٰهُمْ يُنفِقُونَ\u00A0٣\n',
          ayahNumber: 3,
        ),
        'وَمِمَّا رَزَقْنَٰهُمْ يُنفِقُونَ',
      );
    });

    test('removes a matching decorated ayah number', () {
      expect(
        QuranAyahDisplayText.withoutTrailingNumber(
          'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ﴿٦﴾',
          ayahNumber: 6,
        ),
        'قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
      );
    });

    test('preserves an unmatched number and numbers inside the ayah', () {
      const text = 'فِي ٦ أَيَّامٍ ثُمَّ اسْتَوَىٰ ٧';

      expect(
        QuranAyahDisplayText.withoutTrailingNumber(text, ayahNumber: 6),
        text,
      );
    });

    test('preserves Quran text and spacing when no terminal number exists', () {
      const text = '  مِن شَرِّالْوَسْوَاسِ\n';

      expect(
        QuranAyahDisplayText.withoutTrailingNumber(text, ayahNumber: 4),
        text,
      );
    });

    for (final (surah, ayah, number) in const [
      (7, 206, '٢٠٦'),
      (96, 19, '١٩'),
    ]) {
      test('keeps the sajdah sign of $surah:$ayah and removes only the number',
          () {
        final source = qcf.getVerse(surah, ayah);
        expect(source, contains('۩'), reason: 'fixture must be a sajdah ayah');

        final shown = QuranAyahDisplayText.withoutTrailingNumber(
          source,
          ayahNumber: ayah,
        );

        expect(shown, endsWith('۩'));
        expect(shown, isNot(contains(number)));
        expect(source, startsWith(shown));
      });
    }

    test('replaces the terminal number glyph with Quran verse brackets', () {
      expect(
        QuranAyahDisplayText.withVerseBrackets(
          'وَمِمَّا رَزَقْنَٰهُمْ يُنفِقُونَ\u00A0٣',
          ayahNumber: 3,
        ),
        '﴿ وَمِمَّا رَزَقْنَٰهُمْ يُنفِقُونَ ﴾',
      );
    });

    test('does not duplicate existing Quran verse brackets', () {
      expect(
        QuranAyahDisplayText.withVerseBrackets(
          '﴿ قُلْ هُوَ ٱللَّهُ أَحَدٌ ﴾',
          ayahNumber: 1,
        ),
        '﴿ قُلْ هُوَ ٱللَّهُ أَحَدٌ ﴾',
      );
    });
  });
}
