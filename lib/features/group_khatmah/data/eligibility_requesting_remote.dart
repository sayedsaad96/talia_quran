import '../domain/entities/group_khatmah.dart';
import 'group_khatmah_remote.dart';
import 'supabase_group_khatmah_remote.dart' show GroupRemoteOwnerChanged;

/// When a create or join is refused as `not_eligible`, asks the server for
/// self-service eligibility and repeats that request once with the same
/// arguments. The server decides. A refusal is returned unchanged and not
/// asked again for [refusalTtl], so a profile synced a moment later counts.
class EligibilityRequestingRemote implements GroupKhatmahRemote {
  EligibilityRequestingRemote(
    this._inner, {
    required this.requestEligibility,
    this.refusalTtl = const Duration(minutes: 10),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final GroupKhatmahRemote _inner;

  /// True when the server now holds this account as eligible.
  final Future<bool> Function(String ownerId) requestEligibility;
  final Duration refusalTtl;
  final DateTime Function() _clock;

  static const _entryRpcs = {'create_group_khatmah', 'join_group_khatmah'};

  /// Owner id -> when its last request was refused.
  final _refusedAt = <String, DateTime>{};

  bool _mayAsk(String ownerId) {
    final refused = _refusedAt[ownerId];
    return refused == null || _clock().difference(refused) >= refusalTtl;
  }

  @override
  Future<Map<String, dynamic>> rpc(
    String function,
    Map<String, dynamic> args, {
    required String ownerId,
  }) async {
    final result = await _inner.rpc(function, args, ownerId: ownerId);
    if (!_entryRpcs.contains(function) ||
        result['code'] != 'not_eligible' ||
        !_mayAsk(ownerId)) {
      return result;
    }
    final bool granted;
    try {
      granted = await requestEligibility(ownerId);
    } on GroupRemoteOwnerChanged {
      rethrow;
    } catch (_) {
      // Not deployed or unreachable: a later attempt may ask again.
      return result;
    }
    if (!granted) {
      _refusedAt[ownerId] = _clock();
      return result;
    }
    _refusedAt.remove(ownerId);
    return _inner.rpc(function, args, ownerId: ownerId);
  }

  @override
  Future<GroupKhatmahPage> fetchMine({
    required String ownerId,
    String? cursor,
  }) => _inner.fetchMine(ownerId: ownerId, cursor: cursor);

  @override
  Future<GroupKhatmah?> fetchGroup({
    required String ownerId,
    required String groupId,
  }) => _inner.fetchGroup(ownerId: ownerId, groupId: groupId);
}
