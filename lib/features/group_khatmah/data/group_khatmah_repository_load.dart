part of 'group_khatmah_repository_impl.dart';

class _GroupReadAuthority {
  const _GroupReadAuthority(
    this.generation,
    this.baselineEpoch,
    this.expectedEpoch,
    this.operationId,
    this.admission,
  );
  final int generation;
  final String? baselineEpoch, expectedEpoch, operationId;
  final bool admission;
}

class _GroupPublicationSuperseded implements Exception {
  const _GroupPublicationSuperseded();
}

extension _GroupKhatmahLoad on GroupKhatmahRepositoryImpl {
  String _invalidationKey(_Scope scope, String id) => '${scope.ownerId}|$id';
  int _groupGeneration(_Scope scope, String id) =>
      _groupInvalidations[_invalidationKey(scope, id)] ?? 0;

  void _invalidateGroup(_Scope scope, String id) {
    _groupInvalidations[_invalidationKey(scope, id)] =
        _groupGeneration(scope, id) + 1;
  }

  GroupCacheState _removeGroupState(
    _Scope scope,
    GroupCacheState state,
    String id,
  ) {
    _invalidateGroup(scope, id);
    return state.copyWith(
      groups: {...state.groups}..remove(id),
      intents: state.intents.where((i) => i.groupId != id).toList(),
    );
  }

  GroupCacheState _removeIntentMembership(
    _Scope scope,
    GroupCacheState state,
    GroupIntent responseIntent,
  ) {
    final id = responseIntent.groupId;
    final epoch = responseIntent.args['p_membership_epoch'];
    final live = state.intents.any(
      (i) => i.operationId == responseIntent.operationId,
    );
    final current = state.groups[id];
    if (id != null &&
        live &&
        (current == null || current.membershipEpoch == epoch)) {
      return _removeGroupState(scope, state, id);
    }
    return state.copyWith(
      intents: state.intents
          .where(
            (intent) =>
                intent.operationId != responseIntent.operationId &&
                !(id != null &&
                    intent.groupId == id &&
                    intent.args['p_membership_epoch'] == epoch),
          )
          .toList(),
    );
  }

  bool _mayPublish(
    _Scope scope,
    String id,
    _GroupReadAuthority authority,
    GroupCacheState state, [
    GroupKhatmah? snapshot,
  ]) {
    if (_groupGeneration(scope, id) != authority.generation) return false;
    final current = state.groups[id];
    if (authority.operationId != null) {
      final intent = state.intents
          .where((i) => i.operationId == authority.operationId)
          .firstOrNull;
      if (intent == null ||
          (authority.admission
              ? intent.action != 'create' && intent.action != 'join'
              : intent.groupId != id)) {
        return false;
      }
    }
    if (snapshot != null &&
        (snapshot.id != id ||
            (authority.expectedEpoch != null &&
                snapshot.membershipEpoch != authority.expectedEpoch))) {
      return false;
    }
    if (authority.admission) {
      return authority.operationId != null &&
          (current == null ||
              current.membershipEpoch == authority.baselineEpoch ||
              current.membershipEpoch == snapshot?.membershipEpoch);
    }
    return current != null &&
        authority.expectedEpoch != null &&
        current.membershipEpoch == authority.expectedEpoch &&
        current.membershipEpoch == authority.baselineEpoch;
  }

  Future<GroupKhatmah?> _loadGroup(
    _Scope scope,
    String id, {
    int? minVersion,
    String? operationId,
    bool admission = false,
    String? expectedEpoch,
  }) async {
    _check(scope);
    final initial = _cache.read(scope.ownerId);
    final epoch = initial.groups[id]?.membershipEpoch;
    final authority = _GroupReadAuthority(
      _groupGeneration(scope, id),
      epoch,
      expectedEpoch ?? (admission ? null : epoch),
      operationId,
      admission,
    );
    if (!_mayPublish(scope, id, authority, initial)) {
      throw const _GroupPublicationSuperseded();
    }
    final snapshot = await _remote.fetchGroup(
      ownerId: scope.ownerId,
      groupId: id,
    );
    _check(scope);
    if (snapshot != null &&
        minVersion != null &&
        snapshot.version < minVersion) {
      throw const FormatException('stale group snapshot');
    }
    final saved = await _cache.update(scope.ownerId, scope.lease, (state) {
      if (!_mayPublish(scope, id, authority, state, snapshot)) {
        throw const _GroupPublicationSuperseded();
      }
      if (snapshot == null) return _removeGroupState(scope, state, id);
      return state.copyWith(
        groups: {...state.groups, id: _merge.newer(state.groups[id], snapshot)},
      );
    });
    return saved.groups[id];
  }
}
