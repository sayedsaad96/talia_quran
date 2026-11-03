import 'package:shared_preferences/shared_preferences.dart';
import '../memorization/review_record_identity.dart';

/// Durable proof that unscoped stores were cleared before a guest restore.
/// These markers do not identify an account or grant access to account data.
class GuestStoreOwnership {
  const GuestStoreOwnership(this._prefs);
  final SharedPreferences _prefs;
  static const accountKey = 'restore_account_state_v1';
  static const cleanKey = 'restore_guest_clean_v1';
  static const pendingKey = 'restore_cleanup_pending_v1';
  static const _lastOwner = 'auth_last_signed_in_user_id';
  static const _deletionOwner = 'account_deletion_owner';
  static const _deletionStage = 'account_deletion_stage';

  /// A clean installation is eligible. Historical account data requires an
  /// explicit successful-cleanup proof; unreadable or malformed state denies.
  Future<bool> canRestoreGuest() async {
    try {
      await _prefs.reload();
      final account = _prefs.get(accountKey);
      final pending = _prefs.get(pendingKey);
      final clean = _prefs.get(cleanKey);
      if ((account != null && account is! bool) ||
          account == true ||
          (pending != null && pending is! bool) ||
          pending == true ||
          (clean != null && clean is! bool)) {
        return false;
      }
      if (_prefs.containsKey(_deletionOwner) ||
          _prefs.containsKey(_deletionStage)) {
        return false;
      }
      for (final key in _prefs.getKeys()) {
        if (_isSessionKey(key) && _isNonempty(_prefs.get(key))) return false;
      }
      final khatmahOwner = _prefs.get('khatmah_owner');
      if (khatmahOwner != null &&
          khatmahOwner != ReviewRecordIdentity.localOwnerId) {
        return false;
      }
      final historical = _prefs.get(_lastOwner);
      if (historical != null && historical is! String) return false;
      if (_isNonempty(historical) && clean != true) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Records account ownership first so interruption can never leave a clean proof.
  Future<void> markAccountActive() async {
    await _writeBool(accountKey, true);
    await _remove(cleanKey);
  }

  /// Persists the fence before any account-owned stores are cleared.
  Future<void> beginCleanup() async {
    await _writeBool(pendingKey, true);
    await _remove(cleanKey);
  }

  /// Only a caller that completed every required store/projection may finish.
  Future<void> finishCleanup() async {
    await _prefs.reload();
    if (_prefs.get(pendingKey) != true) {
      throw StateError('Cleanup was not started');
    }
    await _remove(accountKey);
    await _writeBool(cleanKey, true);
    await _remove(pendingKey);
  }

  Future<void> _writeBool(String key, bool value) async {
    final ok = await _prefs.setBool(key, value);
    await _prefs.reload();
    if (!ok || _prefs.get(key) != value) {
      throw StateError('Ownership marker write failed');
    }
  }

  Future<void> _remove(String key) async {
    final ok = await _prefs.remove(key);
    await _prefs.reload();
    if (!ok || _prefs.containsKey(key)) {
      throw StateError('Ownership marker removal failed');
    }
  }

  static bool _isNonempty(Object? value) =>
      value != null && (value is! String || value.trim().isNotEmpty);
  static bool _isSessionKey(String key) {
    final lower = key.toLowerCase();
    return (lower.startsWith('sb-') && lower.endsWith('-auth-token')) ||
        lower == 'supabase_persist_session_key' ||
        lower == 'supabase.auth.token' ||
        lower == 'supabase_auth_token' ||
        lower == 'supabase_session' ||
        lower == 'supabase.auth.session';
  }
}
