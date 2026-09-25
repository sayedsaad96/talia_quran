# Talia Prayer V2 — Stage 10 Execution Report

**Date:** 2026-09-21
**Branch:** `main`
**Stage:** Stage 10 — Runtime Torture Tests (device matrix + golden-rule fix)
**Status:** **PASS for the automated subset; manual matrix documented for hardware-specific gates**

---

## 1. Test Bench

- Connected device: **Android 9 (API 28)** emulator (adb over 127.0.0.1:5555). Note: exact alarms are always granted on API 28, so the Android 12+ exact-permission consent flow is exercised logically (see the manual matrix) but not visually.
- App installed from `build/app/outputs/flutter-apk/app-debug.apk` built **with the Stage 7 golden-rule fix**.

## 2. Automated on-device results

| Gate | Check | Result |
|---|---|---|
| B | Merged manifest clean (no awqat, no USE_EXACT_ALARM) | **PASS** |
| C | Native `PrayerAlarmReceiver` owns prayer alarms; legacy FLN 2000–2039 cleared after the migration refresh | **PASS** (see §3) |
| G | Exact-permission fallback (API 28 = always granted; Android 12+ flow documented) | **PASS (logical)** |
| H | Reboot recovery (`PrayerRecoveryReceiver`) | **JVM-verified + manifest-wired** (device reboot pending, see §4) |
| §27 | Second master switch disabled with «فعّل مواقيت الصلاة أولًا» until the first switch is ON | **PASS (live UI)** |
| §33 | Past prayer shows neutral state, not a completed check | **PASS** (existing test) |

## 3. Critical live finding and fix — Golden Rule (Gate C)

During the on-device verification the dumpsys output revealed **the same prayer occurrence armed in both paths** (legacy FLN id + native `PrayerAlarmReceiver` at the same instant) on the *second* app session after the migration:

- **Root cause:** after migration to V2, `shouldRefreshRolling` skips the rebuild on subsequent same-day refreshes, so the legacy ids (armed before the migration) were never cancelled — both paths stayed armed.
- **Fix (Dart):** `NotificationScheduler` now cancels legacy prayer reminders on **every** refresh when the native V2 path is the active owner — even when the rolling-window guard skips the rebuild (idempotent `cancelPrayerTimesReminders`). The Prayer Companion namespace (2100–2134) is untouched.
- **Regression test added:** `golden rule: a native-owner refresh skipped by the rolling guard still cancels legacy FLN alarms (no dual ownership after app restart)` in `notification_scheduler_prayer_delivery_test.dart` (39/39 passing).

**Note on dumpsys reading:** `dumpsys alarm` lists each alarm twice (once in the index, once inside its batch). The duplicated native entry observed after the fix was verified to be a single alarm (`count=1` in the batch), not a duplicate.

## 4. Reboot check

`adb reboot` was issued and the `PrayerRecoveryReceiver` (BOOT_COMPLETED) re-arms stored native alarms at boot. On this bench the emulator (WSA) takes longer than the 30s command window to finish rebooting; the receiver's re-arm plan is JVM-covered (`PrayerRecoveryTest` 4/4) and the manifest wiring is verified. Complete the manual §7 below on hardware to close Gate H on-device.

## 5. Manual matrix (§37 / Stages 10)

Full step-by-step device matrix in `docs/audits/TALIA_PRAYER_V2_STAGE10_MANUAL_MATRIX.md`:
foreground / background / killed / locked / doze / stop button / Quran overlap / reboot / timezone change / device time change / exact-permission denied / adhan off / single prayer off / change city / change method / duplicate detection.

## 6. Rollback safety

Rollback path (V2 → V1) is covered by the §40 coordinator logic and the Stage 7 rollback test; no production data migration risk.

## 7. Next

- Re-run on Android 12+ device to visually verify the exact-permission consent UX and the inexact fallback.
- After a stability window, Stage 11 removes the provably-unused legacy adhan delivery code.
