import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/home_widget/platform_home_widget_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');
  final calls = <MethodCall>[];
  var succeeds = true;
  setUp(() {
    calls.clear();
    succeeds = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return succeeds;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test(
    'writes and clears the native key then redraws the qualified provider',
    () async {
      final bridge = PlatformHomeWidgetBridge(supported: true);
      await bridge.save('talia_widget_snapshot_v1', '{"schemaVersion":1}');
      await bridge.save('talia_widget_snapshot_v1', null);
      await bridge.requestUpdate();
      expect(calls.map((c) => c.method), [
        'saveWidgetData',
        'saveWidgetData',
        'updateWidget',
      ]);
      expect(calls[1].arguments['data'], isNull);
      expect(
        calls.last.arguments['qualifiedAndroidName'],
        'com.talia.quran.widget.TaliaHomeWidgetProvider',
      );
    },
  );
  test('native refusal is not acknowledged as a successful clear', () async {
    succeeds = false;
    await expectLater(
      PlatformHomeWidgetBridge(supported: true).save('key', null),
      throwsStateError,
    );
  });
  test('unsupported platforms never call the plugin', () async {
    final bridge = PlatformHomeWidgetBridge(supported: false);
    await bridge.save('key', null);
    await bridge.requestUpdate();
    expect(calls, isEmpty);
  });
}
