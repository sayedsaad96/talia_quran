import '../../../../../core/identity/record_owner_provider.dart';
import '../../../../../core/memorization/kids_home_mission_cloud_merge.dart';
import '../../../../../core/utils/talia_logger.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import 'memorization_cloud_mappers.dart';

/// Child-side home-mission sync: merges the server rows into the local list
/// and pushes reports made offline. Transport is injected so the logic is
/// testable without a live Supabase client. Never throws: a failure here must
/// not fail the rest of the kids sync, and a pending report is never lost.
class KidsHomeMissionChildSync {
  KidsHomeMissionChildSync(this._datasource, this._mappers, this._owner);

  final MemorizationPlusLocalDatasource _datasource;
  final MemorizationCloudMappers _mappers;
  final RecordOwnerProvider _owner;

  /// Fetches the child's server rows and merges them under the local lock.
  Future<void> pull({
    required String ownerId,
    required Future<List<Map<String, dynamic>>> Function() fetchRows,
  }) async {
    try {
      final rows = await fetchRows();
      if (_owner.currentOwnerId != ownerId) return;
      final remote = rows
          .map((row) => _mappers.homeMissionFromCloud(row))
          .toList();
      await _datasource.updateHomeMissions(
        (local) async =>
            KidsHomeMissionCloudMerge.merge(local: local, remote: remote),
      );
    } catch (e) {
      TaliaLogger.w('Kids home missions pull skipped', e);
    }
  }

  /// Server errors that will never succeed for this mission.
  static const _terminalMessages = [
    'Child link is not active',
    'Mission not found',
  ];

  static bool _isTerminal(Object error) {
    final text = error.toString();
    return _terminalMessages.any(text.contains);
  }

  /// Calls [reportRpc] for every locally pending report with a server id.
  ///
  /// - Success clears `pendingReportSync`.
  /// - A terminal error ("Child link is not active", "Mission not found")
  ///   also clears the flag so it is not retried forever; the local `reported`
  ///   status stays. If the child re-links to a guardian later, that old
  ///   report is NOT re-sent.
  /// - Any other error is transient: the flag is kept and the method returns
  ///   `true` so the caller can surface a retryable failure.
  ///
  /// Returns whether any transient failure happened. Never throws.
  Future<bool> push({
    required String ownerId,
    required Future<void> Function(int missionId) reportRpc,
  }) async {
    var hadTransientFailure = false;
    try {
      final pending = (await _datasource.getHomeMissions())
          .where((m) => m.pendingReportSync)
          .toList();
      final toClear = <String>{};
      for (final mission in pending) {
        final serverId = int.tryParse(mission.id);
        if (serverId == null) continue;
        try {
          if (_owner.currentOwnerId != ownerId) return hadTransientFailure;
          await reportRpc(serverId);
          toClear.add(mission.id);
        } catch (e) {
          if (_isTerminal(e)) {
            TaliaLogger.w('Kids home mission report rejected', e);
            toClear.add(mission.id);
          } else {
            TaliaLogger.w('Kids home mission report push failed', e);
            hadTransientFailure = true;
          }
        }
      }
      if (toClear.isEmpty || _owner.currentOwnerId != ownerId) {
        return hadTransientFailure;
      }
      await _datasource.updateHomeMissions(
        (local) async => [
          for (final m in local)
            toClear.contains(m.id) && m.pendingReportSync
                ? m.copyWith(pendingReportSync: false)
                : m,
        ],
      );
    } catch (e) {
      TaliaLogger.w('Kids home missions push skipped', e);
      hadTransientFailure = true;
    }
    return hadTransientFailure;
  }
}
