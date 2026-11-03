import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/home_widget/home_widget_publisher.dart';

class _Bridge implements HomeWidgetBridge {
  String? snapshot = 'private-account-data';
  bool fail = false;
  final actions = <String>[];
  @override
  Future<void> save(String key, String? json) async {
    if (fail) throw StateError('native storage unavailable');
    expect(key, HomeWidgetPublisher.snapshotKey);
    snapshot = json;
    actions.add('clear');
  }

  @override
  Future<void> requestUpdate() async {
    actions.add('redraw');
  }

  @override
  Future<void> cancelScheduledUpdates() async {
    actions.add('cancel');
  }

  @override
  Future<void> scheduleUpdates(List<DateTime> times) async {}
  @override
  Future<void> setReceiverEnabled(bool enabled) async {}
}

void main() {
  test(
    'startup clears private projection without constructing its progress loader',
    () async {
      final bridge = _Bridge();
      await clearHomeWidgetProjection(bridge);
      expect(bridge.snapshot, isNull);
      expect(bridge.actions, ['clear', 'redraw', 'cancel']);
    },
  );
  test('native failure rejects account activation before any redraw', () async {
    final bridge = _Bridge()..fail = true;
    await expectLater(clearHomeWidgetProjection(bridge), throwsStateError);
    expect(bridge.snapshot, 'private-account-data');
    expect(bridge.actions, isEmpty);
  });
}
