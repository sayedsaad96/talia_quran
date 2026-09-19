import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/features/prayer_companion/application/prayer_companion_controller.dart';
import 'package:talia_quran/features/prayer_companion/application/prayer_companion_usecases.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_companion/domain/repositories/prayer_companion_repository.dart';
import 'package:talia_quran/features/prayer_companion/domain/services/prayer_companion_policy.dart';
import 'package:talia_quran/features/prayer_companion/notifications/prayer_companion_notification_intent.dart';

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

class _InMemoryPrayerCompanionRepository implements PrayerCompanionRepository {
  final Map<String, PrayerCompanionRecord> records = {};
  final List<String> calls = [];

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<PrayerCompanionRecord?> read(PrayerOccurrence occurrence) async =>
      records[occurrence.occurrenceKey];

  @override
  Future<Map<PrayerKey, PrayerCompanionRecord>> readDay({
    required String ownerId,
    required DateTime localDate,
  }) async => const {};

  @override
  Future<PrayerCompanionRecord> save(PrayerCompanionRecord record) async {
    calls.add('save');
    records[record.occurrence.occurrenceKey] = record;
    return record;
  }

  @override
  Future<void> clearOwner(String ownerId) async {}
}

void main() {
  const ownerId = 'owner-a';
  final day = DateTime(2026, 9, 16);
  final occurrence = PrayerOccurrence(
    ownerId: ownerId,
    localDate: day,
    prayerKey: PrayerKey.asr,
    scheduledAt: DateTime(2026, 9, 16, 15),
  );
  final intent = PrayerCompanionNotificationIntent(
    occurrence: occurrence,
    kind: PrayerCompanionNotificationKind.checkIn,
  );

  late _InMemoryPrayerCompanionRepository repository;
  late _MockNotificationScheduler scheduler;
  late List<String> calls;

  PrayerCompanionController buildController({
    Future<DateTime?> Function()? nextPrayerAt,
  }) {
    return PrayerCompanionController(
      applyCommand: ApplyPrayerCompanionCommand(
        repository,
        const PrayerCompanionPolicy(),
      ),
      scheduler: scheduler,
      locale: () => const Locale('en'),
      nextPrayerAt: nextPrayerAt,
    );
  }

  setUpAll(() {
    registerFallbackValue(lookupAppLocalizations(const Locale('en')));
  });

  setUp(() {
    repository = _InMemoryPrayerCompanionRepository();
    calls = repository.calls;
    scheduler = _MockNotificationScheduler();
    when(
      () => scheduler.refreshNotifications(any(), force: any(named: 'force')),
    ).thenAnswer((_) async {
      calls.add('refresh');
    });
  });

  group('PrayerCompanionController.handle', () {
    test('confirm action saves before refreshing notifications', () async {
      final outcome = await buildController().handle(
        NotificationResponseEvent(
          payload: intent.encode(),
          actionId: 'action_prayer_companion_confirm',
        ),
      );

      expect(calls, ['save', 'refresh']);
      expect(
        repository.records[occurrence.occurrenceKey]?.status,
        PrayerCompanionStatus.confirmed,
      );
      expect(outcome.route, AppRoutes.home);
    });

    test('notification body tap opens Home without changing status', () async {
      final outcome = await buildController().handle(
        NotificationResponseEvent(payload: intent.encode()),
      );

      expect(outcome.route, AppRoutes.home);
      expect(calls, isEmpty);
      expect(repository.records, isEmpty);
    });

    test('empty-string action id is a body tap (no mutation)', () async {
      final outcome = await buildController().handle(
        NotificationResponseEvent(payload: intent.encode(), actionId: ''),
      );

      expect(outcome.route, AppRoutes.home);
      expect(calls, isEmpty);
      expect(repository.records, isEmpty);
    });

    test('invalid payload is a no-op resolved by legacy routing', () async {
      final outcome = await buildController().handle(
        const NotificationResponseEvent(payload: 'not-a-companion-payload'),
      );

      expect(outcome.route, AppRoutes.home);
      expect(calls, isEmpty);
      expect(repository.records, isEmpty);
    });

    test('invalid payload keeps legacy route payload untouched', () async {
      final outcome = await buildController().handle(
        const NotificationResponseEvent(payload: '/azkar/morning'),
      );

      expect(outcome.route, '/azkar/morning');
      expect(calls, isEmpty);
      expect(repository.records, isEmpty);
    });

    test('pray_now action maps to the prayNow command', () async {
      final outcome = await buildController().handle(
        NotificationResponseEvent(
          payload: intent.encode(),
          actionId: 'action_prayer_companion_pray_now',
        ),
      );

      expect(calls, ['save', 'refresh']);
      expect(
        repository.records[occurrence.occurrenceKey]?.status,
        PrayerCompanionStatus.prayNow,
      );
      expect(outcome.route, AppRoutes.home);
    });

    test('remind_later action maps to the remindLater command', () async {
      final outcome = await buildController().handle(
        NotificationResponseEvent(
          payload: intent.encode(),
          actionId: 'action_prayer_companion_remind_later',
        ),
      );

      expect(calls, ['save', 'refresh']);
      expect(
        repository.records[occurrence.occurrenceKey]?.status,
        PrayerCompanionStatus.remindLater,
      );
      expect(outcome.route, AppRoutes.home);
    });

    test(
      'unknown action id with pc1 payload navigates without mutation',
      () async {
        final outcome = await buildController().handle(
          NotificationResponseEvent(
            payload: intent.encode(),
            actionId: 'action_something_unknown',
          ),
        );

        expect(outcome.route, AppRoutes.home);
        expect(calls, isEmpty);
        expect(repository.records, isEmpty);
      },
    );
  });

  group('PrayerCompanionController.applyInApp', () {
    test('persists the command then force-refreshes notifications', () async {
      final saved = await buildController().applyInApp(
        occurrence,
        PrayerCompanionCommand.confirm,
      );

      expect(saved.status, PrayerCompanionStatus.confirmed);
      expect(calls, ['save', 'refresh']);
      verify(
        () => scheduler.refreshNotifications(any(), force: true),
      ).called(1);
    });

    test(
      'supplies the next prayer time to the command when available',
      () async {
        // Next prayer lands only 5 minutes after "now": a remindLater
        // follow-up (now + 10 min) falls past it, so the policy declines to
        // schedule one. This only happens when nextPrayerAt is supplied.
        final controller = PrayerCompanionController(
          applyCommand: ApplyPrayerCompanionCommand(
            repository,
            const PrayerCompanionPolicy(),
          ),
          scheduler: scheduler,
          locale: () => const Locale('en'),
          nextPrayerAt: () async =>
              DateTime.now().add(const Duration(minutes: 5)),
        );

        final saved = await controller.applyInApp(
          occurrence,
          PrayerCompanionCommand.remindLater,
        );

        expect(saved.status, PrayerCompanionStatus.remindLater);
        expect(saved.followUpAt, isNull);
        expect(saved.followUpCount, 0);
      },
    );

    test('without a next prayer time a follow-up is scheduled', () async {
      final saved = await buildController().applyInApp(
        occurrence,
        PrayerCompanionCommand.remindLater,
      );

      expect(saved.status, PrayerCompanionStatus.remindLater);
      expect(saved.followUpAt, isNotNull);
      expect(saved.followUpCount, 1);
    });
  });
}
