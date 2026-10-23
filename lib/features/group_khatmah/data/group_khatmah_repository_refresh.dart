part of 'group_khatmah_repository_impl.dart';

extension _GroupKhatmahRefresh on GroupKhatmahRepositoryImpl {
  Future<Either<Failure, void>> _refreshMineImpl() async {
    try {
      final scope = _scope();
      if (!_environment.isOnline) return const Left(NetworkFailure());
      final baseline = _cache.read(scope.ownerId);
      final found = await _fetchAllMine(scope);
      for (final id in baseline.groups.keys.where(
        (id) => !found.containsKey(id),
      )) {
        _check(scope);
        final current = await _remote.fetchGroup(
          ownerId: scope.ownerId,
          groupId: id,
        );
        _check(scope);
        if (current != null) found[id] = current;
      }
      await _commitRefresh(scope, baseline, found);
      await _schedule(scope);
      return const Right(null);
    } catch (error) {
      return Left(_failure(error));
    }
  }

  Future<Map<String, GroupKhatmah>> _fetchAllMine(_Scope scope) async {
    final found = <String, GroupKhatmah>{};
    String? cursor;
    final cursors = <String>{};
    do {
      _check(scope);
      final page = await _remote.fetchMine(
        ownerId: scope.ownerId,
        cursor: cursor,
      );
      _check(scope);
      for (final group in page.groups) {
        found[group.id] = group;
      }
      cursor = page.nextCursor;
      if (cursor != null && !cursors.add(cursor)) {
        throw const FormatException('repeated cursor');
      }
    } while (cursor != null);
    return found;
  }

  Future<void> _commitRefresh(
    _Scope scope,
    GroupCacheState baseline,
    Map<String, GroupKhatmah> found,
  ) async {
    await _cache.update(scope.ownerId, scope.lease, (state) {
      final merged = <String, GroupKhatmah>{};
      for (final group in found.values) {
        final before = baseline.groups[group.id];
        final now = state.groups[group.id];
        if (before != null && now == null) {
          continue;
        }
        if (before != null &&
            now != null &&
            now.membershipEpoch != before.membershipEpoch) {
          merged[group.id] = now;
        } else {
          merged[group.id] = _merge.newer(now, group);
        }
      }
      for (final entry in state.groups.entries) {
        if (found.containsKey(entry.key)) {
          continue;
        }
        final before = baseline.groups[entry.key];
        if (before == null ||
            entry.value.membershipEpoch != before.membershipEpoch) {
          merged[entry.key] = entry.value;
        }
      }
      final intents = state.intents.where(
        (intent) =>
            (intent.groupId == null || merged.containsKey(intent.groupId)) &&
            (intent.action != 'complete_group_part' ||
                intent.deadLetter ||
                _merge.completionStillValid(
                  intent,
                  merged[intent.groupId],
                  scope.ownerId,
                )),
      );
      return state.copyWith(groups: merged, intents: intents.toList());
    });
  }
}
