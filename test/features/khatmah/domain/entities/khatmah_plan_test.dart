import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';

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

    test('copyWith clearPausedAt unsets pausedAt', () {
      final pausedPlan = makePlan().copyWith(
        status: KhatmahStatus.paused,
        pausedAt: DateTime(2026, 2, 1),
      );
      expect(pausedPlan.pausedAt, isNotNull);

      final resumedPlan = pausedPlan.copyWith(
        status: KhatmahStatus.active,
        clearPausedAt: true,
      );
      expect(resumedPlan.pausedAt, isNull);
      expect(resumedPlan.status, KhatmahStatus.active);
    });

    test('pause and resume helpers work correctly', () {
      final plan = makePlan();
      final pauseTime = DateTime(2026, 2, 1);
      final paused = plan.pause(at: pauseTime);
      expect(paused.status, KhatmahStatus.paused);
      expect(paused.pausedAt, pauseTime);

      final resumeTime = DateTime(2026, 2, 10);
      final resumed = paused.resume(fromDate: resumeTime);
      expect(resumed.status, KhatmahStatus.active);
      expect(resumed.pausedAt, isNull);
      expect(
        resumed.expectedEndDate,
        resumeTime.add(const Duration(days: 151)),
      );
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

  group('KhatmahHistoryEntry', () {
    test('creates entry and checks fields and equatable props', () {
      final entry1 = KhatmahHistoryEntry(
        id: 'hist-1',
        khatmahNumber: 1,
        title: 'Ramadan Khatmah',
        startDate: DateTime(2026, 1, 1),
        completedDate: DateTime(2026, 1, 30),
        totalDays: 30,
        dedication: const KhatmahDedication(
          isDedicated: true,
          recipientName: 'Father',
          condition: DedicationCondition.deceased,
        ),
        certificateId: 'cert-123',
      );

      final entry2 = KhatmahHistoryEntry(
        id: 'hist-1',
        khatmahNumber: 1,
        title: 'Ramadan Khatmah',
        startDate: DateTime(2026, 1, 1),
        completedDate: DateTime(2026, 1, 30),
        totalDays: 30,
        dedication: const KhatmahDedication(
          isDedicated: true,
          recipientName: 'Father',
          condition: DedicationCondition.deceased,
        ),
        certificateId: 'cert-123',
      );

      expect(entry1, equals(entry2));
      expect(entry1.khatmahNumber, 1);
      expect(entry1.totalDays, 30);
      expect(entry1.certificateId, 'cert-123');
      expect(entry1.dedication?.recipientName, 'Father');
    });
  });
}
