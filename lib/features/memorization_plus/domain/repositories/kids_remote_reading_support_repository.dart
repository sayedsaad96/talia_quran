import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/kids_learning_support_profile.dart';

/// The guardian's view of a linked child's reading answer (roadmap T7).
abstract interface class KidsRemoteReadingSupportRepository {
  Future<Either<Failure, KidsRemoteReadingSupport>> load(String childUserId);

  /// CAS against [expectedVersion]; a conflict is `PolicyConflictFailure`.
  Future<Either<Failure, KidsRemoteReadingSupport>> save(
    String childUserId,
    KidsLearningSupportProfile profile, {
    required int expectedVersion,
  });
}
