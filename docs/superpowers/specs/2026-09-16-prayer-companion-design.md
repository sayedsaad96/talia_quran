# Prayer Companion V1 — repository-backed design

**Status:** Proposed; awaiting review before implementation planning  
**Date:** 2026-09-16  
**Scope:** Local-first, opt-in prayer support. No application code is changed by this document.

## 1. Decision summary

Build Prayer Companion as a small, isolated feature that extends—rather than replaces—the current prayer calculation, notification scheduling, Home prayer sheet, settings, localization, dependency injection, and account-data lifecycle.

V1 records only a user's explicit, self-reported prayer state. It never treats a passed prayer time, ignored notification, device sensor, location, or background signal as proof that a prayer was or was not performed.

The feature is enabled independently of existing Prayer Times and prayer-time notifications. It is local-only, is excluded from XP/streak/activity events, and has no Supabase schema or synchronization. Its first release supports a preparation reminder (optional), a post-prayer check-in, `I prayed`, `I will pray now`, `Remind me later`, and `Not yet`; it limits each prayer to one optional follow-up.

## 2. Current repository assessment

### A. Prayer calculation and display

[`PrayerTimesService`](../../../lib/core/services/prayer_times_service.dart) calculates Fajr, sunrise, Dhuhr, Asr, Maghrib, and Isha locally with the `adhan` package. The city comes from the bundled `assets/data/prayer_cities.json` data set and the selected city, calculation method, and display enablement live in `SharedPreferences`.

`PrayerTimesService.current()` returns the next prayer plus the six calculated times. It is injected into [`HomeCubit`](../../../lib/features/home/presentation/cubits/home_cubit.dart), which places the snapshot in `HomeLoaded`. [`HomePrayerChip`](../../../lib/features/home/presentation/widgets/home_night_header.dart) opens [`HomePrayerTimesSheet`](../../../lib/features/home/presentation/widgets/home_prayer_times_sheet.dart). The sheet currently renders a time-centric list: the next time is highlighted and earlier entries are only marked visually as past. It contains no persisted completion state.

The existing prayer-settings section, [`PrayerTimesSettingsSection`](../../../lib/features/settings/presentation/widgets/settings_prayer_tiles.dart), changes the display enablement, city, and calculation method. Every change forces notification rescheduling. A city and method must be explicitly persisted before prayer notifications are scheduled; no implicit fallback city is used for alerts.

### B. Notification architecture and lifecycle

[`NotificationScheduler`](../../../lib/core/services/notification_scheduler.dart) is the sole high-level scheduling orchestrator. On app initialization, resume, and locale changes it configures device timezone and refreshes enabled reminder categories. It schedules the existing prayer-time notifications for seven days, using up to 35 events (five prayers × seven days).

[`TaliaNotificationService`](../../../lib/core/services/notification_service.dart) wraps `flutter_local_notifications`, maintains Android/iOS channels and categories, handles timezone configuration, reserves iOS notification slots, and defines the existing prayer notification IDs `2000`–`2039`. Prayer alerts use the generic `prayer_category` and contain only `action_quran` and `action_azkar`; their payload is `/`.

Notification taps are reduced to navigation in `TaliaNotificationService._onNotificationTapped()`. [`LaunchDestination`](../../../lib/core/router/launch_destination.dart) maps action IDs to routes; [`TaliaApp`](../../../lib/app.dart) applies a cold-start request after initialization. The response pipeline currently drops prayer identity and action-specific data, so it cannot persist a confirmation. All current Android actions request UI and there is no registered background-notification response handler. Therefore, V1 must open the app before it writes a Companion action; it must not claim background persistence for killed-app actions.

Timezone is refreshed before every scheduler refresh and the last valid timezone is retained as a fallback. Android declares exact-alarm, notification, boot-completed, and the local-notifications boot receiver permissions in `AndroidManifest.xml`. Scheduled alarms may be restored by the plugin after reboot, but a recalculated rolling window still depends on a foreground or background refresh.

[`runNotificationRefreshTask`](../../../lib/core/sync/notification_refresh_worker.dart) currently instantiates `NotificationScheduler(TaliaNotificationService())` without a `PrayerTimesService`, and does not configure GetIt. Thus it cannot currently rebuild prayer notifications in the headless path. This must be corrected before Companion relies on periodic rolling rescheduling.

### C. Storage, identity, and privacy

The app already opens Isar in [`configureDependencies`](../../../lib/core/di/injection.dart) and uses it for durable structured records such as progress, streaks, XP, review evidence, and Home activity. `SharedPreferences` is used for settings and small preference-backed stores. The existing Isar schema list has no prayer-completion collection.

[`AccountDataReset`](../../../lib/core/identity/account_data_reset.dart) maintains an explicit inventory of account-owned preferences and clears every Isar collection on account reset. Prayer history must be added to that reset path. Its records should include the local/active owner identifier even though V1 never syncs them; this prevents a later account on the same device from reading another account's private prayer history and preserves the established ownership convention.

Supabase is present for selected memorization, profile, and progress flows, but there is no prayer-history table, sync contract, or product need to add one. V1 data stays on-device.

### D. Settings, localization, accessibility, and companion presence

[`NotificationSettingsCubit`](../../../lib/features/settings/presentation/cubits/notification_settings_cubit.dart) and [`NotificationSettingsSection`](../../../lib/features/settings/presentation/widgets/settings_notification_tiles.dart) already manage the master prayer-notification preference, each of five prayer filters, system-permission state, exact-alarm requests, and forced reschedules.

Arabic and English are maintained in `lib/core/l10n/app_ar.arb` and `lib/core/l10n/app_en.arb`, with generated localizations used throughout. Current prayer copy is Arabic MSA, so new production copy will follow that voice rather than hard-code Egyptian Arabic. The Home sheet already uses semantics for the entry chip, supports RTL/LTR via Flutter localization, honors dark theme, text scaling, and reduced animation. Companion state must add visible text and semantic labels; color alone is insufficient.

Talia imagery exists in assets, but repository inspection found no reusable runtime character-event or companion-message system that owns prayer interactions. V1 should use concise localized UI and notification copy, not create a speculative Talia-character subsystem.

### E. Existing coverage and relevant constraints

Useful tests already cover local calculation ([`prayer_times_service_test.dart`](../../../test/core/services/prayer_times_service_test.dart)), rolling prayer scheduling and per-prayer filters ([`notification_scheduler_phase2_test.dart`](../../../test/core/services/notification_scheduler_phase2_test.dart)), notification budgets, quiet hours, notification settings, and the Home prayer sheet in Arabic and English.

The current 35-event, seven-day prayer schedule cannot be expanded with preparation and check-in events without exhausting iOS's pending-notification budget. Companion events require their own ID namespace and a shorter rolling horizon. The existing bulk cancellation of IDs `2000`–`2039` must continue to operate only on legacy prayer-time events.

## 3. Approaches considered

### Option A — Store a daily JSON blob in SharedPreferences

This would append Companion state beside existing prayer settings and leave the scheduler mostly unchanged.

**Advantages:** smallest initial diff and no Isar generator changes.  
**Disadvantages:** weak uniqueness guarantees, brittle concurrent updates from tap/reopen flows, cumbersome correction and aggregation queries, unclear retention, and hard-to-test history.  
**Decision:** reject. A structured per-prayer record is a better fit for sensitive, user-correctable state.

### Option B — Isolated local Prayer Companion feature (recommended)

Add a small feature with explicit domain state, an Isar-backed repository, preferences, a coordinator that owns follow-up decisions, and a typed bridge between notification responses and the coordinator. Extend the current scheduling service rather than create a second notification stack.

**Advantages:** preserves stable prayer calculation and alerts; explicit ownership; idempotent writes; clear cancellation and retention; easy unit tests; room for a later private weekly reflection without committing V1 to it.  
**Costs:** new Isar schema, targeted scheduler/service refactor, and response routing work.  
**Decision:** recommended.

### Option C — Reuse XP, streak, Home activity, or generic journey events

This would emit prayer actions through existing gamification/progress infrastructure.

**Advantages:** fewer feature-specific abstractions.  
**Disadvantages:** couples worship confirmation to unrelated achievement and streak semantics, risks accidental rewards or public/cloud behavior, and does not supply a reusable notification-action model.  
**Decision:** reject. Prayer Companion must remain outside XP, streak, activity feed, and unified journey prioritization in V1.

## 4. Recommended V1 architecture

### 4.1 Feature boundaries

Create `lib/features/prayer_companion/` with conventional `domain`, `data`, and `presentation` layers. The feature owns self-confirmation records, preferences, state-transition policy, daily summary queries, and contextual presentation data. It does **not** own prayer calculation, raw local-notification plugin calls, app routing, shared timezone configuration, or generic settings rendering.

Existing ownership remains:

- `PrayerTimesService`: calculation, selected city, calculation method, and prayer-time availability.
- `NotificationScheduler`: one orchestration point for all notification categories and refresh triggers.
- `TaliaNotificationService`: channels/categories, platform scheduling/cancellation, notification IDs, timezone, permissions, and raw response capture.
- `HomeCubit`: assembling Home data; it receives a compact Companion day summary rather than business rules.
- `NotificationSettingsCubit`: existing prayer-time notifications. It should not absorb Companion preferences into an already broad state object.
- `AccountDataReset`: deletion of local Companion data.

### 4.2 Domain model

Use these types; names may be adjusted only to match surrounding conventions.

```
PrayerKey = fajr | dhuhr | asr | maghrib | isha

PrayerConfirmationStatus =
  unconfirmed          // no explicit user confirmation
  prayNow              // user chose “I will pray now”; not completion
  remindLater          // a single follow-up was requested
  confirmed            // user explicitly said “I prayed”
  notYet               // user explicitly said “Not yet”

PrayerCompanionRecord
  ownerId
  occurrenceKey        // owner + local civil date + PrayerKey; unique
  localDate            // YYYY-MM-DD in current device timezone
  prayerKey
  scheduledAt          // calculation result at time of interaction/schedule
  status
  statusUpdatedAt
  followUpAt?          // null unless a valid one-off follow-up is active
  followUpCount        // V1: 0 or 1
  createdAt
  updatedAt
```

`unconfirmed` is the default absence/record state; it never means not prayed. A record is created only when a user responds, a follow-up must be tracked, or an explicit correction is made. This avoids fabricating historical data when Companion is enabled mid-day.

`confirmed` is the only completed state. `prayNow`, `remindLater`, and `notYet` are intent/support states, never evidence of completion. A manual correction can move `confirmed` back to `unconfirmed` or `notYet`; it cancels associated follow-up events. Repeated commands are idempotent: the repository upserts by `occurrenceKey`, and transition execution returns the existing final record when nothing needs to change.

Companion preferences live separately in `SharedPreferences`:

```
prayer_companion_enabled                // default false
prayer_companion_preparation_minutes    // 0, 5, 10, or 15; default 0
prayer_companion_follow_up_enabled      // default true
```

The initial Settings UX should expose only: Enable Prayer Companion, preparation reminder timing, check-in toggle, and follow-up toggle. V1 uses a fixed 20-minute check-in delay; it does not add another timing control. Existing prayer-time master and individual-prayer switches continue to mean prayer-time alerts. Companion follows the existing individual-prayer filters, so users retain one clear prayer-by-prayer control surface, but its own master switch remains independent of the prayer-time master switch.

### 4.3 State transitions

```
upcoming
  └─ prayer time begins → awaitingCheckIn
        ├─ I prayed      → confirmed (cancel check-in/follow-up)
        ├─ I will pray now → prayNow (schedule one check-in, if in window)
        ├─ Remind me later → remindLater (schedule one check-in, if in window)
        ├─ Not yet       → notYet (no automatic judgment; at most one follow-up if user asks)
        └─ no response   → unconfirmed

confirmed ── manual correction → unconfirmed or notYet
```

`awaitingCheckIn` is derived from time, configuration, and an absence of confirmation; it is not stored as a claim about user behavior. `unconfirmed` persists across the current day's display but produces no shame copy, no streak penalty, and no escalation. A prayer occurrence's active window ends at the next calculated obligatory prayer (or at a capped end-of-day/Fajr boundary for Isha). The coordinator suppresses any follow-up after that boundary or after Companion/per-prayer notifications are disabled.

### 4.4 Notification schedule and platform behavior

Keep the existing prayer-time alert as the primary event. Companion adds, at most:

1. an optional preparation reminder before the scheduled prayer;
2. one post-prayer check-in after the configured delay; and
3. one on-demand follow-up after `I will pray now` or `Remind me later`.

The coordinator never pre-schedules a second follow-up and never generates an escalating sequence. It cancels scheduled check-in/follow-up events after confirmation, correction, switch-off, a calculation/location change, or expiry of the prayer window.

Use a two-day rolling Companion horizon. It produces at most 20 planned Companion events—one preparation reminder and one check-in for each of five prayers across two days—before on-demand follow-ups. Together with the existing 35 legacy prayer-time alerts, this leaves practical iOS capacity for other reminders after the current lower-priority trimming policy runs. The scheduler must reserve Companion IDs in explicit non-overlapping ranges (for example `2100`–`2199` for planned check-ins/preparation and `2200`–`2249` for follow-ups) and update `notificationIdsToCancelForBudget()` so all prayer and Companion IDs are protected equally. The final constants and capacity calculation belong in `TaliaNotificationService`, not UI or the new repository.

The notification payload must be a versioned, compact target containing `PrayerKey`, local date, occurrence timestamp, and event kind; it must not contain user history or Arabic/English copy. A typed `PrayerCompanionNotificationIntent` parser validates it. Invalid/old payloads are logged and treated as no-op navigation.

Refactor the app's response bridge so it delivers both payload and action ID, rather than a route string alone. On an active app response, the bridge passes a validated Companion intent to the feature coordinator, persists the idempotent transition, cancels superseded events, then navigates to Home/the prayer sheet. On a cold start, initialization parses and applies the saved notification response after dependencies are ready, then resolves the route. This satisfies the realistic killed-app behavior: a user action that launches Talia is persisted during app startup. It does not rely on an unsupported hidden background write.

The check-in notification itself should use action labels for `I prayed`, `I will pray now`, and `Remind me later`; `Not yet` stays available in-app to avoid overcrowding platform action areas. iOS/Android action limits and category setup must be verified on supported OS versions before final labels are committed. Existing prayer-time notification actions should stay intact unless a product decision explicitly replaces them; V1's safer path is a separate Companion check-in category rather than changing the Adhan/prayer-time category.

Preparation and check-in reminders obey Companion enablement, existing per-prayer filters, and quiet-hours policy. Prayer-time alerts retain their current time-critical behavior. A Companion event that falls inside quiet hours is suppressed rather than shifted into a misleading next-day slot. A time-zone, city, or calculation-method refresh cancels and reconstructs only future Companion events; it preserves completed and user-authored local records.

### 4.5 Background, reboot, date, and clock handling

Fix the headless notification-refresh path before adding Companion scheduling. It must initialize the minimal local dependencies required for `PrayerTimesService`, the Companion repository, and scheduling, without requesting permissions or starting Supabase/UI services. Alternatively, extract a dependency-light prayer scheduling factory that accepts `SharedPreferences`, Isar, and services explicitly. The latter is preferred because it avoids GetIt fallback behavior in a background isolate.

The existing Android plugin boot receiver retains scheduled alarms after reboot. The periodic WorkManager task and foreground resume should still reconcile the two-day rolling window. iOS background delivery remains best-effort; the V1 UI reconciles stale events when the app opens.

Every occurrence key uses local civil date plus prayer key, and each record stores its original `scheduledAt`. This avoids accidental reassignment when timezones, DST, locations, or calculation methods change. Today is derived from the current local timezone; Isha is assigned to the civil day of its calculated start, while the next day's Fajr is a new occurrence. A manually changed device clock may cause rescheduling/reconciliation, but never auto-confirms or backfills a status.

### 4.6 Home and Settings integration

Extend `HomeCubit` with a compact `PrayerCompanionDaySummary` and the current actionable occurrence. It should query once during `load()` and refresh on app resume/route return, not maintain a permanent seconds timer or query storage per row.

Use the existing `HomePrayerTimesSheet` as the main Companion surface. Preserve the prayer times and sunrise row; attach Companion status only to the five obligatory prayers. It should clearly show a text label and semantic value for each of:

- upcoming;
- confirmed;
- awaiting a user response;
- unconfirmed past time; and
- user-selected `I will pray now`, `Remind me later`, or `Not yet`.

The current actionable prayer can show a compact, accessible button group in the sheet, not a new Home dashboard. The Home header chip stays focused on the next prayer; V1 does not add a confirmed-today count there. No automatic checkmark is shown merely because time has passed.

Add a small dedicated `Prayer Companion` settings subsection near the existing prayer and notification settings. It should explain local-only storage and provide a clear `Clear prayer confirmations` action with confirmation. Do not expose coaching profile, reasons, weekly reflections, or a large matrix of toggles in V1.

### 4.7 Tone and localization

All strings are added to both ARB files and generated through the project's normal localization workflow. Use respectful, concise MSA consistent with current prayer strings. Examples are design guidance only, not final copy: a preparation nudge, a neutral question asking whether the prayer was performed, a warm acceptance after explicit confirmation, and a recovery-oriented next-prayer message. Do not insert verses, hadith, reward claims, legal rulings, or punishment language.

## 5. Failure and reconciliation policy

| Situation | Required behavior |
|---|---|
| Record write fails | Do not show confirmed UI or cancel the existing event; show a recoverable in-app error and log the failure. |
| Scheduling/cancellation fails | Keep the local record authoritative; surface no false promise, log the failure, and retry through the next refresh. |
| Repeated tap/action | Upsert by occurrence key and make the final state/cancellation idempotent. |
| No notification permission | In-app sheet remains fully usable; settings explain that reminders are unavailable. |
| Companion disabled mid-day | Cancel its pending events; retain past explicit records until user clears them. |
| Prayer Times disabled | Cancel Companion events; retain local confirmations but hide active prompts until valid prayer times are available. |
| App killed on action | Launch app, resolve typed intent after initialization, write once, then show current state. |
| City/method/timezone changes | Cancel future Companion events and recompute; preserve historical user statements with original timestamp. |
| Next prayer arrives | Suppress expired pending follow-up; leave prior occurrence neutral/unconfirmed. |
| Account reset/delete | Clear Companion Isar records and Companion preference keys through the existing reset inventory. |

## 6. Privacy, retention, and performance

V1 stores only the owning profile ID, prayer occurrence metadata, user-selected state, and timestamps. It stores no audio, camera, sensor, continuous location, reason-for-difficulty, religious judgement, or cloud copy. The user can clear records from Companion settings, and account reset clears them. The initial retention policy is local history retained until user deletion or account reset; no automated pruning is needed until Phase 2 actually introduces reports. If storage growth becomes meaningful, add an explicit, documented retention period with migration and user disclosure—not an implicit deletion.

The feature is offline-first. Prayer calculation, local record changes, UI summaries, and scheduled local notifications require no network. It adds no polling: scheduling happens on existing refresh triggers and user actions; Home loads one daily summary; follow-up cancellation is event-driven.

## 7. Migration and rollback

Companion is off by default. Existing city, calculation method, prayer display, prayer-time notification switch, individual prayer filters, channels, and scheduled alerts remain unchanged. First enablement affects only future occurrences and never creates records for earlier prayers that day.

Use a schema addition with no data migration because there is no legacy Companion state. Add explicit notification-ID ranges and cancellation functions without reusing IDs `2000`–`2039`. If a Companion-specific schedule fails, normal prayer-time alerts continue to work.

V1 uses the Companion setting as its operational rollback. Disabling it cancels Companion IDs but must never call `cancelPrayerTimesReminders()` or mutate prayer-time settings. Isar records remain inert and can be removed through a later migration only after a retention/deletion decision.

## 8. Test strategy and acceptance evidence

### Domain and repository tests

- occurrence-key uniqueness, owner scoping, and date-boundary behavior;
- explicit confirmation is idempotent and does not duplicate a row;
- `prayNow`, `remindLater`, `notYet`, correction, expiry, and confirmation transitions;
- one-follow-up limit and next-prayer boundary suppression;
- aggregation counts only `confirmed` records;
- local deletion and account-reset cleanup.

### Scheduler and notification tests

- two-day event count and no ID collision with legacy prayer alerts;
- existing prayer-time alerts remain unchanged;
- preparation disabled, per-prayer disabled, Companion disabled, quiet-hours suppression, and permission-denied UI behavior;
- cancellation after confirmation/correction/switch-off;
- invalid and duplicate payload/action handling;
- background refresh constructs required local dependencies and preserves timezone behavior;
- iOS budget logic protects Companion events while trimming lower-priority rolling reminders.

### Cubit and widget tests

- `HomeCubit` produces an actionable Companion summary without full-screen changes;
- prayer sheet renders confirmed, unconfirmed past, intention, and upcoming states;
- actions change only after persistence succeeds;
- Arabic RTL and English LTR copy, semantics, text scaling, dark mode, and reduced animation.

### Runtime verification

On Android and iOS, test real/emulated notification scheduling, each action with the app foregrounded, backgrounded, and terminated; repeated action taps; reboot/clock/timezone behavior where the OS allows; location/calculation changes; permission denial; and cancellation/no-extra-follow-up after confirmation. Report platform limitations honestly rather than claiming a background action worked without evidence.

## 9. Explicit non-goals for V1

- Camera, microphone, movement, GPS, mosque-attendance, or other prayer verification.
- Supabase prayer history, social features, rankings, competition, XP, achievements, or streak penalties.
- Weekly reflection, difficulty reasons, adaptive coaching, support-profile onboarding, or a Talia runtime-character engine.
- Replacing calculation logic, redesigning Home, or replacing the notification service.

## 10. Confirmed integration inventory

### Likely existing files to modify

- `lib/core/services/notification_service.dart`
- `lib/core/services/notification_scheduler.dart`
- `lib/core/sync/notification_refresh_worker.dart`
- `lib/core/di/injection.dart`
- `lib/core/router/launch_destination.dart`
- `lib/app.dart`
- `lib/core/identity/account_data_reset.dart`
- `lib/features/home/presentation/cubits/home_cubit.dart`
- `lib/features/home/presentation/cubits/home_state.dart`
- `lib/features/home/presentation/widgets/home_prayer_times_sheet.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/core/l10n/app_ar.arb`
- `lib/core/l10n/app_en.arb`
- generated localization files, through the project's normal generator
- focused existing notification, Home-sheet, settings, router, reset, and prayer-time tests

### Likely new files

- Prayer Companion domain entities, repository interface, state-transition/coordinator service, and use cases.
- Isar record model and generated schema output.
- Isar datasource and repository implementation.
- Companion preferences store.
- Presentation Cubit/state and focused sheet/settings widgets, only where the existing widgets would otherwise become too large.
- Notification-intent parser/typed response bridge and new focused tests.

### Components intentionally not changed in V1

- The `adhan` calculation implementation in `PrayerTimesService`.
- The bundled city data set.
- Existing prayer-time notification semantics and IDs `2000`–`2039`.
- XP, streak, activity feed, unified journey, and Supabase schemas.
- Existing Talia assets/character plans.

## 11. Product choices fixed for V1

- The post-prayer check-in delay is 20 minutes; users can disable check-ins but cannot tune the delay in V1.
- Companion follows the existing individual-prayer notification filters, but its master switch remains independent from the existing prayer-time alert master switch.
- The Home header remains a next-prayer entry point; the daily confirmation summary lives in the prayer-times sheet.
- Arabic and English copy is concise MSA/neutral English and must pass the existing localization and religious-content review process before release.
