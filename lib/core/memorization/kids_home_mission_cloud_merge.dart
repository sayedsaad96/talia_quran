import '../../features/memorization_plus/domain/entities/kids_home_mission.dart';

/// Pure merge of the child's local home missions with the server rows.
///
/// Status only moves forward (`assigned → reported → acknowledged`):
/// - a higher server status wins (the pending flag is cleared: the server has
///   the report);
/// - a local `reported` mission the server still shows `assigned` (offline
///   report not pushed yet) keeps its local state and its pending flag;
/// - server rows missing locally are added (oldest first, after local ones);
/// - local rows missing on the server (never-synced `local-...` ids) are
///   untouched;
/// - with [dropMissingServerIds] (a SUCCESSFUL child pull, P3-R14), local
///   rows whose id is a server id but absent from [remote] are orphans (link
///   revoked, mission removed) and are dropped, unless a report is still
///   pending (`pendingReportSync`) so it is never lost silently.
abstract final class KidsHomeMissionCloudMerge {
  static List<KidsHomeMission> merge({
    required List<KidsHomeMission> local,
    required List<KidsHomeMission> remote,
    bool dropMissingServerIds = false,
  }) {
    final remoteById = {for (final m in remote) m.id: m};
    final localIds = {for (final m in local) m.id};
    bool isOrphan(KidsHomeMission m) =>
        dropMissingServerIds &&
        !remoteById.containsKey(m.id) &&
        int.tryParse(m.id) != null &&
        !m.pendingReportSync;
    final merged = <KidsHomeMission>[
      for (final mission in local)
        if (!isOrphan(mission)) _mergeOne(mission, remoteById[mission.id]),
      ...(remote.where((m) => !localIds.contains(m.id)).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt))),
    ];
    return merged;
  }

  static KidsHomeMission _mergeOne(
    KidsHomeMission local,
    KidsHomeMission? remote,
  ) {
    if (remote == null) return local;
    if (remote.status.index > local.status.index) {
      return remote.copyWith(pendingReportSync: false);
    }
    if (remote.status == local.status) {
      // The server already holds this state: take its authoritative copy.
      return remote.copyWith(pendingReportSync: false);
    }
    // Local is ahead (e.g. an unpushed offline report): keep it as is.
    return local;
  }
}
