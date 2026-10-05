import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/memorization_entities.dart';

/// The family dashboard in steps: the children first, with each linked
/// child's missions and policy marked `detailsLoading`, then one update per
/// batch of children read. The last event is the complete dashboard.
abstract interface class FamilyDashboardStreamRepository {
  Stream<Either<Failure, FamilyDashboard>> watchFamilyDashboard();
}
