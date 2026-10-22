import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/kids_legacy_resume_recovery.dart';
import '../entities/parent_dashboard.dart';
import '../repositories/kids_legacy_split_recovery_repository.dart';

class RecoverKidsSessionSplit {
  const RecoverKidsSessionSplit(this._repository);
  final KidsLegacySplitRecoveryRepository _repository;

  Future<Either<Failure, ParentSettings>> call(
    KidsLegacyResumeRecoveryTicket ticket, {
    required bool whole,
    int? stageSize,
  }) => _repository.save(ticket, whole: whole, stageSize: stageSize);
}
