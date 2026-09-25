# Talia Prayer V2 — Stage 8 Execution Report

**Date:** 2026-09-20
**Branch:** `main`
**Stage:** Stage 8 — Time / Timezone Change Recovery (§30 + Gate H)
**Status:** **PASS — native recovery receiver wired; zero Flutter involvement; JVM-tested recovery plan**

---

## 1. New Components

| File | Responsibility |
|---|---|
| `prayer/PrayerRecoveryReceiver.kt` | Manifest receiver for `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `QUICKBOOT_POWERON`, `TIME_SET`, `TIMEZONE_CHANGED`. Calls `PrayerAlarmScheduler.rearmFromStore()` only. |
| `PrayerAlarmScheduler.rearmPlan()` (pure) | Decodes persisted events, drops stale/past occurrences, orders by trigger time. Pure JVM — unit tested. |
| `PrayerAlarmScheduler.rearmFromStore()` | Re-arms stored future events (exact/inexact per permission), prunes the store, returns count. |
| `PrayerAlarmScheduler.armAlarm()` | Extracted single-arm helper shared by schedule + recovery (removes duplication). |

## 2. Design Decisions (§30)

- **Native-only recovery:** the receiver never starts the Flutter engine and never computes prayer times. It re-arms the persisted absolute-time (`scheduledAtUtcMillis`) events created by the Dart side — exactly the "event data المخزنة" path the plan endorses.
- **Why re-arm (not rebuild):** the 7-day full rebuild belongs to the Dart refresh (city/method ownership). Reboot/time-change recovery only needs to restore what was already planned; the next app open / Workmanager tick performs the full rebuild.
- **Stale pruning:** events at/past `now` are dropped from the store on recovery (they already fired or were invalidated); the next Dart refresh rebuilds the window.
- **No duplicates:** re-arm reuses the same deterministic PendingIntent (same request code, `FLAG_UPDATE_CURRENT`) — idempotent.
- **Boot coverage (Gate H):** after reboot AlarmManager alarms are cleared; the receiver restores them at boot without waiting for the app to open.
- **Timezone note:** V2 alarms are absolute UTC instants anchored to the *city* zone — a device timezone change cannot shift them; re-arm still runs defensively and prunes stale entries, satisfying "تغيير Time Zone لا ينتظر 6 ساعات".

## 3. Manifest

```xml
<receiver android:name=".prayer.PrayerRecoveryReceiver" android:exported="false">
  <intent-filter>
    BOOT_COMPLETED / MY_PACKAGE_REPLACED / TIME_SET / TIMEZONE_CHANGED / QUICKBOOT_POWERON
  </intent-filter>
</receiver>
```

`RECEIVE_BOOT_COMPLETED` permission already present. Mirrors the proven `exported="false"` pattern used by flutter_local_notifications' own boot receiver in this app.

## 4. Verification

- `gradlew :app:testDebugUnitTest` → **BUILD SUCCESSFUL**
  - `PrayerRecoveryTest` 4/4 (future-only + sorted, stale-at-now dropped, malformed entries skipped, empty store), `AdhanPlaybackPolicyTest` 6/6, `PrayerAlarmIdentityTest` 6/6, `PrayerEventCodecTest` 9/9 — 25/25 total, zero failures.
  - One intentional deprecation warning remains (`Notification.Builder.addAction`) — standard API, no functional issue.
- Merged manifest verified: receiver + all five actions present.
- No Dart changes in this stage.

## 5. Next

- Stage 9 — UX cleanup (two master switches, live countdown, past-prayer neutral state, city/method display).
- Stage 10 — runtime torture tests (doze / reboot / killed / locked / audio interactions) before release.
- Stage 11 (later release) — remove provably-unused legacy adhan delivery code.
