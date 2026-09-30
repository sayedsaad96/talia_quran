import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_return_policy.dart';

void main() {
  group('kidsIsReturningAfterBreak (K33)', () {
    final now = DateTime(2026, 9, 30, 9);

    test('three local days away is a return', () {
      expect(kidsIsReturningAfterBreak(DateTime(2026, 9, 27, 23), now), isTrue);
    });

    test('two days away is not, even across midnight', () {
      expect(kidsIsReturningAfterBreak(DateTime(2026, 9, 28, 1), now), isFalse);
      expect(
        kidsIsReturningAfterBreak(DateTime(2026, 9, 29, 23), now),
        isFalse,
      );
    });

    test('a child who never practised is new, not returning', () {
      expect(kidsIsReturningAfterBreak(null, now), isFalse);
    });
  });
}
