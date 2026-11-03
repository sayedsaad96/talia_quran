enum RetainedAccountRecoveryResult {
  recovered,
  wrongAccount,
  failed,
  unavailable,
}

abstract interface class RetainedAccountRecoveryRepository {
  Future<RetainedAccountRecoveryResult> signIn({
    required String email,
    required String password,
  });
}
