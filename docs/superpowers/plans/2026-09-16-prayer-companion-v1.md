# Prayer Companion V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Add an opt-in, local-only Prayer Companion for explicit self-confirmation, gentle check-ins, one follow-up, and accessible daily status.

**Architecture:** The new prayer_companion feature owns self-reported state, Isar persistence, preferences, policy, and daily projections. It supplies typed requests to the existing notification scheduler/service and enriches the existing Home prayer sheet; it never calculates prayer times, syncs to Supabase, or emits XP, streak, activity, or journey events.

**Tech Stack:** Flutter/Dart 3.11, flutter_bloc, Isar 3, SharedPreferences, flutter_local_notifications, Workmanager, go_router, Flutter localization.

**Spec:** docs/superpowers/specs/2026-09-16-prayer-companion-design.md

## Global Constraints

- Self-confirmation only: no passed time, ignored alert, sensor, GPS, camera, microphone, or background signal is evidence of prayer.
- Local and owner-scoped only: no Supabase schema, cloud queue, XP, streak, activity-feed, or unified-journey change.
- Preserve PrayerTimesService, the city asset, legacy prayer IDs 2000–2039, and existing prayer-time notification behavior.
- Companion defaults off; it follows existing individual prayer filters, but not the existing prayer-alert master switch.
- Check in 20 minutes after prayer; follow up 15 minutes after I will pray now, 10 minutes after Remind me later, and never more than once per occurrence.
- Use MSA Arabic/neutral English and no religious reward, punishment, ruling, or shame copy.
- Planned Companion IDs are 2100–2119; follow-ups are 2120–2129; schedule only two rolling days.
- Persist notification actions only after Talia opens and dependencies are ready. Do not create a hidden background notification handler.
- Every task follows TDD: failing test, focused pass, analysis, and its own commit.

---

## File structure

| Path | Responsibility |
|---|---|
| lib/features/prayer_companion/domain/entities/prayer_companion.dart | Keys, occurrence identity, statuses, settings, records, summary and commands. |
| lib/features/prayer_companion/domain/repositories/prayer_companion_repository.dart | Owner-scoped persistence interface. |
| lib/features/prayer_companion/domain/services/prayer_companion_policy.dart | Pure transitions, follow-up, expiry and UI-state rules. |
| lib/features/prayer_companion/domain/services/prayer_companion_scheduler_planner.dart | Produces two-day notification requests. |
| lib/features/prayer_companion/data/ | Isar row, datasource, preferences and repository implementation. |
| lib/features/prayer_companion/application/ | Command use cases and notification-response controller. |
| lib/features/prayer_companion/notifications/ | Versioned notification payload parser. |
| lib/features/prayer_companion/presentation/ | Sheet action Cubit, status widget and settings section. |
| lib/core/services/notification_service.dart | Raw scheduling, categories, IDs and raw response delivery. |
| lib/core/services/notification_scheduler.dart | Existing central scheduling entry point; invokes Companion planner. |
| lib/core/sync/notification_refresh_worker.dart | Headless local scheduling graph. |
| lib/app.dart and lib/core/router/launch_destination.dart | Persist response after startup, then navigate Home. |

## Shared interfaces

~~~dart
enum PrayerKey { fajr, dhuhr, asr, maghrib, isha }
enum PrayerCompanionStatus { unconfirmed, prayNow, remindLater, confirmed, notYet }
enum PrayerCompanionCommand { confirm, prayNow, remindLater, notYet, clear }
enum PrayerCompanionNotificationKind { preparation, checkIn, followUp }

class PrayerOccurrence {
  const PrayerOccurrence({
    required this.ownerId, required this.localDate,
    required this.prayerKey, required this.scheduledAt,
  });
  final String ownerId;
  final DateTime localDate;
  final PrayerKey prayerKey;
  final DateTime scheduledAt;
  String get occurrenceKey => makeOccurrenceKey(ownerId, localDate, prayerKey);
}

abstract interface class PrayerCompanionRepository {
  Stream<void> get changes;
  Future<PrayerCompanionRecord?> read(PrayerOccurrence occurrence);
  Future<Map<PrayerKey, PrayerCompanionRecord>> readDay({
    required String ownerId, required DateTime localDate,
  });
  Future<PrayerCompanionRecord> save(PrayerCompanionRecord record);
  Future<void> clearOwner(String ownerId);
}
~~~

### Task 1: Implement pure state and transition policy

**Files:**
- Create: lib/features/prayer_companion/domain/entities/prayer_companion.dart
- Create: lib/features/prayer_companion/domain/services/prayer_companion_policy.dart
- Test: test/features/prayer_companion/domain/services/prayer_companion_policy_test.dart

**Consumes:** Dart time values only.
**Produces:** PrayerCompanionRecord, PrayerCompanionSettings, PrayerCompanionTransition, and PrayerCompanionPolicy.

- [ ] **Step 1: Add failing state-transition tests**

~~~dart
test('confirmation is terminal and idempotent', () {
  final first = policy.apply(
    existing: null, occurrence: asr,
    command: PrayerCompanionCommand.confirm, now: at1505,
  );
  final second = policy.apply(
    existing: first.record, occurrence: asr,
    command: PrayerCompanionCommand.confirm, now: at1506,
  );
  expect(first.record.status, PrayerCompanionStatus.confirmed);
  expect(first.shouldCancelFollowUp, isTrue);
  expect(second.record, same(first.record));
});

test('remind later creates one 10-minute follow-up before next prayer', () {
  final result = policy.apply(
    existing: null, occurrence: asr,
    command: PrayerCompanionCommand.remindLater, now: at1505,
    nextPrayerAt: DateTime(2026, 9, 16, 18),
  );
  expect(result.record.followUpAt, DateTime(2026, 9, 16, 15, 15));
  expect(result.record.followUpCount, 1);
});

test('unanswered occurrence is unconfirmed and never notYet', () {
  expect(policy.statusFor(occurrence: asr, record: null, now: at1521),
      PrayerCompanionStatus.unconfirmed);
});
~~~

Also test prayNow (15 minutes), notYet (no automatic follow-up), clear, duplicate follow-up attempts, suppression at/after next prayer, Isha/Fajr date boundaries, and that only confirmed counts in a summary.

- [ ] **Step 2: Run the focused test before implementation**

Run: flutter test test/features/prayer_companion/domain/services/prayer_companion_policy_test.dart
Expected: FAIL because the feature imports do not exist.

- [ ] **Step 3: Add immutable types and the minimal pure policy**

~~~dart
class PrayerCompanionRecord {
  const PrayerCompanionRecord({
    required this.occurrence, required this.status,
    required this.statusUpdatedAt, required this.followUpCount,
    required this.createdAt, required this.updatedAt, this.followUpAt,
  });
  final PrayerOccurrence occurrence;
  final PrayerCompanionStatus status;
  final DateTime statusUpdatedAt;
  final DateTime? followUpAt;
  final int followUpCount;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class PrayerCompanionPolicy {
  const PrayerCompanionPolicy();

  PrayerCompanionTransition apply({
    required PrayerCompanionRecord? existing,
    required PrayerOccurrence occurrence,
    required PrayerCompanionCommand command,
    required DateTime now,
    DateTime? nextPrayerAt,
  }) {
    if (command == PrayerCompanionCommand.confirm &&
        existing?.status == PrayerCompanionStatus.confirmed) {
      return PrayerCompanionTransition(
        record: existing!,
        shouldScheduleFollowUp: false,
        shouldCancelFollowUp: true,
      );
    }
    final candidateFollowUp = switch (command) {
      PrayerCompanionCommand.prayNow => now.add(const Duration(minutes: 15)),
      PrayerCompanionCommand.remindLater => now.add(const Duration(minutes: 10)),
      _ => null,
    };
    final canScheduleFollowUp = candidateFollowUp != null &&
        existing?.followUpCount != 1 &&
        (nextPrayerAt == null || candidateFollowUp.isBefore(nextPrayerAt));
    final status = switch (command) {
      PrayerCompanionCommand.confirm => PrayerCompanionStatus.confirmed,
      PrayerCompanionCommand.prayNow => PrayerCompanionStatus.prayNow,
      PrayerCompanionCommand.remindLater => PrayerCompanionStatus.remindLater,
      PrayerCompanionCommand.notYet => PrayerCompanionStatus.notYet,
      PrayerCompanionCommand.clear => PrayerCompanionStatus.unconfirmed,
    };
    return PrayerCompanionTransition(
      record: PrayerCompanionRecord(
        occurrence: occurrence,
        status: status,
        statusUpdatedAt: now,
        followUpAt: canScheduleFollowUp ? candidateFollowUp : null,
        followUpCount: canScheduleFollowUp ? 1 : 0,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
      shouldScheduleFollowUp: canScheduleFollowUp,
      shouldCancelFollowUp: !canScheduleFollowUp,
    );
  }
}
~~~

A repeated confirm returns the existing confirmed record. The only candidate follow-up times are 15 minutes for prayNow and 10 minutes for remindLater. Save count one only when it is before nextPrayerAt. Confirm, clear, and expiry clear followUpAt. statusFor derives unconfirmed without persisting a row.

- [ ] **Step 4: Run and verify the focused policy tests**

Run: flutter test test/features/prayer_companion/domain/services/prayer_companion_policy_test.dart
Expected: PASS.

- [ ] **Step 5: Format, analyze, and commit Task 1**

Run: dart format lib/features/prayer_companion/domain test/features/prayer_companion/domain
Run: flutter analyze lib/features/prayer_companion/domain test/features/prayer_companion/domain
Expected: no diagnostics.

~~~bash
git add lib/features/prayer_companion/domain test/features/prayer_companion/domain
git commit -m "feat(prayer): add companion domain policy"
~~~

### Task 2: Add Isar persistence, preferences, and reset cleanup

**Files:**
- Create: lib/features/prayer_companion/domain/repositories/prayer_companion_repository.dart
- Create: lib/features/prayer_companion/data/models/prayer_companion_record_isar.dart
- Create: lib/features/prayer_companion/data/datasources/prayer_companion_local_datasource.dart
- Create: lib/features/prayer_companion/data/datasources/prayer_companion_preferences.dart
- Create: lib/features/prayer_companion/data/repositories/prayer_companion_repository_impl.dart
- Modify: lib/core/di/injection.dart
- Modify: lib/core/identity/account_data_reset.dart
- Test: test/features/prayer_companion/data/prayer_companion_local_datasource_test.dart
- Test: test/core/identity/account_data_reset_test.dart

**Consumes:** Task 1, RecordOwnerProvider.currentOwnerId, Isar, and AccountDataBarrier.
**Produces:** owner-scoped repository, local preference store, schema registration, and reset-safe deletion.

- [ ] **Step 1: Add failing uniqueness, ownership, and reset tests**

~~~dart
test('same owner/date/prayer is replaced rather than duplicated', () async {
  await repository.save(record(asr, PrayerCompanionStatus.prayNow));
  await repository.save(record(asr, PrayerCompanionStatus.confirmed));
  final day = await repository.readDay(ownerId: 'owner-a', localDate: asr.localDate);
  expect(day, hasLength(1));
  expect(day[PrayerKey.asr]!.status, PrayerCompanionStatus.confirmed);
});

test('another owner cannot read a record', () async {
  await ownerARepository.save(record(asrFor('owner-a'), PrayerCompanionStatus.confirmed));
  expect(await ownerBRepository.readDay(ownerId: 'owner-b', localDate: at1505), isEmpty);
});
~~~

The reset test saves a row and every prayer_companion_ preference, calls clearAccountOwnedData, then expects no row and no matching key.

- [ ] **Step 2: Run persistence/reset tests before implementation**

Run: flutter test test/features/prayer_companion/data/prayer_companion_local_datasource_test.dart test/core/identity/account_data_reset_test.dart
Expected: FAIL because the collection, repository and preference store are absent.

- [ ] **Step 3: Implement the collection and transactional mapping**

~~~dart
@collection
class PrayerCompanionRecordIsar {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true) late String occurrenceKey;
  @Index() late String ownerId;
  @Index() late int localDayKey;
  late int prayerKeyIndex;
  late DateTime scheduledAt;
  late int statusIndex;
  late DateTime statusUpdatedAt;
  DateTime? followUpAt;
  int followUpCount = 0;
  late DateTime createdAt;
  late DateTime updatedAt;
}

class PrayerCompanionPreferences {
  static const enabledKey = 'prayer_companion_enabled';
  static const preparationMinutesKey = 'prayer_companion_preparation_minutes';
  static const checkInEnabledKey = 'prayer_companion_check_in_enabled';
  static const followUpEnabledKey = 'prayer_companion_follow_up_enabled';
  PrayerCompanionPreferences(this._prefs);
  final SharedPreferences _prefs;
}
~~~

Use the unique occurrenceKey for idempotent upsert. Register PrayerCompanionRecordIsarSchema and the datasource/repository/preferences in configureDependencies. Add prayer_companion_ to AccountDataReset.clearedPreferencePrefixes and clear the new collection in its existing Isar transaction. Do not add cloudDirty, a queue, Supabase imports, or a legacy migration.

Run: dart run build_runner build --delete-conflicting-outputs
Expected: generated Isar schema changes only.

- [ ] **Step 4: Run persistence/reset tests after implementation**

Run: flutter test test/features/prayer_companion/data/prayer_companion_local_datasource_test.dart test/core/identity/account_data_reset_test.dart
Expected: PASS.

- [ ] **Step 5: Format, analyze, and commit Task 2**

Run: dart format lib/features/prayer_companion lib/core/di/injection.dart lib/core/identity/account_data_reset.dart test/features/prayer_companion/data
Run: flutter analyze lib/features/prayer_companion lib/core/di/injection.dart lib/core/identity/account_data_reset.dart
Expected: no diagnostics.

~~~bash
git add lib/features/prayer_companion lib/core/di/injection.dart lib/core/identity/account_data_reset.dart test/features/prayer_companion/data test/core/identity/account_data_reset_test.dart
git commit -m "feat(prayer): persist companion confirmations locally"
~~~

### Task 3: Add daily projection and two-day planner

**Files:**
- Create: lib/features/prayer_companion/domain/services/prayer_companion_scheduler_planner.dart
- Create: lib/features/prayer_companion/application/prayer_companion_usecases.dart
- Test: test/features/prayer_companion/domain/services/prayer_companion_scheduler_planner_test.dart
- Test: test/features/prayer_companion/application/prayer_companion_usecases_test.dart

**Consumes:** Tasks 1–2 and PrayerTimesService.timesForDate.
**Produces:** PrayerCompanionDaySummary, ScheduledPrayerCompanionNotification, ApplyPrayerCompanionCommand, GetPrayerCompanionDaySummary, and PrayerCompanionPlanner.plan.

- [ ] **Step 1: Add failing planner and summary tests**

~~~dart
test('two-day plan has preparation and check-in for every enabled prayer', () async {
  final plan = await planner.plan(now: DateTime(2026, 9, 16, 9));
  expect(plan.where((e) => e.kind == PrayerCompanionNotificationKind.preparation), hasLength(10));
  expect(plan.where((e) => e.kind == PrayerCompanionNotificationKind.checkIn), hasLength(10));
});

test('confirmed occurrence has no Companion event', () async {
  await repository.save(record(asr, PrayerCompanionStatus.confirmed));
  final plan = await planner.plan(now: DateTime(2026, 9, 16, 9));
  expect(plan.where((e) => e.occurrence.occurrenceKey == asr.occurrenceKey), isEmpty);
});

test('daily progress counts confirmed records only', () async {
  await repository.save(record(fajr, PrayerCompanionStatus.confirmed));
  await repository.save(record(dhuhr, PrayerCompanionStatus.notYet));
  expect((await getDaySummary(at1505)).confirmedCount, 1);
});
~~~

- [ ] **Step 2: Run planner/use-case tests before implementation**

Run: flutter test test/features/prayer_companion/domain/services/prayer_companion_scheduler_planner_test.dart test/features/prayer_companion/application/prayer_companion_usecases_test.dart
Expected: FAIL because planner and use cases are absent.

- [ ] **Step 3: Implement deterministic planner and command use case**

~~~dart
class ScheduledPrayerCompanionNotification {
  const ScheduledPrayerCompanionNotification({
    required this.id, required this.kind,
    required this.occurrence, required this.scheduledAt,
  });
  final int id;
  final PrayerCompanionNotificationKind kind;
  final PrayerOccurrence occurrence;
  final DateTime scheduledAt;
}

// Planned ID: 2100 + dayOffset * 10 + prayerIndex * 2 + eventIndex.
// Follow-up ID: 2120 + dayOffset * 5 + prayerIndex.

class ApplyPrayerCompanionCommand {
  const ApplyPrayerCompanionCommand(this._repository, this._policy);
  Future<PrayerCompanionRecord> call({
    required PrayerOccurrence occurrence,
    required PrayerCompanionCommand command,
    required DateTime now,
    DateTime? nextPrayerAt,
  });
}

class GetPrayerCompanionDaySummary {
  const GetPrayerCompanionDaySummary(this._repository, this._owner);
  Future<PrayerCompanionDaySummary> call({
    required DateTime localDate,
    required List<({PrayerKey key, DateTime time})> prayerTimes,
    required DateTime now,
  });
}
~~~

For two local civil dates, calculate only the five obligatory prayers, skip individually disabled ones, skip elapsed events and confirmed records, then add preparation at 5/10/15 minutes before and check-in at 20 minutes after. Add persisted follow-ups only once, only within two days, and only before the next obligatory prayer. Planner reads but never creates records. The command use case calls the policy, persists its result, and returns the saved record.

- [ ] **Step 4: Run focused planner and prayer-calculation tests**

Run: flutter test test/features/prayer_companion/domain/services/prayer_companion_scheduler_planner_test.dart test/features/prayer_companion/application/prayer_companion_usecases_test.dart test/core/services/prayer_times_service_test.dart
Expected: PASS.

- [ ] **Step 5: Format, analyze, and commit Task 3**

Run: dart format lib/features/prayer_companion/domain lib/features/prayer_companion/application test/features/prayer_companion
Run: flutter analyze lib/features/prayer_companion/domain lib/features/prayer_companion/application
Expected: no diagnostics.

~~~bash
git add lib/features/prayer_companion/domain lib/features/prayer_companion/application test/features/prayer_companion
git commit -m "feat(prayer): plan companion reminders and daily status"
~~~

### Task 4: Extend notification infrastructure without disturbing prayer alerts

**Files:**
- Create: lib/features/prayer_companion/notifications/prayer_companion_notification_intent.dart
- Modify: lib/core/services/notification_service.dart
- Test: test/features/prayer_companion/notifications/prayer_companion_notification_intent_test.dart
- Test: test/core/services/notification_budget_test.dart
- Test: test/core/services/notification_service_companion_test.dart

**Consumes:** Task 3 scheduled requests and existing notification service/channel conventions.
**Produces:** NotificationResponseEvent, Companion categories/actions, payload codec, schedulePrayerCompanionReminders, and cancelPrayerCompanionReminders.

- [ ] **Step 1: Add failing codec, ID, and budget tests**

~~~dart
test('intent round-trips occurrence metadata only', () {
  final source = PrayerCompanionNotificationIntent(
    occurrence: asr,
    kind: PrayerCompanionNotificationKind.checkIn,
  );
  final decoded = PrayerCompanionNotificationIntent.tryParse(source.encode());
  expect(decoded, source);
  expect(source.encode(), isNot(contains('صليت')));
});

test('budget never selects protected Companion IDs', () {
  final evicted = notificationIdsToCancelForBudget(
    pendingIds: [...List.generate(20, (i) => 2100 + i), ...List.generate(21, (i) => 1040 + i)],
    incomingCount: 10,
    limit: 60,
  );
  expect(evicted.any((id) => id >= 2100 && id < 2130), isFalse);
});

test('Companion cancellation does not touch legacy prayer IDs', () async {
  await service.cancelPrayerCompanionReminders();
  verifyNever(() => plugin.cancel(id: any(that: inInclusiveRange(2000, 2039))));
});
~~~

- [ ] **Step 2: Run notification tests before implementation**

Run: flutter test test/features/prayer_companion/notifications/prayer_companion_notification_intent_test.dart test/core/services/notification_budget_test.dart test/core/services/notification_service_companion_test.dart
Expected: FAIL because the typed intent and Companion service methods are absent.

- [ ] **Step 3: Add versioned payload and service-owned namespaces**

~~~dart
class NotificationResponseEvent {
  const NotificationResponseEvent({this.payload, this.actionId});
  final String? payload;
  final String? actionId;
}

class PrayerCompanionNotificationIntent {
  const PrayerCompanionNotificationIntent({
    required this.occurrence, required this.kind,
  });
  static const version = 'pc1';
  final PrayerOccurrence occurrence;
  final PrayerCompanionNotificationKind kind;

  String encode() => encodeCompanionPayload(version, occurrence, kind);
  static PrayerCompanionNotificationIntent? tryParse(String? payload) =>
      parseCompanionPayload(payload);
}
~~~

In TaliaNotificationService add constants companionPlannedBaseId = 2100, companionPlannedMaxCount = 20, companionFollowUpBaseId = 2120, and companionFollowUpMaxCount = 10. Add a prayer_companion_category and Android actions action_prayer_companion_confirm, action_prayer_companion_pray_now, and action_prayer_companion_remind_later. Use showsUserInterface: true on Android. Leave prayer_category and its Quran/Azkar actions unchanged.

Replace the String-only onPayloadReceived callback with onNotificationResponse accepting NotificationResponseEvent. _onNotificationTapped forwards raw payload and action ID. Keep takePendingLaunch returning the same raw fields through NotificationLaunchRequest.

~~~dart
Future<void> schedulePrayerCompanionReminders({
  required List<ScheduledPrayerCompanionNotification> reminders,
}) async {
  await cancelPrayerCompanionReminders();
  await _reserveSlotsForPrayerNotifications(reminders.length);
  final slots = await _availableScheduledNotificationSlots();
  for (final reminder in reminders.take(slots)) {
    await _plugin.zonedSchedule(
      id: reminder.id,
      title: _companionTitle(reminder),
      body: _companionBody(reminder),
      scheduledDate: tz.TZDateTime.from(reminder.scheduledAt, tz.local),
      notificationDetails: _companionDetailsFor(reminder.kind),
      androidScheduleMode: await resolveTimeCriticalScheduleMode('prayer_companion'),
      payload: PrayerCompanionNotificationIntent(
        occurrence: reminder.occurrence, kind: reminder.kind,
      ).encode(),
    );
  }
}
~~~

Protect both 2000–2039 and 2100–2129 in notificationIdsToCancelForBudget. cancelPrayerCompanionReminders must cancel only 2100–2129.

- [ ] **Step 4: Run focused and legacy notification tests**

Run: flutter test test/features/prayer_companion/notifications/prayer_companion_notification_intent_test.dart test/core/services/notification_budget_test.dart test/core/services/notification_service_companion_test.dart test/core/services/notification_scheduler_phase2_test.dart
Expected: PASS; all existing prayer scheduling assertions still pass.

- [ ] **Step 5: Format, analyze, and commit Task 4**

Run: dart format lib/core/services/notification_service.dart lib/features/prayer_companion/notifications test/core/services test/features/prayer_companion/notifications
Run: flutter analyze lib/core/services/notification_service.dart lib/features/prayer_companion/notifications
Expected: no diagnostics.

~~~bash
git add lib/core/services/notification_service.dart lib/features/prayer_companion/notifications test/core/services test/features/prayer_companion/notifications
git commit -m "feat(prayer): add companion notification transport"
~~~

### Task 5: Schedule Companion events in foreground and headless refreshes

**Files:**
- Modify: lib/core/services/notification_scheduler.dart
- Modify: lib/core/sync/notification_refresh_worker.dart
- Modify: lib/core/di/injection.dart
- Test: test/core/services/notification_scheduler_companion_test.dart
- Test: test/core/sync/notification_refresh_worker_test.dart

**Consumes:** Tasks 2–4 and current localization/timezone refresh lifecycle.
**Produces:** Companion scheduling on normal refresh, cancellation when disabled, and a minimal headless local graph.

- [ ] **Step 1: Add failing scheduler/background tests**

~~~dart
test('scheduler adds Companion events without changing legacy prayer requests', () async {
  when(() => planner.plan(now: any(named: 'now'))).thenAnswer((_) async => [checkInReminder]);
  await scheduler.refreshNotifications(l10n, force: true);
  verify(() => service.schedulePrayerTimesReminders(prayers: any(named: 'prayers'))).called(1);
  verify(() => service.schedulePrayerCompanionReminders(reminders: [checkInReminder])).called(1);
});

test('disabled Companion cancels only Companion events', () async {
  await scheduler.refreshNotifications(l10n, force: true);
  verify(() => service.cancelPrayerCompanionReminders()).called(1);
  verifyNever(() => service.cancelPrayerTimesReminders());
});

test('headless refresh builds local prayer and Companion dependencies', () async {
  final result = await runNotificationRefreshTask(createScheduler: recordingFactory);
  expect(result, isTrue);
  expect(recordingFactory.receivedPrayerTimesService, isTrue);
  expect(recordingFactory.receivedCompanionPlanner, isTrue);
});
~~~

- [ ] **Step 2: Run focused scheduling tests before implementation**

Run: flutter test test/core/services/notification_scheduler_companion_test.dart test/core/sync/notification_refresh_worker_test.dart
Expected: FAIL because the scheduler cannot receive Companion dependencies and the worker has no local factory seam.

- [ ] **Step 3: Extend the existing scheduler through explicit dependencies**

~~~dart
class NotificationScheduler {
  NotificationScheduler(
    this._service, {
    PrayerTimesService? prayerTimesService,
    PrayerCompanionPlanner? prayerCompanionPlanner,
    PrayerCompanionPreferences? prayerCompanionPreferences,
    // Preserve all existing named dependencies.
  }) : _prayerTimesService = prayerTimesService,
       _prayerCompanionPlanner = prayerCompanionPlanner,
       _prayerCompanionPreferences = prayerCompanionPreferences;

  Future<void> _refreshPrayerCompanion(DateTime now) async {
    final settings = _prayerCompanionPreferences?.read();
    if (settings == null || !settings.enabled || !_prayerTimesReady()) {
      await _service.cancelPrayerCompanionReminders();
      return;
    }
    final reminders = await _prayerCompanionPlanner!.plan(now: now);
    await _service.schedulePrayerCompanionReminders(reminders: reminders);
  }
}
~~~

Call _refreshPrayerCompanion after the existing legacy prayer-time block. Pass PrayerTimesService, PrayerCompanionPlanner and PrayerCompanionPreferences from configureDependencies; do not rely on GetIt fallbacks.

Refactor runNotificationRefreshTask to accept an optional NotificationScheduler Function(SharedPreferences) createScheduler test seam. The production factory must use the same SharedPreferences, open the local Isar schema, construct PrayerTimesService, PrayerCompanionLocalDatasource, repository, preferences and planner explicitly, then create NotificationScheduler with them. It must not call AppInitializer.initialize, request permission, initialize Supabase, or register a second Workmanager dispatcher.

- [ ] **Step 4: Run scheduler, worker, and existing prayer tests**

Run: flutter test test/core/services/notification_scheduler_companion_test.dart test/core/sync/notification_refresh_worker_test.dart test/core/services/notification_scheduler_phase2_test.dart test/core/services/notification_budget_test.dart
Expected: PASS.

- [ ] **Step 5: Format, analyze, and commit Task 5**

Run: dart format lib/core/services/notification_scheduler.dart lib/core/sync/notification_refresh_worker.dart lib/core/di/injection.dart test/core/services test/core/sync
Run: flutter analyze lib/core/services/notification_scheduler.dart lib/core/sync/notification_refresh_worker.dart lib/core/di/injection.dart
Expected: no diagnostics.

~~~bash
git add lib/core/services/notification_scheduler.dart lib/core/sync/notification_refresh_worker.dart lib/core/di/injection.dart test/core/services/notification_scheduler_companion_test.dart test/core/sync/notification_refresh_worker_test.dart
git commit -m "feat(prayer): schedule companion reminders locally"
~~~

### Task 6: Persist notification actions after Talia has opened

**Files:**
- Create: lib/features/prayer_companion/application/prayer_companion_controller.dart
- Modify: lib/app.dart
- Modify: lib/core/router/launch_destination.dart
- Test: test/features/prayer_companion/application/prayer_companion_controller_test.dart
- Test: test/core/router/launch_destination_test.dart

**Consumes:** Tasks 1–5, NotificationResponseEvent and PrayerCompanionNotificationIntent.
**Produces:** one foreground/cold-start response path that persists, refreshes, and then routes.

- [ ] **Step 1: Add failing controller and route tests**

~~~dart
test('confirm saves before refresh', () async {
  final calls = <String>[];
  when(() => applyCommand(any(), any())).thenAnswer((_) async {
    calls.add('save');
    return confirmedRecord;
  });
  when(() => scheduler.refreshNotifications(any(), force: true)).thenAnswer((_) async {
    calls.add('refresh');
  });

  await controller.handle(NotificationResponseEvent(
    payload: intent.encode(), actionId: 'action_prayer_companion_confirm',
  ));
  expect(calls, ['save', 'refresh']);
});

test('notification body opens Home without changing a status', () async {
  final outcome = await controller.handle(NotificationResponseEvent(payload: intent.encode()));
  expect(outcome.route, AppRoutes.home);
  verifyNever(() => applyCommand(any(), any()));
});
~~~

- [ ] **Step 2: Run response tests before implementation**

Run: flutter test test/features/prayer_companion/application/prayer_companion_controller_test.dart test/core/router/launch_destination_test.dart
Expected: FAIL because controller and response route helper do not exist.

- [ ] **Step 3: Implement controller and app response bridge**

~~~dart
class PrayerCompanionController {
  PrayerCompanionController(this._applyCommand, this._scheduler, this._locale);

  Future<PrayerCompanionRecord> applyInApp(
    PrayerOccurrence occurrence,
    PrayerCompanionCommand command,
  ) async {
    final saved = await _applyCommand(occurrence, command);
    await _scheduler.refreshNotifications(
      lookupAppLocalizations(_locale()),
      force: true,
    );
    return saved;
  }

  Future<PrayerCompanionResponseOutcome> handle(NotificationResponseEvent event) async {
    final intent = PrayerCompanionNotificationIntent.tryParse(event.payload);
    final command = commandForActionId(event.actionId);
    if (intent == null || command == null) {
      return PrayerCompanionResponseOutcome(
        route: LaunchDestination.routeForResponse(event),
      );
    }
    await applyInApp(intent.occurrence, command);
    return const PrayerCompanionResponseOutcome(route: AppRoutes.home);
  }
}
~~~

Map only the three Companion action IDs. An empty action ID is a body tap: navigate Home and do not mutate. Add LaunchDestination.routeForResponse(NotificationResponseEvent), retaining current legacy action/payload precedence but never treating pc1 payloads as go_router paths.

In TaliaApp set notificationService.onNotificationResponse once. For active responses, await controller.handle then AppRouter.router.go(outcome.route). In _applyLaunchNavigation, pass takePendingLaunch through exactly the same controller after DI is ready, then route. This is the supported killed-app behavior: launch first, persist second.

- [ ] **Step 4: Run response and legacy route tests**

Run: flutter test test/features/prayer_companion/application/prayer_companion_controller_test.dart test/core/router/launch_destination_test.dart test/core/router/app_router_route_policy_test.dart test/core/services/daily_ayah_notification_target_test.dart
Expected: PASS.

- [ ] **Step 5: Format, analyze, and commit Task 6**

Run: dart format lib/features/prayer_companion/application lib/app.dart lib/core/router/launch_destination.dart test/features/prayer_companion/application test/core/router
Run: flutter analyze lib/features/prayer_companion/application lib/app.dart lib/core/router/launch_destination.dart
Expected: no diagnostics.

~~~bash
git add lib/features/prayer_companion/application lib/app.dart lib/core/router/launch_destination.dart test/features/prayer_companion/application test/core/router
git commit -m "feat(prayer): handle companion notification actions"
~~~

### Task 7: Project Companion status into Home and enrich the current prayer sheet

**Files:**
- Create: lib/features/prayer_companion/presentation/cubits/prayer_companion_cubit.dart
- Create: lib/features/prayer_companion/presentation/cubits/prayer_companion_state.dart
- Create: lib/features/prayer_companion/presentation/widgets/prayer_companion_status.dart
- Modify: lib/features/home/presentation/cubits/home_cubit.dart
- Modify: lib/features/home/presentation/cubits/home_state.dart
- Modify: lib/features/home/presentation/widgets/home_prayer_times_sheet.dart
- Test: test/features/prayer_companion/presentation/cubits/prayer_companion_cubit_test.dart
- Test: test/features/home/presentation/widgets/home_prayer_times_sheet_companion_test.dart

**Consumes:** Tasks 1–6 and the current Home prayer snapshot/sheet.
**Produces:** PrayerCompanionDaySummary on HomeLoaded, a sheet-scoped Cubit, status labels, and action controls.

- [ ] **Step 1: Add failing Cubit and widget tests**

~~~dart
testWidgets('past unconfirmed prayer is not displayed as completed', (tester) async {
  await tester.pumpWidget(sheetHarness(
    summary: PrayerCompanionDaySummary(
      statusByPrayer: {PrayerKey.asr: PrayerCompanionStatus.unconfirmed},
      confirmedCount: 0,
    ),
  ));
  expect(find.text('لم يتم التأكيد بعد'), findsOneWidget);
  expect(find.bySemanticsLabel('العصر: لم يتم التأكيد بعد'), findsOneWidget);
  expect(find.text('✓ العصر'), findsNothing);
});

testWidgets('confirmed prayer has text and icon, not color only', (tester) async {
  await tester.pumpWidget(sheetHarness(
    summary: PrayerCompanionDaySummary(
      statusByPrayer: {PrayerKey.asr: PrayerCompanionStatus.confirmed},
      confirmedCount: 1,
    ),
  ));
  expect(find.text('تم التأكيد'), findsOneWidget);
  expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
});

blocTest<PrayerCompanionCubit, PrayerCompanionState>(
  'does not report success when persistence fails',
  build: () => failingCubit,
  act: (cubit) => cubit.submit(PrayerCompanionCommand.confirm),
  expect: () => [isA<PrayerCompanionSubmitting>(), isA<PrayerCompanionFailure>()],
);
~~~

- [ ] **Step 2: Run UI/Cubit tests before implementation**

Run: flutter test test/features/prayer_companion/presentation/cubits/prayer_companion_cubit_test.dart test/features/home/presentation/widgets/home_prayer_times_sheet_companion_test.dart
Expected: FAIL because the summary, Cubit and status widget are absent.

- [ ] **Step 3: Add the compact projection and presentation layer**

~~~dart
class PrayerCompanionDaySummary {
  const PrayerCompanionDaySummary({
    required this.statusByPrayer,
    required this.confirmedCount,
    this.actionableOccurrence,
  });
  final Map<PrayerKey, PrayerCompanionStatus> statusByPrayer;
  final int confirmedCount;
  final PrayerOccurrence? actionableOccurrence;
  static const totalObligatoryPrayers = 5;
}

class PrayerCompanionCubit extends Cubit<PrayerCompanionState> {
  PrayerCompanionCubit(this._controller, this._occurrence)
      : super(const PrayerCompanionIdle());

  Future<void> submit(PrayerCompanionCommand command) async {
    emit(const PrayerCompanionSubmitting());
    try {
      await _controller.applyInApp(_occurrence, command);
      emit(const PrayerCompanionSuccess());
    } catch (error) {
      emit(PrayerCompanionFailure(error));
    }
  }
}
~~~

Inject the GetPrayerCompanionDaySummary use case into HomeCubit.withExtras, load it once in _loadExtras, and add nullable prayerCompanionSummary to HomeLoaded. Do not add a permanent timer or storage query per row. Existing Home resume and route-return reloads are the refresh boundary; after an in-sheet success, call HomeCubit.load once.

Extend HomePrayerTimesSheet to receive the summary. Keep sunrise time-only. For only the five obligatory rows, render PrayerCompanionStatusWidget with a localized text label, icon, and semantic label. Render action buttons only for actionableOccurrence and disable them while submitting. Place a 3 من 5 / 3 of 5 confirmed label in the sheet heading. Do not put a count in the Home header and never infer a checkmark from time passing.

- [ ] **Step 4: Run Arabic, English, accessibility, and existing sheet tests**

Run: flutter test test/features/prayer_companion/presentation/cubits/prayer_companion_cubit_test.dart test/features/home/presentation/widgets/home_prayer_times_sheet_companion_test.dart test/features/home/presentation/widgets/home_prayer_times_sheet_test.dart
Expected: PASS in Arabic RTL and English LTR harnesses.

- [ ] **Step 5: Format, analyze, and commit Task 7**

Run: dart format lib/features/prayer_companion/presentation lib/features/home/presentation/cubits/home_cubit.dart lib/features/home/presentation/cubits/home_state.dart lib/features/home/presentation/widgets/home_prayer_times_sheet.dart test/features/prayer_companion/presentation test/features/home/presentation/widgets
Run: flutter analyze lib/features/prayer_companion/presentation lib/features/home/presentation
Expected: no diagnostics.

~~~bash
git add lib/features/prayer_companion/presentation lib/features/home/presentation/cubits/home_cubit.dart lib/features/home/presentation/cubits/home_state.dart lib/features/home/presentation/widgets/home_prayer_times_sheet.dart test/features/prayer_companion/presentation test/features/home/presentation/widgets
git commit -m "feat(prayer): show companion status in prayer sheet"
~~~

### Task 8: Add settings, localized copy, and local-history deletion

**Files:**
- Create: lib/features/prayer_companion/presentation/widgets/prayer_companion_settings_section.dart
- Modify: lib/features/settings/presentation/pages/settings_page.dart
- Modify: lib/core/l10n/app_ar.arb
- Modify: lib/core/l10n/app_en.arb
- Modify: generated lib/core/l10n/app_localizations*.dart
- Test: test/features/prayer_companion/presentation/widgets/prayer_companion_settings_section_test.dart
- Test: test/core/l10n/localization_regression_test.dart

**Consumes:** Tasks 2, 5 and 7 and existing SettingsSection design.
**Produces:** Companion opt-in/configuration/deletion UI and all localized strings.

- [ ] **Step 1: Add failing settings/localization tests**

~~~dart
testWidgets('Companion is off by default and enabling it reschedules', (tester) async {
  await tester.pumpWidget(settingsHarness());
  expect(find.text('مرافق الصلاة'), findsOneWidget);
  await tester.tap(find.byType(Switch).first);
  await tester.pumpAndSettle();
  expect(prefs.getBool(PrayerCompanionPreferences.enabledKey), isTrue);
  verify(() => scheduler.refreshNotifications(any(), force: true)).called(1);
});

testWidgets('clear confirmations requires consent', (tester) async {
  await tester.pumpWidget(settingsHarness(hasRecords: true));
  await tester.tap(find.text('مسح تأكيدات الصلاة'));
  await tester.pumpAndSettle();
  expect(find.text('هل تريد مسح التأكيدات المحفوظة على هذا الجهاز؟'), findsOneWidget);
});
~~~

- [ ] **Step 2: Run focused settings test before implementation**

Run: flutter test test/features/prayer_companion/presentation/widgets/prayer_companion_settings_section_test.dart
Expected: FAIL because the section and localization keys are absent.

- [ ] **Step 3: Implement the small settings surface and ARB copy**

Add exactly these controls: Companion enablement; preparation interval dropdown with disabled/5/10/15; post-prayer check-in enablement with fixed 20-minute explanation; one-follow-up enablement; and a clear-confirmations tile with a confirmation dialog. Each setting writes its preference before calling NotificationScheduler.refreshNotifications(context.l10n, force: true). Disabling Companion therefore cancels only Companion events. Clear invokes repository.clearOwner(owner.currentOwnerId), never changes prayer-time settings, and uses a recovery-friendly error message if deletion fails.

Add ARB keys for section title, controls, preparation intervals, fixed check-in description, status text, action labels, daily count, local-storage explanation, clear confirmation, failure, and notification title/body. Use these production terms:

~~~text
Arabic: مرافق الصلاة; هل أديت صلاة {prayer}؟; تم التأكيد; لم يتم التأكيد بعد.
English: Prayer Companion; Did you pray {prayer}?; Confirmed; Not confirmed yet.
~~~

Do not add a reward, streak, guilt, or theological claim. Generate localized Dart:

~~~bash
flutter gen-l10n
~~~

Place PrayerCompanionSettingsSection directly below PrayerTimesSettingsSection in SettingsPage. Do not add its settings into NotificationSettingsCubit; that Cubit remains responsible for existing system reminder settings.

- [ ] **Step 4: Run settings/localization regressions**

Run: flutter test test/features/prayer_companion/presentation/widgets/prayer_companion_settings_section_test.dart test/core/l10n/localization_regression_test.dart test/features/settings/presentation/widgets/settings_notification_tiles_test.dart
Expected: PASS.

- [ ] **Step 5: Format, analyze, and commit Task 8**

Run: dart format lib/features/prayer_companion/presentation/widgets/prayer_companion_settings_section.dart lib/features/settings/presentation/pages/settings_page.dart
Run: flutter analyze lib/features/prayer_companion/presentation/widgets/prayer_companion_settings_section.dart lib/features/settings/presentation/pages/settings_page.dart
Expected: no diagnostics.

~~~bash
git add lib/features/prayer_companion/presentation/widgets/prayer_companion_settings_section.dart lib/features/settings/presentation/pages/settings_page.dart lib/core/l10n test/features/prayer_companion/presentation/widgets test/core/l10n
git commit -m "feat(prayer): add companion settings and copy"
~~~

### Task 9: Validate V1 behavioral and platform contracts

**Files:**
- Create: test/features/prayer_companion/prayer_companion_flow_test.dart
- Modify: test/core/services/notification_scheduler_phase2_test.dart
- Modify: test/features/settings/presentation/cubits/notification_settings_cubit_test.dart
- Create: docs/release/v1/prayer-companion-runtime-checklist.md
- Modify: docs/release/v1/physical-android-checklist.md

**Consumes:** Tasks 1–8.
**Produces:** full automated contract coverage and an honest Android/iOS runtime evidence checklist.

- [ ] **Step 1: Add failing end-to-end contract tests**

~~~dart
test('confirmation cancels future Companion events for its occurrence', () async {
  await flow.confirm(asr);
  expect(await repository.read(asr), hasStatus(PrayerCompanionStatus.confirmed));
  verify(() => notificationService.cancelPrayerCompanionReminders()).called(greaterThanOrEqualTo(1));
});

test('pray now is not completion and creates one follow-up', () async {
  await flow.prayNow(asr);
  final record = await repository.read(asr);
  expect(record!.status, PrayerCompanionStatus.prayNow);
  expect(record.followUpCount, 1);
});

test('no response remains unconfirmed', () async {
  expect((await flow.summaryFor(at1505)).statusByPrayer[PrayerKey.asr],
      PrayerCompanionStatus.unconfirmed);
});
~~~

- [ ] **Step 2: Run contract test before final harness work**

Run: flutter test test/features/prayer_companion/prayer_companion_flow_test.dart
Expected: FAIL until the harness composes repository, planner, controller, and scheduler.

- [ ] **Step 3: Complete the contract harness and runtime checklist**

Use a fixed clock, temporary Isar, FixedRecordOwnerProvider, fake PrayerTimesService, fake notification service, and SharedPreferences.setMockInitialValues. Add automated cases for:

~~~text
- confirmation idempotency and follow-up suppression
- prayNow vs confirmed distinction
- remindLater one-follow-up limit
- ignored notification remains unconfirmed
- cold-start response uses the same controller
- Companion disabled leaves legacy prayer alerts intact
- denied notifications leave in-app controls usable
- city/method/timezone refresh preserves explicit records
- Arabic and English semantic state labels
- account reset clears local history
~~~

The runtime checklist must record actual device, OS, build and result for Android/iOS alert appearance; foreground/background/terminated actions; duplicate tap; remind-later timing; reboot; timezone and calculation-method changes; denied permission; and Companion disablement. Label iOS background refresh best-effort; do not mark any scenario passed without running it.

- [ ] **Step 4: Run the full automated suite and static analysis**

Run: flutter test
Expected: PASS.

Run: flutter analyze
Expected: no diagnostics.

- [ ] **Step 5: Record runtime evidence and commit Task 9**

Run the checklist on Android and iOS where available. Enter only observed outcomes in docs/release/v1/prayer-companion-runtime-checklist.md.

~~~bash
git add test/features/prayer_companion test/core/services/notification_scheduler_phase2_test.dart test/features/settings/presentation/cubits/notification_settings_cubit_test.dart docs/release/v1
git commit -m "test(prayer): verify companion v1 behavior"
~~~

## Coverage audit

| Design requirement | Implementing task(s) |
|---|---|
| Explicit self-confirmation; no inference; idempotency | 1, 2, 3, 9 |
| Local first, owner-scoped, reset/deletion | 2, 8, 9 |
| Existing calculation and alert behavior retained | 3, 4, 5, 9 |
| Preparation, check-in, one follow-up, cancellation | 1, 3, 4, 5, 6, 9 |
| Killed-app action supported only after launch | 4, 6, 9 |
| Timezone, reboot, city/method and day boundary | 1, 3, 5, 9 |
| Home sheet, daily count, no automatic checkmark | 7 |
| Settings, Arabic/English and privacy disclosure | 8 |
| iOS budget, ID safety and quiet-hours scheduling | 4, 5, 9 |
| Accessibility, RTL/LTR and non-color state | 7, 8, 9 |
| No Supabase, XP, streak or gamification | Global constraints, 2, 3, 9 |
