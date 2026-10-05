import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';

/// What the guardian sends to the child device: gifts, home missions and the
/// per-child policy.
abstract interface class KidsInboundRepository {
  /// Signed out is a successful no-op.
  Future<Either<Failure, void>> pullKidsInboundFromCloud();
}
