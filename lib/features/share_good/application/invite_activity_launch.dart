/// In-memory navigation context for an activity opened from an invite.
/// The identifier is local to this installation and is not a bearer token.
final class InviteActivityLaunch {
  const InviteActivityLaunch(this.localSessionId);

  final String localSessionId;
}
