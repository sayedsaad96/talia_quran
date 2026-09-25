import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/prayer_delivery/android_prayer_delivery_scheduler.dart';
import 'package:talia_quran/core/prayer_delivery/prayer_scheduled_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('talia/prayer_delivery');
  final event = PrayerScheduledEvent(
    eventId: '2026-09-21_fajr',
    prayerKey: 'fajr',
    scheduledAtUtc: DateTime.utc(2026, 9, 20, 21, 12),
    localPrayerTime: '00:12',
    timezoneId: 'Africa/Cairo',
    notificationEnabled: true,
    adhanEnabled: true,
  );

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AndroidPrayerDeliveryScheduler', () {
    test('scheduleEvents sends serialized events and reports success', () async {
      Object? receivedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'scheduleEvents');
        receivedArgs = call.arguments;
        return <Object?, Object?>{
          'success': true,
          'scheduledCount': 1,
          'exactAllowed': true,
        };
      });

      final scheduler = AndroidPrayerDeliveryScheduler(channel: channel);
      final result = await scheduler.schedulePrayerEvents([event]);

      expect(result.success, isTrue);
      expect(result.scheduledCount, 1);
      expect(result.exactSchedulingAllowed, isTrue);
      final events = (receivedArgs as Map)['events'] as List;
      expect(events.single['eventId'], '2026-09-21_fajr');
      expect(events.single['adhanEnabled'], isTrue);
      expect(events.single['scheduledAtUtc'], endsWith('Z'));
    });

    test('empty batch short-circuits without touching the channel',
        () async {
      var calls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls++;
        return <Object?, Object?>{'success': true};
      });

      final scheduler = AndroidPrayerDeliveryScheduler(channel: channel);
      final result = await scheduler.schedulePrayerEvents(const []);

      expect(result.success, isTrue);
      expect(result.scheduledCount, 0);
      expect(calls, 0);
    });

    test('native failure maps to a non-throwing failed result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return <Object?, Object?>{
          'success': false,
          'error': 'exact alarms denied',
        };
      });

      final scheduler = AndroidPrayerDeliveryScheduler(channel: channel);
      final result = await scheduler.schedulePrayerEvents([event]);

      expect(result.success, isFalse);
      expect(result.error, 'exact alarms denied');
    });

    test('platform exception is swallowed into a failed result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ALARM_MANAGER', message: 'boom');
      });

      final scheduler = AndroidPrayerDeliveryScheduler(channel: channel);
      final result = await scheduler.schedulePrayerEvents([event]);

      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('missing native handler (MissingPluginException) fails softly',
        () async {
      // No handler registered at all → invokeMethod throws
      // MissingPluginException, which must map to a failed result.
      final scheduler = AndroidPrayerDeliveryScheduler(channel: channel);
      final result = await scheduler.schedulePrayerEvents([event]);

      expect(result.success, isFalse);
    });

    test('cancelAll targets the cancelAll method', () async {
      var cancelAllCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'cancelAll') cancelAllCalls++;
        return null;
      });

      final scheduler = AndroidPrayerDeliveryScheduler(channel: channel);
      await scheduler.cancelPrayerEvents();

      expect(cancelAllCalls, 1);
    });

    test('cancelEvent forwards the serialized event', () async {
      Object? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'cancelEvent') received = call.arguments;
        return null;
      });

      final scheduler = AndroidPrayerDeliveryScheduler(channel: channel);
      await scheduler.cancelPrayerEvent(event);

      expect(((received as Map)['event'] as Map)['eventId'],
          '2026-09-21_fajr');
    });

    test('canScheduleExact reports native permission state', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'canScheduleExact');
        return <Object?, Object?>{'canScheduleExact': false};
      });

      final scheduler = AndroidPrayerDeliveryScheduler(channel: channel);
      expect(await scheduler.canScheduleExact(), isFalse);
    });

    test('canScheduleExact fails softly when native side is absent',
        () async {
      final scheduler = AndroidPrayerDeliveryScheduler(channel: channel);
      expect(await scheduler.canScheduleExact(), isFalse);
    });
  });
}