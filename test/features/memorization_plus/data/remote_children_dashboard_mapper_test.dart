import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_cloud_mappers.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  final mapper = MemorizationCloudMappers(const ProgressMetricsService());

  Map<String, dynamic> child({
    required Map<String, dynamic> reviewSummary,
    Object? activitySnapshot,
  }) => {
    'child_user_id': 'child-1',
    'display_name': 'Maryam',
    'logs': <dynamic>[],
    'rewards': <dynamic>[],
    'review_summary': reviewSummary,
    'daily_plan': null,
    'certificates': <dynamic>[],
    'streak': null,
    'activities': <dynamic>[],
    'activity_snapshot': activitySnapshot,
  };

  Map<String, dynamic> snapshot({Map<String, dynamic>? overrides}) => {
    'device_id': '00000000-0000-0000-0000-000000000001',
    'updated_at': '2026-10-05T06:30:00+00:00',
    'revision': 7,
    'snapshot': {
      'day_key': '2026-10-05',
      'read_pages_count': 40,
      'total_xp': 1200,
      'current_streak': 4,
      'longest_streak': 11,
      'active_days_last_30': 18,
      'today_activity_count': 3,
      'today_read_pages_count': 2,
      'activities': <dynamic>[],
      ...?overrides,
    },
  };

  group('review summary', () {
    test('tracked ayahs come from tracked_count, not review events', () {
      final summary = mapper.remoteChildSummaryFromDashboardJson(
        child(
          reviewSummary: {
            'review_count': 20,
            'tracked_count': 5,
            'memorized_count': 3,
            'overdue_count': 1,
          },
        ),
      );

      expect(summary.production!.totalAyahsTracked, 5);
      expect(summary.production!.reviewsCompleted, 20);
      expect(summary.production!.totalMemorizedAyahs, 3);
    });

    test('a server without tracked_count keeps review_count as ayahs', () {
      final summary = mapper.remoteChildSummaryFromDashboardJson(
        child(reviewSummary: {'review_count': 5, 'memorized_count': 2}),
      );

      expect(summary.production!.totalAyahsTracked, 5);
    });
  });

  group('activity snapshot', () {
    test('is parsed and feeds streak and active days', () {
      final summary = mapper.remoteChildSummaryFromDashboardJson(
        child(
          reviewSummary: {'review_count': 0, 'tracked_count': 0},
          activitySnapshot: snapshot(),
        ),
      );

      final activity = summary.activity!;
      expect(activity.updatedAt, DateTime.utc(2026, 10, 5, 6, 30));
      expect(activity.dayKey, '2026-10-05');
      expect(activity.readPagesCount, 40);
      expect(activity.todayReadPagesCount, 2);
      expect(activity.totalXp, 1200);
      expect(summary.production!.currentStreak, 4);
      expect(summary.production!.longestStreak, 11);
      expect(summary.production!.activeDaysLast30, 18);
    });

    test('reads the kids progress extras when present', () {
      final activity = mapper.activityFromDashboardJson(
        snapshot(
          overrides: {
            'week_read_pages_count': 6,
            'achievements': [
              {'id': 'firstAyah', 'at': '2026-09-01T00:00:00Z'},
              {'id': 42, 'at': 'bad'},
            ],
            'activities': [
              {
                'at': '2026-10-05T06:00:00Z',
                'kind': 'memorize',
                'key': 'memorize|kids|20261005|114:3',
                'surah': 114,
                'start': 1,
                'end': 3,
              },
              {'at': 'nope', 'kind': 'reading', 'key': 'x'},
            ],
          },
        ),
      )!;

      expect(activity.weekReadPagesCount, 6);
      expect(activity.achievements, {'firstAyah': DateTime.utc(2026, 9, 1)});
      expect(activity.events.single.surahId, 114);
      expect(activity.events.single.endAyah, 3);
      expect(activity.events.single.kind.name, 'memorize');
      expect(activity.events.single.isKids, isTrue);
    });

    test('an older snapshot without the extras still parses', () {
      final activity = mapper.activityFromDashboardJson(snapshot())!;

      expect(activity.weekReadPagesCount, isNull);
      expect(activity.achievements, isEmpty);
      expect(activity.events, isEmpty);
    });

    test('absent snapshot stays null instead of zero activity', () {
      final summary = mapper.remoteChildSummaryFromDashboardJson(
        child(reviewSummary: {'review_count': 0, 'tracked_count': 0}),
      );

      expect(summary.activity, isNull);
      expect(summary.production!.currentStreak, isNull);
    });

    test('malformed snapshot is ignored', () {
      expect(mapper.activityFromDashboardJson('oops'), isNull);
      expect(
        mapper.activityFromDashboardJson(
          snapshot(overrides: {'current_streak': 'four'}),
        ),
        isNull,
      );
      expect(
        mapper.activityFromDashboardJson({...snapshot(), 'updated_at': null}),
        isNull,
      );
    });

    test('the dashboard copy keeps the activity snapshot', () {
      final summary = mapper.remoteChildSummaryFromDashboardJson(
        child(reviewSummary: {'review_count': 0}, activitySnapshot: snapshot()),
      );

      expect(
        summary.copyWith(policyUnavailable: true).activity,
        summary.activity,
      );
    });
  });

  group('gift rows', () {
    Map<String, dynamic> row(String status, {String? requestedAt}) => {
      'id': 7,
      'title': 'نزهة',
      'status': status,
      'created_at': '2026-10-01T08:00:00Z',
      'unlocked_at': '2026-10-02T08:00:00Z',
      'requested_at': requestedAt,
      'claimed_at': null,
    };

    test('a requested gift keeps its request time', () {
      final reward = mapper.rewardFromCloud(
        row('requested', requestedAt: '2026-10-03T08:00:00Z'),
      );

      expect(reward.id, '7');
      expect(reward.status, ParentRewardStatus.requested);
      expect(reward.requestedAt, DateTime.utc(2026, 10, 3, 8));
      expect(reward.claimedAt, isNull);
    });

    test('an unknown status reads as locked', () {
      final reward = mapper.rewardFromCloud(row('lost'));

      expect(reward.status, ParentRewardStatus.locked);
      expect(reward.requestedAt, isNull);
    });
  });
}
