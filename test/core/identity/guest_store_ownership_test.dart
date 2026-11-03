import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/guest_store_ownership.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';

class RejectStore extends InMemorySharedPreferencesStore {
  RejectStore(super.data) : super.withData();
  String? rejectKey;
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      key.endsWith(rejectKey ?? '\u0000')
      ? false
      : super.setValue(type, key, value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<SharedPreferences> fresh([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test(
    'cold guest excludes sessions, deletion and unproven historical account',
    () async {
      for (final values in <Map<String, Object>>[
        {'sb-project-auth-token': 'nonempty'},
        {'SUPABASE_PERSIST_SESSION_KEY': 'nonempty'},
        {'account_deletion_owner': 'a'},
        {'account_deletion_stage': 'requested'},
        {'restore_cleanup_pending_v1': true},
        {'restore_account_state_v1': true},
        {'restore_cleanup_pending_v1': 'corrupt'},
        {'restore_guest_clean_v1': 'corrupt'},
        {'khatmah_owner': 'a'},
        {'auth_last_signed_in_user_id': 'a'},
      ]) {
        final ownership = GuestStoreOwnership(await fresh(values));
        expect(
          await ownership.canRestoreGuest(),
          isFalse,
          reason: values.keys.first,
        );
      }
      expect(
        await GuestStoreOwnership(await fresh()).canRestoreGuest(),
        isTrue,
      );
      expect(
        await GuestStoreOwnership(
          await fresh({
            'auth_last_signed_in_user_id': 'a',
            'restore_guest_clean_v1': true,
          }),
        ).canRestoreGuest(),
        isTrue,
      );
    },
  );
  test(
    'pending marker is durable before cleanup and proof follows only success',
    () async {
      final prefs = await fresh({'auth_last_signed_in_user_id': 'a'});
      final ownership = GuestStoreOwnership(prefs);
      await ownership.markAccountActive();
      expect(await ownership.canRestoreGuest(), isFalse);
      await ownership.beginCleanup();
      expect(prefs.getBool('restore_cleanup_pending_v1'), isTrue);
      expect(await ownership.canRestoreGuest(), isFalse);
      await ownership.finishCleanup();
      expect(prefs.containsKey('restore_cleanup_pending_v1'), isFalse);
      expect(await ownership.canRestoreGuest(), isTrue);
    },
  );
  test(
    'failed proof write remains pending and cannot authorize guest restore',
    () async {
      final store = RejectStore({});
      SharedPreferencesStorePlatform.instance = store;
      SharedPreferences.resetStatic();
      final prefs = await SharedPreferences.getInstance();
      final ownership = GuestStoreOwnership(prefs);
      await ownership.markAccountActive();
      await ownership.beginCleanup();
      store.rejectKey = 'restore_guest_clean_v1';
      await expectLater(ownership.finishCleanup(), throwsA(anything));
      expect(await ownership.canRestoreGuest(), isFalse);
    },
  );
  test(
    'failed clear retains pending; projection retry completes proof',
    () async {
      final prefs = await fresh({'auth_last_signed_in_user_id': 'a'});
      final barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = const FixedRecordOwnerProvider('local');
      await expectLater(
        barrier.clear(
          () async => throw AccountProjectionClearFailure(
            StateError('projection'),
            StackTrace.current,
          ),
        ),
        throwsStateError,
      );
      expect(await GuestStoreOwnership(prefs).canRestoreGuest(), isFalse);
      expect(await barrier.retryFailedClear(projection: () async {}), isTrue);
      expect(await GuestStoreOwnership(prefs).canRestoreGuest(), isTrue);
    },
  );
  test('signed-in cleanup restores deny marker before resuming', () async {
    final prefs = await fresh();
    final barrier = AccountDataBarrier.forPreferences(prefs)
      ..owner = const FixedRecordOwnerProvider('a');
    await barrier.clear(() async {});
    expect(barrier.isReady, isTrue);
    expect(prefs.getBool('restore_account_state_v1'), isTrue);
    expect(await GuestStoreOwnership(prefs).canRestoreGuest(), isFalse);
  });
  test('projection retry for signed-in owner restores deny marker', () async {
    final prefs = await fresh();
    final barrier = AccountDataBarrier.forPreferences(prefs)
      ..owner = const FixedRecordOwnerProvider('a');
    await expectLater(
      barrier.clear(
        () async => throw AccountProjectionClearFailure(
          StateError('projection'),
          StackTrace.current,
        ),
      ),
      throwsStateError,
    );
    expect(await barrier.retryFailedClear(projection: () async {}), isTrue);
    expect(prefs.getBool('restore_account_state_v1'), isTrue);
    expect(await GuestStoreOwnership(prefs).canRestoreGuest(), isFalse);
  });
  test('cleanup without bound owner cannot establish guest proof', () async {
    final prefs = await fresh();
    final barrier = AccountDataBarrier.forPreferences(prefs);
    await barrier.clear(() async {});
    expect(prefs.getBool('restore_account_state_v1'), isTrue);
    expect(await GuestStoreOwnership(prefs).canRestoreGuest(), isFalse);
  });
  test(
    'account activation invalidates previous clean proof before ready',
    () async {
      final prefs = await fresh({'restore_guest_clean_v1': true});
      const owner = FixedRecordOwnerProvider('a');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      barrier.prepareOwner('a');
      await barrier.markOwnerReady('a');
      expect(prefs.getBool('restore_account_state_v1'), isTrue);
      expect(prefs.containsKey('restore_guest_clean_v1'), isFalse);
      expect(await GuestStoreOwnership(prefs).canRestoreGuest(), isFalse);
    },
  );
  test('ordinary store failure never publishes a clean proof', () async {
    final prefs = await fresh();
    final barrier = AccountDataBarrier.forPreferences(prefs)
      ..owner = const FixedRecordOwnerProvider('a');
    await expectLater(
      barrier.clear(() async => throw StateError('store')),
      throwsStateError,
    );
    expect(prefs.getBool('restore_cleanup_pending_v1'), isTrue);
    expect(await GuestStoreOwnership(prefs).canRestoreGuest(), isFalse);
    expect(await barrier.retryFailedClear(), isFalse);
  });
}
