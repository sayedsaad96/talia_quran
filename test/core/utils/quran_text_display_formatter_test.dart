import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/utils/quran_text_display_formatter.dart';

void main() {
  group('QuranTextDisplayFormatter', () {
    test('removes trailing ayah numbers and decorations', () {
      expect(
        QuranTextDisplayFormatter.cleanAyahForMemorization(
          'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ١',
        ),
        'قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
      );

      expect(
        QuranTextDisplayFormatter.cleanAyahForMemorization(
          'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ﴿١﴾',
        ),
        'قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
      );
    });

    test('normalizes safe whitespace while preserving tashkeel', () {
      expect(
        QuranTextDisplayFormatter.cleanAyahForMemorization(
          '  مِن   شَرِّالْوَسْوَاسِ  ',
        ),
        'مِن شَرِّ الْوَسْوَاسِ',
      );
    });

    test('removes known trailing markers before final cleanup', () {
      expect(
        QuranTextDisplayFormatter.cleanAyahForMemorization(
          'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝',
          trailingMarker: '۝',
        ),
        'قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
      );
    });
  });
}
