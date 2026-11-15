import 'package:equatable/equatable.dart';
import 'invite_activity_target.dart';

enum InviteMode { personal, public }

enum InviteMoment { beforeActivity, afterActivity }

enum InviteIdentityMode { fullName, firstName, displayName, anonymous }

enum InviteLifecycleStatus { active, expired, revoked }

enum InviteParticipationStatus {
  opened,
  started,
  completedPrivate,
  completedSharedIdentity,
  continuedAsNewInvite;

  bool canAdvanceTo(InviteParticipationStatus next) => next.index > index;
}

enum ShareGoodFailure {
  featureUnavailable,
  network,
  invalidInvite,
  expired,
  rateLimited,
  authRequired,
  notEligible,
}

final class InviterIdentity extends Equatable {
  @override
  bool get stringify => false;

  const InviterIdentity({required this.mode, this.visibleName})
    : assert(mode != InviteIdentityMode.anonymous || visibleName == null);
  final InviteIdentityMode mode;
  final String? visibleName;
  @override
  List<Object?> get props => [mode, visibleName];
}

final class InviteContext extends Equatable {
  const InviteContext({
    required this.target,
    required this.moment,
    required this.mode,
    required this.identity,
  });
  final InviteActivityTarget target;
  final InviteMoment moment;
  final InviteMode mode;
  final InviterIdentity identity;
  @override
  List<Object?> get props => [target, moment, mode, identity];
}

final class CreatedInvite extends Equatable {
  @override
  bool get stringify => false;

  const CreatedInvite({
    required this.token,
    required this.shareUrl,
    required this.context,
    required this.createdAt,
    required this.expiresAt,
  });
  final String token;
  final Uri shareUrl;
  final InviteContext context;
  final DateTime createdAt, expiresAt;
  @override
  List<Object?> get props => [token, shareUrl, context, createdAt, expiresAt];
}

final class ResolvedInvite extends Equatable {
  @override
  bool get stringify => false;

  const ResolvedInvite({
    required this.token,
    required this.target,
    required this.moment,
    required this.mode,
    required this.inviter,
    required this.status,
    required this.expiresAt,
  });
  final String token;
  final InviteActivityTarget target;
  final InviteMoment moment;
  final InviteMode mode;
  final InviterIdentity inviter;
  final InviteLifecycleStatus status;
  final DateTime expiresAt;
  @override
  List<Object?> get props => [
    token,
    target,
    moment,
    mode,
    inviter,
    status,
    expiresAt,
  ];
}

final class InviteSession extends Equatable {
  @override
  bool get stringify => false;

  const InviteSession({
    required this.token,
    required this.snapshot,
    this.serverStatus,
    this.pendingStatus,
    this.awaitingConsent = false,
    this.localSessionId,
    this.startedAt,
  });
  final String token;
  final ResolvedInvite snapshot;
  final InviteParticipationStatus? serverStatus, pendingStatus;
  final bool awaitingConsent;
  final String? localSessionId;
  final DateTime? startedAt;
  @override
  List<Object?> get props => [
    token,
    snapshot,
    serverStatus,
    pendingStatus,
    awaitingConsent,
    localSessionId,
    startedAt,
  ];
}
