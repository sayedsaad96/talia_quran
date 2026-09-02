import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';

void main() {
  KhatmahPlan makePlan({int currentPage = 0, int startPage = 1}) {
    return KhatmahPlan(
      id: 'test-id',
      title: 'Test Khatmah',
      startPage: startPage,
      currentPage: currentPage,
      targetPagesPerDay: 4,
      targetDays: 151,
      startDate: DateTime(2026, 1, 1),
      expectedEndDate: DateTime(2026, 6, 1),
    );
  }

  group('KhatmahPlan', () {
    test('completedPagesCount is 0 when no pages read', () {
      expect(makePlan(currentPage: 0).completedPagesCount, 0);
    });

    test('completedPagesCount correct after reading', () {
      expect(makePlan(currentPage: 10).completedPagesCount, 10);
    });

    test('completedPagesCount with custom startPage', () {
      expect(makePlan(currentPage: 15, startPage: 11).completedPagesCount, 5);
      expect(makePlan(currentPage: 5, startPage: 10).completedPagesCount, 0);
    });

    test('progressPercentage at halfway', () {
      expect(makePlan(currentPage: 302).progressPercentage, closeTo(0.5, 0.01));
    });

    test('progressPercentage at start', () {
      expect(makePlan(currentPage: 0).progressPercentage, 0.0);
    });

    test('progressPercentage at end', () {
      expect(makePlan(currentPage: 604).progressPercentage, 1.0);
    });

    test('remainingPages correct', () {
      expect(makePlan(currentPage: 100).remainingPages, 504);
      expect(makePlan(currentPage: 0).remainingPages, 604);
      expect(makePlan(currentPage: 604).remainingPages, 0);
    });

    test('copyWith returns updated plan', () {
      final plan = makePlan();
      final updated = plan.copyWith(
        currentPage: 50,
        status: KhatmahStatus.paused,
        dedication: const KhatmahDedication(
          isDedicated: true,
          recipientName: 'Mother',
          condition: DedicationCondition.alive,
        ),
      );
      expect(updated.currentPage, 50);
      expect(updated.id, plan.id);
      expect(updated.status, KhatmahStatus.paused);
      expect(updated.dedication.recipientName, 'Mother');
      expect(updated.dedication.condition, DedicationCondition.alive);
    });

    test('equality works with Equatable', () {
      final plan1 = makePlan();
      final plan2 = makePlan();
      expect(plan1, equals(plan2));
    });
  });

  group('KhatmahDedication', () {
    test('default dedication has isDedicated false and none constant', () {
      const dedication = KhatmahDedication();
      expect(dedication.isDedicated, false);
      expect(dedication.recipientName, isNull);
      expect(dedication.relationship, isNull);
      expect(dedication.condition, isNull);
      expect(dedication.customNote, isNull);
      expect(KhatmahDedication.none, equals(dedication));
    });

    test('props equality works', () {
      const d1 = KhatmahDedication(
        isDedicated: true,
        recipientName: 'Father',
        condition: DedicationCondition.deceased,
      );
      const d2 = KhatmahDedication(
        isDedicated: true,
        recipientName: 'Father',
        condition: DedicationCondition.deceased,
      );
      expect(d1, equals(d2));
    });
  });
}
