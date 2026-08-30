import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/security/encrypted_account_preferences_store.dart';

void main() {
  test(
    'encrypted account read surfaces an unreadable storage failure',
    () async {
      final store = FlutterEncryptedAccountPreferencesStore(
        storage: const _UnreadableSecureStorage(),
      );

      await expectLater(
        store.read('owner-a', 'quran_bookmarks'),
        throwsA(isA<Exception>()),
      );
    },
  );

  test('encrypted account write surfaces a storage failure', () async {
    final store = FlutterEncryptedAccountPreferencesStore(
      storage: const _UnwritableSecureStorage(),
    );

    await expectLater(
      store.write('owner-a', 'quran_bookmarks', '[]'),
      throwsA(isA<Exception>()),
    );
  });
}

class _UnreadableSecureStorage extends FlutterSecureStorage {
  const _UnreadableSecureStorage();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('keystore unavailable');
  }
}

class _UnwritableSecureStorage extends FlutterSecureStorage {
  const _UnwritableSecureStorage();

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('keystore unavailable');
  }
}
