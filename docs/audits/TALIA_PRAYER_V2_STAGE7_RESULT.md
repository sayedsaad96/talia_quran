# Talia Prayer V2 — Stage 7 Execution Report

**Date:** 2026-09-20
**Branch:** `main`
**Stage:** Stage 7 — Migration V1 → V2 (Mutually Exclusive Scheduling)
**Status:** **PASS — V1/V2 selection live on Android; migration gated on verified success; rollback path proven**

---

## 1. New Dart Components (`lib/core/prayer_delivery/`)

| File | Responsibility |
|---|---|
| `prayer_event_builder.dart` | Converts planned times from `PrayerTimesService` (sole source of truth) into `PrayerScheduledEvent`s: 7-day rolling window, per-prayer filters, past occurrences skipped, city IANA timezone resolved exactly like the service does. Computes no times itself. |
| `prayer_delivery_coordinator.dart` | V1/V2 ownership + §22 migration + §23 refresh + §40 rollback (below). |

## 2. Coordinator Behavior (§22 / §23 / §40)

- **version 1 → migration:** cancel legacy FLN (2000–2039) → cancel native defensively → schedule native → verify result → persist `prayer_delivery_version = 2` **only on success**. On failure: legacy schedule is **rebuilt in the same refresh** and version stays 1.
- **version 2 → refresh:** native cancel-first rebuild via `AndroidPrayerDeliveryScheduler`. On native failure: §40 rollback — cancel native → version 1 → rebuild legacy.
- **empty events (all prayers filtered) while V2 owner:** cancel native alarms (no stale alarms), handled.
- **empty events on V1:** not handled → legacy path cancels legacy ids (unchanged behavior).
- **non-Android:** returns not-handled immediately; iOS/other keep the existing behavior untouched.

## 3. `NotificationScheduler` Change (prayer block only)

- New optional ctor param `prayerDeliveryCoordinator`; on Android it defaults to a `PrayerDeliveryCoordinator(AndroidPrayerDeliveryScheduler())`, on other platforms `null` (legacy only). Injectable for tests.
- The legacy 7-day FLN loop moved **verbatim** into `_scheduleLegacyPrayerReminders` (kept for fallback + §40 rollback; removal deferred to Stage 11).
- Flow: build events → `refreshNativeDelivery(...)`. If the coordinator reports handled, the legacy block does **not** run (golden rule). Otherwise the legacy block runs exactly as before.
- When prayer notifications are disabled: legacy cancel + native `cancelAll` (no stale native alarms).
- **Everything else untouched**: Companion, Daily Ayah, Azkar, Kids, Streak, Tahajjud, Kahf, Khatmah, quiet hours, Workmanager architecture.

## 4. Failure Policy

The native block is wrapped so any failure (builder, channel, migration) falls back to the legacy path in the same refresh — a denied exact-alarm permission or a native error can never leave the user without prayer reminders.

## 5. Tests

New (all passing):
- `test/core/prayer_delivery/prayer_delivery_coordinator_test.dart` — 8 tests: non-Android, migration success (cancel→schedule→persist V2), migration failure (legacy rebuilt, version stays 1), V2 refresh (no legacy calls), V2 rollback (§40), empty-events on V2/V1, `isNativeOwner`.
- `test/core/prayer_delivery/prayer_event_builder_test.dart` — 3 tests: 7-day build with city IANA zone + uniqueness + no past occurrences, per-prayer filters, request codes inside 2200–2499.
- `test/core/services/notification_scheduler_prayer_delivery_test.dart` — 4 tests:
  - **no FLN scheduling when V2 owner** (golden rule, `verifyNever` on legacy schedule),
  - V2 dormant on non-Android → legacy keeps ownership,
  - migration failure → legacy rebuilt in the same refresh, version stays 1,
  - disabling prayer notifications clears both owners.

Regression: full `test/core/services` suite → 214 passed / 2 failed; the 2 failures are the **pre-existing clock-rot cases** in `notification_service_companion_test.dart` documented in `TALIA_PRAYER_V2_STAGE1_RESULT.md` §6 (hardcoded `2026-09-20 12:20` timestamp now in the past — unrelated to this stage; Companion IDs 2100–2134 and the legacy path are untouched).

`flutter analyze` on all touched files: **No issues found**.

## 6. Activation Semantics

On the next Android build: first refresh with prayer notifications enabled and a configured city/method promotes the device to V2 (persisted). Until that refresh, legacy FLN delivery continues unchanged. Rollback to V1 is automatic on native failure and manually possible by writing `prayer_delivery_version = 1`.

## 7. Next

- Stage 8 — TIME_SET / TIMEZONE_CHANGED recovery (native receiver + reschedule path).
- Stage 9 — UX cleanup (master switches, live countdown, past-prayer state, city/method display).
- Stage 10 — runtime torture tests (doze/reboot/killed/audio interactions) before any release.
