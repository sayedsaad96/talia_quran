import 'package:flutter_test/flutter_test.dart';
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
