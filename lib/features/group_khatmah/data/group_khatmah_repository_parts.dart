part of 'group_khatmah_repository_impl.dart';

extension _GroupKhatmahParts on GroupKhatmahRepositoryImpl {
  Future<Either<Failure, GroupPart>> _changePart(
    String action,
    String groupId,
    int juz,
  ) async {
    try {
      final scope = _scope();
      if (!_environment.isOnline) return const Left(NetworkFailure());
      final group = _group(scope, groupId);
      final part = group?.part(juz);
      if (group == null || part == null) return const Left(NotFoundFailure());
      if (!await _preflight(scope, groupId: groupId)) {
        return const Left(NotFoundFailure());
      }
      final operationId = _operationId();
      final intent = await _record(scope, action, {
        'p_group_id': groupId,
        'p_juz': juz,
        'p_expected_version': part.version,
        'p_membership_epoch': group.membershipEpoch,
        'p_operation_id': operationId,
      }, groupId);
      final response = await _send(scope, intent);
      return await _partResponse(scope, intent, group, part, response);
    } on _Offline {
      return const Left(NetworkFailure());
    } catch (error) {
      return Left(_failure(error));
    }
  }

  Future<Either<Failure, GroupPart>> _partResponse(
    _Scope scope,
    GroupIntent intent,
    GroupKhatmah group,
    GroupPart part,
    Map<String, dynamic> response,
  ) async {
    if (response['applied'] != true) {
      await _terminal(scope, intent, response);
      if (response['code'] == 'conflict') {
        await _loadGroup(scope, group.id, expectedEpoch: group.membershipEpoch);
        return const Left(GroupPartConflictFailure());
      }
      return Left(GroupKhatmahFailure(response['code'] as String));
    }
    return Right(
      await _acceptPartMutation(
        scope,
        intent.operationId,
        intent.action,
        group,
        part,
        response,
      ),
    );
  }

  Future<GroupPart> _acceptPartMutation(
    _Scope scope,
    String operationId,
    String action,
    GroupKhatmah group,
    GroupPart part,
    Map<String, dynamic> response,
  ) async {
    final responseVersion = (response['group_version'] as num).toInt();
    if (responseVersion != group.version + 1) {
      final latest = await _loadGroup(
        scope,
        group.id,
        minVersion: responseVersion,
        operationId: operationId,
        expectedEpoch: group.membershipEpoch,
      );
      final confirmed = latest?.part(part.juz);
      if (confirmed == null ||
          confirmed.version < (response['part_version'] as num).toInt()) {
        throw const FormatException('missing accepted part');
      }
      await _replace(scope, operationId);
      return confirmed;
    }
    final updated = part.copyWith(
      status: action == 'claim_group_part'
          ? GroupPartStatus.claimed
          : GroupPartStatus.open,
      claimedBy: action == 'claim_group_part' ? scope.ownerId : null,
      claimEpoch: action == 'claim_group_part' ? group.membershipEpoch : null,
      version: (response['part_version'] as num).toInt(),
    );
    final next = group.copyWith(
      version: responseVersion,
      parts: [
        for (final row in group.parts) row.juz == part.juz ? updated : row,
      ],
    );
    await _replace(scope, operationId, group: next);
    return updated;
  }
}
