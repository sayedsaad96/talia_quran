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

  group('pace (K-U5)', () {
    KhatmahPlan paced({required int read}) => KhatmahPlan(
      id: 'p',
      title: 'P',
      completedPages: {for (var page = 1; page <= read; page++) page},
      targetPagesPerDay: 4,
      targetDays: 151,
      startDate: DateTime(2026, 1, 1),
      expectedEndDate: DateTime(2026, 1, 10),
    );

    test('behind when remaining pages exceed what the pace can cover', () {
      // Jan 6: 5 days left (6..10) x 4 = 20 pages of capacity.
      final plan = paced(read: 560); // 44 remaining
      expect(plan.pagesBehind(DateTime(2026, 1, 6, 9)), 24);
    });

    test('on schedule when the pace covers the remaining pages', () {
      final plan = paced(read: 590); // 14 remaining
      expect(plan.pagesBehind(DateTime(2026, 1, 6, 9)), 0);
    });
  });

  group('starting from a chosen page (C7)', () {
    KhatmahPlan from(int startPage, Iterable<int> read) => KhatmahPlan(
      id: 's',
      title: 'S',
      startPage: startPage,
      completedPages: read,
      targetPagesPerDay: 4,
      targetDays: 151,
      startDate: DateTime(2026, 1, 1),
      expectedEndDate: DateTime(2026, 6, 1),
    );

    test('reading begins at the start page', () {
      final plan = from(300, const []);
      expect(plan.nextUnreadPage, 300);
      expect(plan.dailyTargetFor(DateTime(2026, 1, 1)), (
        startPage: 300,
        endPage: 303,
      ));
      expect(plan.currentPage, 0);
    });

    test('progress follows the reading order from the start page', () {
      final plan = from(300, [for (var p = 300; p <= 310; p++) p]);
      expect(plan.nextUnreadPage, 311);
      expect(plan.currentPage, 310);
    });

    test('after page 604 it wraps to page 1', () {
      final plan = from(300, [for (var p = 300; p <= 604; p++) p]);
      expect(plan.nextUnreadPage, 1);
      expect(plan.currentPage, 604);
      expect(plan.isComplete, isFalse);
    });

    test('the khatmah completes only when every page is read', () {
      final plan = from(300, [for (var p = 1; p <= 604; p++) p]);
      expect(plan.isComplete, isTrue);
      expect(plan.nextUnreadPage, 605);
    });

    test('starting at page 1 keeps the original behaviour', () {
      final plan = from(1, [1, 2, 3, 5]);
      expect(plan.nextUnreadPage, 4);
      expect(plan.currentPage, 3);
    });
  });

  group('pagesThrough (wrap-aware)', () {
    KhatmahPlan planFrom(int start, Set<int> read) => KhatmahPlan(
      id: 'p',
      title: KhatmahPlan.defaultTitle,
      startPage: start,
      completedPages: read,
      targetPagesPerDay: 5,
      targetDays: 121,
      startDate: DateTime(2026, 1, 1),
      expectedEndDate: DateTime(2026, 5, 1),
    );

    test('continues across 604 to page 1', () {
      final plan = planFrom(300, {for (var p = 300; p <= 600; p++) p});
      expect(plan.pagesThrough(3), [601, 602, 603, 604, 1, 2, 3]);
    });

    test('already-read page in reading order yields nothing', () {
      final plan = planFrom(300, {
        for (var p = 300; p <= 604; p++) p,
        for (var p = 1; p <= 9; p++) p,
      });
      expect(plan.nextUnreadPage, 10);
      expect(plan.pagesThrough(350), isEmpty);
      expect(plan.pagesThrough(10), [10]);
    });

    test('plain plan from page 1', () {
      final plan = planFrom(1, {1, 2});
      expect(plan.pagesThrough(5), [3, 4, 5]);
      expect(plan.pagesThrough(0), isEmpty);
      expect(plan.pagesThrough(605), isEmpty);
    });

    test('recordThroughPage wraps too', () {
      final plan = planFrom(600, {600, 601, 602, 603, 604});
      expect(plan.recordThroughPage(2).completedPages, containsAll([1, 2]));
    });
  });

  group('juz wird', () {
    KhatmahPlan juzPlan(Set<int> read, {DateTime? end}) => KhatmahPlan(
      id: 'r',
      title: KhatmahPlan.defaultTitle,
      wirdUnit: KhatmahWirdUnit.juz,
      completedPages: read,
      targetPagesPerDay: 21,
      targetDays: 30,
      startDate: DateTime(2026, 2, 18),
      expectedEndDate: end ?? DateTime(2026, 3, 19),
    );

    test('daily target is the rest of the current juz', () {
      expect(
        juzPlan({}).dailyTargetFor(DateTime(2026, 2, 18)),
        (startPage: 1, endPage: 21),
      );
      expect(
        juzPlan({
          for (var p = 1; p <= 25; p++) p,
        }).dailyTargetFor(DateTime(2026, 2, 19)),
        (startPage: 26, endPage: 41),
      );
    });

    test('last day with the 23-page final juz left is on track', () {
      final lastDay = juzPlan({for (var p = 1; p <= 581; p++) p});
      expect(lastDay.remainingJuzCount, 1);
      expect(lastDay.remainingWirdDays, 1);
      expect(lastDay.pagesBehind(DateTime(2026, 3, 19)), 0);
      expect(lastDay.pagesBehind(DateTime(2026, 3, 20)), 23);
    });

    test('two juz left with one day left is behind by the second juz', () {
      final plan = juzPlan({for (var p = 1; p <= 561; p++) p});
      expect(plan.pagesBehind(DateTime(2026, 3, 19)), 23);
    });

    test('pages mode keeps its page-count pace', () {
      final plan = KhatmahPlan(
        id: 'p',
        title: KhatmahPlan.defaultTitle,
        completedPages: const {1, 2, 3},
        targetPagesPerDay: 5,
        targetDays: 121,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 5, 1),
      );
      expect(plan.wirdUnit, KhatmahWirdUnit.pages);
      expect(plan.remainingWirdDays, 121);
    });
  });

  group('projection', () {
    test('projection counts from tomorrow once today is done', () {
      final plan = KhatmahPlan(
        id: 'p',
        title: KhatmahPlan.defaultTitle,
        completedPages: {for (var p = 1; p <= 20; p++) p},
        targetPagesPerDay: 5,
        targetDays: 121,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 5, 1),
        dailyTargetDate: DateTime(2026, 1, 1),
        dailyTargetStartPage: 1,
        dailyTargetEndPage: 5,
      );
      final today = DateTime(2026, 1, 1, 20);
      // 584 pages / 5 = 117 days starting 2026-01-02 → ends 2026-04-28.
      expect(plan.projectedEndDate(today), DateTime(2026, 4, 28));
      expect(plan.daysAhead(today), 3);
    });

    test('days ahead is never negative', () {
      final plan = KhatmahPlan(
        id: 'p',
        title: KhatmahPlan.defaultTitle,
        targetPagesPerDay: 5,
        targetDays: 121,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 1, 10),
      );
      expect(plan.daysAhead(DateTime(2026, 1, 1)), 0);
    });

    test('a fresh plan on its first day is not ahead', () {
      final plan = KhatmahPlan(
        id: 'p',
        title: KhatmahPlan.defaultTitle,
        targetPagesPerDay: 5,
        targetDays: 121,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 5, 1),
      );
      expect(plan.daysAhead(DateTime(2026, 1, 1, 9)), 0);
    });
  });

  test('juz progress and first unread page', () {
    final plan = KhatmahPlan(
      id: 'p',
      title: KhatmahPlan.defaultTitle,
      completedPages: {for (var p = 1; p <= 21; p++) p, 22, 30},
      targetPagesPerDay: 5,
      targetDays: 121,
      startDate: DateTime(2026, 1, 1),
      expectedEndDate: DateTime(2026, 5, 1),
    );
    expect(plan.juzProgress(1), (read: 21, total: 21));
    expect(plan.juzProgress(2), (read: 2, total: 20));
    expect(plan.juzProgress(30), (read: 0, total: 23));
    expect(plan.firstUnreadPageInJuz(2), 23);
    expect(plan.firstUnreadPageInJuz(1), 1);
  });
}
