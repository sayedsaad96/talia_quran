import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/prayer_delivery/prayer_delivery_coordinator.dart';
import 'package:talia_quran/core/prayer_delivery/prayer_delivery_scheduler.dart';
import 'package:talia_quran/core/prayer_delivery/prayer_delivery_version.dart';
import 'package:talia_quran/core/prayer_delivery/prayer_scheduled_event.dart';

class _FakeScheduler implements PrayerDeliveryScheduler {
  _FakeScheduler(this.result);
  PrayerDeliveryResult result;
  int scheduleCalls = 0;
  int cancelAllCalls = 0;
  final List<List<PrayerScheduledEvent>> batches = [];

  @override
  Future<bool> canScheduleExact() async => true;

  @override
  Future<void> cancelPrayerEvent(PrayerScheduledEvent event) async {}

  @override
  Future<void> cancelPrayerEvents() async {
    cancelAllCalls++;
  }

  @override
  Future<PrayerDeliveryResult> schedulePrayerEvents(
    List<PrayerScheduledEvent> events,
  ) async {
    scheduleCalls++;
    batches.add(events);
    return result;
  }
}

PrayerScheduledEvent _event(String id) => PrayerScheduledEvent(
      eventId: id,
      prayerKey: 'fajr',
      scheduledAtUtc: DateTime.utc(2026, 9, 20, 21, 12),
      localPrayerTime: '00:12',
      timezoneId: 'Africa/Cairo',
      notificationEnabled: true,
      adhanEnabled: false,
    );

Future<SharedPreferences> _freshPrefs() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return SharedPreferences.getInstance();
}

void main() {
  test('non-Android never uses native delivery', () async {
    final scheduler = _FakeScheduler(
      const PrayerDeliveryResult(success: true, scheduledCount: 1),
    );
    final coordinator = PrayerDeliveryCoordinator(scheduler, isAndroid: () => false);
    final p = await _freshPrefs();

    var legacyCancelled = false;
    var legacyRebuilt = false;
    final handled = await coordinator.refreshNativeDelivery(
      prefs: p,
      events: [_event('e1')],
      cancelLegacyReminders: () async => legacyCancelled = true,
      rebuildLegacyReminders: () async => legacyRebuilt = true,
    );

    expect(handled, isFalse);
    expect(scheduler.scheduleCalls, 0);
    expect(legacyCancelled, isFalse);
    expect(legacyRebuilt, isFalse);
    expect(PrayerDeliveryVersion.read(p), PrayerDeliveryVersion.legacy);
  });

  test('V1 migration: legacy cancelled, native scheduled, V2 persisted',
      () async {
    final scheduler = _FakeScheduler(
      const PrayerDeliveryResult(success: true, scheduledCount: 2),
    );
    final coordinator = PrayerDeliveryCoordinator(scheduler, isAndroid: () => true);
    final p = await _freshPrefs();

    var legacyCancelled = false;
    var legacyRebuilt = false;
    final handled = await coordinator.refreshNativeDelivery(
      prefs: p,
      events: [_event('e1'), _event('e2')],
      cancelLegacyReminders: () async => legacyCancelled = true,
      rebuildLegacyReminders: () async => legacyRebuilt = true,
    );

    expect(handled, isTrue);
    expect(legacyCancelled, isTrue, reason: '§22 step 1');
    expect(scheduler.cancelAllCalls, 1, reason: '§22 step 2 (defensive)');
    expect(scheduler.scheduleCalls, 1);
    expect(legacyRebuilt, isFalse,
        reason: 'native succeeded — no legacy rebuild');
    expect(PrayerDeliveryVersion.read(p), PrayerDeliveryVersion.nativeAndroidV2,
        reason: '§22 step 6: persisted only after verified success');
  });

  test('V1 migration failure: legacy rebuilt, version stays 1', () async {
    final scheduler = _FakeScheduler(
      const PrayerDeliveryResult(
        success: false,
        scheduledCount: 0,
        error: 'denied',
      ),
    );
    final coordinator = PrayerDeliveryCoordinator(scheduler, isAndroid: () => true);
    final p = await _freshPrefs();

    var legacyRebuilt = false;
    final handled = await coordinator.refreshNativeDelivery(
      prefs: p,
      events: [_event('e1')],
      cancelLegacyReminders: () async {},
      rebuildLegacyReminders: () async => legacyRebuilt = true,
    );

    expect(handled, isTrue, reason: 'fallback legacy rebuild IS the delivery');
    expect(legacyRebuilt, isTrue);
    expect(PrayerDeliveryVersion.read(p), PrayerDeliveryVersion.legacy,
        reason: '§22: DO NOT persist V2 on failure');
  });

  test('V2 owner refresh: native rebuild only, no legacy calls', () async {
    SharedPreferences.setMockInitialValues({
      PrayerDeliveryVersion.prefsKey: PrayerDeliveryVersion.nativeAndroidV2,
    });
    final p = await SharedPreferences.getInstance();
    final scheduler = _FakeScheduler(
      const PrayerDeliveryResult(success: true, scheduledCount: 2),
    );
    final coordinator = PrayerDeliveryCoordinator(scheduler, isAndroid: () => true);

    var legacyCancelled = false;
    var legacyRebuilt = false;
    final handled = await coordinator.refreshNativeDelivery(
      prefs: p,
      events: [_event('e1'), _event('e2')],
      cancelLegacyReminders: () async => legacyCancelled = true,
      rebuildLegacyReminders: () async => legacyRebuilt = true,
    );

    expect(handled, isTrue);
    expect(scheduler.scheduleCalls, 1);
    expect(scheduler.cancelAllCalls, 0,
        reason: 'cancel-first happens inside the native scheduler');
    expect(legacyCancelled, isFalse);
    expect(legacyRebuilt, isFalse);
  });

  test('V2 rollback on failure: native cancelled, version 1, legacy rebuilt',
      () async {
    SharedPreferences.setMockInitialValues({
      PrayerDeliveryVersion.prefsKey: PrayerDeliveryVersion.nativeAndroidV2,
    });
    final p = await SharedPreferences.getInstance();
    final scheduler = _FakeScheduler(
      const PrayerDeliveryResult(
        success: false,
        scheduledCount: 0,
        error: 'boom',
      ),
    );
    final coordinator = PrayerDeliveryCoordinator(scheduler, isAndroid: () => true);

    var legacyRebuilt = false;
    final handled = await coordinator.refreshNativeDelivery(
      prefs: p,
      events: [_event('e1')],
      cancelLegacyReminders: () async {},
      rebuildLegacyReminders: () async => legacyRebuilt = true,
    );

    expect(handled, isTrue);
    expect(scheduler.cancelAllCalls, 1, reason: '§40: cancel native alarms');
    expect(legacyRebuilt, isTrue);
    expect(PrayerDeliveryVersion.read(p), PrayerDeliveryVersion.legacy);
  });

  test('empty events on V2: native alarms cancelled, handled', () async {
    SharedPreferences.setMockInitialValues({
      PrayerDeliveryVersion.prefsKey: PrayerDeliveryVersion.nativeAndroidV2,
    });
    final p = await SharedPreferences.getInstance();
    final scheduler = _FakeScheduler(
      const PrayerDeliveryResult(success: true, scheduledCount: 0),
    );
    final coordinator = PrayerDeliveryCoordinator(scheduler, isAndroid: () => true);

    final handled = await coordinator.refreshNativeDelivery(
      prefs: p,
      events: const [],
      cancelLegacyReminders: () async {},
      rebuildLegacyReminders: () async {},
    );

    expect(handled, isTrue);
    expect(scheduler.cancelAllCalls, 1);
    expect(scheduler.scheduleCalls, 0, reason: 'no stale native alarms');
  });

  test('empty events on V1: not handled (legacy path cancels legacy ids)',
      () async {
    final scheduler = _FakeScheduler(
      const PrayerDeliveryResult(success: true, scheduledCount: 0),
    );
    final coordinator = PrayerDeliveryCoordinator(scheduler, isAndroid: () => true);
    final p = await _freshPrefs();

    final handled = await coordinator.refreshNativeDelivery(
      prefs: p,
      events: const [],
      cancelLegacyReminders: () async {},
      rebuildLegacyReminders: () async {},
    );

    expect(handled, isFalse);
    expect(scheduler.scheduleCalls, 0);
    expect(PrayerDeliveryVersion.read(p), PrayerDeliveryVersion.legacy);
  });

  test('isNativeOwner mirrors the persisted version and platform', () async {
    final p = await _freshPrefs();
    final android = PrayerDeliveryCoordinator(
      _FakeScheduler(
        const PrayerDeliveryResult(success: true, scheduledCount: 0),
      ),
      isAndroid: () => true,
    );
    final nonAndroid = PrayerDeliveryCoordinator(
      _FakeScheduler(
        const PrayerDeliveryResult(success: true, scheduledCount: 0),
      ),
      isAndroid: () => false,
    );

    expect(android.isNativeOwner(p), isFalse);
    await PrayerDeliveryVersion.save(p, PrayerDeliveryVersion.nativeAndroidV2);
    expect(android.isNativeOwner(p), isTrue);
    expect(nonAndroid.isNativeOwner(p), isFalse);
  });
}