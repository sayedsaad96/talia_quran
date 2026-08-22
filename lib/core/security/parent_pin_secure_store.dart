import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/talia_logger.dart';

abstract interface class ParentPinSecureStore {
  Future<String?> readVerifier(String ownerId);
  Future<void> writeVerifier(String ownerId, String verifier);
  Future<void> clearVerifier(String ownerId);
  Future<DateTime?> readBlockedUntil(String ownerId);
  Future<void> writeBlockedUntil(String ownerId, DateTime? blockedUntil);
  Future<int> readFailureCount(String ownerId);
  Future<void> writeFailureCount(String ownerId, int count);
}

class FlutterParentPinSecureStore implements ParentPinSecureStore {
  FlutterParentPinSecureStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _verifierKey = 'talia.parent_pin.verifier.v2';
  static const _blockedUntilKey = 'talia.parent_pin.blocked_until.v2';
  static const _failureCountKey = 'talia.parent_pin.failure_count.v2';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readVerifier(String ownerId) =>
      _guard<String?>('readVerifier', () => _storage.read(key: _verifier(ownerId)));

  @override
  Future<void> writeVerifier(String ownerId, String verifier) => _guard(
    'writeVerifier',
    () => _storage.write(key: _verifier(ownerId), value: verifier),
  );

  @override
  Future<void> clearVerifier(String ownerId) =>
      _guard('clearVerifier', () => _storage.delete(key: _verifier(ownerId)));

  @override
  Future<DateTime?> readBlockedUntil(String ownerId) async {
    final raw = await _guard(
      'readBlockedUntil',
      () => _storage.read(key: _ownerKey(_blockedUntilKey, ownerId)),
    );
    return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
  }

  @override
  Future<void> writeBlockedUntil(String ownerId, DateTime? blockedUntil) {
    final key = _ownerKey(_blockedUntilKey, ownerId);
    if (blockedUntil == null) {
      return _guard('writeBlockedUntil', () => _storage.delete(key: key));
    }
    return _guard(
      'writeBlockedUntil',
      () => _storage.write(
        key: key,
        value: blockedUntil.toUtc().toIso8601String(),
      ),
    );
  }

  @override
  Future<int> readFailureCount(String ownerId) async {
    final raw = await _guard(
      'readFailureCount',
      () => _storage.read(key: _ownerKey(_failureCountKey, ownerId)),
    );
    return int.tryParse(raw ?? '') ?? 0;
  }

  @override
  Future<void> writeFailureCount(String ownerId, int count) => _guard(
    'writeFailureCount',
    () => _storage.write(
      key: _ownerKey(_failureCountKey, ownerId),
      value: count.toString(),
    ),
  );

  String _verifier(String ownerId) => _ownerKey(_verifierKey, ownerId);

  String _ownerKey(String key, String ownerId) => '$key.$ownerId';

  // Android KeyStore throws PlatformException after reinstall or backup
  // restore; a PIN-store hiccup must never crash sign-out or account
  // switching, so failures degrade to "no stored value".
  Future<T?> _guard<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on Exception catch (error, stack) {
      TaliaLogger.w('ParentPin secure store $operation failed', error, stack);
      return null;
    }
  }
}
