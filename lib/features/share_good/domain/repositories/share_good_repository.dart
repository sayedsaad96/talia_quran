import 'package:dartz/dartz.dart';
import '../entities/good_impact.dart';
import '../entities/invite_types.dart';

abstract class ShareGoodRepository {
  Future<Either<ShareGoodFailure, CreatedInvite>> create(InviteContext ctx);
  Future<Either<ShareGoodFailure, CreatedInvite>> continueChain(
    String parentToken,
    InviteContext ctx,
  );
  Future<Either<ShareGoodFailure, InviteSession>> resolve(String token);
  Future<Either<ShareGoodFailure, InviteSession>> advance(
    String token,
    InviteParticipationStatus status,
  );
  Future<Either<ShareGoodFailure, InviteSession>> disclose(
    String token,
    String visibleName,
  );
  Future<Either<ShareGoodFailure, GoodImpact>> impact();
  Future<void> replayPending();
}
