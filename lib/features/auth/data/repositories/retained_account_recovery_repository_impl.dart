import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/identity/guest_store_ownership.dart';
import '../../../../core/identity/startup_account_guard.dart';
import '../../domain/repositories/retained_account_recovery_repository.dart';

abstract interface class RetainedAccountAuthentication {
  String? get currentOwnerId;
  Future<String?> signIn({required String email, required String password});
  Future<void> signOutLocal();
}

class RetainedAuthenticationUnavailable implements Exception {
  const RetainedAuthenticationUnavailable();
}

class SupabaseRetainedAccountAuthentication
    implements RetainedAccountAuthentication {
  SupabaseClient get _client {
    if (!Supabase.instance.isInitialized) {
      throw const RetainedAuthenticationUnavailable();
    }
    return Supabase.instance.client;
  }

  @override
  String? get currentOwnerId => _client.auth.currentUser?.id;
  @override
  Future<String?> signIn({
    required String email,
    required String password,
  }) async => (await _client.auth.signInWithPassword(
    email: email,
    password: password,
  )).user?.id;
  @override
  Future<void> signOutLocal() =>
      _client.auth.signOut(scope: SignOutScope.local);
}

/// Authentication only; never opens progress, migrations or sync services.
class RetainedAccountRecoveryRepositoryImpl
    implements RetainedAccountRecoveryRepository {
  RetainedAccountRecoveryRepositoryImpl({
    required this.prefs,
    required this.expectedOwnerId,
    required this.authentication,
  });
  final SharedPreferences prefs;
  final String? expectedOwnerId;
  final RetainedAccountAuthentication authentication;
  bool _busy = false;

  @override
  Future<RetainedAccountRecoveryResult> signIn({
    required String email,
    required String password,
  }) async {
    if (_busy) return RetainedAccountRecoveryResult.failed;
    final expected = expectedOwnerId;
    if (expected == null || expected.isEmpty) {
      return RetainedAccountRecoveryResult.unavailable;
    }
    _busy = true;
    try {
      final before = await StartupAccountGuard(prefs).inspect(null);
      if (before.expectedOwnerId != expected) {
        return RetainedAccountRecoveryResult.wrongAccount;
      }
      await GuestStoreOwnership(prefs).markAccountActive();
      final authenticated = await authentication.signIn(
        email: email.trim(),
        password: password,
      );
      final decision = await StartupAccountGuard(prefs).inspect(authenticated);
      if (authenticated != expected ||
          authentication.currentOwnerId != expected ||
          !decision.canStartProgress ||
          decision.expectedOwnerId != expected) {
        await authentication.signOutLocal();
        return RetainedAccountRecoveryResult.wrongAccount;
      }
      return RetainedAccountRecoveryResult.recovered;
    } on RetainedAuthenticationUnavailable {
      return RetainedAccountRecoveryResult.unavailable;
    } catch (_) {
      return RetainedAccountRecoveryResult.failed;
    } finally {
      _busy = false;
    }
  }
}
