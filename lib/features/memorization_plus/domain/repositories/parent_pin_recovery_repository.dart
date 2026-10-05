import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/app_failure.dart';

/// A child device's request to replace a forgotten guardian PIN. The linked
/// guardian approves it from their own account and reads out a one-time code.
class PinRecoveryChallenge extends Equatable {
  const PinRecoveryChallenge({required this.id, required this.expiresAt});

  final String id;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [id, expiresAt];
}

abstract interface class ParentPinRecoveryRepository {
  /// Child side. Reuses the open request of this device while it is valid.
  Future<Either<Failure, PinRecoveryChallenge>> requestPinRecovery();

  /// Child side. Replaces the PIN with [newPin] only when the server accepts
  /// [code]; returns false for a wrong, used or expired code.
  Future<Either<Failure, bool>> completePinRecovery({
    required String challengeId,
    required String code,
    required String newPin,
  });

  /// Guardian side: open requests of a linked child.
  Future<Either<Failure, List<PinRecoveryChallenge>>> pendingPinRecoveries(
    String childUserId,
  );

  /// Guardian side: the one-time code to give the child.
  Future<Either<Failure, String>> approvePinRecovery(String challengeId);
}
