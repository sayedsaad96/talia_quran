import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/entities/kids_encouragement.dart';
import '../../domain/repositories/kids_encouragement_repository.dart';

final class ChildEncouragementInboxState extends Equatable {
  const ChildEncouragementInboxState({
    this.pending = const [],
    this.loading = false,
    this.failed = false,
  });
  final List<KidsEncouragement> pending;
  final bool loading;
  final bool failed;

  ChildEncouragementInboxState copyWith({
    List<KidsEncouragement>? pending,
    bool? loading,
    bool? failed,
  }) => ChildEncouragementInboxState(
    pending: pending ?? this.pending,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
  );

  @override
  List<Object?> get props => [pending, loading, failed];
}

final class ChildEncouragementInboxCubit
    extends Cubit<ChildEncouragementInboxState> {
  ChildEncouragementInboxCubit({
    required this._repository,
    required this._owner,
    required this._barrier,
    required Stream<void> accountChanges,
  }) : super(const ChildEncouragementInboxState()) {
    _changes = accountChanges.listen((_) => _clearForAccountChange());
  }

  final KidsEncouragementRepository _repository;
  final RecordOwnerProvider _owner;
  final AccountDataBarrier _barrier;
  late final StreamSubscription<void> _changes;
  int _generation = 0;

  Future<void> load() async {
    final request = ++_generation;
    final ownerId = _owner.currentOwnerId;
    AccountDataLease? lease;
    try {
      lease = _barrier.capture()..checkOwner(ownerId);
      emit(state.copyWith(loading: true, failed: false));
      final pendingIds = await _repository.pendingSeenIds();
      if (!_isCurrent(ownerId, lease, request)) return;
      final rows = await _repository.refresh(childUserId: ownerId);
      if (!_isCurrent(ownerId, lease, request)) return;
      final suppressed = pendingIds.toSet();
      emit(
        state.copyWith(
          pending: List.unmodifiable(
            rows.where(
              (row) =>
                  row.childUserId == ownerId &&
                  row.seenAt == null &&
                  !suppressed.contains(row.id),
            ),
          ),
          loading: false,
        ),
      );
    } catch (_) {
      if (lease != null && _isCurrent(ownerId, lease, request)) {
        emit(state.copyWith(loading: false, failed: true));
      }
    }
  }

  Future<void> dismiss(int id) async {
    if (id <= 0 || !state.pending.any((row) => row.id == id)) return;
    final request = ++_generation;
    final ownerId = _owner.currentOwnerId;
    AccountDataLease? lease;
    try {
      lease = _barrier.capture()..checkOwner(ownerId);
      emit(
        state.copyWith(
          pending: List.unmodifiable(
            state.pending.where((row) => row.id != id),
          ),
          loading: false,
        ),
      );
      await _repository.markSeen([id]);
      if (_isCurrent(ownerId, lease, request)) {
        emit(state.copyWith(failed: false));
      }
    } catch (_) {
      if (lease != null && _isCurrent(ownerId, lease, request)) {
        emit(state.copyWith(failed: true));
      }
    }
  }

  Future<void> retryAcknowledgements() async {
    final request = _generation;
    final ownerId = _owner.currentOwnerId;
    AccountDataLease? lease;
    try {
      lease = _barrier.capture()..checkOwner(ownerId);
      await _repository.retryPendingSeen();
    } catch (_) {
      if (lease != null && _isCurrent(ownerId, lease, request)) {
        emit(state.copyWith(failed: true));
      }
    }
  }

  bool _isCurrent(String ownerId, AccountDataLease lease, int request) {
    try {
      lease.checkOwner(ownerId);
      return request == _generation &&
          _owner.currentOwnerId == ownerId &&
          !isClosed;
    } on AccountDataUnavailableException {
      return false;
    }
  }

  void _clearForAccountChange() {
    _generation++;
    if (!isClosed) emit(const ChildEncouragementInboxState());
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
