import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/memorization_entities.dart';

abstract class MemorizationIdentityRepository {
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile();
  Future<Either<Failure, MemorizationProfile>> selectMemorizationPath(
    MemorizationPath path,
  );
  Future<Either<Failure, MemorizationProfile>> continueWithoutGuardian();
  Future<Either<Failure, PairingSession>> createGuardianPairingSession();
  Future<Either<Failure, MemorizationProfile>> acceptGuardianPairingCode(
    String codeOrQrData,
  );
  Future<Either<Failure, PairingSession?>> refreshPairingSession();
  Future<Either<Failure, MemorizationProfile>> unlinkGuardian();
  Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(
    bool value,
  );
  Future<Either<Failure, MemorizationProfile>> refreshChildGuardianLink();
  Future<Either<Failure, MemorizationProfile>> resetMemorizationIdentity();
  Future<Either<Failure, SmartMemorizationSettings>> getSmartSettings();
  Future<Either<Failure, void>> saveSmartSettings(
    SmartMemorizationSettings settings,
  );

  Either<Failure, MemorizationTrack?> getSelectedTrack();
  Future<Either<Failure, void>> saveSelectedTrack(MemorizationTrack track);

  Either<Failure, bool> getIsParentMode();
  Future<Either<Failure, void>> setIsParentMode(bool value);
}
