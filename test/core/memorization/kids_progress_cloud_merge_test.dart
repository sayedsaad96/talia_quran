import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/kids_progress_cloud_merge.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_progress.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_log.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';

void main() {
  test('takes the greater numeric fields from either side', () {
    final merged = KidsProgressCloudMerge.merge(
      local: KidsProgress(
        totalPoints: 50,
        currentLevel: 2,
        currentStreak: 1,
        starsEarned: 3,
        ayahsCompleted: 4,
        lastSessionAt: DateTime.utc(2026, 8, 1),
      ),
      remote: KidsProgress(
        totalPoints: 80,
        currentLevel: 1,
        currentStreak: 5,
        starsEarned: 2,
        ayahsCompleted: 10,
        lastSessionAt: DateTime.utc(2026, 8, 7),
      ),
    );

    expect(merged.totalPoints, 80);
    expect(merged.currentLevel, 2);
    expect(merged.currentStreak, 5);
    expect(merged.starsEarned, 3);
    expect(merged.ayahsCompleted, 10);
    expect(merged.lastSessionAt, DateTime.utc(2026, 8, 7));
  });

  test('merges logs by id and logical ayah without duplicating completion', () {
    final local = KidsSessionLog(
      id: 'local-1',
      surahId: 1,
      ayahNumber: 1,
      repeatsCompleted: 3,
      pointsEarned: 14,
      completedAt: DateTime.utc(2026, 8, 1),
    );
    final remoteSameAyah = KidsSessionLog(
      id: 'remote-1',
      surahId: 1,
      ayahNumber: 1,
      repeatsCompleted: 3,
      pointsEarned: 14,
      completedAt: DateTime.utc(2026, 8, 2),
      syncedAt: DateTime.utc(2026, 8, 2),
    );
    final remoteDifferentAyah = KidsSessionLog(
      id: 'remote-2',
      surahId: 1,
      ayahNumber: 2,
      repeatsCompleted: 3,
      pointsEarned: 14,
      completedAt: DateTime.utc(2026, 8, 2),
      syncedAt: DateTime.utc(2026, 8, 2),
    );

    final merged = KidsSessionLogsCloudMerge.merge(
      local: [local],
      remote: [remoteSameAyah, remoteDifferentAyah],
    );

    expect(merged, hasLength(2));
    expect(
      merged.map((log) => '${log.surahId}:${log.ayahNumber}'),
      containsAll(['1:1', '1:2']),
    );
    expect(KidsSessionLogsCloudMerge.completedAyahsCount(merged), 2);
    expect(merged.singleWhere((log) => log.ayahNumber == 1).isSynced, isTrue);
  });
  test('keeps distinct review sessions while counting an ayah once', () {
    final first = KidsSessionLog(
      id: 'session-1',
      surahId: 114,
      ayahNumber: 1,
      repeatsCompleted: 1,
      pointsEarned: 10,
      completedAt: DateTime.utc(2026, 8, 1),
    );
    final review = KidsSessionLog(
      id: 'review-1',
      surahId: 114,
      ayahNumber: 1,
      repeatsCompleted: 1,
      pointsEarned: 0,
      completedAt: DateTime.utc(2026, 8, 8),
      missionType: KidsMissionType.dueReview,
    );

    final merged = KidsSessionLogsCloudMerge.merge(
      local: [first],
      remote: [review],
    );

    expect(merged.map((log) => log.id), ['session-1', 'review-1']);
    expect(KidsSessionLogsCloudMerge.completedAyahsCount(merged), 1);
  });
  test('cloud acknowledgement does not erase local learning metrics', () {
    final local = KidsSessionLog(
      id: 'review-session',
      surahId: 114,
      ayahNumber: 2,
      repeatsCompleted: 1,
      pointsEarned: 0,
      completedAt: DateTime.utc(2026, 8, 8),
      missionType: KidsMissionType.dueReview,
      ayahNumbers: const [1, 2],
      durationSeconds: 90,
      attemptCount: 2,
      hintCount: 1,
      masteryRating: PerformanceRating.average,
    );
    final cloudAcknowledgement = KidsSessionLog(
      id: 'review-session',
      surahId: 114,
      ayahNumber: 2,
      repeatsCompleted: 1,
      pointsEarned: 0,
      completedAt: DateTime.utc(2026, 8, 8),
      syncedAt: DateTime.utc(2026, 8, 9),
    );

    final merged = KidsSessionLogsCloudMerge.merge(
      local: [local],
      remote: [cloudAcknowledgement],
    ).single;

    expect(merged.isSynced, isTrue);
    expect(merged.missionType, KidsMissionType.dueReview);
    expect(merged.ayahNumbers, [1, 2]);
    expect(merged.durationSeconds, 90);
    expect(merged.attemptCount, 2);
    expect(merged.hintCount, 1);
    expect(merged.masteryRating, PerformanceRating.average);
  });
}
