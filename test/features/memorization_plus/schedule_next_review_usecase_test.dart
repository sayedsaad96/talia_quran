/// schedule_next_review_usecase_test.dart
///
/// Unit tests for ScheduleNextReviewUsecase (SM-2 spaced-repetition scheduler).
/// Covers: UTC date policy, strength progression, interval caps/floor,
/// rating effects, totalReviews increment, and midnight boundary safety.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

const _scheduler = ScheduleNextReviewUsecase();

/// Fresh review record at strength-0 / interval-0 — represents a brand-new ayah.
AyahReviewRecordModel _newRecord({
  int surahId = 1,
  int ayahNumber = 1,
  int strengthLevel = 0,
  int intervalDays = 0,
  int totalReviews = 0,
}) => AyahReviewRecordModel(
  surahId: surahId,
  ayahNumber: ayahNumber,
  strengthLevel: strengthLevel,
  intervalDays: intervalDays,
  lastReviewedAt: DateTime.now().toUtc(),
  nextReviewDate: DateTime.now().toUtc(),
  totalReviews: totalReviews,
  lastRating: null,
);

void main() {
  // ─── AyahReviewRecordModel.initial() ───────────────────────────────────────

  group('AyahReviewRecordModel.initial() — UTC seed', () {
    test('lastReviewedAt is UTC', () {
      final record = AyahReviewRecordModel.initial(1, 1);
      expect(
        record.lastReviewedAt.isUtc,
        isTrue,
        reason: '.initial() must produce UTC dates',
      );
    });

    test('nextReviewDate is UTC', () {
      final record = AyahReviewRecordModel.initial(1, 1);
      expect(record.nextReviewDate.isUtc, isTrue);
    });

    test('starts with strength 0 and 0 reviews', () {
      final record = AyahReviewRecordModel.initial(2, 5);
      expect(record.strengthLevel, equals(0));
      expect(record.totalReviews, equals(0));
      expect(record.intervalDays, equals(0));
      expect(record.lastRating, isNull);
    });
  });

  // ─── ScheduleNextReviewUsecase — UTC dates ─────────────────────────────────

  group('ScheduleNextReviewUsecase — UTC date policy', () {
    test('schedule(excellent) produces UTC lastReviewedAt', () {
      final updated = _scheduler.schedule(
        _newRecord(),
        PerformanceRating.excellent,
      );
      expect(updated.lastReviewedAt.isUtc, isTrue);
    });

    test('schedule(excellent) produces UTC nextReviewDate', () {
      final updated = _scheduler.schedule(
        _newRecord(),
        PerformanceRating.excellent,
      );
      expect(updated.nextReviewDate.isUtc, isTrue);
    });

    test('schedule(average) produces UTC dates', () {
      final updated = _scheduler.schedule(
        _newRecord(),
        PerformanceRating.average,
      );
      expect(updated.lastReviewedAt.isUtc, isTrue);
      expect(updated.nextReviewDate.isUtc, isTrue);
    });

    test('schedule(weak) produces UTC dates', () {
      final updated = _scheduler.schedule(_newRecord(), PerformanceRating.weak);
      expect(updated.lastReviewedAt.isUtc, isTrue);
      expect(updated.nextReviewDate.isUtc, isTrue);
    });

    test('nextReviewDate is >= lastReviewedAt for all ratings', () {
      for (final rating in PerformanceRating.values) {
        final updated = _scheduler.schedule(_newRecord(), rating);
        expect(
          updated.nextReviewDate.millisecondsSinceEpoch >=
              updated.lastReviewedAt.millisecondsSinceEpoch,
          isTrue,
          reason: 'nextReviewDate must be >= lastReviewedAt for $rating',
        );
      }
    });
  });

  // ─── ScheduleNextReviewUsecase — strength progression ─────────────────────

  group('ScheduleNextReviewUsecase — strength progression', () {
    test('excellent increases strength by 1', () {
      final base = _newRecord(strengthLevel: 3);
      final updated = _scheduler.schedule(base, PerformanceRating.excellent);
      expect(updated.strengthLevel, equals(4));
    });

    test('average does not change strength', () {
      final base = _newRecord(strengthLevel: 5);
      final updated = _scheduler.schedule(base, PerformanceRating.average);
      expect(updated.strengthLevel, equals(5));
    });

    test('weak decreases strength by 1', () {
      final base = _newRecord(strengthLevel: 4);
      final updated = _scheduler.schedule(base, PerformanceRating.weak);
      expect(updated.strengthLevel, equals(3));
    });

    test('weak at strength 0 stays at 0 (clamp)', () {
      final updated = _scheduler.schedule(
        _newRecord(strengthLevel: 0),
        PerformanceRating.weak,
      );
      expect(updated.strengthLevel, equals(0));
    });

    test('excellent at strength 9 caps at 10', () {
      final updated = _scheduler.schedule(
        _newRecord(strengthLevel: 9),
        PerformanceRating.excellent,
      );
      expect(updated.strengthLevel, equals(10));
    });

    test('excellent at strength 10 stays at 10 (clamp)', () {
      final updated = _scheduler.schedule(
        _newRecord(strengthLevel: 10),
        PerformanceRating.excellent,
      );
      expect(updated.strengthLevel, equals(10));
    });
  });

  // ─── ScheduleNextReviewUsecase — interval logic (V3.2) ─────────────────────

  group('ScheduleNextReviewUsecase — interval logic (V3.2)', () {
    test('first review (strength 0, interval 0) → excellent → 1 day (no fuzz/overdue)', () {
      final updated = _scheduler.schedule(
        _newRecord(),
        PerformanceRating.excellent,
      );
      expect(updated.intervalDays, equals(1));
    });

    test('first review (strength 0, interval 0) → weak → 1 day', () {
      final updated = _scheduler.schedule(_newRecord(), PerformanceRating.weak);
      expect(updated.intervalDays, equals(1));
    });

    test('interval 100, excellent caps at 180', () {
      final base = _newRecord(strengthLevel: 9, intervalDays: 100);
      final updated = _scheduler.schedule(base, PerformanceRating.excellent);
      expect(updated.intervalDays, equals(180));
    });

    test('interval 70, average caps at 90', () {
      final base = _newRecord(strengthLevel: 5, intervalDays: 70);
      final updated = _scheduler.schedule(base, PerformanceRating.average);
      expect(updated.intervalDays, equals(90));
    });
  });

  group('ScheduleNextReviewUsecase — Deterministic Fuzzing', () {
    test('same input produces same fuzzed output', () {
      final base = _newRecord(strengthLevel: 2, intervalDays: 30, ayahNumber: 15);
      final u1 = _scheduler.schedule(base, PerformanceRating.excellent);
      final u2 = _scheduler.schedule(base, PerformanceRating.excellent);
      expect(u1.intervalDays, equals(u2.intervalDays));
    });

    test('fuzz stays within ±5% of raw interval', () {
      // 30 * 2.65 = 79.5 -> 80 raw. Fuzz range: 76 to 84
      final base = _newRecord(strengthLevel: 2, intervalDays: 30, ayahNumber: 15);
      final updated = _scheduler.schedule(base, PerformanceRating.excellent);
      expect(updated.intervalDays, greaterThanOrEqualTo(76));
      expect(updated.intervalDays, lessThanOrEqualTo(84));
    });

    test('weak logic bypasses fuzzing completely', () {
      final weakBase = _newRecord(strengthLevel: 2, intervalDays: 14); // 14 * 0.3 = 4.2 -> 4.
      final weakUpdated = _scheduler.schedule(weakBase, PerformanceRating.weak);
      expect(weakUpdated.intervalDays, equals(4));
    });
  });

  group('ScheduleNextReviewUsecase — Overdue Compensation & Fragile Protection', () {
    test('interval 1: max base is 2', () {
      final base = _newRecord(strengthLevel: 1, intervalDays: 1, ayahNumber: 1);
      final nowOverride = base.lastReviewedAt.add(const Duration(days: 30));
      final updated = _scheduler.schedule(base, PerformanceRating.excellent, nowOverride);
      // effectiveBase = 2. newEaseFactor = 2.65. rawInterval = 5.
      expect(updated.intervalDays, equals(5));
    });

    test('interval 3: max base is 6', () {
      final base = _newRecord(strengthLevel: 2, intervalDays: 3, ayahNumber: 1);
      final nowOverride = base.lastReviewedAt.add(const Duration(days: 30));
      final updated = _scheduler.schedule(base, PerformanceRating.excellent, nowOverride);
      // effectiveBase = 6. newEaseFactor = 2.65. rawInterval = 16.
      expect(updated.intervalDays, greaterThanOrEqualTo(15));
      expect(updated.intervalDays, lessThanOrEqualTo(17));
    });

    test('interval 7: max base is 14', () {
      final base = _newRecord(strengthLevel: 3, intervalDays: 7, ayahNumber: 1);
      final nowOverride = base.lastReviewedAt.add(const Duration(days: 30));
      final updated = _scheduler.schedule(base, PerformanceRating.excellent, nowOverride);
      // effectiveBase = 14. newEaseFactor = 2.65. rawInterval = 37.
      expect(updated.intervalDays, greaterThanOrEqualTo(35));
      expect(updated.intervalDays, lessThanOrEqualTo(39));
    });

    test('interval 10: max base is 20', () {
      final base = _newRecord(strengthLevel: 4, intervalDays: 10, ayahNumber: 1);
      final nowOverride = base.lastReviewedAt.add(const Duration(days: 30));
      final updated = _scheduler.schedule(base, PerformanceRating.excellent, nowOverride);
      // effectiveBase = 20. newEaseFactor = 2.65. rawInterval = 53.
      expect(updated.intervalDays, greaterThanOrEqualTo(50));
      expect(updated.intervalDays, lessThanOrEqualTo(56));
    });

    test('interval 14+: full compensation allowed (Case A)', () {
      final base = _newRecord(strengthLevel: 4, intervalDays: 14, ayahNumber: 1);
      final nowOverride = base.lastReviewedAt.add(const Duration(days: 30)); // 30 elapsed
      final updated = _scheduler.schedule(base, PerformanceRating.excellent, nowOverride);
      // effectiveBase = 30. newEaseFactor = 2.65. rawInterval = 80.
      expect(updated.intervalDays, greaterThanOrEqualTo(76));
      expect(updated.intervalDays, lessThanOrEqualTo(84));
    });

    test('Case B: interval 20, elapsed 40, average', () {
      final base = _newRecord(strengthLevel: 4, intervalDays: 20, ayahNumber: 1);
      final nowOverride = base.lastReviewedAt.add(const Duration(days: 40));
      final updated = _scheduler.schedule(base, PerformanceRating.average, nowOverride);
      // effectiveBase = 40. newEaseFactor = 2.40. multiplier = 1.4. rawInterval = 56.
      expect(updated.intervalDays, greaterThanOrEqualTo(53));
      expect(updated.intervalDays, lessThanOrEqualTo(59));
    });

    test('Case C: interval 60, elapsed 120, weak', () {
      final base = _newRecord(strengthLevel: 4, intervalDays: 60, ayahNumber: 1);
      final nowOverride = base.lastReviewedAt.add(const Duration(days: 120));
      final updated = _scheduler.schedule(base, PerformanceRating.weak, nowOverride);
      // effectiveBase NOT USED. Soft lapse on 60: max(3, 60 * 0.3) = 18.
      expect(updated.intervalDays, equals(18));
    });
  });

  group('ScheduleNextReviewUsecase — Large Corpus Distribution', () {
    test('fuzzing distributes 1000 ayahs across multiple days', () {
      final records = List.generate(1000, (i) {
        return _newRecord(strengthLevel: 3, intervalDays: 30, ayahNumber: i + 1);
      });

      final scheduledIntervals = <int>[];
      for (final record in records) {
        final updated = _scheduler.schedule(record, PerformanceRating.excellent);
        scheduledIntervals.add(updated.intervalDays);
      }

      final uniqueIntervals = scheduledIntervals.toSet();
      
      // If we didn't have fuzzing, all 1000 ayahs would have exactly interval = 80.
      // With fuzzing, they should be distributed between 76 and 84.
      expect(uniqueIntervals.length, greaterThan(1), reason: 'Intervals should be dispersed');
      expect(uniqueIntervals.length, lessThanOrEqualTo(9), reason: 'Fuzzing range is restricted');
    });
  });

  // ─── ScheduleNextReviewUsecase — totalReviews & lastRating ────────────────

  group('ScheduleNextReviewUsecase — review meta', () {
    test('totalReviews increments on each call', () {
      final r1 = _scheduler.schedule(_newRecord(), PerformanceRating.average);
      expect(r1.totalReviews, equals(1));
      // schedule() returns AyahReviewRecord (domain entity) — pass it directly.
      final r2 = _scheduler.schedule(r1, PerformanceRating.average);
      expect(r2.totalReviews, equals(2));
    });

    test('lastRating is set to the given rating', () {
      for (final rating in PerformanceRating.values) {
        final updated = _scheduler.schedule(_newRecord(), rating);
        expect(updated.lastRating, equals(rating));
      }
    });
  });

  // ─── Midnight boundary safety ──────────────────────────────────────────────

  group('midnight boundary safety', () {
    test('lastReviewedAt is within 2 seconds of current UTC time', () {
      final before = DateTime.now().toUtc().subtract(
        const Duration(seconds: 2),
      );
      final updated = _scheduler.schedule(
        _newRecord(),
        PerformanceRating.average,
      );
      final after = DateTime.now().toUtc().add(const Duration(seconds: 2));

      expect(
        updated.lastReviewedAt.isAfter(before) &&
            updated.lastReviewedAt.isBefore(after),
        isTrue,
        reason: 'lastReviewedAt must be close to current UTC time',
      );
    });

    test(
      'nextReviewDate is strictly after lastReviewedAt for non-zero intervals',
      () {
        final base = _newRecord(strengthLevel: 3, intervalDays: 5);
        final updated = _scheduler.schedule(base, PerformanceRating.excellent);
        expect(updated.nextReviewDate.isAfter(updated.lastReviewedAt), isTrue);
      },
    );
  });
}
