import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/security/encrypted_account_preferences_store.dart';
import 'package:talia_quran/core/security/parent_pin_secure_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Map<String, String> data;
  late bool fail;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    data = {
      'talia.parent_pin.verifier.v2.owner-a': 'existing-verifier',
      'talia.account_preferences.v1.owner-a.bookmarks': 'existing-bookmarks',
    };
    fail = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      final args = Map<Object?, Object?>.from(call.arguments as Map);
      final options = Map<Object?, Object?>.from(args['options'] as Map);
      expect(options, {
        ...AndroidOptions.defaultOptions.toMap(),
        'resetOnError': 'false',
        'migrateOnAlgorithmChange': 'false',
      });
      if (fail) throw PlatformException(code: 'keystore');
      final key = args['key'] as String;
      switch (call.method) {
        case 'read':
          return data[key];
        case 'write':
          data[key] = args['value'] as String;
          return null;
        case 'delete':
          data.remove(key);
          return null;
      }
      throw StateError('Unexpected storage operation: ${call.method}');
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('existing owner data survives an Android keystore failure', () async {
    final pin = FlutterParentPinSecureStore();
    final accounts = FlutterEncryptedAccountPreferencesStore();
    expect(
      await pin.lookupVerifier('owner-a'),
      isA<ParentPinVerifierPresent>(),
    );
    expect(await accounts.read('owner-a', 'bookmarks'), 'existing-bookmarks');
    fail = true;
    expect(
      await pin.lookupVerifier('owner-a'),
      isA<ParentPinVerifierUnreadable>(),
    );
    await expectLater(
      accounts.read('owner-a', 'bookmarks'),
      throwsA(isA<PlatformException>()),
    );
    await expectLater(
      accounts.write('owner-a', 'bookmarks', 'new'),
      throwsA(isA<PlatformException>()),
    );
    fail = false;
    expect(await pin.readVerifier('owner-a'), 'existing-verifier');
    expect(await accounts.read('owner-a', 'bookmarks'), 'existing-bookmarks');
    await accounts.write('owner-b', 'bookmarks', 'other-owner');
    expect(await accounts.read('owner-b', 'bookmarks'), 'other-owner');
    expect(await accounts.read('owner-a', 'bookmarks'), 'existing-bookmarks');
  });
}
