import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/memorization_plus/data/models/memorization_models.dart';
import '../memorization/review_record_identity.dart';
import '../security/parent_pin_secure_store.dart';
import '../security/parent_pin_verifier.dart';
import '../security/secure_storage_configuration.dart';

/// Strict reads are needed because the normal PIN store deliberately degrades
/// failed throttle reads to defaults. Both access the same platform keys.
abstract interface class RestorePinThrottleStorage {
  Future<String?> read(String key);
}

class FlutterRestorePinThrottleStorage implements RestorePinThrottleStorage {
  const FlutterRestorePinThrottleStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? taliaSecureStorage;
  final FlutterSecureStorage _storage;
  @override
  Future<String?> read(String key) => _storage.read(key: key);
}

/// Guest-only PIN gate for cold maintenance, without activating app services.
class RestoreParentPinGuard {
  RestoreParentPinGuard({
    required this._prefs,
    required this._pinStore,
    RestorePinThrottleStorage? throttleStorage,
    DateTime Function()? now,
  }) : _throttleStorage =
           throttleStorage ?? const FlutterRestorePinThrottleStorage(),
       _now = now ?? DateTime.now;
  final SharedPreferences _prefs;
  final ParentPinSecureStore _pinStore;
  final RestorePinThrottleStorage _throttleStorage;
  final DateTime Function() _now;
  static const _owner = ReviewRecordIdentity.localOwnerId;
  static const _settings = 'mem_plus_parent_settings';
  static const _secureMarker = 'secure-v2';
  static const _countKey = 'talia.parent_pin.failure_count.v2.local';
  static const _blockedKey = 'talia.parent_pin.blocked_until.v2.local';
  static Future<void> _tail = Future.value();

  /// Errors are treated as protected; callers must not interpret them as no PIN.
  Future<bool> requiresPin() async {
    try {
      final stored = await _settingsPin();
      final lookup = await _pinStore.lookupVerifier(_owner);
      await _readThrottle();
      if (lookup is ParentPinVerifierUnreadable) return true;
      return lookup is ParentPinVerifierPresent ||
          (stored != null && stored.isNotEmpty);
    } catch (_) {
      return true;
    }
  }

  /// Does not migrate or rewrite the stored PIN. Attempts are serialized and
  /// the owner's existing persistent lockout is checked and updated.
  Future<bool> verify(String pin) {
    final result = _tail.then((_) => _verify(pin));
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<bool> _verify(String pin) async {
    try {
      if (!RegExp(r'^\d{4}$').hasMatch(pin)) return false;
      final stored = await _settingsPin();
      final lookup = await _pinStore.lookupVerifier(_owner);
      if (lookup is ParentPinVerifierUnreadable) return false;
      final throttle = await _readThrottle();
      if (throttle.count > 0 && throttle.blockedUntil == null) return false;
      if (throttle.blockedUntil?.isAfter(_now().toUtc()) ?? false) return false;
      bool matches;
      if (lookup is ParentPinVerifierPresent) {
        matches = await ParentPinVerifier.verifyInBackground(
          pin,
          lookup.verifier,
        );
      } else if (stored == _secureMarker || stored == null || stored.isEmpty) {
        return false;
      } else {
        matches =
            stored == sha256.convert(utf8.encode(pin)).toString() ||
            (stored.length == 4 &&
                int.tryParse(stored) != null &&
                stored == pin);
      }
      if (!matches) {
        await _recordFailure(throttle.count + 1);
        return false;
      }
      return await _clearThrottle();
    } catch (_) {
      return false;
    }
  }

  Future<String?> _settingsPin() async {
    await _prefs.reload();
    const scoped = '$_settings|$_owner';
    final raw = _prefs.containsKey(scoped)
        ? _prefs.get(scoped)
        : _prefs.get(_settings);
    if (raw == null) return null;
    if (raw is! String) {
      throw const FormatException('Unreadable parent settings');
    }
    final parsed = jsonDecode(raw);
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Unreadable parent settings');
    }
    return ParentSettingsModel.fromJson(parsed).pinHash;
  }

  Future<({int count, DateTime? blockedUntil})> _readThrottle() async {
    final rawCount = await _throttleStorage.read(_countKey);
    final rawBlock = await _throttleStorage.read(_blockedKey);
    final count = rawCount == null ? 0 : int.tryParse(rawCount);
    final blocked = rawBlock == null
        ? null
        : DateTime.tryParse(rawBlock)?.toUtc();
    if (count == null || count < 0 || (rawBlock != null && blocked == null)) {
      throw const FormatException('Unreadable PIN throttle');
    }
    final sessionCount = await _pinStore.readFailureCount(_owner);
    final sessionBlock = await _pinStore.readBlockedUntil(_owner);
    final latest = blocked == null
        ? sessionBlock
        : sessionBlock == null || blocked.isAfter(sessionBlock)
        ? blocked
        : sessionBlock;
    final effectiveCount = max(count, sessionCount);
    if (effectiveCount > 0 && latest == null) {
      throw const FormatException('Incomplete PIN throttle');
    }
    return (count: effectiveCount, blockedUntil: latest);
  }

  Future<void> _recordFailure(int count) async {
    final delay = min(60, 1 << min(6, count));
    final until = _now().toUtc().add(Duration(seconds: delay));
    await _pinStore.writeFailureCount(_owner, count);
    await _pinStore.writeBlockedUntil(_owner, until);
    final persisted = await _readThrottle();
    final rawCount = await _throttleStorage.read(_countKey);
    final rawBlock = await _throttleStorage.read(_blockedKey);
    if (int.tryParse(rawCount ?? '') != count ||
        DateTime.tryParse(rawBlock ?? '')?.toUtc() != until ||
        persisted.count < count) {
      throw StateError('PIN throttle could not be stored');
    }
  }

  Future<bool> _clearThrottle() async {
    await _pinStore.writeFailureCount(_owner, 0);
    await _pinStore.writeBlockedUntil(_owner, null);
    final rawCount = await _throttleStorage.read(_countKey);
    final rawBlock = await _throttleStorage.read(_blockedKey);
    final effective = await _readThrottle();
    return rawCount == '0' &&
        rawBlock == null &&
        effective.count == 0 &&
        effective.blockedUntil == null;
  }
}
