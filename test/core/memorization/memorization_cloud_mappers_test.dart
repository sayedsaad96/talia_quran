import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_cloud_mappers.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  test('maps kids learning metrics from cloud without spoken content', () {
    final mapper = MemorizationCloudMappers(const ProgressMetricsService());

    final log = mapper.logFromCloud({
      'local_id': 'review-session-1',
      'surah_id': 114,
      'ayah_number': 2,
      'repeats_completed': 1,
      'points_earned': 0,
      'completed_at': '2026-09-01T10:00:00.000Z',
      'mission_type': 'dueReview',
      'ayah_numbers': [1, 2, 3],
      'duration_seconds': 145,
      'attempt_count': 2,
      'hint_count': 1,
      'mastery_rating': 'average',
    });

    expect(log.missionType, KidsMissionType.dueReview);
    expect(log.ayahNumbers, [1, 2, 3]);
    expect(log.durationSeconds, 145);
    expect(log.attemptCount, 2);
    expect(log.hintCount, 1);
    expect(log.masteryRating, PerformanceRating.average);
  });

  test('falls back safely when cloud metrics come from the old schema', () {
    final mapper = MemorizationCloudMappers(const ProgressMetricsService());

    final log = mapper.logFromCloud({
      'id': 7,
      'surah_id': 114,
      'ayah_number': 1,
      'completed_at': '2026-09-01T10:00:00.000Z',
    });

    expect(log.missionType, KidsMissionType.newMemorization);
    expect(log.ayahNumbers, isEmpty);
    expect(log.durationSeconds, 0);
    expect(log.attemptCount, 1);
    expect(log.hintCount, 0);
    expect(log.masteryRating, PerformanceRating.excellent);
  });
}
