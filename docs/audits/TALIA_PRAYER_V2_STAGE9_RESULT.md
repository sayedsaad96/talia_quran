# Talia Prayer V2 — Stage 9 Execution Report

**Date:** 2026-09-21
**Branch:** `main`
**Stage:** Stage 9 — UX Cleanup (§26/§27/§28/§32/§33/§34)
**Status:** **PASS — 63/63 affected tests green; goldens excluded (see §5)**

---

## 1. §27 — Two Master Switches (`settings_notification_tiles.dart`)

- The notifications-page switch `notifications_prayer_times` is now explicitly the SECOND switch: when `prayer_times_enabled` (prayer page) is OFF, it renders **disabled** with the hint «فعّل مواقيت الصلاة أولًا» (new key `notificationSettingsPrayerNeedsTimes`).
- The per-prayer chips, the adhan switch, and the exact-alarm entry are additionally gated on the first switch.
- Preference keys unchanged; only the UX relationship is made explicit.

## 2. §28 — Adhan Switch Meaning

- `notifications_prayer_athan` keeps its key; its label now reads **«الأذان الكامل»** with subtitle «تشغيل الأذان الكامل عند دخول وقت الصلاة مع إمكانية إيقافه» (EN: "Full Adhan" / "Plays the full adhan at prayer time with a stop control") — matching the V2 owned-playback semantics instead of the legacy channel-sound phrasing.

## 3. §26 — Exact Alarm UX

- The button label is now «تفعيل التنبيهات الدقيقة» with a calm explanation line above it («تضمن وصول تنبيه الصلاة والأذان في وقتهما بالضبط», new key `notificationExactAlarmExplanation`).
- The denied message is reassuring, never an error: «ستصلك التنبيهات في وقتها تقريبًا بالوضع العادي، ويمكنك تفعيل الدقة الكاملة لاحقًا من إعدادات الهاتف.» The inexact fallback keeps reminders alive (Stage 7 coordinator + §11 native fallback already implement the behavior).

## 4. §32 — Live Countdown (`home_prayer_timeline.dart` + `home_night_header.dart`)

- Presentation-only ticking countdown: a 1-second `AnimationController` ticker (no Dart `Timer`, no prayer recalculation) decays the snapshot's own `minutesUntil` as time passes and updates the header.
- At zero it fires `onSnapshotStale` **exactly once**; `home_night_header` wires it to `HomeCubit.load()` so the snapshot reloads and the timeline advances to the next prayer (guard re-armed only on a genuinely new snapshot).
- Gated by the same `enableAnimations`/`disableAnimationsOf` flags as the existing pulse — widget tests using `pumpAndSettle` remain safe.
- Fixtures note: the live value decays FROM the snapshot's `minutesUntil` (never recomputed from prayer times), which keeps existing test fixtures meaningful.

## 5. §33 — Past Prayer State (`home_prayer_times_sheet.dart`)

- Removed the `check_circle` icon shown purely because time passed. The dimmed card + a neutral `history` glyph is the past state; a completion indicator appears only via `companionStatus` (Prayer Companion confirmation) — pinned by the existing test `past unconfirmed prayer is not displayed as completed` (passing).
- The timeline widget already used the neutral dimmed visual; unchanged.

## 6. §34 — City/Method Transparency (`home_prayer_times_sheet.dart`)

- The sheet header now reads `المدينة • الطريقة` — e.g. «القاهرة • الهيئة المصرية» — showing the ACTIVE calculation method (user's manual choice) resolved via `PrayerTimesService`, defensively skipped when DI is absent (same pattern as the settings tiles).

## 7. l10n

- `app_ar.arb` / `app_en.arb` updated (2 new keys, 3 retitled keys) + `flutter gen-l10n` regenerated `app_localizations*.dart` (checked-in generated files).

## 8. Verification

- `flutter analyze` (home presentation, settings presentation, l10n): **No issues found**.
- `flutter test` timeline + sheet-companion + settings suites: **63/63 passed** — including the countdown header tests, `pumpAndSettle` test, and the §33 no-completed-semantic test.
- **Excluded:** `home_preview_capture_test.dart` golden pair fails with an 8.26% pixel diff — **verified pre-existing at git HEAD** (ran with all working-tree changes stashed: same failure). The goldens are stale relative to an earlier state and must be regenerated (`flutter test --update-goldens`) as part of the Stage 10 manual pass, after visual sign-off.

## 9. Hygiene Note

`assets/images/mosque_bg.png` shows an uncommitted size change (1.87 MB → 1.11 MB) dating to this session's build window (likely an image optimization from a prior/parallel session). It is NOT part of the V2 changes; left untouched for the owner to review before the next commit.

## 10. Next

- Stage 10 — runtime torture tests on device/emulator (foreground/background/killed/locked/doze/reboot/timezone/audio-interaction matrix) — requires a connected device and manual execution.
- Stage 11 (later release) — remove provably-unused legacy adhan delivery code.
