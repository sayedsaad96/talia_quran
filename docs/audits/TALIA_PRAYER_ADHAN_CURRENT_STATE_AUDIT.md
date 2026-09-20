# Talia Prayer Times + Adhan — Current-State Forensic Audit

**Date:** 2026-09-20
**Branch:** `feature/prayer-companion-v1`
**Scope:** Read-only investigation. No code, manifest, dependency, or configuration was modified.
**Method:** Full-repo search (Dart, Kotlin, manifest, gradle, pubspec, assets, l10n, tests, docs) + live runtime inspection of the installed debug build on an Android emulator (`emulator-5554`) via `adb dumpsys` / `logcat`.

Legend used throughout:
- **[V]** = verified by reading source or runtime output.
- **[I]** = inferred from source with high confidence, not directly observed at runtime.

---

## 1. Executive Summary

Talia already has a substantial, mostly-well-engineered prayer system:

- **Calculation** uses the `adhan` package (2.0.0+1) [V], driven by a bundled city dataset (`assets/data/prayer_cities.json`, 20 cities / 16 countries) [V], with the city's IANA timezone — never the device timezone — used for all math [V]. Fully offline [V].
- **Scheduling** is a rolling 7-day × 5-prayer window of `flutter_local_notifications` `zonedSchedule` entries (IDs 2000–2039) [V], refreshed on app launch, app resume, locale change, settings changes, and a 6-hour Workmanager periodic task [V]. Exact-when-allowed scheduling (`exactAllowWhileIdle` / fallback `inexactAllowWhileIdle`) is implemented for prayers [V] and verified live in `dumpsys alarm` [V].
- **Adhan audio is a notification-channel sound, not a player.** The `awqat` package is used solely to bundle `res/raw/adhan.mp3` (Android) / `adhan.caf` (iOS), attached to a dedicated channel `talia_prayer_times_athan` [V]. The sound is frozen into the channel at creation, plays for the clip duration under the OS notification ringtone path, and has no stop control, no audio focus, no MediaSession, and no guarantee of full playback in Doze/locked/background states beyond ordinary notification-sound behavior [V/I].
- **Prayer Companion** is a separate, well-structured opt-in feature (planner + policy + Isar records + 3 notification actions) sharing the same `PrayerTimesService` and readiness gate [V].

**Why the current experience is below the desired quality:**

1. **The Adhan is not reliable audio.** A notification-channel sound (a) is truncated to whatever the OS allows for notification ringtones, (b) cannot be stopped from inside the app, (c) has no audio-focus handling (it will overlap Quran recitation or music), and (d) is not a foreground playback path — behavior in Doze/lock-screen is at the mercy of the OEM's notification pipeline, not the app. This is the single biggest gap vs. the target.
2. **Location is manual-only.** 20 cities in a dropdown; no GPS, no approximate location, no "nearest city". Users outside the 20 cities get wrong times.
3. **Method/fiqh controls are partial.** 5 methods exposed; no madhab (Asr) option, no high-latitude rule option, no manual minute adjustments — although the `adhan` library supports all three and the code seam (`_paramsFor`) is trivially extensible.
4. **Two "enable" switches with different meanings** (`prayer_times_enabled` gates the Home UI; `notifications_prayer_times` gates alerts) sit on two different settings pages with no cross-reference — a real confusion/duplication risk.
5. **A dead competitor scheduler is fused into the APK.** `awqat` is included only for its sound file, but its manifest injects `USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM`, an exported `AlarmReceiver`, and an exported `BootReceiver` into the merged manifest [V — verified in `build/app/intermediates/merged_manifests/...` and the pub-cache manifest]. Its Dart scheduler API is never imported [V]. This silently contradicts the app manifest's own comment that "USE_EXACT_ALARM / battery-optimization bypasses are deliberately avoided (Play policy)" [V].
6. **Fajr-specific Adhan and muezzin selection do not exist.** `prayer_sound.dart` has an explicit Fajr clip-resolution seam, but no muezzin-selection model or preference seam yet [V].

---

## 2. Current Architecture Diagram (actual runtime flow)

```
                         ┌────────────────────────────────────────────────────────┐
                         │                    TRIGGERS OF REFRESH                 │
                         │ App launch (AppInitializer._scheduleFirstLaunchNotif.) │
                         │ App resume (TaliaApp.didChangeAppLifecycleState)       │
                         │ Locale change (BlocListener<LocaleCubit>)              │
                         │ Any prayer/notification setting toggle (force: true)   │
                         │ Workmanager periodic every 6h (background isolate)     │
                         │ Companion action applied (force: true)                 │
                         └───────────────────────────┬────────────────────────────┘
                                                     ▼
                                      NotificationScheduler.refreshNotifications()
                          (lib/core/services/notification_scheduler.dart)
                                                     │
              ┌──────────────────────────────────────┼──────────────────────────────────────┐
              ▼                                      ▼                                      ▼
   PrayerTimesService                     TaliaNotificationService                 PrayerCompanionPlanner
   (prayer_times_service.dart)            (notification_service.dart)              (prayer_companion_…planner.dart)
   timesForDate(date) × 7 days            schedulePrayerTimesReminders()           plan(now) → 2-day events
   └─ adhan pkg PrayerTimes.utc()         └─ cancel 2000–2039 → zonedSchedule      └─ reads Isar records + prefs
      coords from city asset                 exact mode when allowed               (preparation / check-in / follow-up)
      tz = city.timeZone (NOT device)     └─ channel: talia_prayer_times           └─ quiet-hours SUPPRESS at scheduler layer
      method from prefs (country default)    or talia_prayer_times_athan           IDs 2100–2134 (never collide)
      (adhan ^2.0.0+1)                       (athan = RawResource sound 'adhan')   schedulePrayerCompanionReminders()
                                                                                    channel: talia_prayer_companion

  DISPLAY PATH (foreground only):
  HomeCubit._loadExtras → PrayerTimesService.current(isArabic) → PrayerTimesSnapshot
      → HomeNightHeader → HomePrayerTimeline (6 stations, countdown chip) → tap → HomePrayerTimesSheet
      → sheet renders Companion statuses/actions when enabled (PrayerCompanionDaySummary)

  FOREGROUND-ONLY SIDE SYSTEM:
  PrayerSerenityWatcher (30s Timer, started in AppInitializer, killed with app process)
      → PrayerSerenityPolicy.activeOccurrenceKey → pause QuranContinuousPlayerService
      → showPrayerSerenityMoment() (immediate notification id 1063, channel talia_milestones)

  ANDROID DELIVERY:
  flutter_local_notifications AlarmManager alarms (RTC_WAKEUP)
      → ScheduledNotificationReceiver → posts notification
  ScheduledNotificationBootReceiver ← BOOT_COMPLETED / MY_PACKAGE_REPLACED / QUICKBOOT_POWERON
      → re-registers alarms from the plugin's persisted schedule store
```

Key truth: **there is exactly one scheduler** (NotificationScheduler + TaliaNotificationService over flutter_local_notifications). No AlarmManager of our own, no second scheduling engine in Dart [V]. The only foreign scheduler artifacts are awqat's unused, manifest-merged receivers [V].

---

## 3. File Map

### Core — calculation
| File | Responsibility |
|---|---|
| `lib/core/services/prayer_times_service.dart` | City model (`PrayerCity`, `PrayerCountry`), snapshot model, city/country loading from asset, method persistence + auto-follow-country logic, `current()` (next-prayer snapshot, all 6 times), `timesForDate(date)` (used by schedulers), readiness gate `isReadyForNotificationScheduling`. |
| `assets/data/prayer_cities.json` | 20 cities / 16 countries: lat, lng, IANA tz, country, country-default method. |
| `lib/core/utils/prayer_time_formatter.dart` | Arabic/English remaining-time formatting (full + compact). |

### Core — sound
| File | Responsibility |
|---|---|
| `lib/core/services/prayer_sound.dart` | `resolvePrayerSound()`: system vs athan mode; channel IDs (`talia_prayer_times`, `talia_prayer_times_athan`); per-prayer clip map (`{'fajr':'adhan'}` — documented Fajr seam). |
| *(package)* `awqat-0.1.14/android/src/main/res/raw/adhan.mp3`, `ios/Resources/adhan.caf` | The actual Adhan clips (verified present in pub cache). Only resource of `awqat` used. |

### Core — notification pipeline
| File | Responsibility |
|---|---|
| `lib/core/services/notification_service.dart` (2036 lines) | Plugin init, channel definitions (16), `zonedSchedule` wrappers, ID namespaces, iOS budget eviction (`notificationIdsToCancelForBudget` — prayer/companion never evicted), exact-alarm capability check + request, `configureLocalTimezone()` (device tz → tz.local, GMT-offset-ID normalization, last-known fallback, UTC safety net), `schedulePrayerTimesReminders`, `cancelPrayerTimesReminders`, companion scheduling, `showPrayerSerenityMoment`, tap/action routing entry point. |
| `lib/core/services/notification_scheduler.dart` | Orchestrates all reminders; prayer block (7-day rolling build from `timesForDate`, per-prayer filter, athan flag), companion block (planner + quiet-hours suppression), rolling-refresh gate `_lastRollingDateKey` (per-isolate), smart reminder, quiet-hours helpers. |
| `lib/core/sync/notification_refresh_worker.dart` | Headless Workmanager entry: builds local-only scheduler graph (prefs + Isar + planner), `force: true` refresh. Documented V1 limitation: owner-id falls back to local scope in background isolate. |
| `lib/core/sync/background_sync_scheduler.dart` | Workmanager init + single dispatcher routing (`kNotificationRefreshTaskName` → notification refresh; else cloud sync). |
| `lib/core/services/app_initializer.dart` | Startup ordering: `initialize()` → `requestPermissions()` (unawaited) → first-launch refresh → registers 6h periodic Workmanager task → starts `PrayerSerenityWatcher` (foreground only). |
| `lib/core/services/prayer_serenity_policy.dart` | Pure rules: 10-min serenity window per prayer occurrence, occurrence key. |
| `lib/core/services/prayer_serenity_watcher.dart` | Foreground 30-s tick watcher; pauses recitation + shows one notification per occurrence; own pref key `prayer_serenity_enabled` (default true). |

### Prayer Companion feature
| File | Responsibility |
|---|---|
| `lib/features/prayer_companion/domain/entities/prayer_companion.dart` | `PrayerKey`, statuses/commands/kinds, occurrence identity (ownerId+localDate+prayer), settings, record, day summary. |
| `lib/features/prayer_companion/domain/services/prayer_companion_policy.dart` | Pure transitions; ≤1 pending follow-up; follow-up delays (15/10 min). |
| `lib/features/prayer_companion/domain/services/prayer_companion_scheduler_planner.dart` | Deterministic 2-day plan; ID namespaces 2100–2119 planned, 2120–2129 follow-ups, 2130–2134 yesterday-spillover; respects per-prayer filter keys. |
| `lib/features/prayer_companion/application/prayer_companion_usecases.dart` | `ApplyPrayerCompanionCommand` (owner re-stamping), `GetPrayerCompanionDaySummary` (actionable window until next prayer; Isha capped at civil-day rollover). |
| `lib/features/prayer_companion/application/prayer_companion_controller.dart` | Notification-response bridge (`pc1\|…` payload + 3 action IDs); persists then force-refreshes notifications. |
| `lib/features/prayer_companion/notifications/prayer_companion_notification_intent.dart` | Versioned payload codec (`pc1|owner|date|prayer|millis|kind`). |
| `lib/features/prayer_companion/data/datasources/prayer_companion_preferences.dart` | SharedPreferences store, `prayer_companion_*` keys (cleared on account reset). |
| `lib/features/prayer_companion/data/datasources/prayer_companion_local_datasource.dart`, `data/models/prayer_companion_record_isar.dart` (+`.g.dart`), `data/repositories/prayer_companion_repository_impl.dart` | Isar persistence, owner-scoped. |
| `lib/features/prayer_companion/presentation/cubits/prayer_companion_cubit.dart` | Submit-state cubit for sheet action buttons. |
| `lib/features/prayer_companion/presentation/widgets/prayer_companion_settings_section.dart` | Companion settings + Serenity toggle + clear-history. |
| `lib/features/prayer_companion/presentation/widgets/prayer_companion_status.dart` | Status chip in the sheet rows. |

### UI surfaces
| File | Responsibility |
|---|---|
| `lib/features/home/presentation/widgets/home_night_header.dart` | Hosts `HomePrayerTimeline`; also contains legacy `HomePrayerChip` (dead code — defined, never instantiated [V]). |
| `lib/features/home/presentation/widgets/home_prayer_timeline.dart` | Celestial 6-station timeline; next-prayer header + countdown; opens the sheet. |
| `lib/features/home/presentation/widgets/home_prayer_times_sheet.dart` | Full-day sheet: 6 rows, next/past styling, countdown chip, Companion statuses + action row. |
| `lib/features/home/presentation/cubits/home_cubit.dart` | Loads `prayerSnapshot` + `companionSummary` per load; passes controller through. |
| `lib/features/settings/presentation/pages/subpages/prayer_settings_page.dart` | Prayer settings page = Prayer Times section + Companion section. |
| `lib/features/settings/presentation/widgets/settings_prayer_tiles.dart` | Master enable (`prayer_times_enabled`), country/city dropdowns, method dropdown (Auto + 5 methods). |
| `lib/features/settings/presentation/pages/subpages/notification_settings_page.dart`, `widgets/settings_notification_tiles.dart` | Notifications page incl. prayer master switch, 5 per-prayer chips, athan switch, "request exact alarm" button. |
| `lib/features/settings/presentation/cubits/notification_settings_cubit.dart` | Persists all notification prefs and force-reschedules on every change. |
| `lib/features/settings/presentation/pages/settings_page.dart` | Navigation entries to both subpages. |

### Platform & config
| File | Responsibility |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | App permissions; FLN boot/scheduled receivers; audio_service `AudioService` (mediaPlayback) + `MediaButtonReceiver`; comment claiming USE_EXACT_ALARM is avoided. |
| `android/app/src/main/kotlin/com/example/talia_quran/MainActivity.kt` | `class MainActivity : AudioServiceActivity()` — the only app Kotlin code. |
| `android/app/build.gradle.kts` | compileSdk 37; min/target from Flutter defaults. |
| `pubspec.yaml` / `pubspec.lock` | `adhan ^2.0.0+1` (locked 2.0.0+1); `awqat ^0.1.14` (locked 0.1.14) with explicit comment "Its scheduler is NOT used"; `flutter_local_notifications ^22.0.1` (locked 22.2.0); `timezone ^0.11.0` (0.11.1); `flutter_timezone ^5.1.0`; `workmanager ^0.10.9`; `just_audio ^0.10.5` + `audio_service ^0.18.19` (Quran audio only). |
| `lib/core/di/injection.dart` | Wiring for all services above (incl. Serenity watcher callbacks and HomeCubit extras). |
| `lib/core/router/launch_destination.dart` | Legacy action→route map (`action_quran`→Quran, `action_azkar`→Azkar hub…); companion action IDs deliberately absent. |
| `lib/app.dart` | Lifecycle refresh wiring; cold-start launch handling; companion response handling. |
| `lib/core/identity/account_data_reset.dart` | Clears `prayer_companion_*` prefix on account reset. |

### Tests (prayer-relevant, 14+ files [V])
`test/core/services/prayer_times_service_test.dart`, `prayer_sound_test.dart`, `prayer_serenity_policy_test.dart`, `prayer_serenity_watcher_test.dart`, `notification_scheduler_*_test.dart` (companion/kids/phase2/phase_b/streak), `notification_service_test.dart`, `notification_service_companion_test.dart`, `notification_budget_test.dart`, `notification_quiet_hours_test.dart`, and `test/features/prayer_companion/**` (planner, policy, usecases, datasource, intent, controller, cubit, settings section, full flow).

### Docs (context, not source of truth)
`docs/superpowers/plans/2026-09-16-prayer-companion-v1.md`, `docs/superpowers/specs/2026-09-16-prayer-companion-design.md`, `docs/superpowers/specs/2026-09-17-celestial-prayer-timeline-design.md`, `docs/2026-09-19-talia-companion-v1-phase0-audit.md`.

---

## 4. Prayer Calculation

**Library & version [V]:** `adhan` package, `^2.0.0+1` in pubspec, locked `2.0.0+1`.

**Call chain (actual) [V]:**
```
UI (HomeNightHeader / HomePrayerTimeline / HomePrayerTimesSheet)
  ← HomeCubit._loadExtras → PrayerTimesService.current(isArabic: true)
Schedulers (NotificationScheduler, PrayerCompanionPlanner, background worker)
  → PrayerTimesService.timesForDate(date)
      → _calculate(city, date):
           tz.getLocation(city.timeZone)
           PrayerTimes.utc(Coordinates(lat, lng), DateComponents.from(cityDate), _paramsFor(method))
           each result converted back via tz.TZDateTime.from(x, location)
```

**Calculation methods:**
- Supported by the library: 13 [V — adhan 2.0.0 enum: muslim_world_league, egyptian, karachi, umm_al_qura, dubai, moon_sighting_committee, north_america, kuwait, qatar, singapore, turkey, tehran, other].
- Persisted/validated: any `CalculationMethod.values` name; unknown → MWL fallback [V].
- Exposed in UI: Auto + MWL, Egyptian, Umm al-Qura, Karachi, North America only [V].
- **Default:** `muslim_world_league` [V] when no city default applies.

**Method by country [V]:** Yes — each city asset entry carries `method`; `setCityId` applies the country default while `prayer_calc_method_manual` is false; `setMethodAutomatic()` restores country-driven selection. Pinned defaults exist only for SA (`umm_al_qura`), EG (`egyptian`), PK (`karachi`), US/CA (`north_america`); everything else MWL [V].

**Madhab [V]:** Not supported by the app layer. `adhan` supports `madhab` (Shafi default / Hanafi) but `_paramsFor` never sets it — Asr is always Shafi. No UI, no pref key.

**High-latitude handling [V]:** Library default only (`middle_of_the_night`, from `CalculationParameters` default). Not configurable in the app.

**Manual minute adjustments [V]:** Not exposed. `adhan`'s `PrayerAdjustments` is never used in `lib/` (grep verified). No pref key, no UI.

**DST handling [V]:** Correct by construction — times are computed in the city's IANA zone via the `timezone` tz database; `TZDateTime` arithmetic handles DST transitions. The 7-day schedule loop and companion planner use civil dates in the device-local zone (`DateTime(now.year,…)`), then `_calculate` re-anchors to the city zone — a device-tz ≠ city-tz mismatch shifts "which day" is calculated by up to a day at boundaries (edge case, see §5).

**Date rollover [V]:** `current()` anchors `now` in the city zone, takes the first future time among fajr→isha; if all are past, next day's fajr is computed via `tz.TZDateTime(location, y, m, d+1)`. `timesForDate` uses the passed date; the scheduler passes `DateTime.now().add(days: n)` (device-local).

**Offline behavior [V]:** Fully offline. City data is a bundled asset; calculation is pure; no network anywhere in the chain. (Asset-load failure falls back to a single hardcoded Makkah entry — a deliberate safety net that would silently wrong-time non-Makkah users [V].)

---

## 5. Location & Timezone

**Location sources [V]:** Exactly one — the manual city dropdown persisted as `prayer_city_id`. There is **no GPS**, no reverse geocoding, no `geolocator` dependency, no cached device location, no approximate/coarse location. No location permissions exist in the manifest [V]. If `prayer_city_id` is unset, `current()` falls back to the first city in the asset (Makkah) for **display**, but notification scheduling is gated off (`isReadyForNotificationScheduling` requires an explicit city AND explicit method) [V] — good guard.

**Timezone resolution — two distinct layers (important):**

1. **Calculation/display timezone [V]:** always `city.timeZone` from the asset (`tz.getLocation`). Device timezone is never used for prayer math. This is a deliberate, documented design ("all math and display use it, never the device zone").
2. **Scheduling timezone [V]:** `tz.local`, configured by `TaliaNotificationService.configureLocalTimezone()`: `flutter_timezone` device ID → GMT-offset normalization (e.g. `GMT+03:00` → `Etc/GMT-3`) → persisted last-known fallback (`notifications_last_known_timezone`) → UTC last-resort. Runs on every scheduler refresh and in background isolates via the UTC pre-seed safety net.

**Edge cases found:**
- **Travel mismatch [I]:** A user flying from Riyadh to Cairo gets city-anchored times (Makkah's), not local times — arguably intended for a city-pinned model, but the sheet shows only the city name, no hint that device time ≠ city zone.
- **Device-tz/city-tz day boundary [V/I]:** `timesForDate(DateTime.now().add(...))` computes "which date" in device-local time but then calculates in city-local time. When the device is in a different zone than the city (travel), the 7-day schedule can compute a neighboring city-day than the one the user's clock says.
- **Timezone *change* has no dedicated listener [V]:** `configureLocalTimezone()` re-runs on each refresh, so `tz.local` corrections only land at the next refresh trigger (resume, 6h worker, settings change). There is no `TIMEZONE_CHANGED`/`TIME_SET` handling in the app (plugin boot receiver covers reboots, not live tz changes).
- **tz.local = UTC fallback [V]:** if every device-tz lookup fails, notifications convert against UTC — logged, but the user-visible effect would be shifted alerts. Rare, contained.

---

## 6. Settings & Persistence

All prayer-related settings live in **SharedPreferences** (no Supabase persistence of prayer settings; Supabase supplies only the owner ID that scopes Isar companion records [V]). Isar stores only companion **records** (not settings) [V]. Cubit state is ephemeral and always re-read from prefs [V].

| Setting | UI control | State owner | Persistence (key) | Runtime consumer |
|---|---|---|---|---|
| Prayer times enabled (UI) | Switch, Prayer settings page | `PrayerTimesSettingsSection` | `prayer_times_enabled` | `PrayerTimesService.isEnabled` → gates `current()` → Home timeline visibility |
| Prayer notifications enabled | Switch, Notifications page | `NotificationSettingsCubit` | `notifications_prayer_times` | Scheduler prayer block (master gate for scheduling) |
| City | Dropdown (country→city) | `PrayerTimesSettingsSection` | `prayer_city_id` | `PrayerTimesService` (all calculation), readiness gate |
| Calculation method (+Auto) | Dropdown, Prayer settings page | `PrayerTimesSettingsSection` | `prayer_calc_method`, `prayer_calc_method_manual` | `_paramsFor()`, readiness gate |
| Per-prayer alerts (5) | FilterChips, Notifications page | `NotificationSettingsCubit` | `notifications_prayer_{fajr,dhuhr,asr,maghrib,isha}` | Scheduler prayer filter + Companion planner filter |
| Adhan sound on/off | Switch, Notifications page | `NotificationSettingsCubit` | `notifications_prayer_athan` | Scheduler → athan channel variant |
| Serenity Mode | Switch, Prayer settings page (Companion section) | `PrayerCompanionSettingsSection` | `prayer_serenity_enabled` (default true) | `PrayerSerenityWatcher.isEnabled` |
| Companion enabled | Switch, Prayer settings page | `PrayerCompanionSettingsSection` | `prayer_companion_enabled` (default false) | Scheduler companion block; Home sheet summary |
| Companion prep minutes / check-in / follow-up | Dropdown + 2 switches | same | `prayer_companion_preparation_minutes` / `_check_in_enabled` / `_follow_up_enabled` | `PrayerCompanionPreferences.read()` → planner/policy |
| Companion records | — (self-report actions) | — | Isar `PrayerCompanionRecordIsar` (owner-scoped) | Summary, planner, follow-ups |
| Device timezone (cache) | — | — | `notifications_last_known_timezone` | `configureLocalTimezone()` fallback |
| Exact-alarm permission | Button, Notifications page | Cubit call | (OS state, not prefs) | `resolveTimeCriticalScheduleMode` |

**Sources-of-truth / conflict analysis:**
- **Two independent "enabled" switches [V]:** `prayer_times_enabled` (UI feature) vs `notifications_prayer_times` (alerts). A user can have the timeline but no alerts, or alerts (impossible — alerts are blocked while the timeline is off? No: they are independent — `current()` returning null suppresses the timeline only; the scheduler checks only `notifications_prayer_times` + readiness, where readiness includes `isEnabled`, i.e. `prayer_times_enabled` **is** an implicit scheduling gate [V]). Net effect: enabling alerts requires the settings-page switch too — undiscoverable, and the two switches live on different pages with no cross-link.
- **Notification vs prayer settings overlap [V]:** per-prayer chips + athan toggle (Notifications page) vs city/method (Prayer page). Both force-reschedule through the same `refreshNotifications(force: true)`; no state divergence was found, but the split surface is the UX issue, not data.
- **Companion filter keys reuse prayer filter keys [V]** (`prayerFilterKeys` maps to `TaliaNotificationService.prayer*Key`) — one source of truth for per-prayer filtering. Good.
- **Account reset [V]:** `prayer_companion_*` prefix cleared; `prayer_times_enabled`, city, method, and notification prefs survive logout (device-owned). Consistent with the "local-only" claim in the companion UI.

---

## 7. Scheduling Architecture

**API [V]:** `flutter_local_notifications` 22.2.0 `zonedSchedule` exclusively. No direct AlarmManager usage in app code. Workmanager is used only for *refreshing schedules*, never for firing prayer events.

**Window & capacity [V]:** 7 days × 5 prayers = up to 35 entries, IDs `2000 + offset` (offset increments across all computed prayers, filtered later), hard cap `_prayerTimesMaxCount = 40`. Companion uses 2100–2134. `notificationIdsToCancelForBudget` protects IDs 2000–2039 and 2100–2134 from iOS eviction [V].

**Exact vs inexact [V]:** `resolveTimeCriticalScheduleMode('prayer_times')` → `exactAllowWhileIdle` when `canScheduleExactNotifications()`, else `inexactAllowWhileIdle`. The exact-permission request UX is a manual button on the Notifications page (`Permission.scheduleExactAlarm.request()`), surfaced only on Android under the prayer section [V].

**Duplicate prevention / cancellation [V]:** cancel-first-then-reschedule (`cancelPrayerTimesReminders()` loops IDs 2000–2039 before scheduling). Deterministic ID assignment means a re-refresh cannot duplicate. Companion does the same for 2100–2134 with a planner-side ID namespace + runtime `assert`.

**Refresh triggers [V — all call sites traced]:** app launch (`AppInitializer`), every app resume (`app.dart`), locale change, every settings mutation (cubit/settings widgets call with `force: true`), companion action application, and the Workmanager 6-h periodic task (`force: true` in a headless isolate). Rolling rebuild is additionally gated by the in-memory `_lastRollingDateKey` (per isolate) so resume-refreshes on the same day don't rebuild rolling schedules (unless forced).

**Behavior per scenario:**

| Scenario | What happens | Basis |
|---|---|---|
| App launches | Plugin init → tz config → full refresh (rolling, since fresh isolate) → schedules up to 7 days | [V] code |
| App closed (process alive) | Nothing runs in Dart; pre-scheduled OS alarms fire independently | [V] design |
| App killed | OS alarms (RTC_WAKEUP to `ScheduledNotificationReceiver`) still fire; plugin persists its schedule | [V] plugin design + [V] alarms observed with process cold-started |
| Screen locked / Doze | `exactAllowWhileIdle` alarms fire in Doze; `inexactAllowWhileIdle` deferred to maintenance windows | [V] code path + [V] both alarm types observed in `dumpsys alarm` |
| Reboot | `ScheduledNotificationBootReceiver` (BOOT_COMPLETED, MY_PACKAGE_REPLACED, QUICKBOOT_POWERON) re-registers stored alarms | [V] manifest + [V] receiver registered on device |
| Timezone change | No dedicated listener; corrected on next refresh (tz.local re-resolved); prayer *math* unaffected (city tz) but alert *delivery* timing uses tz.local conversions at schedule time | [V/I] |
| Date/time change | Same as tz: no TIME_SET listener; the 6-h worker bounds drift to ≤6 h | [I] |
| Location (city) change | `setCityId` → settings widget → force refresh; method may auto-follow country | [V] |
| Method change | force refresh | [V] |
| Per-prayer toggle / athan toggle | force refresh; channel variant chosen per notification at schedule time | [V] |
| App update | `MY_PACKAGE_REPLACED` → boot receiver re-registers alarms | [V] manifest |

**Receivers/listeners/workers involved [V]:** `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver` (both from flutter_local_notifications, manifest-declared), `awqat`'s `.AlarmReceiver`/`.BootReceiver` (merged from package manifest, **no Dart usage**), Workmanager `cloudSyncCallbackDispatcher` (routes `talia.notification_refresh`), `MediaButtonReceiver` (audio_service, Quran only).

---

## 8. Android Platform Integration

### Permissions
**App manifest [V]:** `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `SCHEDULE_EXACT_ALARM`, `WAKE_LOCK` (+ non-prayer: INTERNET, CAMERA, RECORD_AUDIO, WRITE_EXTERNAL_STORAGE≤28).

**Merged manifest [V — `build/app/intermediates/merged_manifests/*/AndroidManifest.xml`]:** additionally `USE_EXACT_ALARM` and `FOREGROUND_SERVICE_SHORT_SERVICE`, plus `awqat`'s exported `.AlarmReceiver` and `.BootReceiver` (BOOT_COMPLETED/QUICKBOOT_POWERON intent filters). Source verified: `awqat-0.1.14/android/src/main/AndroidManifest.xml` declares `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `FOREGROUND_SERVICE` + the two receivers. `flutter_local_notifications` contributes only `VIBRATE` + `POST_NOTIFICATIONS`. This directly contradicts the app manifest comment "USE_EXACT_ALARM … deliberately avoided (Play policy)" [V]. (On devices where `USE_EXACT_ALARM` applies — Play-policy-sensitive alarm apps — this changes the exact-alarm posture of the whole app without any Talia code deciding it.)

**No location permissions, no FOREGROUND_SERVICE_* beyond mediaPlayback/short_service, no Media3** [V]. No `USE_EXACT_ALARM` declaration of our own.

### Native code [V]
`MainActivity.kt` = `class MainActivity : AudioServiceActivity()`. Nothing else. No custom BootReceiver, no AlarmManager code, no MethodChannels for prayer (the only MethodChannel is `talia/badge` for the iOS badge).

### Services [V]
`com.ryanheise.audioservice.AudioService` (`foregroundServiceType="mediaPlayback"`) — scoped to **Quran recitation** background playback via `QuranBackgroundAudioHandler`. It is *not* used for Adhan. There is no foreground service, no MediaSession, and no Media3 anywhere in the prayer path.

### Notification channels (code-defined, 16 [V])
| Channel | Importance | Sound | Notes |
|---|---|---|---|
| `talia_prayer_times` | **max** | system default (frozen at creation) | Legacy prayer channel; actions `action_quran`/`action_azkar` |
| `talia_prayer_times_athan` | **max** | **`android.resource://…/raw/adhan` (frozen at creation)** | Created because Android freezes channel sound; used whenever `notifications_prayer_athan` is on |
| `talia_prayer_companion` | high | system default | Companion actions (confirm / pray-now / remind-later) |
| `talia_reminders`, `talia_streak`, `talia_streak_gentle`, `talia_smart`, `talia_daily_ayah`, `talia_morning_azkar`, `talia_evening_azkar`, `talia_daily_dua`, `talia_kids`, `talia_kahf`, `talia_tahajjud`, `talia_khatmah`, `talia_milestones` | high/default | system default (milestones used for the serenity moment, id 1063) | Non-prayer but adjacent |

- Per-prayer channels: **no** — two prayer channels total (default/athan) [V].
- Old/legacy channels still existing: none found in code; no `deleteChannel` calls anywhere [V]. On-device dump showed only the 8 channels that had actually been used on that install (lazy creation) — consistent with code [V].
- Sound permanence [V]: channel sound is set at creation; changing the athan toggle only switches *which channel* a notification posts to; changing the clip itself would require a new channel ID (the code comment acknowledges this constraint).

---

## 9. Adhan Playback Architecture

**Answer: Option A — notification sound. Nothing else.**

```
Scheduler (refresh) → zonedSchedule(id 2000+n, channel = talia_prayer_times_athan,
                       sound = RawResourceAndroidNotificationSound('adhan'))
OS AlarmManager (RTC_WAKEUP, exact when allowed)
   → ScheduledNotificationReceiver posts the notification
   → Android RingtoneManager plays the channel's frozen sound (awqat res/raw/adhan.mp3)
   → playback ends when the clip ends / notification dismissed / DND or silent mode suppresses it
```

Verified facts [V]:
- `awqat` is used **only** for the bundled clip (`res/raw/adhan.mp3` exists in the pub cache package; iOS `adhan.caf`). Its Dart scheduling API is never imported.
- The athan channel's sound is permanently attached (`mSound=android.resource://com.example.talia_quran/raw/adhan` observed in `dumpsys notification`), importance max, `bypassDnd=false`.
- `prayer_sound.dart` explicitly reserves a Fajr seam: `_clipFor('fajr') → 'adhan'` today; a future `adhan_fajr` asset "plugs in here without touching the scheduler".
- There is **no** Flutter audio player, MediaPlayer, Media3, foreground service, MediaSession, or audio-focus code in the prayer path. `just_audio`/`audio_service`/`audio_session` are used exclusively by Quran recitation (`QuranContinuousPlayerService` etc.).
- No stop action, no preview playback, no mute-while-in-dua logic, no muezzin selection, no downloadable audio. The "Serenity" pause applies to Quran recitation only, never to the adhan.

**Can the app reliably play the FULL Adhan?**
- Foregrounded: plays like any high-importance notification sound — typically yes for the clip's duration [I], subject to the OS ringtone path and user volume (it's a *notification*, not an alarm stream — it uses `USAGE_NOTIFICATION`, verified in the channel dump [V], i.e. notification volume, not alarm volume).
- Backgrounded / process killed: the notification itself still posts (alarms verified live); sound playback follows the normal notification-ringtone path [I]. No guarantee of full clip on aggressive OEMs; the code contains nothing to improve this.
- Screen locked: same as above [I].
- Doze: exact alarms fire; notification sound at delivery [I]. Channel is not DND-exempt [V].
- **Interaction with Quran audio / other media:** none managed — the notification sound is played by the system and will simply overlay whatever is playing; no audio-focus negotiation exists for it [V]. Phone calls/silent mode/DND: system-default behavior, nothing app-side [V].

---

## 10. Prayer UI

| Surface | File | State flow |
|---|---|---|
| Home timeline (6 stations + next-prayer countdown + city name) | `home_prayer_timeline.dart` via `home_night_header.dart` | `HomeCubit.load()` → `prayerSnapshot`; refreshed on resume/route-change/progress events; countdown is a static `minutesUntil` snapshot (no ticking timer — updates only on reload) [V] |
| Prayer times sheet (all 6 times, next highlight, past check icon, countdown chip, Companion statuses + 4 action buttons) | `home_prayer_times_sheet.dart` | snapshot + optional `PrayerCompanionDaySummary`; actions → `PrayerCompanionCubit` → controller → force refresh → `onCompanionChanged` → Home reload |
| Prayer settings page (enable, country, city, method + Auto) | `settings_prayer_tiles.dart` in `prayer_settings_page.dart` | direct `PrayerTimesService` reads/writes + force refresh; no cubit |
| Notifications page prayer section (master, 5 chips, athan, exact-alarm button) | `settings_notification_tiles.dart` | `NotificationSettingsCubit` → prefs + force refresh |
| Companion settings (serenity, enable, prep/check-in/follow-up, clear history) | `prayer_companion_settings_section.dart` | direct prefs writes + force refresh |

UX findings [V]:
- **Two masters, two pages:** `prayer_times_enabled` (Prayer page) vs `notifications_prayer_times` (Notifications page). Neither page references the other; enabling alerts while the feature is disabled (or vice versa) yields silent no-ops.
- **Past prayers display a check-circle icon** purely from elapsed time (`isPast`) — visual only, but easily read as "completed"; Companion statuses are the actual completion semantics and only appear when enabled.
- **Countdown is not live** — it's recomputed on Home reload; leaving Home open across a prayer time shows a stale "next prayer" until something triggers a reload.
- **The sheet/timeline never surfaces method or timezone**, only city; a user cannot tell from the UI which method produced the displayed times (must open Prayer settings).
- **Location permission explanation:** N/A — there is no location feature at all; also no explanation that times are for the selected city rather than the device position.
- **Error/fallback states:** asset-load failure silently falls back to Makkah-only [V]; `current()` failures degrade to "no timeline" without messaging [V].
- **Dead code:** `HomePrayerChip` (superseded by the timeline) remains in `home_night_header.dart` unused [V].

---

## 11. Prayer Companion Integration

- **Shared engine [V]:** Companion plans against the same `PrayerTimesService.timesForDate` and shares the same readiness gate (`isReadyForNotificationScheduling`) — a city/method reset cancels Companion events on the same refresh path.
- **Notification actions [V]:** `action_prayer_companion_confirm` / `…_pray_now` / `…_remind_later` on channel `talia_prayer_companion`, payload `pc1|…`. Responses are intercepted by `PrayerCompanionController.handle()` *before* legacy routing: the command is persisted (owner re-stamped to the active account), notifications are force-refreshed, and navigation always lands on **Home** — never Quran, never the Adhkar page.
- **Prayer (legacy) notification actions [V]:** `action_quran` → Quran, `action_azkar` → post-prayer Adhkar hub; body tap payload `'/'` → Home.
- **"Did you pray?" follow-up logic [V]:** exists in the Companion — check-in at prayer+20 min and user-requested follow-ups (pray-now +15 / remind-later +10, max one pending per occurrence), planned by `PrayerCompanionPlanner`, surfaced as the check-in/follow-up notifications (a live one was observed firing on-device: «هل صليت الفجر؟» [V runtime]).
- **In-app status [V]:** the sheet shows per-prayer statuses and an actionable row for the in-window, unconfirmed prayer; nothing is ever inferred from elapsed time (explicit design, pinned by tests).
- **Background action caveat [V — documented in code]:** with the app killed, a Companion action tap is applied during next cold start (no hidden background handler).
- **Background-isolate owner limitation [V — documented in code]:** the headless refresh worker can't resolve the Supabase owner, so companion planning in the background falls back to the local owner scope until the app next opens.

---

## 12. Runtime Findings (observed vs assumed)

Environment: installed debug build `com.example.talia_quran` on `emulator-5554`; read-only adb inspection; `POST_NOTIFICATIONS` granted via `pm grant`; no clock changes; no UI automation beyond launching the app.

| Check | Result |
|---|---|
| Channels | `talia_prayer_times` (imp 5, system sound), `talia_prayer_times_athan` (imp 5, `android.resource://…/raw/adhan`), `talia_prayer_companion` (imp 4) + 5 others present and exactly matching code config [V] |
| Exact alarms | `dumpsys alarm` shows `RTC_WAKEUP` alarms for `ScheduledNotificationReceiver` with `window=0` (exact) at prayer/companion times (e.g. 12:45, 13:10, 16:36) and one `window=+9h` inexact (07:00 daily-ayah) — the documented exact/inexact split behaves as coded [V] |
| Live notifications | Prayer notification ids 2004/2005 on `talia_prayer_times_athan`; Companion ids 2104–2111 on `talia_prayer_companion`; a real Companion check-in fired at 05:35 («هل صليت الفجر؟») [V] |
| Boot receiver | `ScheduledNotificationBootReceiver` registered for BOOT_COMPLETED / MY_PACKAGE_REPLACED [V] |
| Merged permissions | `SCHEDULE_EXACT_ALARM` + `USE_EXACT_ALARM` + `FOREGROUND_SERVICE_SHORT_SERVICE` present in merged manifest; `USE_EXACT_ALARM` traced to the `awqat` package manifest [V] |
| Background refresh | One Workmanager `BackgroundWorker` run logged result **FAILURE** (09-19 23:58:32) — the headless refresh failed at least once on this device; Android will retry with backoff [V]. Root cause not captured (TaliaLogger output is debug-only and not in logcat for this build) |
| Flutter logs | Scheduler log lines (schedule mode, tz) were not observable via logcat in this build; runtime verification of refresh internals is therefore from `dumpsys` state, not logs [V] |
| UI walkthrough (sheet, toggles, per-prayer chips) | Not exercised via automation; covered by source trace + 14 test files [V/I] |

**Assumption checks that PASSED:** single scheduler (no competing Dart engine) [V]; tz-local fallback chain [V]; ID namespaces disjoint and budget-protected [V]; per-prayer filtering consumed by both prayer and companion scheduling [V].

---

## 13. Conflict / Duplication Risks

1. **awqat as a latent second scheduler [V — highest-confidence structural risk].** The package's manifest injects `USE_EXACT_ALARM`, its own exported `AlarmReceiver` and `BootReceiver`, and battery-exempt alarm posture, while its Dart API is unused. If awqat ever initializes any component (or an OEM treats the exported receivers as an alarm app), behavior conflicts with Talia's FLN pipeline; regardless, the merged permission posture contradicts the manifest's stated Play-policy stance. Any change here (e.g. bundling the clip ourselves and dropping the dependency) removes an entire class of conflicts.
2. **Two "enabled" switches [V]** (`prayer_times_enabled` vs `notifications_prayer_times`) on different pages, one implicitly gating the other — a genuine user-facing duplication.
3. **Per-prayer toggles serve two features [V]** (prayer alerts + Companion filtering). Intentional and currently coherent, but any future per-feature prayer filtering would fork this source of truth.
4. **Channel sound frozen at creation [V]** — the athan clip cannot be changed (e.g. swapping in a Fajr clip or different muezzin) without minting new channel IDs; the codebase already learned this once (`talia_prayer_times_athan` exists for exactly this reason).
5. **Monolith service [V]:** `notification_service.dart` is 2,036 lines owning channels + IDs + scheduling + tz + routing for every reminder category; prayer-specific logic is embedded inside it (athan details, prayer schedule/cancel, budget protection). Not a duplicate system, but a single point of accidental cross-feature damage.
6. **Per-isolate rolling gate [V]:** `_lastRollingDateKey` is in-memory; the foreground isolate and the Workmanager isolate each refresh independently. Harmless today (deterministic IDs + cancel-first), but it means "did we already schedule today?" has two answers in two processes.
7. **Serenity notification reuses the milestones channel [V]** (id 1063 on `talia_milestones`) — a prayer feature borrowing a non-prayer channel; harmless but a coupling to watch when touching channels.

---

## 14. Gap Analysis (current vs target experience)

| Target capability | Current state | Gap |
|---|---|---|
| Offline timezone-aware calculation | adhan + city IANA tz, fully offline | **None material** — city coverage (20 cities) and fiqh options only |
| Reliable prayer scheduler | FLN zonedSchedule, exact-when-allowed, cancel-first, 7-day rolling, 6-h worker refresh | Minor: no tz/time-set change listener; 6-h worst-case drift |
| Precise Android scheduling where appropriate | `exactAllowWhenIdle` + manual permission request button | `USE_EXACT_ALARM` posture is decided by a third-party manifest, not by Talia [V] |
| **Reliable full Adhan playback** | Notification channel sound (USAGE_NOTIFICATION), frozen, uncontrolled | **Major.** No full-clip guarantee, no stop control, no alarm-volume stream, no audio focus, no foreground playback, OEM-dependent |
| Proper audio focus | None for adhan (system ringtone path); audio_session used by Quran only | **Missing** |
| Lock-screen / background support | Alarms + boot receiver (good for *notification*); nothing for *audio* beyond system path | Partial for alerts; **missing for audio** |
| Reboot / timezone / location rescheduling | Reboot: plugin boot receiver [V]. Location/method changes: force refresh [V]. Timezone/time: refresh-bounded only | Timezone/time change detection **missing** |
| Per-prayer behavior | 5 chips (alerts) + Companion filter reuse | Exists; surface split across pages |
| Fajr-specific Adhan | Seam in `prayer_sound.dart` only; same clip | **Missing asset + channel strategy** |
| Muezzin selection | Not present | **Missing** (and channel-sound-freezing constrains naive implementations) |
| Prayer Companion follow-up | Fully implemented (check-in, follow-ups, cap) | Owner-scope caveat in background isolate (documented) |
| GPS / approximate location | Not present | **Missing** entirely |

---

## 15. KEEP / MODIFY / REPLACE / REMOVE / ADD Matrix

| Subsystem | Verdict | Evidence / rationale |
|---|---|---|
| `adhan` package + `PrayerTimesService` core math | **KEEP** | Correct tz anchoring, offline, readiness gates; tests pin behavior. `timesForDate`/`current()` interfaces are the stable contract used by 3 consumers |
| City dataset + auto-method-by-country | **MODIFY** | Works [V]; needs many more cities and a "nearest city" strategy once location exists |
| tz handling (calculation side) | **KEEP** | City-anchored `TZDateTime` math is correct incl. DST |
| `configureLocalTimezone()` chain | **KEEP** | Normalize→last-known→UTC is sound |
| Rolling 7-day scheduler + ID namespaces + budget protection | **KEEP** | Verified correct on-device; deterministic IDs; protected ranges |
| Exact/inexact mode resolution | **KEEP** | Works [V]; note `USE_EXACT_ALARM` posture is externally injected (see awqat) |
| Exact-permission request UX | **MODIFY** | Exists but is a buried manual button; should be offered contextually when prayer alerts are enabled |
| Boot/update rescheduling (FLN boot receiver) | **KEEP** | Registered and verified [V] |
| Timezone/time-change rescheduling | **ADD** | No listener exists [V] |
| Workmanager 6-h refresh worker | **KEEP** | Verified registered/running; one observed FAILURE (retry semantics worked as designed) |
| Adhan delivery = notification channel sound | **REPLACE** | Fundamentally cannot guarantee full playback, no stop, no focus, notification-stream volume, no foreground path. Evidence: channel dump shows `USAGE_NOTIFICATION` + frozen `raw/adhan`; zero player/audio-focus code in prayer path [V] |
| `prayer_sound.dart` mode/channel abstraction | **MODIFY** | Good seam (per-prayer clip map); retain as the source of *which* clip, feed it to the new playback layer |
| `awqat` dependency | **REMOVE (after replacement)** | Only artifact used is the mp3/caf; its manifest injects `USE_EXACT_ALARM` + exported receivers [V]. Bundling our own clips removes the dependency and the conflict |
| `talia_prayer_times_athan` channel | **MODIFY** | Keep for the notification-alert use case, but stop treating it as the Adhan player; any new clip ⇒ new channel id rule documented |
| Serenity Mode (watcher/policy) | **KEEP** | Clean, foreground-only by design, tested |
| Companion (planner/policy/records/controller) | **KEEP** | Deterministic, tested, spec-aligned; watch background owner-scope caveat |
| Companion action routing (`pc1`) | **KEEP** | Single-writer design is explicitly protected from legacy routing |
| Legacy prayer actions (`action_quran`/`action_azkar` → routes) | **KEEP** | Simple, working |
| Home timeline + sheet UI | **MODIFY** | Live countdown, method/timezone surfacing, ambiguous "past = check" icon, dual-master confusion |
| Settings split (prayer vs notification pages) | **MODIFY** | Reunify per-prayer alert controls with location/method context or cross-link the masters |
| `HomePrayerChip` | **REMOVE** | Dead code, superseded by `HomePrayerTimeline` [V] |
| Madhab (Asr) option | **ADD** | Library-supported; `_paramsFor` is the seam |
| High-latitude rule option | **ADD** | Library-supported; same seam |
| Manual minute adjustments | **ADD** | Library-supported (`PrayerAdjustments` unused) |
| GPS/approximate location + nearest-city | **ADD** | No location code exists [V] |
| Fajr-specific Adhan asset | **ADD** | Seam exists; asset + channel-id strategy needed |
| Muezzin selection / downloadable reciters | **ADD** | Nothing exists; must respect channel-sound-freezing constraint |
| Adhan stop control + audio focus | **ADD** | Nothing exists |
| Timezone/time-change listener | **ADD** | Nothing exists |

---

## 16. Safe Migration Boundaries

Interfaces that can be improved without breaking other features:

1. **Behind `PrayerTimesService`:** every consumer (scheduler, companion planner, home cubit, background worker) talks to `current()` / `timesForDate()` / readiness getters. Adding madhab/high-latitude/adjustments/GPS **inside** the service (and its city/location provider) touches no consumer, provided method strings in prefs remain compatible (unknown values already fall back to MWL [V]).
2. **Behind `resolvePrayerSound()`:** the clip-resolution seam already parameterizes channel + clip per prayer. A new playback layer can consume `ResolvedPrayerSound` while the notification path keeps using it unchanged.
3. **`schedulePrayerTimesReminders()` is additive:** the notification path can continue exactly as-is while a playback path subscribes to the same planned schedule; cancellation semantics (cancel 2000–2039) are self-contained.
4. **Channel minting rule:** any new clip/reciter ⇒ new channel ID (precedent: `talia_prayer_times_athan`). Old channels may simply remain dormant (lazy creation means unused channels never appear on fresh installs).
5. **Companion must stay owner-scoped and silent-on-failure** — its contract (planner purity, ≤1 follow-up, cancel-on-failure) is pinned by tests; the scheduler-level quiet-hours suppression point must stay at the scheduler layer.
6. **ID namespaces are frozen de facto** (2000–2039, 2100–2134, budget protection priorities). New features must pick fresh ranges.
7. **Account-reset prefix contract:** `prayer_companion_*` clearing is relied upon; new companion keys must keep the prefix. Conversely, device-level keys (city, method) must stay out of it.
8. **Do not touch** `LaunchDestination.mapNotificationAction` for companion IDs (documented single-writer rule [V]).

---

## 17. Recommended Implementation Order (sequence only — not implemented here)

1. **Harden the existing engine (low risk):** timezone/time-change-triggered refresh; contextual exact-alarm prompt; live countdown; surface city+method in the sheet; remove `HomePrayerChip`; unify/clarify the two master switches.
2. **Own the Adhan asset:** bundle clips in-app (fajr + standard), extend `prayer_sound.dart`, drop `awqat` (removes `USE_EXACT_ALARM` + foreign receivers from the merged manifest).
3. **Introduce a real Adhan playback layer** consuming the planned schedule (audio focus, stop control, alarm-stream volume, foreground playback for full clip), with the notification sound remaining as fallback; decide channel strategy per §16.4.
4. **Fiqh completeness in `PrayerTimesService`:** madhab, high-latitude rule, manual adjustments (prefs + `_paramsFor` + settings UI).
5. **Location upgrade:** location provider abstraction (GPS/approximate → nearest city from an expanded dataset), preserving the manual-city fallback and the readiness gate.
6. **Optional deepening:** muezzin selection & downloadable reciters; per-prayer alert channels if needed.

---

## MOST IMPORTANT QUESTION

**"What is the smallest safe set of changes that transforms the existing Talia Prayer + Adhan implementation into the target experience without rebuilding working functionality or creating two competing systems?"**

Derived strictly from this repository:

1. **Keep the entire existing engine.** `PrayerTimesService` (adhan 2.0.0+1, city-anchored tz), the rolling FLN scheduler with exact-when-allowed and its verified ID/budget/boot machinery, Companion, and Serenity all already satisfy the target's calculation/scheduling/companion requirements. Replacing any of these would create the second system the target forbids.
2. **Replace exactly one thing: the Adhan delivery mechanism.** Today the Adhan is a frozen notification-channel sound with no stop, no focus, and no full-clip guarantee [V]. Introduce a playback layer that consumes the *same* schedule produced by `NotificationScheduler` (via the existing `resolvePrayerSound`/`schedulePrayerTimesReminders` seams), keeps the notification as fallback, and owns audio focus + stop + foreground playback. This is the only subsystem whose current implementation fundamentally cannot reach the target.
3. **Remove exactly one thing: the `awqat` dependency** — after re-bundling its two audio files. This deletes an unused competing scheduler's manifest footprint (`USE_EXACT_ALARM`, exported receivers) that today silently overrides Talia's stated Play-policy posture.
4. **Extend, don't fork, the settings surface:** add madhab / high-latitude / adjustments inside `PrayerTimesService._paramsFor` (zero consumer impact), merge or cross-link the two "enabled" masters, and surface method+timezone in the sheet.
5. **Add only what has no foundation:** tz/time-change refresh triggers, Fajr clip (seam already reserved), and a location provider behind `PrayerTimesService` when GPS is wanted.

Everything else in the target list — reboot rescheduling, per-prayer behavior, Companion follow-up, offline calculation, exact alarms — is **already present and verified working**; the minimal path is to stop shipping a dormant second scheduler, and to move the Adhan from "notification ringtone" to "owned audio playback" while leaving the scheduler that triggers it untouched.
