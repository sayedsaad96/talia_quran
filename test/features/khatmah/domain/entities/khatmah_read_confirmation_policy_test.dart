import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_read_confirmation_policy.dart';

void main() {
  final today = DateTime(2026, 10, 24);
  final plan = KhatmahPlan(
    id: 'five-pages',
    title: 'Five pages',
    targetPagesPerDay: 5,
    targetDays: 121,
    startDate: today,
    expectedEndDate: DateTime(2027, 2, 21),
    dailyTargetDate: today,
    dailyTargetStartPage: 1,
    dailyTargetEndPage: 5,
  );

  // End-1, end, end+1: only the boundary page needs a deliberate action.
  for (final entry in [(4, false), (5, true), (6, false)]) {
    test('page ${entry.$1} confirmation at daily target boundary', () {
      expect(requiresKhatmahReadConfirmation(plan, entry.$1, today), entry.$2);
    });
  }

  test(
    'last missing earlier page requires confirmation after out-of-order reading',
    () {
      final outOfOrder = plan.copyWith(completedPages: {2, 3, 4, 5});
      expect(requiresKhatmahReadConfirmation(outOfOrder, 1, today), isTrue);
    },
  );

  test('already persisted final page needs no new confirmation', () {
    expect(
      requiresKhatmahReadConfirmation(
        plan.copyWith(completedPages: {5}),
        5,
        today,
      ),
      isFalse,
    );
  });

  for (final lastPage in [24, 604]) {
    test('last whole-plan page $lastPage requires confirmation', () {
      final nearlyComplete = plan.copyWith(
        completedPages: {
          for (var page = 1; page <= 604; page++)
            if (page != lastPage) page,
        },
      );
      expect(
        requiresKhatmahReadConfirmation(nearlyComplete, lastPage, today),
        isTrue,
      );
    });
  }

  test('date rollover uses the new target instead of the expired anchor', () {
    final nextDay = DateTime(2026, 10, 25);
    final read = plan.copyWith(completedPages: {1, 2, 3, 4, 5});
    expect(requiresKhatmahReadConfirmation(read, 9, nextDay), isFalse);
    expect(requiresKhatmahReadConfirmation(read, 10, nextDay), isTrue);
  });
}
