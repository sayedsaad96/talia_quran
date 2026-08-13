import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/custom_plan_cloud_merge.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/review_record_cloud_push_acknowledgement.dart';
import 'package:talia_quran/core/memorization/review_record_pull_cursor.dart';
import 'package:talia_quran/core/memorization/review_record_identity.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

AyahReviewRecord _record({
  required int surahId,
  required int ayahNumber,
  ReviewRecordCreatedByMode mode = ReviewRecordCreatedByMode.v2Session,
}) {
  final reviewedAt = DateTime.utc(2026, 8, 10, 1);
  return AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: 2,
    intervalDays: 3,
    lastReviewedAt: reviewedAt,
    nextReviewDate: reviewedAt.add(const Duration(days: 3)),
    totalReviews: 4,
    lastRating: PerformanceRating.average,
    createdByMode: mode,
  );
}

void main() {
  group('review record cloud push acknowledgement', () {
    test('returns only sent rows accepted by the RPC', () {
      final sent = [
        _record(surahId: 1, ayahNumber: 1),
        _record(surahId: 1, ayahNumber: 2),
      ];

      final accepted = ReviewRecordCloudPushAcknowledgement.storageKeys(
        ownerUserId: 'user-a',
        sentRecords: sent,
        acknowledgedRows: const [
          {'surah_id': 1, 'ayah_number': 1, 'audience': 'adult'},
        ],
      );

      expect(accepted, {
        const ReviewRecordIdentity(
          ownerUserId: 'user-a',
          audience: ReviewRecordReadScope.adult,
          surahId: 1,
          ayahNumber: 1,
        ).storageKey,
      });
    });
  });

  group('review record pull cursor', () {
    test('advances through rows with the same timestamp by ID', () {
      final timestamp = DateTime.utc(2026, 8, 10, 2);
      final cursor = ReviewRecordPullCursor(timestamp, 41);

      expect(
        cursor.isBefore(
          ReviewRecordPullCursor.fromCloudRow({
            'updated_at': timestamp.toIso8601String(),
            'id': 42,
          }),
        ),
        isTrue,
      );
    });

    test('reads legacy timestamp-only storage at ID zero', () {
      final timestamp = DateTime.utc(2026, 8, 10, 2);

      expect(
        ReviewRecordPullCursor.fromStorage(timestamp.toIso8601String()),
        ReviewRecordPullCursor(timestamp, 0),
      );
    });
  });

  group('custom plan cloud merge', () {
    test('rejects a stale remote row when a clean local plan is newer', () {
      expect(
        CustomPlanCloudMerge.shouldApplyRemote(
          localDirty: false,
          localUpdatedAt: DateTime.utc(2026, 8, 10, 3),
          remoteUpdatedAt: DateTime.utc(2026, 8, 10, 2),
        ),
        isFalse,
      );
    });
  });
}
