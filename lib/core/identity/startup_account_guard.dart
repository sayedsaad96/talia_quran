import 'package:shared_preferences/shared_preferences.dart';
import 'account_deletion_marker.dart';
import 'guest_store_ownership.dart';

class StartupAccountDecision {
  const StartupAccountDecision({
    required this.canStartProgress,
    this.expectedOwnerId,
  });
  final bool canStartProgress;
  final String? expectedOwnerId;
}

/// Reads identity metadata only, before constructing any progress dependency.
class StartupAccountGuard {
  const StartupAccountGuard(this._prefs);
  final SharedPreferences _prefs;

  Future<StartupAccountDecision> inspect(String? authenticatedOwnerId) async {
    try {
      await _prefs.reload();
      if (AccountDeletionMarker.hasPendingOperation(_prefs)) {
        return const StartupAccountDecision(canStartProgress: true);
      }
      final account = _prefs.get(GuestStoreOwnership.accountKey);
      final pending = _prefs.get(GuestStoreOwnership.pendingKey);
      final clean = _prefs.get(GuestStoreOwnership.cleanKey);
      final last = _prefs.get('auth_last_signed_in_user_id');
      final khatmah = _prefs.get('khatmah_owner');
      final owners = <String>{
        if (last is String && last.isNotEmpty && last != 'local') last,
        if (khatmah is String && khatmah.isNotEmpty && khatmah != 'local')
          khatmah,
      };
      final expected = owners.length == 1 ? owners.single : null;
      final malformed =
          [account, pending, clean].any((v) => v != null && v is! bool) ||
          (last != null && last is! String) ||
          (khatmah != null && khatmah is! String);
      final retained =
          account == true ||
          pending == true ||
          (last != null && last != '' && clean != true) ||
          (khatmah != null && khatmah != 'local' && khatmah != '');
      final unresolvedGuest =
          authenticatedOwnerId == null &&
          !await GuestStoreOwnership(_prefs).canRestoreGuest();
      return StartupAccountDecision(
        canStartProgress:
            !malformed &&
            !unresolvedGuest &&
            (!retained ||
                (expected != null && authenticatedOwnerId == expected)),
        expectedOwnerId: expected,
      );
    } catch (_) {
      return const StartupAccountDecision(canStartProgress: false);
    }
  }
}
