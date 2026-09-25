# Talia Prayer V2 — Stage 6 Execution Report

**Date:** 2026-09-20
**Branch:** `main`
**Stage:** Stage 6 — Playback Service (Full Adhan + Stop + Audio Focus)
**Status:** **PASS — owned adhan playback implemented; still dormant until Stage 7 migration**

---

## 1. New Components

| File | Responsibility |
|---|---|
| `prayer/AdhanClipResolver.kt` | Sound-profile → bundled raw-resource mapping. V2-first ships `default` → `adhan`; the fajr seam is preserved (only this file changes when a licensed `talia_adhan_fajr` asset lands). |
| `prayer/AdhanPlaybackService.kt` | Foreground service (`foregroundServiceType="mediaPlayback"`). Responsibilities ONLY: read profile → request audio focus → foreground media notification → play `res/raw/adhan` via MediaPlayer → stop action → release player → abandon focus → stop foreground. |
| `prayer/AdhanPlaybackPolicyTest.kt` | JVM unit tests for the resolver + stop-action contract + notification-id namespace safety. |

## 2. Behavior Details

- **Audio focus (§17):** `USAGE_MEDIA` + `CONTENT_TYPE_SPEECH`, `AUDIOFOCUS_GAIN`. `AudioFocusRequest` on API 26+, legacy API below. Focus handling: `LOSS` → stop; `LOSS_TRANSIENT` → pause (resumed on `GAIN`); `LOSS_TRANSIENT_CAN_DUCK` → volume 0.2 (restored on `GAIN`). `abandonAudioFocus` on every stop path (completion, error, stop button, focus loss).
- **Stop action (§16/Gate E):** notification action «إيقاف الأذان» → `PendingIntent.getService(ACTION_STOP)` → full cleanup. Start/stop actions verified distinct.
- **Media notification (§16):** channel `talia_adhan_playback` (IMPORTANCE_LOW — must not itself make sound), title «صلاة …», text «الأذان الآن», ongoing, CATEGORY_TRANSPORT, tap → app. **No full-screen intent.**
- **Namespace:** media-notification id 2500 + stop request code 2500 — outside every frozen alarm namespace (test-pinned: not in 2000–2039, 2100–2134, 2200–2499).
- **Quran overlap (§18):** no new Quran audio architecture; the adhan holds temporary focus and abandons it on stop, letting the system/player restore per standard focus semantics.
- **Foreground-service start from background:** `startForegroundService` on API 26+; `startForeground(..., FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)` on API 29+ (2-arg below). Exact alarms are a background FGS-start exemption; with the inexact fallback the start may be blocked — caught and logged, the prayer notification still fires (documented §26 fallback).
- **`PrayerAlarmReceiver`:** now starts `AdhanPlaybackService` when `event.adhanEnabled` (failures logged, never thrown — notification already posted). `PrayerNames` extracted as the shared Arabic name source.

## 3. Manifest

```xml
<service
    android:name="com.example.talia_quran.prayer.AdhanPlaybackService"
    android:exported="false"
    android:foregroundServiceType="mediaPlayback" />
```

`FOREGROUND_SERVICE_MEDIA_PLAYBACK` permission already present. Merged manifest verified: receiver + service both present.

## 4. Verification

- `gradlew :app:testDebugUnitTest` → **BUILD SUCCESSFUL**
  - `AdhanPlaybackPolicyTest` 6/6, `PrayerAlarmIdentityTest` 6/6, `PrayerEventCodecTest` 9/9 — zero failures/errors.
  - One compile iteration: `Notification.CATEGORY_MEDIA` does not exist → corrected to `CATEGORY_TRANSPORT`.
- No Dart changes in this stage; Dart suite state unchanged (51/51 as of Stage 4/5 report).

## 5. Still Dormant

The whole V2 pipeline remains inert in production until Stage 7 flips `prayer_delivery_version` to 2; legacy FLN delivery is still the sole active owner.

## 6. Next

- Stage 7 — V1→V2 migration: mutually exclusive scheduling in `NotificationScheduler` + `prayer_delivery_version` persistence + rollback path.
- Stage 8 — TIME_SET/TIMEZONE_CHANGED recovery.
