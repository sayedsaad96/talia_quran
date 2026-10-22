import 'package:equatable/equatable.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/identity/account_data_barrier.dart';

final class KidsLegacyResumeRecoveryTicket extends Equatable {
  const KidsLegacyResumeRecoveryTicket({
    required this.ownerId,
    required this.lease,
    required this.surahId,
    required this.verifiedAyahCount,
    required this.defaultStageSize,
    required this.checkpointAyah,
  });

  final String ownerId;
  final AccountDataLease lease;
  final int surahId;
  final int verifiedAyahCount;
  final int defaultStageSize;
  final int checkpointAyah;

  @override
  List<Object?> get props => [
    ownerId,
    surahId,
    verifiedAyahCount,
    defaultStageSize,
    checkpointAyah,
  ];
}

final class KidsSplitChoiceRequiredFailure extends Failure {
  const KidsSplitChoiceRequiredFailure(this.ticket);

  final KidsLegacyResumeRecoveryTicket ticket;

  @override
  List<Object> get props => [ticket];
}
