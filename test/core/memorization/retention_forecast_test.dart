import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/retention_forecast.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  final now = DateTime.utc(2026, 10, 19, 12);

  AyahReviewRecord record({
    int surah = 1,
    int ayah = 1,
    double stability = 10,
    int reviews = 1,
    DateTime? lastReviewedAt,
    DateTime? nextReviewDate,
  }) => AyahReviewRecord(
    surahId: surah,
    ayahNumber: ayah,
    strengthLevel: 4,
    intervalDays: 10,
    lastReviewedAt: lastReviewedAt ?? now,
    nextReviewDate: nextReviewDate ?? now.add(const Duration(days: 10)),
    totalReviews: reviews,
    lastRating: PerformanceRating.average,
    stability: stability,
  );

  Ayah ayah(int surah, int number, int page) => Ayah(
    number: number,
    surahId: surah,
    text: '',
    numberInSurah: number,
    page: page,
  );

  group('retrievabilityAt', () {
    test('uses the original exponential formula and fractional UTC days', () {
      final reviewed = DateTime.utc(2026, 10, 18, 0);
      final at = DateTime.utc(2026, 10, 19, 12);
      final result = retrievabilityAt(record(lastReviewedAt: reviewed), at);

      expect(result, closeTo(math.exp(-1.5 / 10), 1e-12));
    });

    test('returns NaN for non-positive stability', () {
      expect(retrievabilityAt(record(stability: 0), now).isNaN, isTrue);
      expect(retrievabilityAt(record(stability: -1), now).isNaN, isTrue);
    });
  });

  group('weakeningSoon', () {
    test('uses strict 0.80 and horizon boundaries', () {
      const horizon = Duration(days: 7);
      final below = record(ayah: 1, stability: 6 / -math.log(.8));
      final atThreshold = record(ayah: 2, stability: 7 / -math.log(.8));
      final above = record(ayah: 3, stability: 8 / -math.log(.8));

      final results = weakeningSoon(
        [below, atThreshold, above],
        now,
        horizon: horizon,
        ayahsBySurah: {
          1: [ayah(1, 1, 1), ayah(1, 2, 1), ayah(1, 3, 1)],
        },
      );
      expect(results, hasLength(1));
      expect(results.single.startAyah, 1);
    });

    test(
      'includes zero stability when scheduled inside horizon, but not due now',
      () {
        final results = weakeningSoon(
          [
            record(
              ayah: 1,
              stability: 0,
              nextReviewDate: now.add(const Duration(days: 7)),
            ),
            record(ayah: 2, stability: 0, nextReviewDate: now),
          ],
          now,
          ayahsBySurah: {
            1: [ayah(1, 1, 1), ayah(1, 2, 1)],
          },
        );
        expect(results, hasLength(1));
        expect(results.single.startAyah, 1);
      },
    );

    test(
      'groups consecutive canonical ayahs, respects pages, and limits to three',
      () {
        final records = [
          record(surah: 1, ayah: 1, stability: 1),
          record(surah: 1, ayah: 2, stability: 1),
          record(surah: 1, ayah: 3, stability: 1),
          record(surah: 1, ayah: 4, stability: 1),
          record(surah: 2, ayah: 1, stability: 1),
          record(surah: 3, ayah: 1, stability: 1),
        ];
        final results = weakeningSoon(
          records,
          now,
          ayahsBySurah: {
            1: [ayah(1, 1, 1), ayah(1, 2, 1), ayah(1, 3, 2), ayah(1, 4, 2)],
            2: [ayah(2, 1, 1)],
            3: [ayah(3, 1, 1)],
          },
        );
        expect(results, hasLength(3));
        expect(results[0].startAyah, 1);
        expect(results[0].endAyah, 2);
        expect(results[1].startAyah, 3);
        expect(results[1].endAyah, 4);
      },
    );
  });
}
