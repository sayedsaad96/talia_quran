import 'package:flutter_test/flutter_test.dart';

import 'package:talia_quran/core/memorization/micro_review_picker.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';

AyahReviewRecord _record(
  int surahId,
  int ayahNumber, {
  int strengthLevel = 4,
  required DateTime lastReviewedAt,
  required DateTime nextReviewDate,
}) {
  return AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel,
    intervalDays: 7,
    lastReviewedAt: lastReviewedAt,
    nextReviewDate: nextReviewDate,
    totalReviews: 3,
    lastRating: PerformanceRating.excellent,
  );
}

void main() {
  const picker = MicroReviewPicker();
  final now = DateTime(2025, 9, 19, 10, 0);

  group('MicroReviewPicker — eligibility', () {
    test('returns null when there are no records', () {
      expect(picker.pick(records: const [], now: now), isNull);
    });

    test('ignores ayahs never memorized (strength 0)', () {
      final pick = picker.pick(
        records: [
          _record(
            2,
            255,
            strengthLevel: 0,
            lastReviewedAt: DateTime(2025, 8, 1),
            nextReviewDate: now.add(const Duration(days: 3)),
          ),
        ],
        now: now,
      );
      expect(pick, isNull);
    });

    test('falls back to memorized ayahs when none are upcoming', () {
      final pick = picker.pick(
        records: [
          _record(
            2,
            255,
            lastReviewedAt: DateTime(2025, 8, 1),
            nextReviewDate: now.subtract(const Duration(days: 2)),
          ),
        ],
        now: now,
      );
      expect(pick, isNotNull);
      expect(pick!.surahId, equals(2));
      expect(pick.ayahNumber, equals(255));
    });
  });

  group('MicroReviewPicker — preference & stability', () {
    test('prefers an upcoming ayah over a due one', () {
      final pick = picker.pick(
        records: [
          _record(
            18,
            1,
            lastReviewedAt: DateTime(2025, 7, 1), // oldest
            nextReviewDate: now.subtract(const Duration(days: 1)), // due
          ),
          _record(
            2,
            255,
            lastReviewedAt: DateTime(2025, 8, 1),
            nextReviewDate: now.add(const Duration(days: 3)), // upcoming
          ),
        ],
        now: now,
      );
      expect(pick!.surahId, equals(2), reason: 'due ayahs belong to the hero');
    });

    test('is stable for the whole day and rotates across days', () {
      final records = [
        _record(
          18,
          1,
          lastReviewedAt: DateTime(2025, 7, 1),
          nextReviewDate: now.add(const Duration(days: 2)),
        ),
        _record(
          2,
          255,
          lastReviewedAt: DateTime(2025, 7, 2),
          nextReviewDate: now.add(const Duration(days: 2)),
        ),
        _record(
          36,
          1,
          lastReviewedAt: DateTime(2025, 7, 3),
          nextReviewDate: now.add(const Duration(days: 2)),
        ),
      ];

      final morning = picker.pick(
        records: records,
        now: DateTime(2025, 9, 19, 6, 0),
      );
      final night = picker.pick(
        records: records,
        now: DateTime(2025, 9, 19, 23, 30),
      );
      expect(morning, equals(night), reason: 'same day → same ayah');

      final nextDay = picker.pick(
        records: records,
        now: DateTime(2025, 9, 20, 10, 0),
      );
      expect(nextDay, isNotNull);
    });

    test('picks among the oldest reviewed candidates', () {
      final records = [
        _record(
          18,
          1,
          lastReviewedAt: DateTime(2025, 7, 1), // oldest
          nextReviewDate: now.add(const Duration(days: 2)),
        ),
        _record(
          2,
          255,
          lastReviewedAt: DateTime(2025, 8, 20), // newest
          nextReviewDate: now.add(const Duration(days: 2)),
        ),
      ];
      final pick = picker.pick(records: records, now: now);
      expect(pick!.surahId, equals(18), reason: 'oldest memory first');
    });
  });
}
