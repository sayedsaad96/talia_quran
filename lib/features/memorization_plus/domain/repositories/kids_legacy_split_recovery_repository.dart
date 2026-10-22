import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/kids_legacy_resume_recovery.dart';
import '../entities/parent_dashboard.dart';

abstract interface class KidsLegacySplitRecoveryRepository {
  Future<Either<Failure, ParentSettings>> save(
    KidsLegacyResumeRecoveryTicket ticket, {
    required bool whole,
    int? stageSize,
  });
}
