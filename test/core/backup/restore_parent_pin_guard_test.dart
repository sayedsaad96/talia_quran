import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/backup/restore_parent_pin_guard.dart';
import 'package:talia_quran/core/security/parent_pin_secure_store.dart';
import 'package:talia_quran/core/security/parent_pin_verifier.dart';

class MemoryPinStore
    implements ParentPinSecureStore, RestorePinThrottleStorage {
  final values = <String, String>{};
  bool unreadable = false, rejectWrites = false;
  String? verifier;
  String _fail(String id) => 'talia.parent_pin.failure_count.v2.$id';
  String _block(String id) => 'talia.parent_pin.blocked_until.v2.$id';
  @override
  Future<String?> read(String key) async {
    if (unreadable) throw StateError('unreadable');
    return values[key];
  }

  @override
  Future<ParentPinVerifierLookup> lookupVerifier(String ownerId) async =>
      unreadable
      ? const ParentPinVerifierUnreadable()
      : verifier == null
      ? const ParentPinVerifierAbsent()
      : ParentPinVerifierPresent(verifier!);
  @override
  Future<String?> readVerifier(String ownerId) async => verifier;
  @override
  Future<void> writeVerifier(String ownerId, String value) async {
    verifier = value;
  }

  @override
  Future<void> clearVerifier(String ownerId) async {
    verifier = null;
  }

  @override
  Future<DateTime?> readBlockedUntil(String id) async =>
      DateTime.tryParse(values[_block(id)] ?? '');
  @override
  Future<int> readFailureCount(String id) async =>
      int.tryParse(values[_fail(id)] ?? '') ?? 0;
  @override
  Future<void> writeBlockedUntil(String id, DateTime? value) async {
    if (rejectWrites) return;
    if (value == null) {
      values.remove(_block(id));
    } else {
      values[_block(id)] = value.toUtc().toIso8601String();
    }
  }

  @override
  Future<void> writeFailureCount(String id, int value) async {
    if (!rejectWrites) values[_fail(id)] = '$value';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<SharedPreferences> prefs([String? settings]) async {
    SharedPreferences.setMockInitialValues(
      settings == null ? {} : {'mem_plus_parent_settings|local': settings},
    );
    return SharedPreferences.getInstance();
  }

  test(
    'absent PIN is clear, corrupt settings and unreadable store fail closed',
    () async {
      final store = MemoryPinStore();
      expect(
        await RestoreParentPinGuard(
          prefs: await prefs(),
          pinStore: store,
          throttleStorage: store,
        ).requiresPin(),
        isFalse,
      );
      expect(
        await RestoreParentPinGuard(
          prefs: await prefs('{bad'),
          pinStore: store,
          throttleStorage: store,
        ).requiresPin(),
        isTrue,
      );
      store.unreadable = true;
      final guard = RestoreParentPinGuard(
        prefs: await prefs(),
        pinStore: store,
        throttleStorage: store,
      );
      expect(await guard.requiresPin(), isTrue);
      expect(await guard.verify('1234'), isFalse);
    },
  );
  test('secure marker without verifier never grants access', () async {
    final store = MemoryPinStore();
    final guard = RestoreParentPinGuard(
      prefs: await prefs('{"pinHash":"secure-v2"}'),
      pinStore: store,
      throttleStorage: store,
    );
    expect(await guard.requiresPin(), isTrue);
    expect(await guard.verify('1234'), isFalse);
  });
  test(
    'secure and legacy PINs verify and incorrect attempts persist a block',
    () async {
      final store = MemoryPinStore()
        ..verifier = ParentPinVerifier.create('1234', salt: List.filled(16, 7));
      final guard = RestoreParentPinGuard(
        prefs: await prefs('{"pinHash":"secure-v2"}'),
        pinStore: store,
        throttleStorage: store,
      );
      expect(await guard.verify('1234'), isTrue);
      expect(await guard.verify('0000'), isFalse);
      expect(await guard.verify('1234'), isFalse);
      expect(store.values['talia.parent_pin.failure_count.v2.local'], '1');
      for (final legacy in [
        '1234',
        sha256.convert(utf8.encode('1234')).toString(),
      ]) {
        final other = MemoryPinStore();
        final g = RestoreParentPinGuard(
          prefs: await prefs(jsonEncode({'pinHash': legacy})),
          pinStore: other,
          throttleStorage: other,
        );
        expect(await g.requiresPin(), isTrue);
        expect(await g.verify('1234'), isTrue);
      }
    },
  );
  test(
    'failed throttle persistence denies a correct PIN and leaves no bypass',
    () async {
      final store = MemoryPinStore()..rejectWrites = true;
      final guard = RestoreParentPinGuard(
        prefs: await prefs('{"pinHash":"1234"}'),
        pinStore: store,
        throttleStorage: store,
      );
      expect(await guard.verify('1234'), isFalse);
    },
  );
  test('legacy unscoped settings are read without being migrated', () async {
    SharedPreferences.setMockInitialValues({
      'mem_plus_parent_settings': '{"pinHash":"4321"}',
    });
    final preferences = await SharedPreferences.getInstance();
    final store = MemoryPinStore();
    final guard = RestoreParentPinGuard(
      prefs: preferences,
      pinStore: store,
      throttleStorage: store,
    );
    expect(await guard.requiresPin(), isTrue);
    expect(await guard.verify('4321'), isTrue);
    expect(preferences.containsKey('mem_plus_parent_settings|local'), isFalse);
    expect(
      preferences.getString('mem_plus_parent_settings'),
      '{"pinHash":"4321"}',
    );
  });
  test(
    'incomplete persisted throttle fails closed even for a correct PIN',
    () async {
      final store = MemoryPinStore();
      store.values['talia.parent_pin.failure_count.v2.local'] = '1';
      final guard = RestoreParentPinGuard(
        prefs: await prefs('{"pinHash":"1234"}'),
        pinStore: store,
        throttleStorage: store,
      );
      expect(await guard.requiresPin(), isTrue);
      expect(await guard.verify('1234'), isFalse);
    },
  );
}
