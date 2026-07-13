import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/review_record_filters.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  // ─── Shared helpers ───────────────────────────────────────────────────────

  AyahReviewRecord makeRecord(ReviewRecordCreatedByMode mode) {
    final now = DateTime.utc(2026, 1, 1);
    return AyahReviewRecord(
      surahId: 1,
      ayahNumber: 1,
      strengthLevel: 3,
      intervalDays: 7,
      lastReviewedAt: now,
      nextReviewDate: now.add(const Duration(days: 7)),
      totalReviews: 2,
      lastRating: PerformanceRating.average,
      createdByMode: mode,
    );
  }

  // ─── isKidsSource ─────────────────────────────────────────────────────────

  group('ReviewRecordFilters.isKidsSource', () {
    test('returns true for kidsMode', () {
      expect(
        ReviewRecordFilters.isKidsSource(
          makeRecord(ReviewRecordCreatedByMode.kidsMode),
        ),
        isTrue,
      );
    });

    test('returns false for adultMemPlus', () {
      expect(
        ReviewRecordFilters.isKidsSource(
          makeRecord(ReviewRecordCreatedByMode.adultMemPlus),
        ),
        isFalse,
      );
    });

    test('returns false for hifz', () {
      expect(
        ReviewRecordFilters.isKidsSource(
          makeRecord(ReviewRecordCreatedByMode.hifz),
        ),
        isFalse,
      );
    });

    test('returns false for migration', () {
      expect(
        ReviewRecordFilters.isKidsSource(
          makeRecord(ReviewRecordCreatedByMode.migration),
        ),
        isFalse,
      );
    });

    test('returns false for unknown', () {
      expect(
        ReviewRecordFilters.isKidsSource(
          makeRecord(ReviewRecordCreatedByMode.unknown),
        ),
        isFalse,
      );
    });
  });

  // ─── isAmbiguousSource ───────────────────────────────────────────────────

  group('ReviewRecordFilters.isAmbiguousSource', () {
    test('returns true for unknown', () {
      expect(
        ReviewRecordFilters.isAmbiguousSource(
          makeRecord(ReviewRecordCreatedByMode.unknown),
        ),
        isTrue,
      );
    });

    test('returns true for migration', () {
      expect(
        ReviewRecordFilters.isAmbiguousSource(
          makeRecord(ReviewRecordCreatedByMode.migration),
        ),
        isTrue,
      );
    });

    test('returns false for adultMemPlus', () {
      expect(
        ReviewRecordFilters.isAmbiguousSource(
          makeRecord(ReviewRecordCreatedByMode.adultMemPlus),
        ),
        isFalse,
      );
    });

    test('returns false for kidsMode', () {
      expect(
        ReviewRecordFilters.isAmbiguousSource(
          makeRecord(ReviewRecordCreatedByMode.kidsMode),
        ),
        isFalse,
      );
    });

    test('returns false for hifz', () {
      expect(
        ReviewRecordFilters.isAmbiguousSource(
          makeRecord(ReviewRecordCreatedByMode.hifz),
        ),
        isFalse,
      );
    });
  });

  // ─── isTrustedSource ─────────────────────────────────────────────────────

  group('ReviewRecordFilters.isTrustedSource', () {
    test('returns true for adultMemPlus', () {
      expect(
        ReviewRecordFilters.isTrustedSource(
          makeRecord(ReviewRecordCreatedByMode.adultMemPlus),
        ),
        isTrue,
      );
    });

    test('returns true for kidsMode', () {
      expect(
        ReviewRecordFilters.isTrustedSource(
          makeRecord(ReviewRecordCreatedByMode.kidsMode),
        ),
        isTrue,
      );
    });

    test('returns true for hifz', () {
      expect(
        ReviewRecordFilters.isTrustedSource(
          makeRecord(ReviewRecordCreatedByMode.hifz),
        ),
        isTrue,
      );
    });

    test('returns false for migration', () {
      expect(
        ReviewRecordFilters.isTrustedSource(
          makeRecord(ReviewRecordCreatedByMode.migration),
        ),
        isFalse,
      );
    });

    test('returns false for unknown', () {
      expect(
        ReviewRecordFilters.isTrustedSource(
          makeRecord(ReviewRecordCreatedByMode.unknown),
        ),
        isFalse,
      );
    });
  });

  // ─── isAdultCompatible ───────────────────────────────────────────────────

  group('ReviewRecordFilters.isAdultCompatible', () {
    test('excludes adultMemPlus', () {
      expect(
        ReviewRecordFilters.isAdultCompatible(
          makeRecord(ReviewRecordCreatedByMode.adultMemPlus),
        ),
        isFalse,
      );
    });

    test('excludes unknown', () {
      expect(
        ReviewRecordFilters.isAdultCompatible(
          makeRecord(ReviewRecordCreatedByMode.unknown),
        ),
        isFalse,
      );
    });

    test('excludes migration', () {
      expect(
        ReviewRecordFilters.isAdultCompatible(
          makeRecord(ReviewRecordCreatedByMode.migration),
        ),
        isFalse,
      );
    });

    test('excludes kidsMode', () {
      expect(
        ReviewRecordFilters.isAdultCompatible(
          makeRecord(ReviewRecordCreatedByMode.kidsMode),
        ),
        isFalse,
      );
    });

    test('includes hifz', () {
      expect(
        ReviewRecordFilters.isAdultCompatible(
          makeRecord(ReviewRecordCreatedByMode.hifz),
        ),
        isTrue,
      );
    });

    test('includes v2Session', () {
      expect(
        ReviewRecordFilters.isAdultCompatible(
          makeRecord(ReviewRecordCreatedByMode.v2Session),
        ),
        isTrue,
      );
    });
  });

  // ─── isAdultRetentionCompatible ──────────────────────────────────────────

  group('ReviewRecordFilters.isAdultRetentionCompatible', () {
    test('excludes adultMemPlus', () {
      expect(
        ReviewRecordFilters.isAdultRetentionCompatible(
          makeRecord(ReviewRecordCreatedByMode.adultMemPlus),
        ),
        isFalse,
      );
    });

    test('excludes unknown', () {
      expect(
        ReviewRecordFilters.isAdultRetentionCompatible(
          makeRecord(ReviewRecordCreatedByMode.unknown),
        ),
        isFalse,
      );
    });

    test('excludes migration', () {
      expect(
        ReviewRecordFilters.isAdultRetentionCompatible(
          makeRecord(ReviewRecordCreatedByMode.migration),
        ),
        isFalse,
      );
    });

    test('excludes kidsMode', () {
      expect(
        ReviewRecordFilters.isAdultRetentionCompatible(
          makeRecord(ReviewRecordCreatedByMode.kidsMode),
        ),
        isFalse,
      );
    });

    test('includes hifz', () {
      expect(
        ReviewRecordFilters.isAdultRetentionCompatible(
          makeRecord(ReviewRecordCreatedByMode.hifz),
        ),
        isTrue,
      );
    });

    test('includes v2Session', () {
      expect(
        ReviewRecordFilters.isAdultRetentionCompatible(
          makeRecord(ReviewRecordCreatedByMode.v2Session),
        ),
        isTrue,
      );
    });
  });

  // ─── isDailyPlanRetentionEligible ─────────────────────────────────────────

  AyahReviewRecord memorizedDueRecord({
    ReviewRecordCreatedByMode mode = ReviewRecordCreatedByMode.v2Session,
    DateTime? nextReviewDate,
    int strengthLevel = 6,
    int totalReviews = 4,
  }) {
    final now = DateTime.utc(2026, 6, 10, 12);
    return AyahReviewRecord(
      surahId: 67,
      ayahNumber: 1,
      strengthLevel: strengthLevel,
      intervalDays: 30,
      lastReviewedAt: now.subtract(const Duration(days: 45)),
      nextReviewDate: nextReviewDate ?? now.subtract(const Duration(days: 1)),
      totalReviews: totalReviews,
      lastRating: PerformanceRating.excellent,
      createdByMode: mode,
    );
  }

  group('ReviewRecordFilters.isDailyPlanRetentionEligible', () {
    test('includes v2Session memorized-due', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(memorizedDueRecord()),
        isTrue,
      );
    });

    test('excludes v2Session non-due memorized', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(
          memorizedDueRecord(nextReviewDate: DateTime.utc(2099, 12, 31)),
        ),
        isFalse,
      );
    });

    test('excludes v2Session due non-memorized', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(
          memorizedDueRecord(strengthLevel: 4),
        ),
        isFalse,
      );
    });

    test('excludes adultMemPlus memorized-due', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(
          memorizedDueRecord(mode: ReviewRecordCreatedByMode.adultMemPlus),
        ),
        isFalse,
      );
    });

    test('excludes v2Session non-due memorized', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(
          memorizedDueRecord(
            mode: ReviewRecordCreatedByMode.v2Session,
            nextReviewDate: DateTime.utc(2099, 12, 31),
          ),
        ),
        isFalse,
      );
    });

    test('excludes kidsMode memorized-due', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(
          memorizedDueRecord(mode: ReviewRecordCreatedByMode.kidsMode),
        ),
        isFalse,
      );
    });

    test('includes hifz memorized-due', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(
          memorizedDueRecord(mode: ReviewRecordCreatedByMode.hifz),
        ),
        isTrue,
      );
    });

    test('excludes unknown memorized-due', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(
          memorizedDueRecord(mode: ReviewRecordCreatedByMode.unknown),
        ),
        isFalse,
      );
    });

    test('excludes migration memorized-due', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(
          memorizedDueRecord(mode: ReviewRecordCreatedByMode.migration),
        ),
        isFalse,
      );
    });
  });

  group('ReviewRecordFilters.compareMemorizedDue', () {
    test('sorts by oldest due date first', () {
      final now = DateTime.utc(2026, 6, 10);
      final older = AyahReviewRecord(
        surahId: 67,
        ayahNumber: 1,
        strengthLevel: 6,
        intervalDays: 30,
        lastReviewedAt: now.subtract(const Duration(days: 45)),
        nextReviewDate: now.subtract(const Duration(days: 5)),
        totalReviews: 6,
        lastRating: PerformanceRating.excellent,
        createdByMode: ReviewRecordCreatedByMode.adultMemPlus,
      );
      final newer = AyahReviewRecord(
        surahId: 67,
        ayahNumber: 2,
        strengthLevel: 6,
        intervalDays: 30,
        lastReviewedAt: now.subtract(const Duration(days: 45)),
        nextReviewDate: now.subtract(const Duration(days: 1)),
        totalReviews: 6,
        lastRating: PerformanceRating.excellent,
        createdByMode: ReviewRecordCreatedByMode.adultMemPlus,
      );
      final sorted = <AyahReviewRecord>[newer, older]
        ..sort(ReviewRecordFilters.compareMemorizedDue);
      expect(sorted.first.ayahNumber, 1);
    });
  });

  // ─── Consistency cross-checks ─────────────────────────────────────────────

  group('ReviewRecordFilters policy consistency', () {
    test(
      'isAdultCompatible and isAdultRetentionCompatible agree on all 5 modes',
      () {
        for (final mode in ReviewRecordCreatedByMode.values) {
          final record = makeRecord(mode);
          expect(
            ReviewRecordFilters.isAdultCompatible(record),
            ReviewRecordFilters.isAdultRetentionCompatible(record),
            reason:
                'isAdultCompatible and isAdultRetentionCompatible should agree for $mode',
          );
        }
      },
    );

    test('adult and kids source predicates are explicit allowlists', () {
      final adultRecord = makeRecord(ReviewRecordCreatedByMode.v2Session);
      final hifzRecord = makeRecord(ReviewRecordCreatedByMode.hifz);
      final kidsRecord = makeRecord(ReviewRecordCreatedByMode.kidsMode);

      expect(ReviewRecordFilters.isAdultCompatible(adultRecord), isTrue);
      expect(ReviewRecordFilters.isAdultCompatible(hifzRecord), isTrue);
      expect(ReviewRecordFilters.isKidsSource(adultRecord), isFalse);
      expect(ReviewRecordFilters.isKidsSource(kidsRecord), isTrue);
      expect(ReviewRecordFilters.isAdultCompatible(kidsRecord), isFalse);

      for (final mode in [
        ReviewRecordCreatedByMode.adultMemPlus,
        ReviewRecordCreatedByMode.unknown,
        ReviewRecordCreatedByMode.migration,
      ]) {
        final record = makeRecord(mode);
        expect(ReviewRecordFilters.isAdultCompatible(record), isFalse);
        expect(ReviewRecordFilters.isKidsSource(record), isFalse);
      }
    });
  });

  // ─── Metric predicates (Phase 0) ──────────────────────────────────────────

  AyahReviewRecord metricRecord({
    required int strengthLevel,
    required int totalReviews,
    ReviewRecordCreatedByMode mode = ReviewRecordCreatedByMode.v2Session,
  }) {
    final now = DateTime.utc(2026, 1, 1);
    return AyahReviewRecord(
      surahId: 2,
      ayahNumber: 5,
      strengthLevel: strengthLevel,
      intervalDays: 7,
      lastReviewedAt: now,
      nextReviewDate: now.add(const Duration(days: 7)),
      totalReviews: totalReviews,
      lastRating: PerformanceRating.average,
      createdByMode: mode,
    );
  }

  group('ReviewRecordFilters.isMemorized', () {
    test('false at strengthLevel 5 (boundary)', () {
      expect(
        ReviewRecordFilters.isMemorized(
          metricRecord(strengthLevel: 5, totalReviews: 3),
        ),
        isFalse,
      );
    });

    test('true at strengthLevel 6 (boundary)', () {
      expect(
        ReviewRecordFilters.isMemorized(
          metricRecord(strengthLevel: 6, totalReviews: 3),
        ),
        isTrue,
      );
    });
  });

  group('ReviewRecordFilters.isStarted', () {
    test('false when totalReviews == 0', () {
      expect(
        ReviewRecordFilters.isStarted(
          metricRecord(strengthLevel: 0, totalReviews: 0),
        ),
        isFalse,
      );
    });

    test('true when totalReviews > 0', () {
      expect(
        ReviewRecordFilters.isStarted(
          metricRecord(strengthLevel: 1, totalReviews: 1),
        ),
        isTrue,
      );
    });
  });

  group('ReviewRecordFilters.isLearning', () {
    test('true when started but not memorized', () {
      expect(
        ReviewRecordFilters.isLearning(
          metricRecord(strengthLevel: 3, totalReviews: 2),
        ),
        isTrue,
      );
    });

    test('false when memorized (disjoint from isMemorized)', () {
      final record = metricRecord(strengthLevel: 6, totalReviews: 4);
      expect(ReviewRecordFilters.isLearning(record), isFalse);
      expect(ReviewRecordFilters.isMemorized(record), isTrue);
    });

    test('false when not started', () {
      expect(
        ReviewRecordFilters.isLearning(
          metricRecord(strengthLevel: 0, totalReviews: 0),
        ),
        isFalse,
      );
    });
  });

  group('ReviewRecordFilters.isAdultProductionCount', () {
    test('includes v2Session', () {
      expect(
        ReviewRecordFilters.isAdultProductionCount(
          metricRecord(
            strengthLevel: 6,
            totalReviews: 4,
            mode: ReviewRecordCreatedByMode.v2Session,
          ),
        ),
        isTrue,
      );
    });

    test('includes hifz (repaired legacy)', () {
      expect(
        ReviewRecordFilters.isAdultProductionCount(
          metricRecord(
            strengthLevel: 6,
            totalReviews: 4,
            mode: ReviewRecordCreatedByMode.hifz,
          ),
        ),
        isTrue,
      );
    });

    test('excludes kidsMode from adult counts', () {
      expect(
        ReviewRecordFilters.isAdultProductionCount(
          metricRecord(
            strengthLevel: 6,
            totalReviews: 4,
            mode: ReviewRecordCreatedByMode.kidsMode,
          ),
        ),
        isFalse,
      );
    });

    test('excludes adultMemPlus, unknown, migration', () {
      for (final mode in [
        ReviewRecordCreatedByMode.adultMemPlus,
        ReviewRecordCreatedByMode.unknown,
        ReviewRecordCreatedByMode.migration,
      ]) {
        expect(
          ReviewRecordFilters.isAdultProductionCount(
            metricRecord(strengthLevel: 6, totalReviews: 4, mode: mode),
          ),
          isFalse,
          reason: '$mode must be excluded from adult production counts',
        );
      }
    });
  });
}
