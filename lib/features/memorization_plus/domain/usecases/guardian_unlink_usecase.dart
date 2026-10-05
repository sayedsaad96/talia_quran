import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/l10n/cubit_message_codes.dart';
import '../entities/memorization_entities.dart';
import '../repositories/memorization_identity_repository.dart';

/// The child ends their own guardian link. The server revokes first; on any
/// failure nothing changes on the device.
class UnlinkGuardianUsecase {
  const UnlinkGuardianUsecase(this._repository);

  final MemorizationIdentityRepository _repository;

  Future<Either<Failure, MemorizationProfile>> call() async {
    final result = await _repository.unlinkGuardian();
    return result.leftMap(
      (_) => const NetworkFailure(CubitMessageCodes.guardianUnlinkFailed),
    );
  }
}
