import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/daily_plan_review_queue.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8, 12);

  AyahReviewRecord record({
    required int surahId,
    required int ayahNumber,
    required DateTime lastReviewedAt,
    required DateTime dueAt,
    int strength = 3,
    int reviews = 2,
    PerformanceRating? rating = PerformanceRating.average,
    int lapses = 0,
  }) => AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strength,
    intervalDays: 2,
    lastReviewedAt: lastReviewedAt,
    nextReviewDate: dueAt,
    totalReviews: reviews,
    lastRating: rating,
    lapses: lapses,
    createdByMode: ReviewRecordCreatedByMode.v2Session,
  );

  test(
    'selects due reviews globally and prioritizes weak or overdue records',
    () {
      final selection = DailyPlanReviewQueue.select(
        records: [
          record(
            surahId: 1,
            ayahNumber: 2,
            lastReviewedAt: now.subtract(const Duration(days: 2)),
            dueAt: now.subtract(const Duration(hours: 1)),
          ),
          record(
            surahId: 36,
            ayahNumber: 10,
            lastReviewedAt: now.subtract(const Duration(days: 1)),
            dueAt: now.subtract(const Duration(days: 2)),
            rating: PerformanceRating.weak,
          ),
          record(
            surahId: 67,
            ayahNumber: 3,
            lastReviewedAt: now.subtract(const Duration(days: 8)),
            dueAt: now.subtract(const Duration(hours: 1)),
          ),
          record(
            surahId: 112,
            ayahNumber: 1,
            lastReviewedAt: now.subtract(const Duration(days: 9)),
            dueAt: now.subtract(const Duration(hours: 1)),
            strength: 6,
            reviews: 7,
          ),
        ],
        now: now,
        nearLimit: 2,
        farLimit: 1,
        retentionLimit: 1,
        includeNear: true,
        includeFar: true,
      );

      expect(
        selection.weak.map((item) => '${item.surahId}:${item.ayahNumber}'),
        ['36:10'],
      );
      expect(
        selection.near.map((item) => '${item.surahId}:${item.ayahNumber}'),
        ['1:2'],
      );
      expect(
        selection.far.map((item) => '${item.surahId}:${item.ayahNumber}'),
        ['67:3'],
      );
      expect(
        selection.retention.map((item) => '${item.surahId}:${item.ayahNumber}'),
        ['112:1'],
      );
      expect(selection.blocksNewMemorization, isFalse);
    },
  );

  test('blocks new memorization when due review backlog exceeds capacity', () {
    final selection = DailyPlanReviewQueue.select(
      records: List.generate(
        4,
        (index) => record(
          surahId: index + 1,
          ayahNumber: 1,
          lastReviewedAt: now.subtract(const Duration(days: 2)),
          dueAt: now.subtract(const Duration(hours: 1)),
        ),
      ),
      now: now,
      nearLimit: 2,
      farLimit: 1,
      retentionLimit: 0,
      includeNear: true,
      includeFar: true,
    );

    expect(selection.dueBacklogCount, 4);
    expect(selection.near, hasLength(3));
    expect(selection.far, isEmpty);
    expect(selection.blocksNewMemorization, isTrue);
  });

  test('disabling near revision excludes near items instead of shrinking capacity', () {
    // 3 near-due items and 1 far-due item. With near revision disabled,
    // the near items must not silently fill the remaining far slots.
    final selection = DailyPlanReviewQueue.select(
      records: [
        record(
          surahId: 1,
          ayahNumber: 1,
          lastReviewedAt: now.subtract(const Duration(days: 2)),
          dueAt: now.subtract(const Duration(hours: 1)),
        ),
        record(
          surahId: 2,
          ayahNumber: 1,
          lastReviewedAt: now.subtract(const Duration(days: 2)),
          dueAt: now.subtract(const Duration(hours: 1)),
        ),
        record(
          surahId: 3,
          ayahNumber: 1,
          lastReviewedAt: now.subtract(const Duration(days: 2)),
          dueAt: now.subtract(const Duration(hours: 1)),
        ),
        record(
          surahId: 67,
          ayahNumber: 1,
          lastReviewedAt: now.subtract(const Duration(days: 8)),
          dueAt: now.subtract(const Duration(hours: 1)),
        ),
      ],
      now: now,
      nearLimit: 3,
      farLimit: 3,
      retentionLimit: 0,
      includeNear: false,
      includeFar: true,
    );

    expect(selection.near, isEmpty);
    expect(
      selection.far.map((item) => '${item.surahId}:${item.ayahNumber}'),
      ['67:1'],
    );
  });

  test('weak recovery items remain schedulable when near revision is disabled', () {
    // A lapsed ayah is due work regardless of the near/far toggles: it is
    // recovery, not routine revision.
    final selection = DailyPlanReviewQueue.select(
      records: [
        record(
          surahId: 36,
          ayahNumber: 10,
          lastReviewedAt: now.subtract(const Duration(days: 1)),
          dueAt: now.subtract(const Duration(hours: 1)),
          lapses: 2,
        ),
      ],
      now: now,
      nearLimit: 3,
      farLimit: 3,
      retentionLimit: 0,
      includeNear: false,
      includeFar: false,
    );

    expect(
      selection.weak.map((item) => '${item.surahId}:${item.ayahNumber}'),
      ['36:10'],
    );
  });

  test('retention limit grows with the overdue backlog and caps at 15', () {
    final records = List.generate(
      40,
      (index) => record(
        surahId: index + 1,
        ayahNumber: 1,
        lastReviewedAt: now.subtract(const Duration(days: 30)),
        dueAt: now.subtract(const Duration(days: 20)),
        strength: 6,
        reviews: 7,
      ),
    );

    // Small backlog: the configured 3/day limit is respected.
    final small = DailyPlanReviewQueue.select(
      records: records.take(5),
      now: now,
      nearLimit: 2,
      farLimit: 1,
      retentionLimit: 3,
      includeNear: true,
      includeFar: true,
    );
    expect(small.retention, hasLength(3));

    // Large backlog: catch-up serves more per day…
    final large = DailyPlanReviewQueue.select(
      records: records,
      now: now,
      nearLimit: 2,
      farLimit: 1,
      retentionLimit: 3,
      includeNear: true,
      includeFar: true,
    );
    expect(large.retention.length, greaterThan(3));

    // …but never drowns the learner.
    expect(large.retention.length, lessThanOrEqualTo(15));
  });

  test(
    'every counted backlog item is visible in a plan bucket (no dead-end)',
    () {
      // Legacy self-assessed records kept totalReviews == 0 while carrying a
      // due date. They are new material, not review backlog: counting them
      // produced a "N ayahs due" notice with nothing listed to review.
      final legacyUnreviewed = List.generate(
        12,
        (index) => record(
          surahId: 2,
          ayahNumber: index + 1,
          lastReviewedAt: now.subtract(const Duration(days: 3)),
          dueAt: now.subtract(const Duration(days: 2)),
          strength: 0,
          reviews: 0,
          rating: null,
        ),
      );
      final reviewed = record(
        surahId: 1,
        ayahNumber: 2,
        lastReviewedAt: now.subtract(const Duration(days: 2)),
        dueAt: now.subtract(const Duration(hours: 1)),
      );

      final selection = DailyPlanReviewQueue.select(
        records: [...legacyUnreviewed, reviewed],
        now: now,
        nearLimit: 10,
        farLimit: 5,
        retentionLimit: 3,
        includeNear: true,
        includeFar: true,
      );

      final visible =
          selection.weak.length + selection.near.length + selection.far.length;
      expect(selection.dueBacklogCount, 1);
      expect(visible, selection.dueBacklogCount);
      expect(selection.blocksNewMemorization, isFalse);
    },
  );
}
