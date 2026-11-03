import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/guest_store_ownership.dart';
import 'package:talia_quran/core/identity/startup_account_guard.dart';
import 'package:talia_quran/features/auth/data/repositories/retained_account_recovery_repository_impl.dart';
import 'package:talia_quran/features/auth/domain/repositories/retained_account_recovery_repository.dart';

class _Authentication implements RetainedAccountAuthentication {
  String? result = 'account-a';
  bool called = false;
  int attempts = 0;
  Completer<void>? hold;
  final entered = Completer<void>();
  @override
  String? currentOwnerId;
  @override
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    called = true;
    attempts++;
    if (!entered.isCompleted) entered.complete();
    await hold?.future;
    currentOwnerId = result;
    return result;
  }

  @override
  Future<void> signOutLocal() async {
    currentOwnerId = null;
  }
}

void main() {
  late SharedPreferences prefs;
  late _Authentication authentication;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      GuestStoreOwnership.accountKey: true,
      'auth_last_signed_in_user_id': 'account-a',
      'unscoped_test_progress': 37,
    });
    prefs = await SharedPreferences.getInstance();
    authentication = _Authentication();
  });
  RetainedAccountRecoveryRepositoryImpl repository({
    String? owner = 'account-a',
  }) => RetainedAccountRecoveryRepositoryImpl(
    prefs: prefs,
    expectedOwnerId: owner,
    authentication: authentication,
  );
  test(
    'a metadata change during authentication fences the stale recovery',
    () async {
      final hold = Completer<void>();
      authentication.hold = hold;
      final operation = repository().signIn(
        email: 'a@example.invalid',
        password: 'password',
      );
      await authentication.entered.future;
      await prefs.setString('auth_last_signed_in_user_id', 'account-b');
      hold.complete();
      expect(await operation, RetainedAccountRecoveryResult.wrongAccount);
      expect(authentication.currentOwnerId, isNull);
      expect(prefs.getInt('unscoped_test_progress'), 37);
    },
  );
  test(
    'overlapping submissions cannot create competing recovery sessions',
    () async {
      final hold = Completer<void>();
      authentication.hold = hold;
      final recovery = repository();
      final first = recovery.signIn(
        email: 'a@example.invalid',
        password: 'password',
      );
      await authentication.entered.future;
      expect(
        await recovery.signIn(email: 'b@example.invalid', password: 'password'),
        RetainedAccountRecoveryResult.failed,
      );
      expect(authentication.attempts, 1);
      hold.complete();
      expect(await first, RetainedAccountRecoveryResult.recovered);
    },
  );
  test('another account cannot open or replace retained progress', () async {
    authentication.result = 'account-b';
    expect(
      await repository().signIn(
        email: 'b@example.invalid',
        password: 'password',
      ),
      RetainedAccountRecoveryResult.wrongAccount,
    );
    expect(authentication.currentOwnerId, isNull);
    expect(prefs.getInt('unscoped_test_progress'), 37);
    expect(
      (await StartupAccountGuard(prefs).inspect(null)).canStartProgress,
      isFalse,
    );
  });
  test(
    'successful same-owner authentication preserves pending progress',
    () async {
      expect(
        await repository().signIn(
          email: 'a@example.invalid',
          password: 'password',
        ),
        RetainedAccountRecoveryResult.recovered,
      );
      expect(authentication.currentOwnerId, 'account-a');
      expect(prefs.getInt('unscoped_test_progress'), 37);
      expect(prefs.getBool(GuestStoreOwnership.accountKey), isTrue);
      expect(
        (await StartupAccountGuard(
          prefs,
        ).inspect('account-a')).canStartProgress,
        isTrue,
      );
    },
  );
  test(
    'unknown retained owner never authenticates an arbitrary account',
    () async {
      expect(
        await repository(
          owner: null,
        ).signIn(email: 'a@example.invalid', password: 'password'),
        RetainedAccountRecoveryResult.unavailable,
      );
      expect(authentication.called, isFalse);
      expect(prefs.getInt('unscoped_test_progress'), 37);
    },
  );
}
