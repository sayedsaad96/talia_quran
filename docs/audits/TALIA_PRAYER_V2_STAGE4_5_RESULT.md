# Talia Prayer V2 — Stage 4 & 5 Execution Report

**Date:** 2026-09-20
**Branch:** `main`
**Stages:** Stage 4 — Native Scheduling (AlarmManager + Receiver) · Stage 5 — Native Notification (no full Adhan yet)
**Status:** **PASS — native delivery pipeline compiled, unit-tested, dormant (Stage 7 migration not yet flipped)**

---

## 1. New Native Components (`android/app/src/main/kotlin/com/example/talia_quran/prayer/`)

| File | Responsibility |
|---|---|
| `PrayerAlarmContract.kt` | MethodChannel + event/result key constants. Mirrors `PrayerDeliveryContract` and `PrayerScheduledEvent.toMap` on the Dart side. |
| `PrayerEventData.kt` | Pure event data + `PrayerAlarmIdentity` (frozen 2200–2499 namespace, identical formula to Dart) + `PrayerEventCodec` (channel-map parsing, extras map, URL-encoded persisted-store encoding). No prayer-time computation. |
| `PrayerAlarmScheduler.kt` | `PrayerEventData → PendingIntent → AlarmManager`. `setExactAndAllowWhileIdle` when exact permitted (API 31+: `canScheduleExactAlarms()`), `setAndAllowWhileIdle` fallback, `setExact` on API < 23. Cancel-first inside `scheduleEvents` (golden rule: no stale + fresh alarm for one occurrence). Tracks scheduled events in a SharedPreferences store (`talia_prayer_v2_alarms`) so `cancelAll` is reliable. |
| `PrayerNotificationFactory.kt` | Posts «حان الآن وقت صلاة …» on the new `talia_prayer_events_v2` channel (IMPORTANCE_HIGH, **no adhan clip**). Body tap → app launch intent. Notification id = deterministic request code. |
| `PrayerAlarmReceiver.kt` | `onReceive` reads the payload only → posts notification (when `notificationEnabled`) → exits. Stage 6 seam documented for `adhanEnabled` playback start. Never starts the Flutter engine. |

## 2. Wiring

- `MainActivity.kt`: registers `PrayerDeliveryChannelHandler` on `configureFlutterEngine` (channel `talia/prayer_delivery`; ops `scheduleEvents` / `cancelAll` / `cancelEvent` / `canScheduleExact`; failures returned as `success:false` maps, never thrown).
- `AndroidManifest.xml`: `PrayerAlarmReceiver` added, `android:exported="false"`.
- Merged manifest verified: receiver present; `SCHEDULE_EXACT_ALARM` retained; zero awqat / `USE_EXACT_ALARM` entries.
- **Dormancy:** Dart still runs the legacy V1 path (`prayer_delivery_version` unset → 1). Native scheduling is reachable but unused until the Stage 7 migration flips the version.

## 3. Verification

- `gradlew :app:testDebugUnitTest` → **BUILD SUCCESSFUL**
  - `PrayerAlarmIdentityTest`: 6/6 (range, determinism, distinctness, no namespace collisions, pinned cross-language value 2200 + (20717 % 60) × 5 for 2026-09-21/fajr).
  - `PrayerEventCodecTest`: 9/9 (channel-map parsing incl. defaults and malformed input, encode/decode round-trip incl. Arabic + `|` payloads, extras-map round-trip, ISO parsing).
  - Note: `Intent` extras are exercised through a pure-JVM `toExtrasMap/fromExtrasMap` layer (android.jar stubs cannot run `putExtra` in unit tests); the `Intent` wrappers are thin delegations covered by Stage 10 integration tests.
- `flutter analyze lib/core/prayer_delivery` → no issues.
- Dart suite (51 tests): prayer_delivery (23) + prayer_sound + prayer_times_service + notification_scheduler_companion → **All tests passed!**
- Dart↔Kotlin identity pinned on both sides to the same request code for a known occurrence.

## 4. Files Touched

New:
- `android/app/src/main/kotlin/com/example/talia_quran/prayer/PrayerAlarmContract.kt`
- `android/app/src/main/kotlin/com/example/talia_quran/prayer/PrayerEventData.kt`
- `android/app/src/main/kotlin/com/example/talia_quran/prayer/PrayerAlarmScheduler.kt`
- `android/app/src/main/kotlin/com/example/talia_quran/prayer/PrayerNotificationFactory.kt`
- `android/app/src/main/kotlin/com/example/talia_quran/prayer/PrayerAlarmReceiver.kt`
- `android/app/src/main/kotlin/com/example/talia_quran/prayer/PrayerDeliveryChannelHandler.kt`
- `android/app/src/test/kotlin/com/example/talia_quran/prayer/PrayerAlarmIdentityTest.kt`
- `android/app/src/test/kotlin/com/example/talia_quran/prayer/PrayerEventCodecTest.kt`

Modified:
- `android/app/src/main/kotlin/com/example/talia_quran/MainActivity.kt` (channel registration)
- `android/app/src/main/AndroidManifest.xml` (receiver entry)
- `android/app/build.gradle.kts` (`testImplementation junit:4.13.2`)
- `test/core/prayer_delivery/prayer_scheduled_event_test.dart` (pinned cross-language identity test)

**Application behavior change: ZERO** (legacy delivery path untouched and still the owner).

## 5. Next

- Stage 6 — `AdhanPlaybackService` (foreground media playback, audio focus, stop action) + start it from `PrayerAlarmReceiver` when `adhanEnabled`.
- Stage 7 — V1→V2 migration + `NotificationScheduler` V1/V2 selection.
