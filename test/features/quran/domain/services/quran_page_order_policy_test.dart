import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/domain/services/quran_page_order_policy.dart';

void main() {
  group('QuranPageOrderPolicy', () {
    test('canonical order preserves each 604-page identifier', () {
      for (var page = 1; page <= 604; page++) {
        expect(
          QuranPageOrderPolicy.canonical.indexForCanonicalPage(page),
          page - 1,
        );
        expect(
          QuranPageOrderPolicy.canonical.canonicalPageForIndex(page - 1),
          page,
        );
      }
    });

    test('kids order is a 604-page bijection with Fatihah first', () {
      final displayedPages = <int>[];
      for (var index = 0; index < 604; index++) {
        final page = QuranPageOrderPolicy.kidsFatihahFirstReverse
            .canonicalPageForIndex(index);
        displayedPages.add(page);
        expect(
          QuranPageOrderPolicy.kidsFatihahFirstReverse
              .indexForCanonicalPage(page),
          index,
        );
      }

      expect(displayedPages.toSet(), hasLength(604));
      expect(displayedPages.take(4), [1, 604, 603, 602]);
      expect(displayedPages.skip(601), [4, 3, 2]);
    });
  });
}
