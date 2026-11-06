import 'package:equatable/equatable.dart';
import 'invite_activity_target.dart';
import 'invite_types.dart';

enum GoodImpactMilestone {
  firstChainStarted,
  fiveReach,
  tenResponses,
  twentyFiveReach,
}

final class InviteImpactSummary extends Equatable {
  @override
  bool get stringify => false;

  const InviteImpactSummary({
    required this.token,
    required this.target,
    required this.status,
    required this.expiresAt,
    required this.opens,
    required this.starts,
    required this.completions,
  });
  final String token;
  final InviteActivityTarget target;
  final InviteLifecycleStatus status;
  final DateTime expiresAt;
  final int opens, starts, completions;
  @override
  List<Object?> get props => [
    token,
    target,
    status,
    expiresAt,
    opens,
    starts,
    completions,
  ];
}

final class NamedAcknowledgement extends Equatable {
  @override
  bool get stringify => false;

  const NamedAcknowledgement({
    required this.target,
    required this.visibleName,
    required this.completedAt,
  });
  final InviteActivityTarget target;
  final String visibleName;
  final DateTime completedAt;
  @override
  List<Object?> get props => [target, visibleName, completedAt];
}

final class GoodImpact extends Equatable {
  const GoodImpact({
    required this.invites,
    required this.responses,
    required this.completions,
    required this.downstreamReach,
    required this.acknowledgements,
    required this.fetchedAt,
  });
  final List<InviteImpactSummary> invites;
  final int responses, completions, downstreamReach;
  final List<NamedAcknowledgement> acknowledgements;
  final DateTime fetchedAt;
  @override
  List<Object?> get props => [
    invites,
    responses,
    completions,
    downstreamReach,
    acknowledgements,
    fetchedAt,
  ];
}
