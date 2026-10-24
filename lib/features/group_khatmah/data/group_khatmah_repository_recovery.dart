part of 'group_khatmah_repository_impl.dart';

extension _GroupKhatmahRecovery on GroupKhatmahRepositoryImpl {
  List<GroupFailedOperation> _failedOperations() {
    try {
      final scope = _scope();
      return List.unmodifiable([
        for (final intent in _cache.read(scope.ownerId).intents)
          if (intent.deadLetter)
            GroupFailedOperation(
              operationId: intent.operationId,
              action: intent.action,
            ),
      ]);
    } catch (_) {
      return const [];
    }
  }

  Future<Either<Failure, void>> _recoverFailedOperation(
    String operationId, {
    required bool discard,
  }) async {
    try {
      final scope = _scope();
      var found = false;
      await _cache.update(scope.ownerId, scope.lease, (state) {
        final intents = <GroupIntent>[];
        for (final intent in state.intents) {
          if (intent.operationId == operationId && intent.deadLetter) {
            found = true;
            if (!discard) intents.add(intent.reactivated(_clock().toUtc()));
          } else {
            intents.add(intent);
          }
        }
        return state.copyWith(intents: intents);
      });
      if (!found) return const Left(GroupKhatmahFailure('no_failed_operation'));
      await _schedule(scope);
      return const Right(null);
    } catch (error) {
      return Left(_failure(error));
    }
  }

  Future<Either<Failure, void>> _retryFailedCompletion(
    String groupId,
    int juz,
  ) async {
    try {
      final scope = _scope();
      String? refusal;
      await _cache.update(scope.ownerId, scope.lease, (state) {
        final group = state.groups[groupId];
        final part = group?.part(juz);
        if (group == null ||
            part == null ||
            part.status != GroupPartStatus.claimed ||
            part.claimedBy != scope.ownerId ||
            part.claimEpoch != group.membershipEpoch) {
          refusal = 'stale_operation';
          return state;
        }
        final matching = state.intents.where(
          (intent) =>
              intent.action == 'complete_group_part' &&
              intent.deadLetter &&
              intent.groupId == groupId &&
              intent.args['p_juz'] == juz &&
              intent.args['p_expected_version'] == part.version &&
              intent.args['p_membership_epoch'] == group.membershipEpoch,
        );
        if (matching.isEmpty) {
          refusal = 'no_failed_completion';
          return state;
        }
        final operationId = matching.first.operationId;
        return state.copyWith(
          intents: [
            for (final intent in state.intents)
              intent.operationId == operationId
                  ? intent.reactivated(_clock().toUtc())
                  : intent,
          ],
        );
      });
      if (refusal != null) return Left(GroupKhatmahFailure(refusal!));
      await _schedule(scope);
      return const Right(null);
    } catch (error) {
      return Left(_failure(error));
    }
  }

  Future<Either<Failure, void>> _discardFailedCompletion(
    String groupId,
    int juz,
  ) async {
    try {
      final scope = _scope();
      var removed = false;
      await _cache.update(
        scope.ownerId,
        scope.lease,
        (state) => state.copyWith(
          intents: state.intents.where((intent) {
            final discard =
                intent.action == 'complete_group_part' &&
                intent.deadLetter &&
                intent.groupId == groupId &&
                intent.args['p_juz'] == juz;
            if (discard) removed = true;
            return !discard;
          }).toList(),
        ),
      );
      if (!removed) {
        return const Left(GroupKhatmahFailure('no_failed_completion'));
      }
      await _schedule(scope);
      return const Right(null);
    } catch (error) {
      return Left(_failure(error));
    }
  }
}
