import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/guest_store_ownership.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/auth/application/cloud_sync_coordinator.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/domain/repositories/auth_repository.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';

class _Auth extends Mock implements AuthRepository {}

class _Reset extends Mock implements AccountDataReset {}

class _Sync extends CloudSyncCoordinator {
  _Sync(AuthRepository auth) : super(authRepository: auth);
  int reconciliations = 0;
  @override
  Future<void> run() async {
    reconciliations++;
  }
}

void main() {
  test(
    'startup waits for the existing confirmed-deletion cleanup without launching it twice',
    () async {
      SharedPreferences.setMockInitialValues({
        'account_deletion_owner': 'account-a',
        'account_deletion_stage': 'remote_confirmed',
        GuestStoreOwnership.accountKey: true,
        'auth_last_signed_in_user_id': 'account-a',
      });
      final prefs = await SharedPreferences.getInstance();
      final auth = _Auth();
      when(() => auth.currentUser).thenReturn(null);
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      final cleanup = Completer<void>();
      when(() => auth.resumeDeletedAccountCleanup()).thenAnswer((_) async {
        await cleanup.future;
        await prefs.remove('account_deletion_owner');
        await prefs.remove('account_deletion_stage');
        await GuestStoreOwnership(prefs).beginCleanup();
        await GuestStoreOwnership(prefs).finishCleanup();
        return const Right(unit);
      });
      final sync = _Sync(auth);
      final cubit = AuthCubit(
        auth,
        null,
        null,
        null,
        null,
        prefs,
        _Reset(),
        sync,
        null,
        true,
      );
      addTearDown(cubit.close);
      var ready = false;
      final preparation = cubit.prepareStartupOwner().then((_) => ready = true);
      await Future<void>.value();
      expect(ready, isFalse);
      cleanup.complete();
      await preparation;
      expect(cubit.state, isA<AuthAccountDeleted>());
      cubit.activateAfterStartup();
      expect(sync.reconciliations, 0);
      verify(() => auth.resumeDeletedAccountCleanup()).called(1);
    },
  );
  test(
    'startup establishes local owner before migrations without starting cloud sync',
    () async {
      SharedPreferences.setMockInitialValues({
        'auth_last_signed_in_user_id': 'account-a',
      });
      final prefs = await SharedPreferences.getInstance();
      final barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = const FixedRecordOwnerProvider('account-a');
      final auth = _Auth();
      when(() => auth.currentUser).thenReturn(
        const AppUser(
          id: 'account-a',
          email: 'a@example.invalid',
          displayName: 'A',
        ),
      );
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      final reset = _Reset();
      when(() => reset.clearAccountWidget()).thenAnswer((_) async {});
      final sync = _Sync(auth);
      final cubit = AuthCubit(
        auth,
        null,
        null,
        null,
        null,
        prefs,
        reset,
        sync,
        null,
        true,
      );
      addTearDown(cubit.close);
      await cubit.ensureCloudSyncComplete();
      expect(sync.reconciliations, 0);
      await cubit.prepareStartupOwner();
      expect(barrier.isReady, isTrue);
      expect(prefs.getBool(GuestStoreOwnership.accountKey), isTrue);
      expect(sync.reconciliations, 0);
      cubit.activateAfterStartup();
      await cubit.ensureCloudSyncComplete();
      expect(sync.reconciliations, 1);
    },
  );

  test(
    'interrupted cleanup resumes before the same owner becomes ready',
    () async {
      SharedPreferences.setMockInitialValues({
        'auth_last_signed_in_user_id': 'account-a',
        GuestStoreOwnership.accountKey: true,
        GuestStoreOwnership.pendingKey: true,
        'test_retained_progress': 37,
      });
      final prefs = await SharedPreferences.getInstance();
      final barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = const FixedRecordOwnerProvider('account-a');
      final auth = _Auth();
      when(() => auth.currentUser).thenReturn(
        const AppUser(
          id: 'account-a',
          email: 'a@example.invalid',
          displayName: 'A',
        ),
      );
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      final reset = _Reset();
      when(() => reset.clearAccountWidget()).thenAnswer((_) async {});
      when(
        () => reset.clearAccountOwnedData(departingOwnerId: 'account-a'),
      ).thenAnswer(
        (_) => barrier.clear(() async {
          await prefs.remove('test_retained_progress');
        }),
      );
      final sync = _Sync(auth);
      final cubit = AuthCubit(
        auth,
        null,
        null,
        null,
        null,
        prefs,
        reset,
        sync,
        null,
        true,
      );
      addTearDown(cubit.close);
      await cubit.prepareStartupOwner();
      expect(prefs.containsKey('test_retained_progress'), isFalse);
      expect(prefs.containsKey(GuestStoreOwnership.pendingKey), isFalse);
      expect(barrier.isReady, isTrue);
      expect(sync.reconciliations, 0);
    },
  );
}
