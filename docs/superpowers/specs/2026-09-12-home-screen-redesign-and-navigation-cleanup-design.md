# Design Specification: Home Screen Redesign & Navigation Cleanup (Revised)

- **Date:** 2026-09-12
- **Status:** Approved for Implementation Planning
- **Topic:** Home Screen Redesign, Khatmah Linkage, Redundant Navigation Elimination, and Interactive Prayer Times Expansion

---

## 1. Problem Statement & Motivation

The application's Home Screen (`HomePage`) currently suffers from four main UX and architectural issues:
1. **Redundant & Duplicate Destinations:**
   - There are **five** distinct paths that lead to the "Progress" page (`AppRoutes.progress`), creating redundancy and confusing navigation:
     1. The weekend contextual banner ("هذا الأسبوع" - `weeklyReflection` in `home_cubit.dart:593`).
     2. The "عرض الكل" text button in "نشاطك الأخير" (`home_activity_feed.dart:52`).
     3. The fallback redirect in `HomeAchievementChip` (`home_context_bar.dart:247`).
     4. The `onTap` action in `HomeMomentumStrip` (`home_momentum_strip.dart:50`).
     5. The dedicated, persistent "تقدمي" tab in the bottom navigation bar (`BottomNavigationBar`).
   - Three out of four action tiles ("استمع", "راجع", "احفظ" in `home_action_tiles.dart`) all navigate to the same generic `AppRoutes.memorizationHub`, which is also a main tab in the bottom bar.
2. **Improper Recitation Card Triggering ("أكمل تلاوتك"):**
   - The hero card "أكمل تلاوتك" is currently triggered whenever any Quran page is read or opened (`hasOpenedMushaf` in `ContinueRecitationMapper`), even if the user never started or opted into a Khatmah.
   - The user requires "أكمل تلاوتك" to be strictly associated with an active Khatmah (`activeKhatmah`). Random reading or memorization must never activate this card.
3. **Screen Clutter & Visual Overcrowding:**
   - The home screen consists of up to 9 stacked blocks, creating visual noise and repetitive interactions.
4. **Static Next-Prayer Chip:**
   - The prayer chip in the header (`HomePrayerChip` in `home_night_header.dart`) only displays the next prayer statically without interactivity, leaving no quick way to inspect all daily prayer times, the full Hijri date, or the day of the week.

---

## 2. Goals & Success Criteria

- **Strict Khatmah Linkage:** "أكمل تلاوتك" appears ONLY if there is an active Khatmah plan (`KhatmahStatus.active`). If no active Khatmah exists, an inviting, high-aesthetic card ("ابدأ ختمتك القرآنية الآن") is displayed with a direct CTA to `AppRoutes.khatmahSetup`.
- **Zero Accidental Redirection to `/progress`:**
   - Completely eliminate all 4 accidental shortcuts to `AppRoutes.progress`:
     1. Delete `weeklyReflection` slot from `HomeCubit` and `HomeContextualSlot`.
     2. Delete "عرض الكل" button from `HomeActivityFeed`.
     3. Replace `HomeAchievementChip` fallback in `home_context_bar.dart` with an in-place `HomeAchievementSheet`.
     4. Replace or remove `HomeMomentumStrip`'s `context.go(AppRoutes.progress)`.
   - The "تقدمي" bottom navigation tab remains the single, deliberate destination for overall progress.
- **Hero Action Contract (Smart Priority - Option A):**
   - If active Khatmah exists: Hero displays `HomeContinueCard` for Khatmah.
   - If NO active Khatmah:
     - If `UnifiedJourneyEngine` has high-priority learning tasks (active session, critical learning alert, overdue review backlog, or smart plan): Hero renders `HomeHeroSection` to safeguard learning momentum, and `HomeStartKhatmahCard` is rendered as an inspiring contextual card.
     - If no urgent learning alerts: Hero renders `HomeStartKhatmahCard`.
- **Purposeful Direct Actions in `HomeActionTiles`:**
   - "استمع": Direct playback of recitation via continuous audio service.
   - "راجع": Direct transition to smart review session (`AppRoutes.memorizationV2Session`).
   - "احفظ": Direct transition to active memorization practice (`AppRoutes.hifzPracticeSurah`).
   - "اقرأ": Direct transition to last read page in the Quran (or `AppRoutes.quran` reader).
- **Streamlined Quick Access (`HomeQuickAccess`):**
   - Keep dynamic time-of-day Azkar chip (Morning before 12, Evening after 16, General otherwise).
   - Keep Bookmarks ("العلامات المرجعية" -> `AppRoutes.quranBookmarks`).
   - Keep Friday Surah Al-Kahf on Fridays before sunset (`/quran/surah/18`).
- **Interactive Prayer Times & Hijri Calendar Sheet:**
   - Tapping `HomePrayerChip` opens `HomePrayerTimesSheet` with a smooth, staggered animation.
   - Displays day of the week (e.g. "الجمعة"), full Hijri date (e.g. "15 رمضان 1445 هـ"), city name, and all 6 prayer times (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) with visual indicators for past, current, and upcoming prayers.
- **Strict Localization:**
   - All new strings must be added to both `app_ar.arb` and `app_en.arb`. Zero hardcoded strings.

---

## 3. Detailed Component & Architecture Design

### 3.1 Khatmah Hero & Recitation Logic
- **`ContinueRecitationMapper` (`lib/features/home/domain/services/continue_recitation_mapper.dart`):**
  - Update `map(...)`: Remove the fallback chain for regular Quran browsing (`_fromPage`, `hasOpenedMushaf`, `resumePage`).
  - Return `_fromKhatmah(...)` if and only if `activeKhatmah != null && activeKhatmah.status == KhatmahStatus.active`.
  - Otherwise, return `null`.
- **`HomeStartKhatmahCard` (New Widget in `lib/features/home/presentation/widgets/home_start_khatmah_card.dart`):**
  - Glass panel matching `HomeSkin`, inviting Quranic icon, headline (`homeStartKhatmahTitle`), subtitle (`homeStartKhatmahSubtitle`), and CTA button navigating to `AppRoutes.khatmahSetup`.

### 3.2 Hero Action Contract & `_PrimaryAction` (`lib/features/home/presentation/pages/home_page.dart`)
- Update `HomePage` and `_PrimaryAction`:
  1. If `state.continueRecitation != null`: Render `HomeContinueCard(recitation: state.continueRecitation!)`.
  2. If `state.continueRecitation == null`:
     - Evaluate `state.heroAction`:
       - If `state.heroAction != null` and `state.heroAction!.priority.index <= UnifiedJourneyPriority.p4SmartPlan.index` (i.e. `p1ActiveSession`, `p2CriticalAlert`, `p3ReviewBacklog`, or `p4SmartPlan`):
         Render `_PrimaryAction` (which displays `HomeHeroSection`) to preserve the Smart Coach / Unified Journey flagship feature.
       - Otherwise: Render `HomeStartKhatmahCard`.
     - In case `HomeHeroSection` is rendered above, offer `HomeStartKhatmahCard` as an inspiring card below it so the user still has an immediate invitation to start a Khatmah.
- **`HomePrimaryActionResolver` (New, Pure):** Extract the decision above into a pure, unit-testable resolver in `lib/features/home/domain/services/home_primary_action_resolver.dart` that takes (`continueRecitation`, `heroAction`, `unifiedJourneyEnabled`) and returns a sealed kind (`khatmahContinue`, `journeyHero`, `startKhatmah`). `HomePage`/`_PrimaryAction` consume it; no branching logic stays inline in the widget.
- **Legacy Cards (`ResumeSessionCard` / `NextBestActionCard`):** Both remain the flag-off fallback: when `JourneyFeatureFlags.unifiedJourneyEnabled == false`, `_PrimaryAction` keeps its current `lastRestorableLocation → ResumeSessionCard → NextBestActionCard` chain, and the existing suites `smart_coach_home_validation_test.dart` and `responsive_home_widgets_test.dart` must keep passing unmodified. They are never rendered when the flag is on.

### 3.3 Contextual Slots & Elimination of Redundancies
- **`HomeSlotKind` (`lib/features/home/domain/entities/home_contextual_slot.dart`):**
  - Deprecate or remove `HomeSlotKind.weeklyReflection`.
- **`HomeCubit` (`lib/features/home/presentation/cubits/home_cubit.dart`):**
  - Remove candidate generation for `weeklyReflection` (line 590-595).
- **`HomeContextualSlot` (`lib/features/home/presentation/widgets/home_contextual_slot.dart`):**
  - Remove UI cases for `weeklyReflection`.
- **`HomeMomentumStrip` (`lib/features/home/presentation/widgets/home_momentum_strip.dart`):**
  - Remove `onTap: () => context.go(AppRoutes.progress)` (line 50) and make it an informative, non-redirecting card (streak stats only; no celebration sheet — streak celebration is already covered by `HomeAchievementSheet` in §3.7).

### 3.4 Interactive Recent Activity Feed (`lib/features/home/presentation/widgets/home_activity_feed.dart`)
- Remove the `TextButton` ("عرض الكل") that called `context.go(AppRoutes.progress)`.
- Wrap each `_ActivityRow` in an `InkWell` with unambiguous direct routing:
  - `ActivityEventKind.reading`:
    If `event.pageNumber != null`: navigate to `/quran/page/${event.pageNumber}`.
    Else if `event.surahId != null`: navigate to `/quran/surah/${event.surahId}`.
    Else: navigate to `AppRoutes.quran`.
  - `ActivityEventKind.khatmah`:
    Navigate to `/quran/page/${event.pageNumber ?? state.activeKhatmah?.nextUnreadPage ?? 1}?mode=khatmah` (fall back to the active khatmah's next unread page, mirroring the cubit's reading-route resolution — never silently jump to Al-Fatiha).
  - `ActivityEventKind.memorize`:
    If `event.surahId != null`: navigate to `AppRoutes.hifzPracticeSurah` with surah context or `AppRoutes.memorizationHub`.
    Else: navigate to `AppRoutes.memorizationHub`.
  - `ActivityEventKind.review`:
    Navigate to `AppRoutes.memorizationV2Session`.

### 3.5 Direct Action Tiles (`lib/features/home/presentation/widgets/home_action_tiles.dart`)
- **استمع (Listen):**
  - If `state.audioResume != null`: resume via `getIt<QuranContinuousPlayerService>().playAyah(...)`.
  - Else: start playback from `state.ayahOfDay` (available on `HomeLoaded`); the daily wird page is not directly exposed to presentation and must not be assumed.
- **راجع (Review):**
  - Navigate directly to `AppRoutes.memorizationV2Session`.
- **احفظ (Memorize):**
  - Navigate directly to `AppRoutes.hifzPracticeSurah`.
- **اقرأ (Read):**
  - If `state.lastRestorableLocation != null && state.lastRestorableLocation!.startsWith('/quran/page/')`:
    Navigate to `state.lastRestorableLocation!`.
  - Else: Navigate to `AppRoutes.quran` (which automatically opens the reader at the user's last saved position).

### 3.6 Quick Access Optimization (`lib/features/home/presentation/widgets/home_quick_access.dart`)
- Preserve 2-3 dynamic, high-value chips:
  1. Bookmarks: `AppRoutes.quranBookmarks`.
  2. Dynamic Time-of-Day Azkar: `/azkar/morning` (morning), `/azkar/evening` (evening), `/azkar/general` (night).
  3. Friday Surah Al-Kahf (on Fridays before 18:00): `/quran/surah/18`.
- Exclude redundant static links to Khatmah (handled in Hero) and generic Azkar tab.

### 3.7 Header Enhancements: Achievement Sheet & Prayer Times Sheet
- **`HomeAchievementChip` (`lib/features/home/presentation/widgets/home_context_bar.dart`):**
  - When tapped: If certificate available, open `AppRoutes.certificate`.
  - If NO certificate available: Instead of `context.go(AppRoutes.progress)`, show `HomeAchievementSheet(progress: state.progress, isKids: state.isKids)`.
- **`HomeAchievementSheet` (New Widget in `lib/features/home/presentation/widgets/home_achievement_sheet.dart`):**
  - Displays user rank/level title, total XP, current progress toward next milestone, and list of earned/in-progress badges.
  - Data source: thread `state.totalXp` into the chip/sheet and derive the level via `XpService.getCurrentLevel(totalXp)` + its exposed `progressToNextLevel` — do not re-derive level thresholds from `XpConstants`.
- **`PrayerTimesService` & Model (`lib/core/services/prayer_times_service.dart`):**
  - Update `PrayerTimesSnapshot` to include all 6 prayer times:
    `final Map<String, DateTime> allTimes;`
    Or explicit fields: `fajr`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`.
  - Fill all 6 times from the computed `PrayerTimes` instance.
- **`HomePrayerChip` (`lib/features/home/presentation/widgets/home_night_header.dart`):**
  - Wire `onTap` to open `HomePrayerTimesSheet`.
- **`HomePrayerTimesSheet` (New Widget in `lib/features/home/presentation/widgets/home_prayer_times_sheet.dart`):**
  - Smooth animated entrance (staggered slide & fade).
  - Displays:
    1. Day of the week (e.g. "الجمعة") and full Hijri date formatted in Arabic (`state.hijriLabel`) + city name (`snapshot.city.nameAr`).
    2. All 6 prayer times with their Arabic names and formatted 12-hour times.
    3. Highlight on the current/next prayer with gold border, glow, and remaining minutes countdown badge.
    4. Soft muted checkmark icon for prayers whose times have passed.

---

## 4. Verification Plan

1. **Automated Unit & Regression Tests:**
   - `test/features/home/domain/services/continue_recitation_mapper_test.dart`:
     - Test that active Khatmah returns `ContinueRecitation` with `mode=khatmah`.
     - Regression test: Test that opening a random Quran page without an active Khatmah returns `null`.
     - Regression test: Test that reading confirmed pages without an active Khatmah returns `null`.
   - `test/features/home/presentation/cubits/home_cubit_test.dart`:
     - Test that `weeklyReflection` is never generated in `activeSlot`.
   - `test/core/services/prayer_times_service_test.dart`:
     - Test that `PrayerTimesSnapshot` includes all 6 prayer times.
   - `test/features/home/domain/services/home_primary_action_resolver_test.dart`:
     - Active khatmah → `khatmahContinue` (regardless of heroAction).
     - p1–p4 heroAction, no khatmah → `journeyHero` (with `HomeStartKhatmahCard` rendered below).
     - p5/p6 heroAction, no khatmah → `startKhatmah`.
   - Widget tests for `HomePrayerTimesSheet` (renders 6 rows, Hijri date, city name, next-prayer highlight) and `HomeStartKhatmahCard` (CTA routes to `AppRoutes.khatmahSetup`).
   - Run `flutter test` to ensure all tests pass (including the existing `ResumeSessionCard`/`NextBestActionCard` suites under the flag-off path).
2. **Static Analysis:**
   - Run `dart analyze` to ensure zero errors or warnings.
3. **Manual / Functional Verification:**
   - Verify that when no Khatmah exists, "ابدأ ختمتك القرآنية الآن" card is visible.
   - Verify that when a Khatmah is active, "أكمل تلاوتك" displays correct target and progress.
   - Verify that tapping "عرض الكل" or "هذا الأسبوع" no longer occurs or redirects to `/progress`.
   - Verify that tapping activity feed items routes directly to the specific page or review.
   - Verify that tapping `HomePrayerChip` opens the animated sheet with all 6 times, Hijri date, and day of week.
   - Verify that tapping `HomeAchievementChip` opens the in-place achievement sheet without jumping to the progress tab.
