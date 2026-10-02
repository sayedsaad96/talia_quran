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

  /// Calls [reportRpc] for every locally pending report with a server id and
  /// clears the flag on success. A failing mission (offline, link revoked,
  /// mission not found) keeps its flag and is retried on the next sync only.
  Future<void> push({
    required String ownerId,
    required Future<void> Function(int missionId) reportRpc,
  }) async {
    try {
      final pending = (await _datasource.getHomeMissions())
          .where((m) => m.pendingReportSync)
          .toList();
      final accepted = <String>{};
      for (final mission in pending) {
        final serverId = int.tryParse(mission.id);
        if (serverId == null) continue;
        try {
          if (_owner.currentOwnerId != ownerId) return;
          await reportRpc(serverId);
          accepted.add(mission.id);
        } catch (e) {
          TaliaLogger.w('Kids home mission report push failed', e);
        }
      }
      if (accepted.isEmpty || _owner.currentOwnerId != ownerId) return;
      await _datasource.updateHomeMissions(
        (local) async => [
          for (final m in local)
            accepted.contains(m.id) && m.pendingReportSync
                ? m.copyWith(pendingReportSync: false)
                : m,
        ],
      );
    } catch (e) {
      TaliaLogger.w('Kids home missions push skipped', e);
    }
  }
}
