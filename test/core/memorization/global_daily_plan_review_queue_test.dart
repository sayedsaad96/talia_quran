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
}
