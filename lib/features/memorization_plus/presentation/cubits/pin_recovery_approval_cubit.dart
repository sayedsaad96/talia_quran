import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/parent_pin_recovery_repository.dart';
import '../../domain/usecases/parent_pin_recovery_usecases.dart';

class PinRecoveryApprovalState extends Equatable {
  const PinRecoveryApprovalState({
    this.requests = const [],
    this.approvedCode,
    this.errorCode,
    this.errorEventId = 0,
    this.busy = false,
  });

  final List<PinRecoveryChallenge> requests;

  /// One-time code to show the guardian after an approval.
  final String? approvedCode;
  final String? errorCode;
  final int errorEventId;
  final bool busy;

  @override
  List<Object?> get props => [
    requests,
    approvedCode,
    errorCode,
    errorEventId,
    busy,
  ];
}

/// Guardian side: open PIN-recovery requests of one linked child.
class PinRecoveryApprovalCubit extends Cubit<PinRecoveryApprovalState> {
  PinRecoveryApprovalCubit(this._recovery, this._childUserId)
    : super(const PinRecoveryApprovalState());

  final ParentPinRecoveryUsecase _recovery;
  final String _childUserId;

  /// A failed read keeps the panel hidden: it is not an action the guardian
  /// started.
  Future<void> load() async {
    final result = await _recovery.pending(_childUserId);
    if (isClosed) return;
    result.fold(
      (_) {},
      (requests) => emit(
        PinRecoveryApprovalState(
          requests: requests,
          errorEventId: state.errorEventId,
        ),
      ),
    );
  }

  Future<void> approve(String challengeId) async {
    if (state.busy) return;
    emit(
      PinRecoveryApprovalState(
        requests: state.requests,
        errorEventId: state.errorEventId,
        busy: true,
      ),
    );
    final result = await _recovery.approve(challengeId);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => PinRecoveryApprovalState(
          requests: state.requests,
          errorCode: failure.message,
          errorEventId: state.errorEventId + 1,
        ),
        (code) => PinRecoveryApprovalState(
          requests: state.requests,
          approvedCode: code,
          errorEventId: state.errorEventId,
        ),
      ),
    );
  }

  void dismissCode() {
    emit(
      PinRecoveryApprovalState(
        requests: state.requests,
        errorEventId: state.errorEventId,
      ),
    );
  }
}
