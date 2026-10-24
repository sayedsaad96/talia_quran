import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/domain/services/quran_spread_policy.dart';

void main() {
  group('shouldShowSpread', () {
    test('requires the tablet-width landscape enabled state', () {
      expect(
        shouldShowSpread(
          widthDp: 839,
          orientation: Orientation.landscape,
          enabled: true,
        ),
        isFalse,
      );
      expect(
        shouldShowSpread(
          widthDp: 840,
          orientation: Orientation.landscape,
          enabled: true,
        ),
        isTrue,
      );
      expect(
        shouldShowSpread(
          widthDp: 1200,
          orientation: Orientation.portrait,
          enabled: true,
        ),
        isFalse,
      );
      expect(
        shouldShowSpread(
          widthDp: 1200,
          orientation: Orientation.landscape,
          enabled: false,
        ),
        isFalse,
      );
    });
  });

  group('default Quran spread policy', () {
    test('places odd pages on the right', () {
      final first = spreadForPage(1);
      final second = spreadForPage(2);
      final finalSpread = spreadForPage(603);

      expect(first.rightPage, 1);
      expect(first.leftPage, 2);
      expect(second.rightPage, 1);
      expect(second.leftPage, 2);
      expect(finalSpread.rightPage, 603);
      expect(finalSpread.leftPage, 604);
    });

    test('rejects pages and indices outside the 604-page Mushaf', () {
      expect(() => spreadForPage(0), throwsRangeError);
      expect(() => spreadForPage(605), throwsRangeError);
      expect(() => spreadIndexForPage(0), throwsRangeError);
      expect(() => spreadIndexForPage(605), throwsRangeError);
      expect(() => spreadAt(-1), throwsRangeError);
      expect(() => spreadAt(302), throwsRangeError);
    });
  });

  for (final oddPageOnRight in [true, false]) {
    group('QuranSpreadPolicy(oddPageOnRight: $oddPageOnRight)', () {
      final policy = QuranSpreadPolicy(oddPageOnRight: oddPageOnRight);

      test('places every canonical page in exactly one spread', () {
        final occurrences = <int, int>{
          for (var page = 1; page <= 604; page++) page: 0,
        };

        for (var index = 0; index < policy.spreadCount(); index++) {
          final spread = policy.spreadAt(index);
          for (final page in [spread.rightPage, spread.leftPage]) {
            if (page != null) {
              occurrences[page] = occurrences[page]! + 1;
            }
          }
        }

        expect(occurrences.values, everyElement(1));
      });

      test('maps each page to a spread that contains it', () {
        for (var page = 1; page <= 604; page++) {
          final spread = policy.spreadAt(policy.spreadIndexForPage(page));
          expect([spread.rightPage, spread.leftPage], contains(page));
        }
      });

      test('uses the requested parity for the right visual page', () {
        final spread = policy.spreadForPage(1);

        expect(spread.rightPage, oddPageOnRight ? 1 : 2);
        expect(spread.leftPage, oddPageOnRight ? 2 : 1);
      });
    });
  }
}
