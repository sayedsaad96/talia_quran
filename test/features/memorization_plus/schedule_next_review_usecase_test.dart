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

  // ─── ScheduleNextReviewUsecase — interval logic ────────────────────────────

  group('ScheduleNextReviewUsecase — interval logic', () {
    test('first review (strength 0, interval 0) → excellent → 1 day', () {
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

    test('interval 4, excellent → 10 days (4 × 2.5)', () {
      final base = _newRecord(strengthLevel: 2, intervalDays: 4);
      final updated = _scheduler.schedule(base, PerformanceRating.excellent);
      expect(updated.intervalDays, equals(10));
    });

    test('interval 100, excellent caps at 180', () {
      final base = _newRecord(strengthLevel: 9, intervalDays: 100);
      final updated = _scheduler.schedule(base, PerformanceRating.excellent);
      expect(updated.intervalDays, equals(180));
    });

    test('weak always resets interval to 1', () {
      final base = _newRecord(strengthLevel: 7, intervalDays: 60);
      final updated = _scheduler.schedule(base, PerformanceRating.weak);
      expect(updated.intervalDays, equals(1));
    });

    test('interval 20, average → 30 days (20 × 1.5)', () {
      final base = _newRecord(strengthLevel: 4, intervalDays: 20);
      final updated = _scheduler.schedule(base, PerformanceRating.average);
      expect(updated.intervalDays, equals(30));
    });

    test('interval 70, average caps at 90', () {
      final base = _newRecord(strengthLevel: 5, intervalDays: 70);
      final updated = _scheduler.schedule(base, PerformanceRating.average);
      expect(updated.intervalDays, equals(90));
    });

    test('nextReviewDate matches the calculated interval in UTC days', () {
      final base = _newRecord(strengthLevel: 4, intervalDays: 20);
      final updated = _scheduler.schedule(base, PerformanceRating.average);

      expect(updated.nextReviewDate.isUtc, isTrue);
      expect(
        updated.nextReviewDate.difference(updated.lastReviewedAt).inDays,
        equals(updated.intervalDays),
      );
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
