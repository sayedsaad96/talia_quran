import '../../features/memorization_plus/domain/entities/kids_progress.dart';
import '../../features/memorization_plus/domain/entities/kids_session_log.dart';

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

/// Combines local and cloud session logs into one completion per ayah.
///
/// A logical ayah key is used in addition to the immutable log id because
/// independently-created logs for the same ayah must never make the journey
/// count the completion twice.
class KidsSessionLogsCloudMerge {
  const KidsSessionLogsCloudMerge._();

  static List<KidsSessionLog> merge({
    required Iterable<KidsSessionLog> local,
    required Iterable<KidsSessionLog> remote,
  }) {
    final byId = <String, KidsSessionLog>{
      for (final log in local) log.id: log,
    };

    for (final cloudLog in remote) {
      final existing = byId[cloudLog.id];
      if (existing == null || _isPreferred(cloudLog, existing)) {
        byId[cloudLog.id] = cloudLog;
      }
    }

    final byAyah = <String, KidsSessionLog>{};
    for (final log in byId.values) {
      final key = '${log.surahId}:${log.ayahNumber}';
      final existing = byAyah[key];
      if (existing == null || _isPreferred(log, existing)) {
        byAyah[key] = log;
      }
    }

    final merged = byAyah.values.toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    return merged;
  }

  static int completedAyahsCount(Iterable<KidsSessionLog> logs) =>
      logs.map((log) => '${log.surahId}:${log.ayahNumber}').toSet().length;

  static bool _isPreferred(KidsSessionLog candidate, KidsSessionLog current) {
    if (candidate.isSynced != current.isSynced) return candidate.isSynced;
    return candidate.completedAt.isAfter(current.completedAt);
  }
}