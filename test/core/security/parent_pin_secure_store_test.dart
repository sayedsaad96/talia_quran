import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/security/parent_pin_secure_store.dart';

class _BrokenStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _BrokenStorage storage;
  late FlutterParentPinSecureStore store;

  setUp(() {
    storage = _BrokenStorage();
    // A keystore reset after reinstall: every call fails.
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenThrow(PlatformException(code: 'keystore'));
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenThrow(PlatformException(code: 'keystore'));
    when(
      () => storage.delete(key: any(named: 'key')),
    ).thenThrow(PlatformException(code: 'keystore'));
    store = FlutterParentPinSecureStore(storage: storage);
  });

  test('throttle state survives a failing keystore for the session', () async {
    final blockedUntil = DateTime.utc(2030);

    await store.writeFailureCount('owner', 4);
    await store.writeBlockedUntil('owner', blockedUntil);

    expect(await store.readFailureCount('owner'), 4);
    expect(await store.readBlockedUntil('owner'), blockedUntil);
    expect(await store.readFailureCount('other-owner'), 0);
  });

  test('clearing the throttle also clears the session fallback', () async {
    await store.writeFailureCount('owner', 3);
    await store.writeBlockedUntil('owner', DateTime.utc(2030));

    await store.writeFailureCount('owner', 0);
    await store.writeBlockedUntil('owner', null);

    expect(await store.readFailureCount('owner'), 0);
    expect(await store.readBlockedUntil('owner'), isNull);
  });
}
