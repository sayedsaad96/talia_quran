import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../entities/memorization_entities.dart';

abstract class MemorizationCloudRepository {
  Future<Either<Failure, String>> createChildLinkToken();
  Future<Either<Failure, void>> acceptChildLinkToken(String token);
  Future<Either<Failure, void>> pullKidsProgressFromCloud();
  Future<Either<Failure, void>> syncKidsProgressToCloud();
  Future<bool> hasPendingCloudWork();
  Future<Either<Failure, List<RemoteChildSummary>>> getRemoteChildren();
  Future<Either<Failure, List<ParentReward>>> saveRemoteParentReward({
    required String childUserId,
    required String title,
  });
  Future<Either<Failure, List<ParentReward>>> unlockRemoteParentReward(
    String rewardId,
  );

  Future<Either<Failure, void>> resyncProductionDataToCloud();
  Future<Either<Failure, void>> pullProductionDataFromCloud();
  Future<Either<Failure, List<CertificateAward>>> pullCertificatesFromCloud();
  Future<Either<Failure, void>> pushCertificatesToCloud(
    List<CertificateAward> certificates,
  );
  Future<Either<Failure, void>> revokeGuardianLink(String counterpartUserId);
  Future<Either<Failure, void>> removeChild(String childUserId);
  Future<Either<Failure, FamilyDashboard>> getFamilyDashboard();
  Future<Either<Failure, void>> pullIdentityFromCloud();
  Future<Either<Failure, void>> pushIdentityToCloud();
}
