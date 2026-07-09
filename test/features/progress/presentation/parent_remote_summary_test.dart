import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/remote_child_production_summary_builder.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  group('parent remote production summary', () {
    const builder = RemoteChildProductionSummaryBuilder();

    test('counts child kidsMode rows instead of adult production rows', () {
      final now = DateTime.utc(2026, 7, 9, 9);
      final childRow = _reviewRow(
        surahId: 67,
        ayahNumber: 1,
        strengthLevel: 6,
        createdByMode: ReviewRecordCreatedByMode.kidsMode,
        lastReviewedAt: now,
      );
      final adultRow = _reviewRow(
        surahId: 67,
        ayahNumber: 2,
        strengthLevel: 6,
        createdByMode: ReviewRecordCreatedByMode.v2Session,
        lastReviewedAt: now.add(const Duration(minutes: 1)),
      );

      final summary = builder.build(
        reviewRows: [childRow, adultRow],
        dailyPlanRow: null,
        certRows: const [],
        streakRow: {'current_streak': 4, 'longest_streak': 9},
        activityRows: const [
          {'day_key': '2026-07-09', 'activity_count': 1},
          {'day_key': '2026-07-08', 'activity_count': 0},
        ],
      );

      expect(summary.totalMemorizedAyahs, 1);
      expect(summary.totalAyahsTracked, 1);
      expect(summary.lastMemorizedAyahNumber, 1);
      expect(summary.currentStreak, 4);
      expect(summary.longestStreak, 9);
      expect(summary.activeDaysLast30, 1);
    });

    test('parses certificate and daily-plan rows for parent display', () {
      final now = DateTime.utc(2026, 7, 9, 9);

      final summary = builder.build(
        reviewRows: [
          _reviewRow(
            surahId: 67,
            ayahNumber: 3,
            strengthLevel: 3,
            createdByMode: ReviewRecordCreatedByMode.kidsMode,
            lastReviewedAt: now,
          ),
        ],
        dailyPlanRow: {
          'surah_id': 67,
          'total_items': 3,
          'completed_count': 1,
          'payload': {
            'generatedAt': now.toIso8601String(),
            'surahId': 67,
            'newAyahs': const [],
            'nearRevision': const [],
            'farRevision': const [],
            'retentionReview': const [],
            'completedAyahNums': const [3],
          },
        },
        certRows: [
          {
            'cert_id': 'surah-67',
            'title_ar': 'سورة الملك',
            'cert_type': 'surah',
            'earned_at': now.toIso8601String(),
          },
        ],
        streakRow: null,
        activityRows: const [],
      );

      expect(summary.dailyPlanSurahId, 67);
      expect(summary.dailyPlanTotal, 3);
      expect(summary.dailyPlanCompleted, 1);
      expect(summary.dailyPlanRemaining, 2);
      expect(summary.certificates.single.certId, 'surah-67');
    });
  });
}

Map<String, dynamic> _reviewRow({
  required int surahId,
  required int ayahNumber,
  required int strengthLevel,
  required ReviewRecordCreatedByMode createdByMode,
  required DateTime lastReviewedAt,
}) {
  return {
    'surah_id': surahId,
    'ayah_number': ayahNumber,
    'strength_level': strengthLevel,
    'interval_days': 1,
    'last_reviewed_at': lastReviewedAt.toIso8601String(),
    'next_review_date': lastReviewedAt
        .add(const Duration(days: 1))
        .toIso8601String(),
    'total_reviews': 1,
    'last_rating': PerformanceRating.excellent.name,
    'ease_factor': 2.5,
    'lapses': 0,
    'review_state': ReviewState.review.name,
    'created_by_mode': createdByMode.name,
  };
}
