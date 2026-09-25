# Talia Prayer V2 — Stage 10 Runtime Test Matrix

**Prereqs:** connected Android device (adb), app built from this branch (`flutter build apk --debug`), prayer times enabled (city Cairo), Adhan ON.

On this bench the device runs **Android 9 (API 28)** — exact alarms are always granted, so the `SCHEDULE_EXACT_ALARM` permission flow is exercised logically, not via the Android 12+ consent dialog. A second pass on Android 12+ is still required for the exact-permission UX.

Run in order; between sections always relaunch the app unless stated otherwise.

---

## 1. Foreground (Gate D)
- Open the app, wait for the next prayer minute (set device clock to `next - 1 min` via Settings or `adb shell date` on an emulator with a permissive image).
- **Expect:** prayer notification «حان الآن وقت صلاة …» + full adhan starts with audio focus, media notification «الأذان الآن» + stop button.
- Verify: `adb shell dumpsys alarm | grep talia_quran` shows **only** `PrayerAlarmReceiver` alarms for prayer times (no `ScheduledNotificationReceiver` prayer ids 2000–2039).

## 2. Background (Gate D)
- Press Home, keep the app in recents, wait for the next prayer.
- **Expect:** same as §1.

## 3. App killed (Gate D)
- `adb shell am force-stop com.example.talia_quran`, wait for the next prayer.
- **Expect:** notification + adhan fire (native receiver runs without Flutter).

## 4. Locked screen (Gate D)
- Lock the device, wait for the next prayer.
- **Expect:** notification on the lock screen, adhan audible.

## 5. Stop button (Gate E)
- While the adhan plays, tap «إيقاف الأذان» on the media notification.
- **Expect:** playback stops immediately, service notification dismissed, audio focus released (Quran player may resume per focus rules).

## 6. Quran overlap (Gate F)
- Start Quran recitation (background audio), wait for the next prayer.
- **Expect:** the adhan gains audio focus, Quran pauses; when the adhan ends, Quran resumes. Never both together uncontrolled.

## 7. Reboot (Gate H)
- Reboot the emulator (`adb reboot`), do NOT open the app, wait for the next prayer.
- **Expect:** `PrayerRecoveryReceiver` re-arms the stored native alarms at boot; the prayer fires.

## 8. Timezone change (Gate I, §30)
- Settings → Date & time → change timezone (e.g. Cairo → London).
- **Expect:** the recovery receiver re-arms stored events immediately (no 6-hour wait); prayer times stay anchored to the city (Cairo) zone.

## 9. Device time change (Gate I)
- Move the device clock forward past the next prayer.
- **Expect:** the receiver re-arms; no stale double-fire.

## 10. Exact permission denied (Gate G) — Android 12+ only
- Settings → Apps → Special access → Alarms & reminders → deny for Talia.
- **Expect:** notifications still arrive (inexact fallback); no error UI.

## 11. User disables Adhan (§37)
- Settings → prayer notifications → turn OFF «الأذان الكامل».
- **Expect:** prayer notification fires **without** playback.

## 12. Disable one prayer (§37)
- Toggle a single prayer off in the prayer settings.
- **Expect:** that prayer has no notification and no adhan; the others still fire.

## 13. Change city (Gate I)
- Switch city Cairo → London.
- **Expect:** old Cairo alarms gone (dump shows only the new city's times); no stale alarms.

## 14. Change calculation method (Gate I)
- Switch the method (e.g. auto → Egyptian).
- **Expect:** alarms rebuilt for the new times; no duplicates.

## 15. Duplicate detection (Gate C / §38)
- After every refresh: `adb shell dumpsys alarm | grep talia_quran` and confirm each prayer occurrence has exactly ONE entry and it is the **native** `PrayerAlarmReceiver` (not FLN).

---

## Diagnostic commands

```bash
# alarms
adb shell dumpsys alarm | grep -A2 talia_quran

# notification channels
adb shell dumpsys notification | grep -A10 talia_prayer

# running adhan foreground service
adb shell dumpsys activity services com.example.talia_quran | grep AdhanPlaybackService

# logs
adb logcat -s PrayerV2
```
