import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_scheduling_engine.dart';

void main() {
  group('KhatmahSchedulingEngine', () {
    test(
      'end date is a local calendar date across the Cairo DST transition',
      () {
        expect(
          KhatmahSchedulingEngine.calculateEndDate(
            DateTime(2026, 4, 23, 12),
            3,
          ),
          DateTime(2026, 4, 25),
        );
        expect(
          KhatmahSchedulingEngine.elapsedCalendarDays(
            DateTime(2026, 4, 23, 12),
            DateTime(2026, 4, 24, 12),
          ),
          2,
        );
      },
    );
    test('calculateDaysFromPages returns ceil(remaining/perDay)', () {
      expect(KhatmahSchedulingEngine.calculateDaysFromPages(604, 2), 302);
      expect(KhatmahSchedulingEngine.calculateDaysFromPages(604, 4), 151);
      expect(KhatmahSchedulingEngine.calculateDaysFromPages(604, 10), 61);
      expect(KhatmahSchedulingEngine.calculateDaysFromPages(604, 20), 31);
      expect(KhatmahSchedulingEngine.calculateDaysFromPages(5, 3), 2);
    });

    test('calculatePagesFromDays returns ceil(remaining/days)', () {
      expect(KhatmahSchedulingEngine.calculatePagesFromDays(604, 30), 21);
      expect(KhatmahSchedulingEngine.calculatePagesFromDays(604, 60), 11);
      expect(KhatmahSchedulingEngine.calculatePagesFromDays(604, 365), 2);
    });

    test('calculateEndDate includes the start date', () {
      final start = DateTime(2026, 1, 1);
      expect(
        KhatmahSchedulingEngine.calculateEndDate(start, 31),
        DateTime(2026, 1, 31),
      );
      expect(KhatmahSchedulingEngine.calculateEndDate(start, 1), start);
    });

    test('todaysWird returns correct page range', () {
      final wird = KhatmahSchedulingEngine.todaysWird(0, 4);
      expect(wird.startPage, 1);
      expect(wird.endPage, 4);
    });

    test('todaysWird clamps endPage to 604', () {
      final wird = KhatmahSchedulingEngine.todaysWird(602, 10);
      expect(wird.startPage, 603);
      expect(wird.endPage, 604);
    });

    test('todaysWird when already at 604', () {
      final wird = KhatmahSchedulingEngine.todaysWird(604, 4);
      expect(wird.startPage, 604);
      expect(wird.endPage, 604);
    });

    test('todaysWird handles non-positive targetPagesPerDay gracefully', () {
      final wird0 = KhatmahSchedulingEngine.todaysWird(10, 0);
      expect(wird0.startPage, 11);
      expect(wird0.endPage, 11);

      final wirdNeg = KhatmahSchedulingEngine.todaysWird(10, -5);
      expect(wirdNeg.startPage, 11);
      expect(wirdNeg.endPage, 11);
    });

    test(
      'recalculateAfterResume calculates exact end date when fromDate is provided',
      () {
        final fixedDate = DateTime(2026, 3, 1);
        final resumed = KhatmahSchedulingEngine.recalculateAfterResume(
          604,
          4,
          fixedDate,
        );
        expect(resumed, DateTime(2026, 7, 29));
      },
    );

    test(
      'recalculateAfterResume defaults to DateTime.now() when fromDate is omitted',
      () {
        final now = DateTime.now();
        final resumed = KhatmahSchedulingEngine.recalculateAfterResume(604, 4);
        final diff = resumed.difference(now).inDays;
        expect(diff, inInclusiveRange(149, 150));
      },
    );

    test(
      'calculateDaysFromPages handles 0 or negative pagesPerDay gracefully',
      () {
        expect(KhatmahSchedulingEngine.calculateDaysFromPages(100, 0), 100);
        expect(KhatmahSchedulingEngine.calculateDaysFromPages(100, -1), 100);
      },
    );

    test(
      'calculatePagesFromDays handles 0 or negative targetDays gracefully',
      () {
        expect(KhatmahSchedulingEngine.calculatePagesFromDays(100, 0), 100);
        expect(KhatmahSchedulingEngine.calculatePagesFromDays(100, -1), 100);
      },
    );
  });
}
