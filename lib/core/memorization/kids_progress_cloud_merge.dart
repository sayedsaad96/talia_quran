import '../../features/memorization_plus/domain/entities/kids_progress.dart';
import '../../features/memorization_plus/domain/entities/kids_session_log.dart';
import '../../features/memorization_plus/domain/entities/kids_session_policy.dart';

/// Merges cloud kids progress into local using GREATEST-style field rules
/// (matches `upsert_kids_progress_cloud` on the server).
class KidsProgressCloudMerge {
  const KidsProgressCloudMerge._();

  static KidsProgress merge({
    required KidsProgress local,
    required KidsProgress remote,
  }) {
    DateTime? lastSession;
    if (local.lastSessionAt == null) {
      lastSession = remote.lastSessionAt;
    } else if (remote.lastSessionAt == null) {
      lastSession = local.lastSessionAt;
    } else {
      lastSession = remote.lastSessionAt!.isAfter(local.lastSessionAt!)
          ? remote.lastSessionAt
          : local.lastSessionAt;
    }

    return KidsProgress(
      totalPoints: local.totalPoints > remote.totalPoints
          ? local.totalPoints
          : remote.totalPoints,
      currentLevel: local.currentLevel > remote.currentLevel
          ? local.currentLevel
          : remote.currentLevel,
      currentStreak: local.currentStreak > remote.currentStreak
          ? local.currentStreak
          : remote.currentStreak,
      starsEarned: local.starsEarned > remote.starsEarned
          ? local.starsEarned
          : remote.starsEarned,
      ayahsCompleted: local.ayahsCompleted > remote.ayahsCompleted
          ? local.ayahsCompleted
          : remote.ayahsCompleted,
      lastSessionAt: lastSession,
    );
  }
}

/// Combines local and cloud session logs without discarding review history.
///
/// Immutable session ids provide idempotency. A second guard collapses only
/// reward-bearing new-memorization logs for the same ayah, which can be created
/// concurrently on two devices. Due and linked reviews remain separate events,
/// while [completedAyahsCount] still counts every ayah once.
class KidsSessionLogsCloudMerge {
  const KidsSessionLogsCloudMerge._();

  static List<KidsSessionLog> merge({
    required Iterable<KidsSessionLog> local,
    required Iterable<KidsSessionLog> remote,
  }) {
    final byId = <String, KidsSessionLog>{for (final log in local) log.id: log};

    for (final cloudLog in remote) {
      final existing = byId[cloudLog.id];
      byId[cloudLog.id] = existing == null
          ? cloudLog
          : _mergeMatchingSession(existing, cloudLog);
    }

    final rewardByAyah = <String, KidsSessionLog>{};
    final merged = <KidsSessionLog>[];
    for (final log in byId.values) {
      if (!_isNewMemorizationReward(log)) {
        merged.add(log);
        continue;
      }

      final key = '${log.surahId}:${log.ayahNumber}';
      final existing = rewardByAyah[key];
      if (existing == null || _isPreferred(log, existing)) {
        rewardByAyah[key] = log;
      }
    }

    merged.addAll(rewardByAyah.values);
    merged.sort((a, b) => a.completedAt.compareTo(b.completedAt));
    return merged;
  }

  static bool _isNewMemorizationReward(KidsSessionLog log) =>
      log.missionType == KidsMissionType.newMemorization &&
      log.pointsEarned > 0;

  static KidsSessionLog _mergeMatchingSession(
    KidsSessionLog local,
    KidsSessionLog cloud,
  ) {
    final detailed = _learningDetailScore(cloud) > _learningDetailScore(local)
        ? cloud
        : local;
    final preferred = _isPreferred(cloud, local) ? cloud : local;

    return KidsSessionLog(
      id: local.id,
      surahId: preferred.surahId,
      ayahNumber: preferred.ayahNumber,
      repeatsCompleted: local.repeatsCompleted > cloud.repeatsCompleted
          ? local.repeatsCompleted
          : cloud.repeatsCompleted,
      pointsEarned: local.pointsEarned > cloud.pointsEarned
          ? local.pointsEarned
          : cloud.pointsEarned,
      completedAt: preferred.completedAt,
      syncedAt: cloud.syncedAt ?? local.syncedAt,
      missionType: detailed.missionType,
      ayahNumbers: detailed.ayahNumbers,
      durationSeconds: local.durationSeconds > cloud.durationSeconds
          ? local.durationSeconds
          : cloud.durationSeconds,
      attemptCount: local.attemptCount > cloud.attemptCount
          ? local.attemptCount
          : cloud.attemptCount,
      hintCount: local.hintCount > cloud.hintCount
          ? local.hintCount
          : cloud.hintCount,
      masteryRating: local.masteryRating.index > cloud.masteryRating.index
          ? local.masteryRating
          : cloud.masteryRating,
    );
  }

  static int _learningDetailScore(KidsSessionLog log) =>
      log.ayahNumbers.length +
      (log.missionType == KidsMissionType.newMemorization ? 0 : 1) +
      (log.durationSeconds > 0 ? 1 : 0) +
      (log.attemptCount > 1 ? 1 : 0) +
      (log.hintCount > 0 ? 1 : 0) +
      (log.masteryRating.index > 0 ? 1 : 0);

  static int completedAyahsCount(Iterable<KidsSessionLog> logs) =>
      logs.map((log) => '${log.surahId}:${log.ayahNumber}').toSet().length;

  static bool _isPreferred(KidsSessionLog candidate, KidsSessionLog current) {
    if (candidate.isSynced != current.isSynced) return candidate.isSynced;
    return candidate.completedAt.isAfter(current.completedAt);
  }
}
