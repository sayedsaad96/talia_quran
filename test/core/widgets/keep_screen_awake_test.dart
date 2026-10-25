import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/screen_awake_service.dart';
import 'package:talia_quran/core/widgets/keep_screen_awake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ScreenAwakeService.channelName);
  late List<bool> calls;
  late ScreenAwakeService service;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'setKeepScreenOn');
          calls.add((call.arguments as Map)['enabled'] as bool);
          return null;
        });
    service = ScreenAwakeService(isAndroid: true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('only the first acquire and last release reach the host', () async {
    await service.acquire();
    await service.acquire();
    await service.release();
    expect(calls, [true]);
    await service.release();
    await service.release();
    expect(calls, [true, false]);
    expect(service.isHeld, isFalse);
  });

  test('is a no-op off Android', () async {
    final other = ScreenAwakeService(isAndroid: false);
    await other.acquire();
    await other.release();
    expect(calls, isEmpty);
  });

  testWidgets('holds while its route is current, releases when covered '
      'and when popped', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox()),
    );

    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              KeepScreenAwake(service: service, child: const Text('reader')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.isHeld, isTrue);
    expect(calls, [true]);

    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Text('notes')),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.isHeld, isFalse);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(service.isHeld, isTrue);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(service.isHeld, isFalse);
    expect(calls, [true, false, true, false]);
  });
}
