/// Keeps session recovery finite and deterministic. Network failures preserve
/// the local session for a later retry; revoked/invalid credentials do not.
class AuthSessionRecoveryPolicy {
  const AuthSessionRecoveryPolicy._();

  static bool isTerminal(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('invalid refresh token') ||
        message.contains('refresh token not found') ||
        message.contains('session not found') ||
        message.contains('session expired') ||
        message.contains('jwt expired') ||
        message.contains('invalid jwt') ||
        message.contains('token has expired') ||
        message.contains('token is expired') ||
        message.contains('revoked') ||
        message.contains('unauthorized') ||
        message.contains('401');
  }
}
