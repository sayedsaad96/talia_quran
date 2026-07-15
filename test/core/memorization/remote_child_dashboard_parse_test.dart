import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/remote_child_production_summary_builder.dart';

void main() {
  group('RemoteChildProductionSummaryBuilder', () {
    const builder = RemoteChildProductionSummaryBuilder();

    test('builds summary from dashboard-shaped cloud rows', () {
      final summary = builder.build(
        reviewRows: const [
          {
            'surah_id': 114,
            'ayah_number': 1,
            'strength_level': 6,
            'interval_days': 7,
            'last_reviewed_at': '2026-05-01T10:00:00.000Z',
            'next_review_date': '2026-05-08T10:00:00.000Z',
            'total_reviews': 3,
            'last_rating': 'excellent',
            'ease_factor': 2.5,
            'lapses': 0,
            'review_state': 'review',
            'created_by_mode': 'kidsMode',
          },
        ],
        dailyPlanRow: const {
          'surah_id': 114,
          'generated_at': '2026-05-01T10:00:00.000Z',
          'total_items': 5,
          'completed_count': 2,
          'payload': {
            'surahId': 114,
            'generatedAt': '2026-05-01T10:00:00.000Z',
            'totalItems': 5,
            'requiredCompletedCount': 2,
            'requiredAyahs': [],
            'retentionReview': [],
          },
        },
        certRows: const [
          {
            'cert_id': 'surah_114',
            'title_ar': 'سورة الناس',
            'cert_type': 'surah',
            'earned_at': '2026-05-01T10:00:00.000Z',
          },
        ],
        streakRow: const {
          'current_streak': 4,
          'longest_streak': 10,
        },
        activityRows: const [
          {'day_key': 20260501, 'activity_count': 2},
          {'day_key': 20260502, 'activity_count': 0},
        ],
      );

      expect(summary.totalMemorizedAyahs, 1);
      expect(summary.currentStreak, 4);
      expect(summary.certificates, hasLength(1));
      expect(summary.activeDaysLast30, 1);
    });
  });
}
