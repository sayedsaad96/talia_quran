import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../repositories/parent_pin_recovery_repository.dart';

/// Forgotten guardian PIN: the child device asks, the linked guardian
/// approves from their account and reads out a one-time code.
class ParentPinRecoveryUsecase {
  const ParentPinRecoveryUsecase(this._repository);

  final ParentPinRecoveryRepository _repository;

  Future<Either<Failure, PinRecoveryChallenge>> request() =>
      _repository.requestPinRecovery();

  Future<Either<Failure, bool>> complete({
    required String challengeId,
    required String code,
    required String newPin,
  }) => _repository.completePinRecovery(
    challengeId: challengeId,
    code: code,
    newPin: newPin,
  );

  Future<Either<Failure, List<PinRecoveryChallenge>>> pending(
    String childUserId,
  ) => _repository.pendingPinRecoveries(childUserId);

  Future<Either<Failure, String>> approve(String challengeId) =>
      _repository.approvePinRecovery(challengeId);
}
