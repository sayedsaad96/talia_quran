import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/progress_metrics.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  const service = ProgressMetricsService();
  final now = DateTime.utc(2026, 6, 10, 12);

  AyahReviewRecord record({
    required int surahId,
    required int ayahNumber,
    required int strengthLevel,
    required int totalReviews,
    ReviewRecordCreatedByMode mode = ReviewRecordCreatedByMode.v2Session,
    DateTime? nextReviewDate,
  }) {
    return AyahReviewRecord(
      surahId: surahId,
      ayahNumber: ayahNumber,
      strengthLevel: strengthLevel,
      intervalDays: 7,
      lastReviewedAt: now.subtract(const Duration(days: 10)),
      nextReviewDate: nextReviewDate ?? now.add(const Duration(days: 7)),
      totalReviews: totalReviews,
      lastRating: PerformanceRating.average,
      createdByMode: mode,
    );
  }

  group('memorized vs started (two-tier definition)', () {
    test('started counts totalReviews>0; memorized counts strengthLevel>=6', () {
      final metrics = service.calculate(
        now: now,
        totalAyahs: 6236,
        records: [
          record(surahId: 1, ayahNumber: 1, strengthLevel: 6, totalReviews: 5),
          record(surahId: 1, ayahNumber: 2, strengthLevel: 3, totalReviews: 2),
          record(surahId: 1, ayahNumber: 3, strengthLevel: 5, totalReviews: 1),
          // never started — must be ignored entirely
          record(surahId: 1, ayahNumber: 4, strengthLevel: 0, totalReviews: 0),
        ],
      );

      expect(metrics.startedAyahs, 3);
      expect(metrics.memorizedAyahs, 1);
    });

    test('learning is started AND not memorized (disjoint from memorized)', () {
      final metrics = service.calculate(
        now: now,
        records: [
          record(surahId: 1, ayahNumber: 1, strengthLevel: 6, totalReviews: 5),
          record(surahId: 1, ayahNumber: 2, strengthLevel: 3, totalReviews: 2),
          record(surahId: 1, ayahNumber: 3, strengthLevel: 5, totalReviews: 1),
        ],
      );

      expect(metrics.memorizedAyahs, 1);
      expect(metrics.learningAyahs, 2);
      // No double counting: memorized + learning == started.
      expect(
        metrics.memorizedAyahs + metrics.learningAyahs,
        metrics.startedAyahs,
      );
    });

    test('totalReviewEvents sums all review repetitions of counted records', () {
      final metrics = service.calculate(
        now: now,
        records: [
          record(surahId: 1, ayahNumber: 1, strengthLevel: 6, totalReviews: 5),
          record(surahId: 1, ayahNumber: 2, strengthLevel: 3, totalReviews: 2),
        ],
      );
      expect(metrics.totalReviewEvents, 7);
    });
  });

  group('audience source filtering', () {
    final mixed = [
      record(
        surahId: 1,
        ayahNumber: 1,
        strengthLevel: 6,
        totalReviews: 5,
        mode: ReviewRecordCreatedByMode.v2Session,
      ),
      record(
        surahId: 1,
        ayahNumber: 2,
        strengthLevel: 6,
        totalReviews: 5,
        mode: ReviewRecordCreatedByMode.hifz,
      ),
      record(
        surahId: 1,
        ayahNumber: 3,
        strengthLevel: 6,
        totalReviews: 5,
        mode: ReviewRecordCreatedByMode.kidsMode,
      ),
      record(
        surahId: 1,
        ayahNumber: 4,
        strengthLevel: 6,
        totalReviews: 5,
        mode: ReviewRecordCreatedByMode.unknown,
      ),
    ];

    test('adult counts v2Session + hifz, excludes kids/unknown', () {
      final metrics = service.calculate(
        now: now,
        records: mixed,
        audience: ProgressAudience.adult,
      );
      expect(metrics.memorizedAyahs, 2);
    });

    test('kids counts only kidsMode records', () {
      final metrics = service.calculate(
        now: now,
        records: mixed,
        audience: ProgressAudience.kids,
      );
      expect(metrics.memorizedAyahs, 1);
    });
  });

  group('memorized surahs and juz require full completion', () {
    test('surah counts only when all its ayahs are memorized', () {
      final metrics = service.calculate(
        now: now,
        surahAyahCounts: {1: 3},
        records: [
          record(surahId: 1, ayahNumber: 1, strengthLevel: 6, totalReviews: 5),
          record(surahId: 1, ayahNumber: 2, strengthLevel: 6, totalReviews: 5),
          // ayah 3 only "started" (strength 4) — surah is NOT complete
          record(surahId: 1, ayahNumber: 3, strengthLevel: 4, totalReviews: 2),
        ],
      );
      expect(metrics.memorizedSurahs, 0);
    });

    test('surah counts when every ayah reaches strength>=6', () {
      final metrics = service.calculate(
        now: now,
        surahAyahCounts: {1: 2},
        records: [
          record(surahId: 1, ayahNumber: 1, strengthLevel: 6, totalReviews: 5),
          record(surahId: 1, ayahNumber: 2, strengthLevel: 7, totalReviews: 9),
        ],
      );
      expect(metrics.memorizedSurahs, 1);
    });

    test('juz counts only when all its keys are memorized', () {
      final metrics = service.calculate(
        now: now,
        ayahKeysByJuz: {
          30: {'1_1', '1_2'},
        },
        records: [
          record(surahId: 1, ayahNumber: 1, strengthLevel: 6, totalReviews: 5),
          record(surahId: 1, ayahNumber: 2, strengthLevel: 5, totalReviews: 5),
        ],
      );
      expect(metrics.memorizedJuz, 0);
    });
  });

  group('due / overdue use injected now', () {
    test('due counts started records at/after scheduled time', () {
      final metrics = service.calculate(
        now: now,
        records: [
          record(
            surahId: 1,
            ayahNumber: 1,
            strengthLevel: 6,
            totalReviews: 5,
            nextReviewDate: now.subtract(const Duration(days: 2)),
          ),
          record(
            surahId: 1,
            ayahNumber: 2,
            strengthLevel: 6,
            totalReviews: 5,
            nextReviewDate: now.add(const Duration(days: 5)),
          ),
        ],
      );
      expect(metrics.dueReviews, 1);
    });

    test('overdue counts records scheduled before start of today', () {
      final metrics = service.calculate(
        now: now,
        records: [
          record(
            surahId: 1,
            ayahNumber: 1,
            strengthLevel: 6,
            totalReviews: 5,
            nextReviewDate: now.subtract(const Duration(days: 2)),
          ),
        ],
      );
      expect(metrics.overdueReviews, 1);
    });
  });

  group('rates and percentages', () {
    test('retentionRate = memorized / started', () {
      final metrics = service.calculate(
        now: now,
        records: [
          record(surahId: 1, ayahNumber: 1, strengthLevel: 6, totalReviews: 5),
          record(surahId: 1, ayahNumber: 2, strengthLevel: 6, totalReviews: 5),
          record(surahId: 1, ayahNumber: 3, strengthLevel: 3, totalReviews: 2),
          record(surahId: 1, ayahNumber: 4, strengthLevel: 3, totalReviews: 2),
        ],
      );
      expect(metrics.retentionRate, 0.5);
    });

    test('retentionRate is 0 when nothing started', () {
      final metrics = service.calculate(now: now, records: const []);
      expect(metrics.retentionRate, 0);
    });

    test('reading completion is readPages / totalQuranPages', () {
      final metrics = service.calculate(
        now: now,
        records: const [],
        readPagesCount: 302,
        totalQuranPages: 604,
      );
      expect(metrics.readingCompletionPercent, 0.5);
      expect(metrics.readJuz, 15);
    });
  });

  test('empty input yields all-zero metrics', () {
    final metrics = service.calculate(now: now, records: const []);
    expect(metrics.startedAyahs, 0);
    expect(metrics.memorizedAyahs, 0);
    expect(metrics.learningAyahs, 0);
    expect(metrics.lastReviewedAt, isNull);
    expect(metrics.lastMemorizedSurahId, isNull);
    expect(metrics.lastMemorizedAyahNumber, isNull);
    expect(metrics.memorizedSurahs, 0);
    expect(metrics.memorizedJuz, 0);
    expect(metrics.dueReviews, 0);
    expect(metrics.retentionRate, 0);
  });

  group('activity timestamps', () {
    test('lastReviewedAt is the newest review among started records', () {
      final older = now.subtract(const Duration(days: 20));
      final newer = now.subtract(const Duration(days: 2));
      final metrics = service.calculate(
        now: now,
        records: [
          AyahReviewRecord(
            surahId: 1,
            ayahNumber: 1,
            strengthLevel: 3,
            intervalDays: 7,
            lastReviewedAt: older,
            nextReviewDate: now.add(const Duration(days: 7)),
            totalReviews: 2,
            lastRating: PerformanceRating.average,
            createdByMode: ReviewRecordCreatedByMode.v2Session,
          ),
          AyahReviewRecord(
            surahId: 2,
            ayahNumber: 5,
            strengthLevel: 6,
            intervalDays: 7,
            lastReviewedAt: newer,
            nextReviewDate: now.add(const Duration(days: 7)),
            totalReviews: 4,
            lastRating: PerformanceRating.excellent,
            createdByMode: ReviewRecordCreatedByMode.v2Session,
          ),
        ],
      );

      expect(metrics.lastReviewedAt, newer);
      expect(metrics.lastMemorizedSurahId, 2);
      expect(metrics.lastMemorizedAyahNumber, 5);
    });
  });
}
