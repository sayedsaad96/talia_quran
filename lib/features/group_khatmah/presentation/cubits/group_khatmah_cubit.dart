import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/entities/group_khatmah.dart';
import '../../domain/repositories/group_khatmah_repository.dart';

class GroupKhatmahState {
  const GroupKhatmahState({
    this.groups = const [],
    this.loading = false,
    this.busy = false,
    this.validated = false,
    this.isStale = false,
    this.failedOperations = const [],
    this.errorCode,
  });

  final List<GroupKhatmah> groups;
  final bool loading;
  final bool busy;
  final bool validated;
  final bool isStale;
  final List<GroupFailedOperation> failedOperations;
  final String? errorCode;

  GroupKhatmah? group(String id) {
    for (final value in groups) {
      if (value.id == id) return value;
    }
    return null;
  }

  GroupKhatmahState copyWith({
    List<GroupKhatmah>? groups,
    bool? loading,
    bool? busy,
    bool? validated,
    bool? isStale,
    List<GroupFailedOperation>? failedOperations,
    Object? errorCode = _unchanged,
  }) => GroupKhatmahState(
    groups: groups ?? this.groups,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    validated: validated ?? this.validated,
    isStale: isStale ?? this.isStale,
    failedOperations: failedOperations ?? this.failedOperations,
    errorCode: identical(errorCode, _unchanged)
        ? this.errorCode
        : errorCode as String?,
  );
}

const Object _unchanged = Object();

class GroupKhatmahCubit extends Cubit<GroupKhatmahState> {
  GroupKhatmahCubit({required this._repository, required this._owner})
    : super(const GroupKhatmahState());

  final GroupKhatmahRepository _repository;
  final RecordOwnerProvider _owner;
  StreamSubscription<List<GroupKhatmah>>? _subscription;
  String? _watchOwner;

  String get currentOwnerId => _owner.currentOwnerId;

  bool _stillCurrent(String ownerId) {
    if (isClosed) return false;
    if (_owner.isSignedIn &&
        _owner.currentOwnerId == ownerId &&
        _watchOwner == ownerId) {
      return true;
    }
    emit(const GroupKhatmahState());
    return false;
  }

  void start() {
    if (isClosed || _subscription != null) return;
    _watchOwner = _owner.currentOwnerId;
    _subscription = _repository.watchMine().listen(
      (groups) {
        if (isClosed) return;
        if (_watchOwner != _owner.currentOwnerId || !_owner.isSignedIn) {
          emit(const GroupKhatmahState());
          return;
        }
        emit(
          state.copyWith(
            groups: List.unmodifiable(groups),
            failedOperations: _repository.failedOperations(),
          ),
        );
      },
      onError: (_) {
        if (!isClosed) emit(state.copyWith(errorCode: 'error'));
      },
    );
    unawaited(refresh());
  }

  void clearError() {
    if (!isClosed) emit(state.copyWith(errorCode: null));
  }

  Future<void> refresh({bool preserveError = false}) async {
    if (isClosed || state.loading) return;
    final ownerId = _owner.currentOwnerId;
    emit(
      state.copyWith(
        loading: true,
        errorCode: preserveError ? state.errorCode : null,
      ),
    );
    final result = await _repository.refreshMine();
    if (!_stillCurrent(ownerId)) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          loading: false,
          isStale: state.validated,
          errorCode: _code(failure),
        ),
      ),
      (_) =>
          emit(state.copyWith(loading: false, validated: true, isStale: false)),
    );
  }

  Future<bool> create(String title, String displayName) =>
      _runGroup(() => _repository.create(title, displayName));

  Future<bool> recoverOperation(
    String operationId, {
    required bool discard,
  }) async {
    if (isClosed || state.busy) return false;
    final ownerId = _owner.currentOwnerId;
    emit(state.copyWith(busy: true, errorCode: null));
    final result = discard
        ? await _repository.discardFailedOperation(operationId)
        : await _repository.retryFailedOperation(operationId);
    if (!_stillCurrent(ownerId)) return false;
    return result.fold(
      (failure) {
        emit(state.copyWith(busy: false, errorCode: _code(failure)));
        return false;
      },
      (_) {
        emit(state.copyWith(busy: false));
        return true;
      },
    );
  }

  Future<bool> join(String code, String displayName) =>
      _runGroup(() => _repository.join(code, displayName));

  Future<bool> _runGroup(
    Future<Either<Failure, GroupKhatmah>> Function() action,
  ) async {
    if (isClosed || state.busy) return false;
    final ownerId = _owner.currentOwnerId;
    emit(state.copyWith(busy: true, errorCode: null));
    final result = await action();
    if (!_stillCurrent(ownerId)) return false;
    return result.fold(
      (failure) {
        emit(state.copyWith(busy: false, errorCode: _code(failure)));
        return false;
      },
      (_) {
        emit(state.copyWith(busy: false, validated: true));
        return true;
      },
    );
  }

  Future<bool> claim(String groupId, int juz) =>
      _runPart(groupId, juz, () => _repository.claim(groupId, juz));

  Future<bool> release(String groupId, int juz) =>
      _runPart(groupId, juz, () => _repository.release(groupId, juz));

  Future<bool> _runPart(
    String groupId,
    int juz,
    Future<Either<Failure, GroupPart>> Function() action,
  ) async {
    if (isClosed || state.busy || state.group(groupId) == null) return false;
    final ownerId = _owner.currentOwnerId;
    emit(state.copyWith(busy: true, errorCode: null));
    final result = await action();
    if (!_stillCurrent(ownerId)) return false;
    return result.fold(
      (failure) {
        emit(state.copyWith(busy: false, errorCode: _code(failure)));
        if (failure is GroupPartConflictFailure) {
          unawaited(refresh(preserveError: true));
        }
        return false;
      },
      (_) {
        emit(state.copyWith(busy: false));
        return true;
      },
    );
  }

  Future<bool> complete(String groupId, int juz) async {
    if (isClosed || state.busy) return false;
    final group = state.group(groupId);
    final part = group?.part(juz);
    if (group == null ||
        part == null ||
        part.status != GroupPartStatus.claimed ||
        part.claimedBy != _owner.currentOwnerId ||
        part.claimEpoch != group.membershipEpoch) {
      return false;
    }
    final ownerId = _owner.currentOwnerId;
    emit(state.copyWith(busy: true, errorCode: null));
    final result = await _repository.completeLocally(groupId, juz);
    if (!_stillCurrent(ownerId)) return false;
    return result.fold(
      (failure) {
        emit(state.copyWith(busy: false, errorCode: _code(failure)));
        return false;
      },
      (_) {
        emit(state.copyWith(busy: false));
        return true;
      },
    );
  }

  Future<bool> retryFailedCompletion(String groupId, int juz) =>
      _runCompletionRecovery(
        groupId,
        juz,
        () => _repository.retryFailedCompletion(groupId, juz),
      );

  Future<bool> discardFailedCompletion(String groupId, int juz) =>
      _runCompletionRecovery(
        groupId,
        juz,
        () => _repository.discardFailedCompletion(groupId, juz),
      );

  Future<bool> _runCompletionRecovery(
    String groupId,
    int juz,
    Future<Either<Failure, void>> Function() action,
  ) async {
    if (isClosed ||
        state.busy ||
        state.group(groupId)?.part(juz)?.isCompletionFailed != true) {
      return false;
    }
    final ownerId = _owner.currentOwnerId;
    emit(state.copyWith(busy: true, errorCode: null));
    final result = await action();
    if (!_stillCurrent(ownerId)) return false;
    return result.fold(
      (failure) {
        emit(state.copyWith(busy: false, errorCode: _code(failure)));
        return false;
      },
      (_) {
        emit(state.copyWith(busy: false));
        return true;
      },
    );
  }

  Future<bool> leave(String groupId) async {
    if (isClosed || state.busy || state.group(groupId) == null) return false;
    final ownerId = _owner.currentOwnerId;
    emit(state.copyWith(busy: true, errorCode: null));
    final result = await _repository.leave(groupId);
    if (!_stillCurrent(ownerId)) return false;
    return result.fold(
      (failure) {
        emit(state.copyWith(busy: false, errorCode: _code(failure)));
        return false;
      },
      (_) {
        emit(state.copyWith(busy: false));
        return true;
      },
    );
  }

  String _code(Failure failure) => switch (failure) {
    GroupPartConflictFailure(claimedByOther: true) => 'conflict_claimed',
    GroupPartConflictFailure() => 'conflict',
    GroupKhatmahFailure(:final code) => code,
    NetworkFailure() => 'network',
    _ => 'error',
  };

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
