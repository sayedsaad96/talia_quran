import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/talia_logger.dart';

/// Owner-scoped account blobs held by platform-backed encrypted storage.
///
/// Device preferences remain in SharedPreferences; callers must use this store
/// for data that can identify, restore, or mutate an authenticated account.
abstract interface class EncryptedAccountPreferencesStore {
  Future<String?> read(String ownerId, String key);
  Future<void> write(String ownerId, String key, String value);
  Future<void> delete(String ownerId, String key);
}

class FlutterEncryptedAccountPreferencesStore
    implements EncryptedAccountPreferencesStore {
  FlutterEncryptedAccountPreferencesStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String ownerId, String key) =>
      _guard<String?>('read', () => _storage.read(key: _storageKey(ownerId, key)));

  @override
  Future<void> write(String ownerId, String key, String value) => _guard(
    'write',
    () => _storage.write(key: _storageKey(ownerId, key), value: value),
  );

  @override
  Future<void> delete(String ownerId, String key) =>
      _guard('delete', () => _storage.delete(key: _storageKey(ownerId, key)));

  String _storageKey(String ownerId, String key) =>
      'talia.account_preferences.v1.$ownerId.$key';

  // Android KeyStore throws PlatformException after reinstall or backup
  // restore; account switching and sign-out must keep working, so failures
  // degrade to "no stored value".
  Future<T?> _guard<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on Exception catch (error, stack) {
      TaliaLogger.w('Account secure store $operation failed', error, stack);
      return null;
    }
  }
}
