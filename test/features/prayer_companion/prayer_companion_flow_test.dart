import 'dart:ffi' show Abi;
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/prayer_companion/application/prayer_companion_controller.dart';
import 'package:talia_quran/features/prayer_companion/application/prayer_companion_usecases.dart';
import 'package:talia_quran/features/prayer_companion/data/datasources/prayer_companion_local_datasource.dart';
import 'package:talia_quran/features/prayer_companion/data/datasources/prayer_companion_preferences.dart';
import 'package:talia_quran/features/prayer_companion/data/models/prayer_companion_record_isar.dart';
import 'package:talia_quran/features/prayer_companion/data/repositories/prayer_companion_repository_impl.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_companion/domain/repositories/prayer_companion_repository.dart';
import 'package:talia_quran/features/prayer_companion/domain/services/prayer_companion_policy.dart';
import 'package:talia_quran/features/prayer_companion/domain/services/prayer_companion_scheduler_planner.dart';
import 'package:talia_quran/features/prayer_companion/notifications/prayer_companion_notification_intent.dart';

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

class _FakeAppLocalizations extends Fake implements AppLocalizations {}

/// Minimal stand-in: the flow tests never rely on real prayer arithmetic.
class _StubPrayerTimesService implements PrayerTimesService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

bool _isarReady = false;

Future<void> _prepareIsar() async {
  if (_isarReady) return;
  if (Platform.isWindows) {
    final appData = Platform.environment['LOCALAPPDATA'];
    final path = appData == null
        ? null
        : '$appData\\Pub\\Cache\\hosted\\pub.dev\\'
              'isar_flutter_libs-3.1.0+1\\windows\\isar.dll';
    if (path != null && File(path).existsSync()) {
      await Isar.initializeIsarCore(libraries: {Abi.current(): path});
      _isarReady = true;
      return;
    }
  }
  await Isar.initializeIsarCore();
  _isarReady = true;
}

void main() {
  const ownerId = 'owner-a';
  final now = DateTime(2026, 9, 16, 15, 30);
  final localDate = DateTime(2026, 9, 16);

  late Isar isar;
  late Directory dir;
  late PrayerCompanionRepository repository;
  late PrayerCompanionPreferences preferences;
  late _MockNotificationScheduler scheduler;
  late PrayerCompanionController controller;

  PrayerOccurrence occurrenceFor(PrayerKey key, DateTime at) =>
      PrayerOccurrence(
        ownerId: ownerId,
        localDate: localDate,
        prayerKey: key,
        scheduledAt: at,
      );

  List<({PrayerKey key, DateTime time})> dayTimes() => [
    (key: PrayerKey.fajr, time: DateTime(2026, 9, 16, 4, 15)),
    (key: PrayerKey.dhuhr, time: DateTime(2026, 9, 16, 11, 55)),
    (key: PrayerKey.asr, time: DateTime(2026, 9, 16, 15, 25)),
    (key: PrayerKey.maghrib, time: DateTime(2026, 9, 16, 18, 5)),
    (key: PrayerKey.isha, time: DateTime(2026, 9, 16, 19, 25)),
  ];

  Future<PrayerCompanionDaySummary> summaryNow() =>
      GetPrayerCompanionDaySummary(
        repository,
        const FixedRecordOwnerProvider(ownerId),
      )(localDate: localDate, prayerTimes: dayTimes(), now: now);

  setUpAll(() {
    registerFallbackValue(_FakeAppLocalizations());
    registerFallbackValue(occurrenceFor(PrayerKey.asr, now));
  });

  setUp(() async {
    await _prepareIsar();
    SharedPreferences.setMockInitialValues({
      PrayerCompanionPreferences.enabledKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    preferences = PrayerCompanionPreferences(prefs);
    dir = await Directory.systemTemp.createTemp('talia_companion_flow_');
    isar = await Isar.open(
      [PrayerCompanionRecordIsarSchema],
      directory: dir.path,
      name: 'flow_${DateTime.now().microsecondsSinceEpoch}',
    );
    addTearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    repository = PrayerCompanionRepositoryImpl(
      PrayerCompanionLocalDatasource(isar),
      owner: const FixedRecordOwnerProvider(ownerId),
    );
    scheduler = _MockNotificationScheduler();
    when(
      () => scheduler.refreshNotifications(any(), force: true),
    ).thenAnswer((_) async {});
    controller = PrayerCompanionController(
      applyCommand: ApplyPrayerCompanionCommand(
        repository,
        const PrayerCompanionPolicy(),
        const FixedRecordOwnerProvider(ownerId),
      ),
      scheduler: scheduler,
      locale: () => const Locale('ar'),
      nextPrayerAt: () async => DateTime.now().add(const Duration(hours: 6)),
    );
  });

  test(
    'confirmation persists, is idempotent, and refreshes once per tap',
    () async {
      final asr = occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15, 25));
      await controller.applyInApp(asr, PrayerCompanionCommand.confirm);

      final saved = await repository.read(asr);
      expect(saved!.status, PrayerCompanionStatus.confirmed);
      expect(saved.followUpAt, isNull);

      // A repeated tap must not duplicate or change the terminal record.
      await controller.applyInApp(asr, PrayerCompanionCommand.confirm);
      final day = await repository.readDay(
        ownerId: ownerId,
        localDate: localDate,
      );
      expect(day, hasLength(1));
      expect(day[PrayerKey.asr]!.status, PrayerCompanionStatus.confirmed);
      verify(
        () => scheduler.refreshNotifications(any(), force: true),
      ).called(2);
    },
  );

  test(
    'pray now is not completion and creates exactly one follow-up',
    () async {
      final asr = occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15, 25));
      final before = DateTime.now();
      final saved = await controller.applyInApp(
        asr,
        PrayerCompanionCommand.prayNow,
      );

      expect(saved.status, PrayerCompanionStatus.prayNow);
      expect(saved.status, isNot(PrayerCompanionStatus.confirmed));
      expect(saved.followUpCount, 1);
      expect(saved.followUpAt, isNotNull);
      // The single follow-up fires 15 minutes after the command.
      final delay = saved.followUpAt!.difference(before);
      expect(delay.inMinutes, greaterThanOrEqualTo(15));
      expect(delay.inMinutes, lessThan(16));

      // The single follow-up budget must not be exceeded by a second tap.
      final again = await controller.applyInApp(
        asr,
        PrayerCompanionCommand.prayNow,
      );
      expect(again.followUpCount, 1);
      expect(
        await repository.readDay(ownerId: ownerId, localDate: localDate),
        hasLength(1),
      );
    },
  );

  test('remind later schedules one 10-minute follow-up', () async {
    final asr = occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15, 25));
    final before = DateTime.now();
    final saved = await controller.applyInApp(
      asr,
      PrayerCompanionCommand.remindLater,
    );
    expect(saved.followUpCount, 1);
    final delay = saved.followUpAt!.difference(before);
    expect(delay.inMinutes, greaterThanOrEqualTo(10));
    expect(delay.inMinutes, lessThan(11));
  });

  test('ignored notification leaves the occurrence unconfirmed', () async {
    final asr = occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15, 25));
    final summary = await summaryNow();

    expect(
      summary.statusByPrayer[PrayerKey.asr],
      PrayerCompanionStatus.unconfirmed,
    );
    expect(summary.confirmedCount, 0);
    expect(await repository.read(asr), isNull);
    // The past, unanswered prayer is what the user can still act on.
    expect(summary.actionableOccurrence!.prayerKey, PrayerKey.asr);
  });

  test('cold-start response writes once and resolves Home', () async {
    final asr = occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15, 25));
    final intent = PrayerCompanionNotificationIntent(
      occurrence: asr,
      kind: PrayerCompanionNotificationKind.checkIn,
    );

    final outcome = await controller.handle(
      NotificationResponseEvent(
        payload: intent.encode(),
        actionId: 'action_prayer_companion_confirm',
      ),
    );

    expect(outcome.route, AppRoutes.home);
    expect(
      (await repository.read(asr))!.status,
      PrayerCompanionStatus.confirmed,
    );
    expect(
      await repository.readDay(ownerId: ownerId, localDate: localDate),
      hasLength(1),
    );
  });

  test('a notification body tap never changes a status', () async {
    final asr = occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15, 25));
    final intent = PrayerCompanionNotificationIntent(
      occurrence: asr,
      kind: PrayerCompanionNotificationKind.checkIn,
    );

    await controller.handle(
      NotificationResponseEvent(payload: intent.encode()),
    );

    expect(await repository.read(asr), isNull);
    verifyNever(() => scheduler.refreshNotifications(any(), force: true));
  });

  test(
    'disabled Companion plans no events while records stay intact',
    () async {
      final asr = occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15, 25));
      await controller.applyInApp(asr, PrayerCompanionCommand.confirm);

      await preferences.write(const PrayerCompanionSettings(enabled: false));
      final planner = PrayerCompanionPlanner(
        prayerTimesService: _StubPrayerTimesService(),
        preferences: preferences,
        repository: repository,
        prefs: SharedPreferences.getInstance(),
        owner: const FixedRecordOwnerProvider(ownerId),
      );
      expect(await planner.plan(now: now), isEmpty);

      // Explicit user statements survive the feature being switched off.
      expect(
        (await repository.read(asr))!.status,
        PrayerCompanionStatus.confirmed,
      );
    },
  );

  test('stored statements keep their identity across refresh cycles', () async {
    final asr = occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15, 25));
    await controller.applyInApp(asr, PrayerCompanionCommand.notYet);

    // The scheduler is mocked here, so this exercises only the storage
    // contract: records are keyed by occurrence identity, not by refresh
    // state, and a reschedule never rewrites scheduledAt. End-to-end
    // refresh behavior is covered by the scheduler tests.
    await scheduler.refreshNotifications(_FakeAppLocalizations(), force: true);

    final saved = await repository.read(asr);
    expect(saved!.status, PrayerCompanionStatus.notYet);
    expect(saved.occurrence.scheduledAt, DateTime(2026, 9, 16, 15, 25));
  });

  test(
    'a stale-owner notification action is re-owned to the active account',
    () async {
      // A notification scheduled under a previous account fires after another
      // account signed in; the tap must be attributed to the active owner.
      final staleOccurrence = PrayerOccurrence(
        ownerId: 'owner-old',
        localDate: localDate,
        prayerKey: PrayerKey.asr,
        scheduledAt: DateTime(2026, 9, 16, 15, 25),
      );

      await controller.applyInApp(
        staleOccurrence,
        PrayerCompanionCommand.confirm,
      );

      final saved = await repository.read(
        occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15, 25)),
      );
      expect(saved!.status, PrayerCompanionStatus.confirmed);
      expect(saved.occurrence.ownerId, ownerId);
      expect(
        await repository.readDay(ownerId: ownerId, localDate: localDate),
        hasLength(1),
      );
    },
  );

  test('account reset clears local history', () async {
    final asr = occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15, 25));
    await controller.applyInApp(asr, PrayerCompanionCommand.confirm);
    expect(await repository.read(asr), isNotNull);

    await repository.clearOwner(ownerId);

    expect(await repository.read(asr), isNull);
    expect(
      await repository.readDay(ownerId: ownerId, localDate: localDate),
      isEmpty,
    );
  });
}
