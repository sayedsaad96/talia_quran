import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/group_khatmah.dart';
import 'group_khatmah_remote.dart';

/// Reads only rows allowed by group RLS and rejects torn multi-table snapshots.
class SupabaseGroupKhatmahRemote implements GroupKhatmahRemote {
  const SupabaseGroupKhatmahRemote(this._client, {this.pageSize = 30});
  final SupabaseClient _client;
  final int pageSize;

  void _checkOwner(String ownerId) {
    if (ownerId.isEmpty ||
        _client.auth.currentUser?.id != ownerId ||
        _client.auth.currentSession?.user.id != ownerId) {
      throw const GroupRemoteOwnerChanged();
    }
  }

  Future<T> _forOwner<T>(String ownerId, Future<T> Function() request) async {
    _checkOwner(ownerId);
    final value = await request();
    _checkOwner(ownerId);
    return value;
  }

  @override
  Future<Map<String, dynamic>> rpc(
    String function,
    Map<String, dynamic> args, {
    required String ownerId,
  }) async {
    const allowed = {
      'create_group_khatmah',
      'join_group_khatmah',
      'claim_group_part',
      'complete_group_part',
      'release_group_part',
      'leave_group_khatmah',
    };
    if (!allowed.contains(function)) throw const FormatException('rpc name');
    final value = await _forOwner(
      ownerId,
      () => _client.rpc(function, params: args),
    );
    if (value is! Map) throw const FormatException('rpc envelope');
    final result = Map<String, dynamic>.from(value);
    if (result['applied'] is! bool || result['code'] is! String) {
      throw const FormatException('rpc envelope');
    }
    return result;
  }

  @override
  Future<GroupKhatmahPage> fetchMine({
    required String ownerId,
    String? cursor,
  }) async {
    if (pageSize < 1 || pageSize > 100) {
      throw const FormatException('page size');
    }
    var query = _client
        .from('group_khatmah_member')
        .select('group_id')
        .eq('user_id', ownerId)
        .isFilter('left_at', null);
    if (cursor != null) query = query.gt('group_id', cursor);
    final rows = await _forOwner(
      ownerId,
      () => query.order('group_id').limit(pageSize),
    );
    final ids = [for (final row in rows) (row['group_id'] as String)];
    final groups = <GroupKhatmah>[];
    for (final id in ids) {
      final group = await fetchGroup(ownerId: ownerId, groupId: id);
      if (group != null) groups.add(group);
    }
    return GroupKhatmahPage(
      groups: groups,
      nextCursor: ids.length == pageSize ? ids.last : null,
    );
  }

  @override
  Future<GroupKhatmah?> fetchGroup({
    required String ownerId,
    required String groupId,
  }) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final before = await _member(ownerId, groupId);
      if (before == null) return null;
      final group = await _group(ownerId, groupId);
      if (group == null) return null;
      final members = await _members(ownerId, groupId);
      final parts = await _parts(ownerId, groupId);
      final after = await _member(ownerId, groupId);
      final latest = await _group(ownerId, groupId);
      if (after == null || latest == null) return null;
      if (before['membership_epoch'] != after['membership_epoch'] ||
          group['version'] != latest['version']) {
        continue;
      }
      if (parts.length != 30 ||
          {for (final row in parts) row['juz']}.length != 30) {
        throw const FormatException('incomplete parts');
      }
      return GroupKhatmah.fromJson({
        ...group,
        'membership_epoch': after['membership_epoch'],
        'members': members,
        'parts': parts,
      });
    }
    throw const FormatException('unstable group snapshot');
  }

  Future<Map<String, dynamic>?> _member(String ownerId, String groupId) async =>
      _forOwner(
        ownerId,
        () => _client
            .from('group_khatmah_member')
            .select('group_id,user_id,membership_epoch')
            .eq('group_id', groupId)
            .eq('user_id', ownerId)
            .isFilter('left_at', null)
            .maybeSingle(),
      );

  Future<Map<String, dynamic>?> _group(
    String ownerId,
    String groupId,
  ) async => _forOwner(
    ownerId,
    () => _client
        .from('group_khatmah')
        .select(
          'id,code,title,owner_id,max_members,status,version,created_at,completed_at',
        )
        .eq('id', groupId)
        .maybeSingle(),
  );

  Future<List<Map<String, dynamic>>> _members(
    String ownerId,
    String groupId,
  ) async => _forOwner(
    ownerId,
    () => _client
        .from('group_khatmah_member')
        .select(
          'group_id,user_id,display_name,joined_at,left_at,membership_epoch',
        )
        .eq('group_id', groupId)
        .isFilter('left_at', null)
        .order('user_id'),
  );

  Future<List<Map<String, dynamic>>> _parts(
    String ownerId,
    String groupId,
  ) async => _forOwner(
    ownerId,
    () => _client
        .from('group_khatmah_part')
        .select('group_id,juz,status,claimed_by,claim_epoch,version,updated_at')
        .eq('group_id', groupId)
        .order('juz'),
  );
}

class GroupRemoteOwnerChanged implements Exception {
  const GroupRemoteOwnerChanged();
}
