import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_companion/domain/services/prayer_companion_scheduler_planner.dart';
import 'package:talia_quran/features/prayer_companion/notifications/prayer_companion_notification_intent.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class FakeTZDateTime extends Fake implements tz.TZDateTime {}

void main() {
  late MockFlutterLocalNotificationsPlugin plugin;
  late TaliaNotificationService service;

  PrayerOccurrence occurrenceFor(PrayerKey prayerKey) => PrayerOccurrence(
    ownerId: 'local',
    localDate: DateTime(2026, 9, 20),
    prayerKey: prayerKey,
    scheduledAt: DateTime(2026, 9, 20, 12, 0),
  );

  ScheduledPrayerCompanionNotification reminder({
    required int id,
    required PrayerCompanionNotificationKind kind,
    PrayerKey prayerKey = PrayerKey.dhuhr,
  }) => ScheduledPrayerCompanionNotification(
    id: id,
    kind: kind,
    occurrence: occurrenceFor(prayerKey),
    scheduledAt: DateTime(2026, 9, 20, 12, 20),
  );

  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(FakeTZDateTime());
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  setUp(() {
    plugin = MockFlutterLocalNotificationsPlugin();
    service = TaliaNotificationService(plugin: plugin);
    service.debugSupportsNotifications = true;

    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  });

  group('ID namespaces', () {
    test('companion constants stay out of the legacy prayer range', () {
      expect(TaliaNotificationService.companionPlannedBaseId, 2100);
      expect(TaliaNotificationService.companionPlannedMaxCount, 20);
      expect(TaliaNotificationService.companionFollowUpBaseId, 2120);
      expect(TaliaNotificationService.companionFollowUpMaxCount, 10);
    });
  });

  group('cancelPrayerCompanionReminders', () {
    test('cancels only IDs 2100-2129, never legacy prayer IDs', () async {
      await service.cancelPrayerCompanionReminders();

      final cancelledIds = verify(
        () => plugin.cancel(id: captureAny(named: 'id')),
      ).captured;

      expect(cancelledIds, hasLength(30));
      expect(cancelledIds, everyElement(inInclusiveRange(2100, 2129)));
      expect(
        cancelledIds.any((id) => (id as int) >= 2000 && id <= 2039),
        isFalse,
      );
      verifyNever(() => plugin.cancelAll());
    });
  });

  group('schedulePrayerCompanionReminders', () {
    test(
      'schedules a single reminder with a round-trippable pc1 payload',
      () async {
        final event = reminder(
          id: 2101,
          kind: PrayerCompanionNotificationKind.checkIn,
        );

        await service.schedulePrayerCompanionReminders(
          reminders: [event],
          titleFor: (r) => 'Companion title',
          bodyFor: (r) => 'Companion body',
        );

        final captured = verify(
          () => plugin.zonedSchedule(
            id: 2101,
            title: 'Companion title',
            body: 'Companion body',
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            payload: captureAny(named: 'payload'),
          ),
        ).captured;

        final payload = captured.single as String;
        final intent = PrayerCompanionNotificationIntent.tryParse(payload);
        expect(intent, isNotNull);
        expect(intent!.occurrence, event.occurrence);
        expect(intent.kind, PrayerCompanionNotificationKind.checkIn);
        expect(payload, isNot(contains('صليت')));
      },
    );

    test('cancels the whole companion range before scheduling', () async {
      await service.schedulePrayerCompanionReminders(
        reminders: [
          reminder(id: 2100, kind: PrayerCompanionNotificationKind.preparation),
        ],
        titleFor: (r) => 't',
        bodyFor: (r) => 'b',
      );

      final cancelledIds = verify(
        () => plugin.cancel(id: captureAny(named: 'id')),
      ).captured;

      expect(cancelledIds, hasLength(30));
      expect(cancelledIds, everyElement(inInclusiveRange(2100, 2129)));
    });

    test('skips reminders whose scheduled time is in the past', () async {
      final past = ScheduledPrayerCompanionNotification(
        id: 2100,
        kind: PrayerCompanionNotificationKind.preparation,
        occurrence: occurrenceFor(PrayerKey.fajr),
        scheduledAt: DateTime(2000),
      );

      await service.schedulePrayerCompanionReminders(
        reminders: [past],
        titleFor: (r) => 't',
        bodyFor: (r) => 'b',
      );

      verifyNever(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test(
      'uses the companion category with the three companion actions',
      () async {
        await service.schedulePrayerCompanionReminders(
          reminders: [
            reminder(id: 2105, kind: PrayerCompanionNotificationKind.followUp),
          ],
          titleFor: (r) => 't',
          bodyFor: (r) => 'b',
        );

        final captured = verify(
          () => plugin.zonedSchedule(
            id: 2105,
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: captureAny(named: 'notificationDetails'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            payload: any(named: 'payload'),
          ),
        ).captured;

        final details = captured.single as NotificationDetails;
        final android = details.android!;
        expect(
          android.actions?.map((a) => a.id),
          containsAll(<String>[
            'action_prayer_companion_confirm',
            'action_prayer_companion_pray_now',
            'action_prayer_companion_remind_later',
          ]),
        );
        expect(details.iOS?.categoryIdentifier, 'prayer_companion_category');
      },
    );
  });
}
