import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/memorization_entities.dart';

/// Gift hand-over: locked → unlocked (guardian) → requested (child) →
/// claimed (guardian approves). A null `childUserId` means the child on this
/// device; otherwise the guardian acts on a linked child through the server.
abstract interface class ParentRewardRepository {
  /// The child's gifts on this device.
  Future<Either<Failure, List<ParentReward>>> getDeviceRewards();

  Future<Either<Failure, List<ParentReward>>> requestParentReward(String id);

  Future<Either<Failure, List<ParentReward>>> unlockParentReward(
    String id, {
    String? childUserId,
  });

  Future<Either<Failure, List<ParentReward>>> approveParentReward(
    String id, {
    String? childUserId,
  });
}
