import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../domain/entities/group_khatmah.dart';
import '../domain/repositories/group_khatmah_repository.dart';
import 'group_khatmah_cache.dart';
import 'group_khatmah_cloud_merge.dart';
import 'group_khatmah_remote.dart';
import 'supabase_group_khatmah_remote.dart';

part 'group_khatmah_repository_refresh.dart';
part 'group_khatmah_repository_parts.dart';
part 'group_khatmah_repository_recovery.dart';
part 'group_khatmah_repository_sync.dart';
part 'group_khatmah_repository_watch.dart';

class GroupKhatmahRepositoryImpl implements GroupKhatmahRepository {
  GroupKhatmahRepositoryImpl({
    required SharedPreferences preferences,
    required this._owner,
    required this._remote,
    required this._wake,
    required this._environment,
    String Function()? operationId,
    DateTime Function()? clock,
  }) : _operationId = operationId ?? const Uuid().v4,
       _clock = clock ?? DateTime.now,
       _barrier = AccountDataBarrier.forPreferences(preferences),
       _cache = GroupKhatmahCache(
         preferences,
         AccountDataBarrier.forPreferences(preferences),
       );

  final RecordOwnerProvider _owner;
  final GroupKhatmahRemote _remote;
  final GroupKhatmahWakeScheduler _wake;
  final GroupKhatmahEnvironment _environment;
  final String Function() _operationId;
  final DateTime Function() _clock;
  final AccountDataBarrier _barrier;
  final GroupKhatmahCache _cache;
  final GroupKhatmahCloudMerge _merge = const GroupKhatmahCloudMerge();
  final Set<Future<void> Function(bool)> _watchCancels = {};
  bool _disposed = false;

  bool get _allowed =>
      !_disposed &&
      _owner.isSignedIn &&
      _environment.featureEnabled &&
      _environment.isAdult &&
      _barrier.isReady;

  _Scope _scope() {
    if (!_allowed) throw const AccountDataUnavailableException();
    final ownerId = _owner.currentOwnerId;
    final lease = _barrier.capture();
    lease.checkOwner(ownerId);
    return _Scope(ownerId, lease);
  }

  void _check(_Scope scope) {
    scope.lease.checkOwner(scope.ownerId);
    if (!_allowed) throw const AccountDataUnavailableException();
  }

  Failure _failure(Object error) => error is AccountDataUnavailableException
      ? const GroupKhatmahFailure('not_available')
      : error is FormatException
      ? const ParseFailure()
      : Failure.fromCloud(error);

  Future<GroupIntent> _record(
    _Scope scope,
    String action,
    Map<String, dynamic> args,
    String? groupId,
  ) async {
    final intent = GroupIntent(
      operationId: args['p_operation_id'] as String,
      action: action,
      args: Map.unmodifiable(args),
      groupId: groupId,
      createdAt: _clock().toUtc(),
    );
    await _cache.update(
      scope.ownerId,
      scope.lease,
      (state) => state.copyWith(intents: [...state.intents, intent]),
    );
    await _schedule(scope);
    return intent;
  }

  Future<void> _replace(
    _Scope scope,
    String operationId, {
    GroupIntent? intent,
    GroupKhatmah? group,
    bool removeGroup = false,
  }) async {
    await _cache.update(scope.ownerId, scope.lease, (state) {
      final groups = Map<String, GroupKhatmah>.of(state.groups);
      if (removeGroup) groups.remove(group?.id);
      if (group != null && !removeGroup) {
        groups[group.id] = _merge.newer(groups[group.id], group);
      }
      final intents = [
        for (final old in state.intents)
          if (old.operationId != operationId) old else ?intent,
      ];
      return state.copyWith(groups: groups, intents: intents);
    });
    await _schedule(scope);
  }

  Future<void> _schedule(_Scope scope) async {
    _check(scope);
    final pending = _cache
        .read(scope.ownerId)
        .intents
        .where((i) => !i.deadLetter)
        .toList();
    pending.sort(
      (a, b) => (a.nextRetryAt ?? a.createdAt).compareTo(
        b.nextRetryAt ?? b.createdAt,
      ),
    );
    await _wake.reconcilePush(
      ownerId: scope.ownerId,
      lease: scope.lease,
      nextRetryAt: pending.isEmpty
          ? null
          : (pending.first.nextRetryAt ?? pending.first.createdAt),
    );
  }

  GroupKhatmah? _group(_Scope scope, String groupId) =>
      _cache.read(scope.ownerId).groups[groupId];

  Future<GroupKhatmah?> _loadGroup(
    _Scope scope,
    String groupId, {
    int? minVersion,
  }) async {
    _check(scope);
    final group = await _remote.fetchGroup(
      ownerId: scope.ownerId,
      groupId: groupId,
    );
    _check(scope);
    if (group == null) return null;
    if (minVersion != null && group.version < minVersion) {
      throw const FormatException('stale group snapshot');
    }
    final saved = await _cache.update(
      scope.ownerId,
      scope.lease,
      (state) => state.copyWith(
        groups: {
          ...state.groups,
          groupId: _merge.newer(state.groups[groupId], group),
        },
      ),
    );
    return saved.groups[groupId];
  }

  Future<Map<String, dynamic>> _send(_Scope scope, GroupIntent intent) async {
    if (!_environment.isOnline) throw const _Offline();
    _check(scope);
    final function = switch (intent.action) {
      'create' => 'create_group_khatmah',
      'join' => 'join_group_khatmah',
      _ => intent.action,
    };
    final response = await _remote.rpc(
      function,
      intent.args,
      ownerId: scope.ownerId,
    );
    _check(scope);
    return response;
  }

  Future<bool> _preflight(_Scope scope, {String? groupId}) async {
    if (!_environment.isOnline) throw const _Offline();
    _check(scope);
    if (groupId == null) {
      await _remote.fetchMine(ownerId: scope.ownerId);
      _check(scope);
      return true;
    }
    final group = await _remote.fetchGroup(
      ownerId: scope.ownerId,
      groupId: groupId,
    );
    _check(scope);
    return group != null;
  }

  Future<Either<Failure, GroupKhatmah>> _newGroup(
    String action,
    String first,
    String displayName,
  ) async {
    try {
      final scope = _scope();
      if (!_environment.isOnline) return const Left(NetworkFailure());
      await _preflight(scope);
      final operationId = _operationId();
      final args = action == 'create'
          ? {
              'p_title': first,
              'p_display_name': displayName,
              'p_operation_id': operationId,
            }
          : {
              'p_code': first,
              'p_display_name': displayName,
              'p_operation_id': operationId,
            };
      final intent = await _record(scope, action, args, null);
      final response = await _send(scope, intent);
      if (response['applied'] != true) {
        await _replace(scope, operationId);
        return Left(GroupKhatmahFailure(response['code'] as String));
      }
      final groupId = response['group_id'] as String;
      final group = await _loadGroup(
        scope,
        groupId,
        minVersion: (response['group_version'] as num).toInt(),
      );
      if (group == null) return const Left(ParseFailure());
      await _replace(scope, operationId);
      return Right(group);
    } on _Offline {
      return const Left(NetworkFailure());
    } catch (error) {
      return Left(_failure(error));
    }
  }

  @override
  Future<Either<Failure, GroupKhatmah>> create(
    String title,
    String displayName,
  ) => _newGroup('create', title, displayName);

  @override
  Future<Either<Failure, GroupKhatmah>> join(String code, String displayName) =>
      _newGroup('join', code, displayName);

  @override
  Future<Either<Failure, GroupPart>> claim(String groupId, int juz) =>
      _changePart('claim_group_part', groupId, juz);

  @override
  Future<Either<Failure, GroupPart>> release(String groupId, int juz) =>
      _changePart('release_group_part', groupId, juz);

  @override
  Future<Either<Failure, void>> completeLocally(String groupId, int juz) async {
    try {
      final scope = _scope();
      final group = _group(scope, groupId);
      final part = group?.part(juz);
      if (part == null ||
          group == null ||
          part.status != GroupPartStatus.claimed ||
          part.claimedBy != scope.ownerId ||
          part.claimEpoch != group.membershipEpoch) {
        return const Left(GroupKhatmahFailure('not_own_claim'));
      }
      final matching = _cache
          .read(scope.ownerId)
          .intents
          .where(
            (intent) =>
                intent.action == 'complete_group_part' &&
                intent.groupId == groupId &&
                intent.args['p_juz'] == juz &&
                intent.args['p_expected_version'] == part.version &&
                intent.args['p_membership_epoch'] == group.membershipEpoch,
          );
      if (matching.any((intent) => intent.deadLetter)) {
        return const Left(GroupKhatmahFailure('recovery_required'));
      }
      if (matching.isNotEmpty) {
        return const Right(null);
      }
      await _record(scope, 'complete_group_part', {
        'p_group_id': groupId,
        'p_juz': juz,
        'p_expected_version': part.version,
        'p_membership_epoch': group.membershipEpoch,
        'p_operation_id': _operationId(),
      }, groupId);
      return const Right(null);
    } catch (error) {
      return Left(_failure(error));
    }
  }

  @override
  Future<Either<Failure, void>> leave(String groupId) async {
    try {
      final scope = _scope();
      if (!_environment.isOnline) return const Left(NetworkFailure());
      final group = _group(scope, groupId);
      if (group == null) return const Left(NotFoundFailure());
      if (!await _preflight(scope, groupId: groupId)) {
        return const Left(NotFoundFailure());
      }
      final operationId = _operationId();
      final intent = await _record(scope, 'leave_group_khatmah', {
        'p_group_id': groupId,
        'p_membership_epoch': group.membershipEpoch,
        'p_operation_id': operationId,
      }, groupId);
      final response = await _send(scope, intent);
      if (response['applied'] != true) {
        await _terminal(scope, intent, response);
        return Left(GroupKhatmahFailure(response['code'] as String));
      }
      await _purge(scope, groupId);
      return const Right(null);
    } on _Offline {
      return const Left(NetworkFailure());
    } catch (error) {
      return Left(_failure(error));
    }
  }

  Future<void> _purge(_Scope scope, String groupId) async {
    await _cache.update(
      scope.ownerId,
      scope.lease,
      (state) => state.copyWith(
        groups: {...state.groups}..remove(groupId),
        intents: state.intents.where((i) => i.groupId != groupId).toList(),
      ),
    );
    await _schedule(scope);
  }

  Future<void> _terminal(
    _Scope scope,
    GroupIntent intent,
    Map<String, dynamic> response,
  ) async {
    final code = response['code'];
    if ((code == 'not_member' || code == 'gone') && intent.groupId != null) {
      await _purge(scope, intent.groupId!);
      return;
    }
    await _replace(scope, intent.operationId);
  }

  @override
  Future<Either<Failure, void>> flushPending() => _flushPendingImpl();

  @override
  List<GroupFailedOperation> failedOperations() => _failedOperations();
  @override
  Future<Either<Failure, void>> retryFailedOperation(String operationId) =>
      _recoverFailedOperation(operationId, discard: false);
  @override
  Future<Either<Failure, void>> discardFailedOperation(String operationId) =>
      _recoverFailedOperation(operationId, discard: true);

  @override
  Future<Either<Failure, void>> reconcilePendingWake() async {
    try {
      await _schedule(_scope());
      return const Right(null);
    } catch (error) {
      return Left(_failure(error));
    }
  }

  @override
  Future<Either<Failure, void>> retryFailedCompletion(
    String groupId,
    int juz,
  ) => _retryFailedCompletion(groupId, juz);

  @override
  Future<Either<Failure, void>> discardFailedCompletion(
    String groupId,
    int juz,
  ) => _discardFailedCompletion(groupId, juz);

  @override
  Future<Either<Failure, void>> refreshMine() => _refreshMineImpl();

  @override
  Future<bool> hasPending() async {
    if (!_owner.isSignedIn) return false;
    try {
      final ownerId = _owner.currentOwnerId;
      final lease = _barrier.capture();
      lease.checkOwner(ownerId);
      return _cache.read(ownerId).intents.isNotEmpty;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<bool> hasRunnablePending() async {
    try {
      final scope = _scope();
      return _cache
          .read(scope.ownerId)
          .intents
          .any((i) => i.due(_clock().toUtc()));
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<List<GroupKhatmah>> watchMine() => _watchMine();

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await Future.wait([
      for (final cancel in _watchCancels.toList()) cancel(true),
    ]);
  }
}

class _Scope {
  const _Scope(this.ownerId, this.lease);
  final String ownerId;
  final AccountDataLease lease;
}

class _Offline implements Exception {
  const _Offline();
}
