import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/group_khatmah.dart';

class GroupPartConflictFailure extends Failure {
  const GroupPartConflictFailure() : super('groupKhatmahConflict');
}

class GroupKhatmahFailure extends Failure {
  const GroupKhatmahFailure(this.code) : super('groupKhatmahError');
  final String code;

  @override
  List<Object> get props => [code];
}

/// A recovery label deliberately excludes request arguments and member names.
class GroupFailedOperation {
  const GroupFailedOperation({required this.operationId, required this.action});
  final String operationId;
  final String action;
}

abstract interface class GroupKhatmahRepository {
  Future<Either<Failure, GroupKhatmah>> create(
    String title,
    String displayName,
  );
  Future<Either<Failure, GroupKhatmah>> join(String code, String displayName);
  Future<Either<Failure, GroupPart>> claim(String groupId, int juz);
  Future<Either<Failure, GroupPart>> release(String groupId, int juz);
  Future<Either<Failure, void>> completeLocally(String groupId, int juz);
  Future<Either<Failure, void>> retryFailedCompletion(String groupId, int juz);
  Future<Either<Failure, void>> discardFailedCompletion(
    String groupId,
    int juz,
  );
  Future<Either<Failure, void>> leave(String groupId);
  Stream<List<GroupKhatmah>> watchMine();
  Future<Either<Failure, void>> refreshMine();
  Future<Either<Failure, void>> flushPending();
  Future<Either<Failure, void>> reconcilePendingWake();
  List<GroupFailedOperation> failedOperations();
  Future<Either<Failure, void>> retryFailedOperation(String operationId);
  Future<Either<Failure, void>> discardFailedOperation(String operationId);

  /// Any unacknowledged intent, including a dead letter, for sign-out safety.
  Future<bool> hasPending();

  /// A non-dead-letter intent whose backoff has expired.
  Future<bool> hasRunnablePending();
  Future<void> dispose();
}
