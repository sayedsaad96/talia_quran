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
    test('includes adultMemPlus', () {
      expect(
        ReviewRecordFilters.isAdultCompatible(
          makeRecord(ReviewRecordCreatedByMode.adultMemPlus),
        ),
        isTrue,
      );
    });

    test('includes unknown', () {
      expect(
        ReviewRecordFilters.isAdultCompatible(
          makeRecord(ReviewRecordCreatedByMode.unknown),
        ),
        isTrue,
      );
    });

    test('includes migration', () {
      expect(
        ReviewRecordFilters.isAdultCompatible(
          makeRecord(ReviewRecordCreatedByMode.migration),
        ),
        isTrue,
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

    test('excludes hifz', () {
      expect(
        ReviewRecordFilters.isAdultCompatible(
          makeRecord(ReviewRecordCreatedByMode.hifz),
        ),
        isFalse,
      );
    });
  });

  // ─── isAdultRetentionCompatible ──────────────────────────────────────────

  group('ReviewRecordFilters.isAdultRetentionCompatible', () {
    test('includes adultMemPlus', () {
      expect(
        ReviewRecordFilters.isAdultRetentionCompatible(
          makeRecord(ReviewRecordCreatedByMode.adultMemPlus),
        ),
        isTrue,
      );
    });

    test('includes unknown', () {
      expect(
        ReviewRecordFilters.isAdultRetentionCompatible(
          makeRecord(ReviewRecordCreatedByMode.unknown),
        ),
        isTrue,
      );
    });

    test('includes migration', () {
      expect(
        ReviewRecordFilters.isAdultRetentionCompatible(
          makeRecord(ReviewRecordCreatedByMode.migration),
        ),
        isTrue,
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

    test('excludes hifz', () {
      expect(
        ReviewRecordFilters.isAdultRetentionCompatible(
          makeRecord(ReviewRecordCreatedByMode.hifz),
        ),
        isFalse,
      );
    });
  });

  // ─── isDailyPlanRetentionEligible ─────────────────────────────────────────

  AyahReviewRecord memorizedDueRecord({
    ReviewRecordCreatedByMode mode = ReviewRecordCreatedByMode.adultMemPlus,
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
    test('includes adultMemPlus memorized-due', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(memorizedDueRecord()),
        isTrue,
      );
    });

    test('excludes adultMemPlus non-due memorized', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(
          memorizedDueRecord(nextReviewDate: DateTime.utc(2099, 12, 31)),
        ),
        isFalse,
      );
    });

    test('excludes adultMemPlus due non-memorized', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(
          memorizedDueRecord(strengthLevel: 4),
        ),
        isFalse,
      );
    });

    // Sprint 4.5: V2 adult records are now eligible for retention review,
    // consistent with Smart Coach, Progress, and AchievementService.
    test('includes v2Session memorized-due', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(
          memorizedDueRecord(mode: ReviewRecordCreatedByMode.v2Session),
        ),
        isTrue,
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

    test('excludes hifz memorized-due', () {
      expect(
        ReviewRecordFilters.isDailyPlanRetentionEligible(
          memorizedDueRecord(mode: ReviewRecordCreatedByMode.hifz),
        ),
        isFalse,
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

    test(
      'isKidsSource is the complement of isAdultCompatible for pure sources',
      () {
        // adultMemPlus, unknown, migration — compatible, not kids
        for (final mode in [
          ReviewRecordCreatedByMode.adultMemPlus,
          ReviewRecordCreatedByMode.unknown,
          ReviewRecordCreatedByMode.migration,
        ]) {
          final record = makeRecord(mode);
          expect(
            ReviewRecordFilters.isKidsSource(record),
            isFalse,
            reason: '$mode should not be kids source',
          );
          expect(
            ReviewRecordFilters.isAdultCompatible(record),
            isTrue,
            reason: '$mode should be adult compatible',
          );
        }

        // kidsMode — not compatible, is kids
        final kidsRecord = makeRecord(ReviewRecordCreatedByMode.kidsMode);
        expect(ReviewRecordFilters.isKidsSource(kidsRecord), isTrue);
        expect(ReviewRecordFilters.isAdultCompatible(kidsRecord), isFalse);
      },
    );
  });
}
