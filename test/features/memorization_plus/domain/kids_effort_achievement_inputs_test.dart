import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_progress.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_log.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/remote_child_activity.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/remote_child_summary.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_achievements.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_effort_achievement_inputs.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_progress_snapshot.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

KidsSessionLog _log(
  String id, {
  required DateTime at,
  KidsMissionType type = KidsMissionType.newMemorization,
  int points = 0,
  int attempts = 1,
}) => KidsSessionLog(
  id: id,
  surahId: 1,
  ayahNumber: 1,
  repeatsCompleted: 1,
  pointsEarned: points,
  completedAt: at,
  missionType: type,
  attemptCount: attempts,
  masteryRating: PerformanceRating.average,
);

void main() {
  final day1 = DateTime(2026, 10, 1, 10);

  group('buildKidsEffortInputs', () {
    test('an empty history counts nothing', () {
      expect(
        buildKidsEffortInputs(const []),
        const KidsEffortAchievementInputs(),
      );
    });

    test('a review with zero points still counts as a completed review', () {
      final inputs = buildKidsEffortInputs([
        _log('r1', at: day1, type: KidsMissionType.dueReview),
        _log('r2', at: day1, type: KidsMissionType.linkedReview, points: 2),
        _log('n1', at: day1),
      ]);

      expect(inputs.completedReviews, 2);
    });

    test('only a success after several attempts counts as a retry', () {
      final inputs = buildKidsEffortInputs([
        _log('a', at: day1),
        _log('b', at: day1.add(const Duration(hours: 1)), attempts: 3),
      ]);

      expect(inputs.retriedSuccesses, 1);
    });

    test('a log repeated by a retry or a cloud merge counts once', () {
      final inputs = buildKidsEffortInputs([
        _log('r1', at: day1, type: KidsMissionType.dueReview, attempts: 2),
        _log('r1', at: day1, type: KidsMissionType.dueReview, attempts: 2),
      ]);

      expect(inputs.completedReviews, 1);
      expect(inputs.retriedSuccesses, 1);
    });

    test('a gap of three local days is a comeback; two is not', () {
      final two = buildKidsEffortInputs([
        _log('a', at: day1),
        _log('b', at: day1.add(const Duration(days: 2))),
      ]);
      final three = buildKidsEffortInputs([
        _log('a', at: day1),
        _log('b', at: day1.add(const Duration(days: 3))),
        _log('c', at: day1.add(const Duration(days: 3, hours: 1))),
      ]);

      expect(two.comebacks, 0);
      expect(three.comebacks, 1);
    });

    test('input order does not matter', () {
      final logs = [
        _log('b', at: day1.add(const Duration(days: 5))),
        _log('a', at: day1),
      ];

      expect(buildKidsEffortInputs(logs).comebacks, 1);
      expect(buildKidsEffortInputs(logs.reversed).comebacks, 1);
    });
  });

  group('catalog', () {
    final now = DateTime.utc(2026, 10, 8);
    const effort = KidsEffortAchievementInputs(
      completedReviews: 1,
      retriedSuccesses: 1,
      comebacks: 1,
    );

    test('effort milestones are absent while the feature is off', () {
      final all = KidsAchievementCatalog.evaluate(
        const KidsAchievementInputs(),
        now: now,
      );

      expect(all, hasLength(KidsAchievementCatalog.specs.length));
      expect(
        all.map((a) => a.id),
        isNot(contains(KidsAchievementId.firstReview)),
      );
    });

    test('they unlock from the effort counts and carry no memorization', () {
      final all = KidsAchievementCatalog.evaluate(
        const KidsAchievementInputs(effort: effort),
        now: now,
      );
      KidsAchievement find(KidsAchievementId id) =>
          all.singleWhere((a) => a.id == id);

      expect(find(KidsAchievementId.firstReview).isUnlocked, isTrue);
      expect(find(KidsAchievementId.triedAgain).isUnlocked, isTrue);
      expect(find(KidsAchievementId.comeback).isUnlocked, isTrue);
      expect(find(KidsAchievementId.firstAyah).isUnlocked, isFalse);
    });

    test('the original milestones keep their stored names and order', () {
      expect(KidsAchievementId.values.take(16).map((e) => e.name).toList(), [
        'firstAyah',
        'ayahs10',
        'ayahs50',
        'ayahs100',
        'firstSurah',
        'surahs3',
        'surahs10',
        'firstPage',
        'pages10',
        'pages30',
        'streak3',
        'streak7',
        'streak30',
        'firstStar',
        'stars10',
        'stars50',
      ]);
    });
  });

  group('loader', () {
    final now = DateTime(2026, 10, 8, 9);

    KidsProgressSnapshotLoader loader({
      Future<List<KidsSessionLog>> Function()? sessionLogs,
      bool enabled = true,
    }) => KidsProgressSnapshotLoader(
      progress: () async => const KidsProgress.initial(),
      streak: () async =>
          const StreakEntity(currentStreak: 0, longestStreak: 0),
      pagesOn: (_) async => const {},
      allPages: () async => const {},
      certificates: () => const [],
      recentActivity: () async => const [],
      achievements: (inputs) async =>
          KidsAchievementCatalog.evaluate(inputs, now: now.toUtc()),
      sessionLogs: sessionLogs,
      effortEnabled: () => enabled,
      clock: () => now,
    );

    test('flag on: a completed review unlocks its milestone', () async {
      final snapshot = await loader(
        sessionLogs: () async => [
          _log('r1', at: day1, type: KidsMissionType.dueReview),
        ],
      ).load();

      expect(
        snapshot.achievements
            .singleWhere((a) => a.id == KidsAchievementId.firstReview)
            .isUnlocked,
        isTrue,
      );
    });

    test('flag off: the logs are never read and nothing is shown', () async {
      var read = false;
      final snapshot = await loader(
        enabled: false,
        sessionLogs: () async {
          read = true;
          return const [];
        },
      ).load();

      expect(read, isFalse);
      expect(
        snapshot.achievements.map((a) => a.id),
        isNot(contains(KidsAchievementId.firstReview)),
      );
    });

    test('unreadable logs unlock nothing and do not break the page', () async {
      final snapshot = await loader(
        sessionLogs: () async => throw StateError('storage unavailable'),
      ).load();

      expect(snapshot.achievements, isNotEmpty);
      expect(
        snapshot.achievements.map((a) => a.id),
        isNot(contains(KidsAchievementId.firstReview)),
      );
    });
  });

  group('guardian view', () {
    final now = DateTime.utc(2026, 10, 8, 9);

    RemoteChildSummary summary(Map<String, DateTime> achievements) =>
        RemoteChildSummary(
          childUserId: 'child-1',
          displayName: 'مريم',
          progress: const KidsProgress.initial(),
          logs: const [],
          rewards: const [],
          activity: RemoteChildActivity(
            updatedAt: now,
            dayKey: '2026-10-08',
            currentStreak: 0,
            longestStreak: 0,
            activeDaysLast30: 0,
            totalXp: 0,
            readPagesCount: 0,
            todayActivityCount: 0,
            todayReadPagesCount: 0,
            achievements: achievements,
          ),
        );

    test('shows only the effort milestones the child device reported', () {
      final snapshot = remoteKidsProgressSnapshot(
        summary({'triedAgain': DateTime.utc(2026, 10, 2)}),
        now: now,
        includeEffort: true,
      );
      final effort = snapshot.achievements
          .where(
            (a) => KidsAchievementCatalog.effortSpecs.any((s) => s.id == a.id),
          )
          .toList();

      expect(effort.map((a) => a.id), [KidsAchievementId.triedAgain]);
      expect(effort.single.unlockedAt, DateTime.utc(2026, 10, 2));
    });

    test('hides them while the guardian-side flag is off', () {
      final snapshot = remoteKidsProgressSnapshot(
        summary({'triedAgain': DateTime.utc(2026, 10, 2)}),
        now: now,
      );

      expect(
        snapshot.achievements.map((a) => a.id),
        isNot(contains(KidsAchievementId.triedAgain)),
      );
    });
  });
}
