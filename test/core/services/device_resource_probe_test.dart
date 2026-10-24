import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/device_resource_probe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(DeviceResourceProbe.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('returns the host answers on Android', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return switch (call.method) {
        'freeBytes' => 4096,
        'isUnmeteredNetwork' => false,
        _ => null,
      };
    });
    const probe = DeviceResourceProbe(isAndroid: true);
    expect(await probe.freeBytes(), 4096);
    expect(await probe.isOnUnmeteredNetwork(), isFalse);
  });

  test('unknown, malformed or failing answers are null', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'freeBytes') return -1;
      throw PlatformException(code: 'boom');
    });
    const probe = DeviceResourceProbe(isAndroid: true);
    expect(await probe.freeBytes(), isNull);
    expect(await probe.isOnUnmeteredNetwork(), isNull);
  });

  test('off Android nothing is asked', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      return true;
    });
    const probe = DeviceResourceProbe(isAndroid: false);
    expect(await probe.freeBytes(), isNull);
    expect(await probe.isOnUnmeteredNetwork(), isNull);
    expect(calls, 0);
  });
}
