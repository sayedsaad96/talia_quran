import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/home_widget/home_widget_launch_controller.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/router/widget_deep_link.dart';

void main() {
  test(
    'only the three allowlisted widget links reach existing destinations',
    () {
      expect(
        widgetDeepLinkDestination(Uri.parse('talia://widget/prayer')),
        '/?widgetPrayer=1',
      );
      expect(
        widgetDeepLinkDestination(Uri.parse('talia://widget/review')),
        AppRoutes.memorizationPlusDailyPlan,
      );
      expect(
        widgetDeepLinkDestination(Uri.parse('talia://widget/khatmah')),
        AppRoutes.khatmahDashboard,
      );
      for (final value in [
        'talia://widget/unknown',
        'https://widget/review',
        'talia://evil/review',
        'talia://widget/review?surahId=999',
        'talia://widget/review#extra',
        'talia://name@widget/review',
      ]) {
        expect(widgetDeepLinkDestination(Uri.parse(value)), AppRoutes.home);
      }
    },
  );
  test(
    'a cold tap waits for the full router and a newer warm tap wins',
    () async {
      final events = StreamController<Uri?>.broadcast(sync: true);
      final initial = Completer<Uri?>();
      final opened = <Uri>[];
      final controller = HomeWidgetLaunchController(
        events: events.stream,
        initial: () => initial.future,
        onOpen: opened.add,
      );
      controller.start();
      final warm = Uri.parse('talia://widget/review');
      events.add(warm);
      initial.complete(Uri.parse('talia://widget/khatmah'));
      await Future<void>.delayed(Duration.zero);
      expect(opened, isEmpty);
      controller.activate();
      expect(opened, [warm]);
      await controller.dispose();
      await events.close();
    },
  );
  test('late initial link after disposal never navigates', () async {
    final initial = Completer<Uri?>();
    final opened = <Uri>[];
    final controller = HomeWidgetLaunchController(
      events: const Stream.empty(),
      initial: () => initial.future,
      onOpen: opened.add,
    );
    controller.start();
    controller.activate();
    await controller.dispose();
    initial.complete(Uri.parse('talia://widget/khatmah'));
    await Future<void>.delayed(Duration.zero);
    expect(opened, isEmpty);
  });
}
