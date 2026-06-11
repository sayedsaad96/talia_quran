import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/review_due_evaluator.dart';

void main() {
  const evaluator = ReviewDueEvaluator();

  group('ReviewDueEvaluator', () {
    test('preserves MemPlus inclusive due behavior', () {
      final now = DateTime.utc(2026, 6, 9, 12);

      expect(
        evaluator.isDue(
          now: now,
          scheduledAt: now,
          policy: ReviewDuePolicy.onOrAfterScheduledTime,
        ),
        isTrue,
      );
      expect(
        evaluator.isDue(
          now: now,
          scheduledAt: now.add(const Duration(seconds: 1)),
          policy: ReviewDuePolicy.onOrAfterScheduledTime,
        ),
        isFalse,
      );
      expect(
        evaluator.isDue(
          now: now,
          scheduledAt: now.subtract(const Duration(seconds: 1)),
          policy: ReviewDuePolicy.onOrAfterScheduledTime,
        ),
        isTrue,
      );
    });

    test('preserves Hifz strict due behavior', () {
      final now = DateTime.utc(2026, 6, 9, 12);

      expect(
        evaluator.isDue(
          now: now,
          scheduledAt: now,
          policy: ReviewDuePolicy.afterScheduledTime,
        ),
        isFalse,
      );
      expect(
        evaluator.isDue(
          now: now,
          scheduledAt: now.add(const Duration(seconds: 1)),
          policy: ReviewDuePolicy.afterScheduledTime,
        ),
        isFalse,
      );
      expect(
        evaluator.isDue(
          now: now,
          scheduledAt: now.subtract(const Duration(seconds: 1)),
          policy: ReviewDuePolicy.afterScheduledTime,
        ),
        isTrue,
      );
    });
  });
}
