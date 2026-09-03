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
      completedPages: {for (var page = 1; page <= currentPage; page++) page},
      targetPagesPerDay: 4,
      targetDays: 151,
      startDate: DateTime(2026, 1, 1),
      expectedEndDate: DateTime(2026, 6, 1),
    );
  }

  group('KhatmahPlan', () {
    test('recordPage records a jump without filling skipped pages', () {
      final updated = makePlan().recordPage(100);

      expect(updated.completedPages, {100});
      expect(updated.currentPage, 0);
      expect(updated.nextUnreadPage, 1);
      expect(updated.isComplete, isFalse);
    });

    test('copyWith cursor input cannot invent or erase explicit coverage', () {
      final plan = makePlan().recordPage(100);
      final copied = plan.copyWith(currentPage: 604);

      expect(copied.completedPages, {100});
      expect(copied.currentPage, 0);
    });

    test(
      'equality and hash code are stable across coverage insertion order',
      () {
        final first = makePlan().recordPage(1).recordPage(100);
        final sameCoverageDifferentOrder = makePlan()
            .recordPage(100)
            .recordPage(1);
        final differentCoverage = makePlan().recordPage(1).recordPage(2);

        expect(first, sameCoverageDifferentOrder);
        expect(first.hashCode, sameCoverageDifferentOrder.hashCode);
        expect(first, isNot(differentCoverage));
      },
    );

    test('normalizes completed pages to an immutable Quran page set', () {
      final plan = KhatmahPlan(
        id: 'normalized',
        title: 'Normalized',
        completedPages: [0, 1, 1, 605],
        targetPagesPerDay: 4,
        targetDays: 151,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 6, 1),
      );

      expect(plan.completedPages, {1});
      expect(() => plan.completedPages.add(2), throwsUnsupportedError);
    });

    test('keeps page 2 as next unread after pages 1 and 100 are recorded', () {
      final updated = makePlan().recordPage(1).recordPage(100);

      expect(updated.currentPage, 1);
      expect(updated.nextUnreadPage, 2);
    });

    test('re-recording a page is idempotent', () {
      final once = makePlan().recordPage(10);
      final twice = once.recordPage(10);

      expect(twice, once);
      expect(twice.completedPages, {10});
    });

    test('recording an earlier page never erases progress', () {
      final updated = makePlan().recordPage(100).recordPage(50);

      expect(updated.completedPages, {50, 100});
    });

    test('is complete only after every Quran page has explicit coverage', () {
      final incomplete = makePlan().recordPage(604);
      final complete = makePlan().recordThroughPage(604);

      expect(incomplete.isComplete, isFalse);
      expect(complete.isComplete, isTrue);
      expect(complete.currentPage, 604);
    });

    test('completedPagesCount is 0 when no pages read', () {
      expect(makePlan(currentPage: 0).completedPagesCount, 0);
    });

    test('completedPagesCount correct after reading', () {
      expect(makePlan(currentPage: 10).completedPagesCount, 10);
    });

    test(
      'completedPagesCount ignores the legacy startPage compatibility field',
      () {
        expect(
          makePlan(currentPage: 15, startPage: 11).completedPagesCount,
          15,
        );
        expect(makePlan(currentPage: 5, startPage: 10).completedPagesCount, 5);
      },
    );

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
        completedPages: {for (var page = 1; page <= 50; page++) page},
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
        DateTime(resumeTime.year, resumeTime.month, resumeTime.day + 150),
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
