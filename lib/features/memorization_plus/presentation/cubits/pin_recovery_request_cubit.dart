import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/parent_pin_recovery_repository.dart';
import '../../domain/usecases/parent_pin_recovery_usecases.dart';

enum PinRecoveryRequestStatus {
  requesting,
  waitingForCode,
  submitting,
  wrongCode,
  pinInvalid,
  done,
  failed,
}

class PinRecoveryRequestState extends Equatable {
  const PinRecoveryRequestState({
    required this.status,
    this.challenge,
    this.errorCode,
  });

  final PinRecoveryRequestStatus status;
  final PinRecoveryChallenge? challenge;

  /// Message code for [PinRecoveryRequestStatus.failed].
  final String? errorCode;

  @override
  List<Object?> get props => [status, challenge, errorCode];
}

/// Child device: asks the linked guardian to approve a new PIN, then sets it
/// once the guardian's one-time code is accepted.
class PinRecoveryRequestCubit extends Cubit<PinRecoveryRequestState> {
  PinRecoveryRequestCubit(this._recovery)
    : super(
        const PinRecoveryRequestState(
          status: PinRecoveryRequestStatus.requesting,
        ),
      );

  final ParentPinRecoveryUsecase _recovery;

  Future<void> start() async {
    emit(
      const PinRecoveryRequestState(
        status: PinRecoveryRequestStatus.requesting,
      ),
    );
    final result = await _recovery.request();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => PinRecoveryRequestState(
          status: PinRecoveryRequestStatus.failed,
          errorCode: failure.message,
        ),
        (challenge) => PinRecoveryRequestState(
          status: PinRecoveryRequestStatus.waitingForCode,
          challenge: challenge,
        ),
      ),
    );
  }

  Future<void> submit({required String code, required String newPin}) async {
    final challenge = state.challenge;
    if (challenge == null ||
        state.status == PinRecoveryRequestStatus.submitting) {
      return;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(newPin)) {
      emit(_withChallenge(PinRecoveryRequestStatus.pinInvalid, challenge));
      return;
    }
    emit(_withChallenge(PinRecoveryRequestStatus.submitting, challenge));
    final result = await _recovery.complete(
      challengeId: challenge.id,
      code: code,
      newPin: newPin,
    );
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => PinRecoveryRequestState(
          status: PinRecoveryRequestStatus.failed,
          challenge: challenge,
          errorCode: failure.message,
        ),
        (accepted) => _withChallenge(
          accepted
              ? PinRecoveryRequestStatus.done
              : PinRecoveryRequestStatus.wrongCode,
          challenge,
        ),
      ),
    );
  }

  PinRecoveryRequestState _withChallenge(
    PinRecoveryRequestStatus status,
    PinRecoveryChallenge challenge,
  ) => PinRecoveryRequestState(status: status, challenge: challenge);
}
