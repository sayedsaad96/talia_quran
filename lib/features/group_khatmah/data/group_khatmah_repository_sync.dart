part of 'group_khatmah_repository_impl.dart';

extension GroupKhatmahRepositorySync on GroupKhatmahRepositoryImpl {
  Future<Either<Failure, void>> _flushPendingImpl() async {
    try {
      final scope = _scope();
      if (!_environment.isOnline) {
        await _schedule(scope);
        return const Left(NetworkFailure());
      }
      final pending = _cache
          .read(scope.ownerId)
          .intents
          .where((i) => i.due(_clock().toUtc()))
          .toList();
      for (final intent in pending) {
        _check(scope);
        await _flushOne(scope, intent);
      }
      return const Right(null);
    } catch (error) {
      return Left(_failure(error));
    }
  }

  Future<void> _flushOne(_Scope scope, GroupIntent intent) async {
    try {
      final response = await _send(scope, intent);
      if (response['applied'] == true) {
        if (intent.action == 'complete_group_part') {
          await _acceptCompletion(scope, intent, response);
        } else if (intent.action == 'leave_group_khatmah') {
          final id = intent.groupId ?? response['group_id'] as String?;
          if (id == null) throw const FormatException('missing left group');
          await _purge(scope, intent);
        } else {
          final id = response['group_id'] as String?;
          if (id == null) throw const FormatException('missing group');
          final group = await _loadGroup(
            scope,
            id,
            minVersion: (response['group_version'] as num).toInt(),
            operationId: intent.operationId,
            admission: intent.action == 'create' || intent.action == 'join',
            expectedEpoch:
                intent.args['p_membership_epoch'] as String? ??
                response['membership_epoch'] as String?,
          );
          if (group == null) throw const FormatException('missing group');
          await _replace(scope, intent.operationId);
        }
      } else {
        await _terminal(scope, intent, response);
        await _refreshAfterConflict(scope, intent, response['code']);
      }
    } on _GroupPublicationSuperseded {
      await _replace(scope, intent.operationId);
    } on AccountDataUnavailableException {
      rethrow;
    } catch (error) {
      await _replace(
        scope,
        intent.operationId,
        intent: _authInterrupted(error)
            ? intent.deferred(_clock().toUtc())
            : intent.failed(_clock().toUtc()),
      );
    }
  }

  bool _authInterrupted(Object error) =>
      error is GroupRemoteOwnerChanged ||
      error is AuthException ||
      (error is PostgrestException &&
          (error.code == 'PGRST301' ||
              error.code == 'PGRST303' ||
              (error.code == 'P0001' &&
                  error.message == 'group_session_required')));

  Future<void> _refreshAfterConflict(
    _Scope scope,
    GroupIntent intent,
    Object? code,
  ) async {
    if (intent.groupId == null || code == 'not_member' || code == 'gone') {
      return;
    }
    try {
      await _loadGroup(
        scope,
        intent.groupId!,
        expectedEpoch: intent.args['p_membership_epoch'] as String?,
      );
    } on AccountDataUnavailableException {
      rethrow;
    } catch (_) {
      try {
        await _wake.requestPull(ownerId: scope.ownerId, lease: scope.lease);
      } catch (_) {
        // Terminal intent is already removed; startup pull can retry.
      }
    }
  }

  Future<void> _acceptCompletion(
    _Scope scope,
    GroupIntent intent,
    Map<String, dynamic> response,
  ) async {
    final group = intent.groupId == null
        ? null
        : _group(scope, intent.groupId!);
    final newGroupVersion = (response['group_version'] as num).toInt();
    if (group != null && newGroupVersion == group.version + 1) {
      final juz = intent.args['p_juz'] as int;
      final part = group.part(juz);
      if (part != null) {
        final updated = part.copyWith(
          status: GroupPartStatus.completed,
          version: (response['part_version'] as num).toInt(),
          isCompletionPending: false,
        );
        await _replace(
          scope,
          intent.operationId,
          group: group.copyWith(
            version: newGroupVersion,
            status: response['group_status'] == 'completed'
                ? GroupKhatmahStatus.completed
                : group.status,
            parts: [
              for (final row in group.parts) row.juz == juz ? updated : row,
            ],
          ),
        );
        return;
      }
    }
    final id = intent.groupId;
    if (id == null) throw const FormatException('missing completion group');
    final latest = await _loadGroup(
      scope,
      id,
      minVersion: newGroupVersion,
      operationId: intent.operationId,
      expectedEpoch: intent.args['p_membership_epoch'] as String?,
    );
    if (latest == null) throw const FormatException('missing accepted group');
    await _replace(scope, intent.operationId);
  }
}
