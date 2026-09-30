/// Outcome of re-verifying the signed-in account's password.
enum AccountPasswordCheck {
  /// The password belongs to the account that is already signed in.
  verified,

  /// The account rejected the password.
  incorrect,

  /// No signed-in email account, or the check could not reach the server.
  unavailable,
}

/// Re-verifies the password of the account that is already signed in,
/// without switching accounts.
///
/// Used where a device-local secret (the guardian PIN) must be recovered:
/// only the account owner may reset it, never whoever holds the device.
abstract interface class AccountPasswordVerifier {
  /// Email of the signed-in account, or null when nobody is signed in.
  String? get currentEmail;

  Future<AccountPasswordCheck> verify(String password);
}
