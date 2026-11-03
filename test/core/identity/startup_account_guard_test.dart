import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/guest_store_ownership.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/identity/startup_account_guard.dart';

void main() {
  Future<SharedPreferences> preferences(Map<String, Object> data) async {
    SharedPreferences.setMockInitialValues(data);
    return SharedPreferences.getInstance();
  }

  test(
    'cold preserved account without Khatmah cannot start guest progress',
    () async {
      final prefs = await preferences({
        GuestStoreOwnership.accountKey: true,
        'auth_last_signed_in_user_id': 'account-a',
        'unscoped_test_progress': 37,
      });
      final decision = await StartupAccountGuard(prefs).inspect(null);
      expect(decision.canStartProgress, isFalse);
      expect(decision.expectedOwnerId, 'account-a');
      expect(prefs.getInt('unscoped_test_progress'), 37);
      final barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = const FixedRecordOwnerProvider('local');
      expect(barrier.isReady, isFalse);
      expect(barrier.capture, throwsA(isA<AccountDataUnavailableException>()));
    },
  );
  test('only the retained owner can recover progress', () async {
    final prefs = await preferences({
      GuestStoreOwnership.accountKey: true,
      'auth_last_signed_in_user_id': 'account-a',
    });
    expect(
      (await StartupAccountGuard(prefs).inspect('account-b')).canStartProgress,
      isFalse,
    );
    expect(
      (await StartupAccountGuard(prefs).inspect('account-a')).canStartProgress,
      isTrue,
    );
  });
  test(
    'clean guest and first sign-in do not require a historical account',
    () async {
      final prefs = await preferences({});
      expect(
        (await StartupAccountGuard(prefs).inspect(null)).canStartProgress,
        isTrue,
      );
      expect(
        (await StartupAccountGuard(
          prefs,
        ).inspect('new-account')).canStartProgress,
        isTrue,
      );
      await prefs.setString('auth_last_signed_in_user_id', 'account-a');
      await prefs.setBool(GuestStoreOwnership.cleanKey, true);
      expect(
        (await StartupAccountGuard(prefs).inspect(null)).canStartProgress,
        isTrue,
      );
    },
  );
  test(
    'historical or malformed ownership remains fenced without destructive cleanup',
    () async {
      final prefs = await preferences({
        'auth_last_signed_in_user_id': 'account-a',
      });
      expect(
        (await StartupAccountGuard(prefs).inspect(null)).canStartProgress,
        isFalse,
      );
      await prefs.setString(GuestStoreOwnership.pendingKey, 'unreadable');
      expect(
        (await StartupAccountGuard(prefs).inspect(null)).canStartProgress,
        isFalse,
      );
      expect(prefs.getString('auth_last_signed_in_user_id'), 'account-a');
    },
  );
}
