import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/memorization_entities.dart';
import '../repositories/parent_reward_repository.dart';

/// Gift hand-over steps for the guardian dashboard and the child's treasures.
class ParentRewardUsecase {
  const ParentRewardUsecase(this._repository);

  final ParentRewardRepository _repository;

  Future<Either<Failure, List<ParentReward>>> deviceRewards() =>
      _repository.getDeviceRewards();

  Future<Either<Failure, List<ParentReward>>> request(String id) =>
      _repository.requestParentReward(id);

  Future<Either<Failure, List<ParentReward>>> unlock(
    String id, {
    String? childUserId,
  }) => _repository.unlockParentReward(id, childUserId: childUserId);

  Future<Either<Failure, List<ParentReward>>> approve(
    String id, {
    String? childUserId,
  }) => _repository.approveParentReward(id, childUserId: childUserId);
}
