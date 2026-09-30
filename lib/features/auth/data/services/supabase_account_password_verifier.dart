import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/talia_logger.dart';
import '../../domain/services/account_password_verifier.dart';

/// Checks the password by signing in again as the current account.
///
/// Signing in with the current user's own email keeps the same owner, so
/// AuthCubit treats the refreshed session as the same session and does not
/// start a restore. A rejected password leaves the existing session intact.
class SupabaseAccountPasswordVerifier implements AccountPasswordVerifier {
  const SupabaseAccountPasswordVerifier();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  String? get currentEmail {
    final email = _client?.auth.currentUser?.email?.trim();
    return email == null || email.isEmpty ? null : email;
  }

  @override
  Future<AccountPasswordCheck> verify(String password) async {
    final client = _client;
    final user = client?.auth.currentUser;
    final email = currentEmail;
    if (client == null || user == null || email == null || password.isEmpty) {
      return AccountPasswordCheck.unavailable;
    }
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user?.id == user.id
          ? AccountPasswordCheck.verified
          : AccountPasswordCheck.unavailable;
    } on AuthException catch (e) {
      if (_isInvalidCredentials(e)) return AccountPasswordCheck.incorrect;
      TaliaLogger.w('Account password check failed', e);
      return AccountPasswordCheck.unavailable;
    } catch (e) {
      TaliaLogger.w('Account password check failed', e);
      return AccountPasswordCheck.unavailable;
    }
  }

  static bool _isInvalidCredentials(AuthException e) =>
      e.code == 'invalid_credentials' ||
      e.message.toLowerCase().contains('invalid login credentials');
}
