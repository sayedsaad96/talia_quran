# Design Specification: Home Screen Redesign & Navigation Cleanup

- **Date:** 2026-09-12
- **Status:** Approved for Implementation Planning
- **Topic:** Home Screen Redesign, Khatmah Linkage, Redundant Navigation Elimination, and Interactive Prayer Times Expansion

---

## 1. Problem Statement & Motivation

The application's Home Screen (`HomePage`) currently suffers from four main UX and structural issues:
1. **Redundant & Duplicate Destinations:**
   - Multiple elements on the screen redirect to the same "Progress" page (`AppRoutes.progress`): the weekend contextual banner ("هذا الأسبوع" - `weeklyReflection`), the "عرض الكل" button on "نشاطك الأخير" (`HomeActivityFeed`), and the achievement chip in the header (`HomeAchievementChip`). Furthermore, "تقدمي" is already a persistent bottom navigation tab.
   - Three out of four action tiles ("استمع", "راجع", "احفظ") all navigate to the same generic `AppRoutes.memorizationHub`, which is also a main tab in the bottom bar.
2. **Improper Recitation Card Triggering ("أكمل تلاوتك"):**
   - The hero card "أكمل تلاوتك" is currently triggered whenever any Quran page is read or opened (`hasOpenedMushaf`), even if the user never started or opted into a Khatmah.
   - The user requires "أكمل تلاوتك" to be strictly associated with an active Khatmah (`activeKhatmah`). Random reading or memorization must never activate this card.
3. **Screen Clutter & Visual Overcrowding:**
   - The home screen consists of up to 9 stacked blocks, creating visual noise and repetitive interactions.
4. **Static Next-Prayer Chip:**
   - The prayer chip in the header only displays the next prayer statically without interactivity, leaving no quick way to inspect all daily prayer times, the full Hijri date, or the day of the week.

---

## 2. Goals & Success Criteria

- **Strict Khatmah Linkage:** "أكمل تلاوتك" appears ONLY if there is an active Khatmah plan (`KhatmahStatus.active`). If no active Khatmah exists, an inviting, high-aesthetic card ("ابدأ ختمتك القرآنية الآن") is displayed with a direct CTA to `AppRoutes.khatmahSetup`.
- **Zero Accidental Redirection to `/progress`:**
   - Eliminate "هذا الأسبوع" (`weeklyReflection`) from contextual slots.
   - Eliminate "عرض الكل" pointing to `/progress` from `HomeActivityFeed`.
   - Make individual activity rows interactive, jumping directly to their specific Quran page or review session.
   - Replace the header achievement chip's fallback redirection to `/progress` with an in-place `HomeAchievementSheet`.
- **Purposeful Direct Actions in `HomeActionTiles`:**
   - "استمع": Direct playback of recitation via continuous audio service.
   - "راجع": Direct transition to smart review session (`AppRoutes.memorizationV2Session`).
   - "احفظ": Direct transition to the user's active memorization practice (`AppRoutes.hifzPracticeSurah` / lesson).
   - "اقرأ": Direct transition to the user's last read page in the Quran (`/quran/page/$lastPage`).
- **Streamlined Quick Access (`HomeQuickAccess`):**
   - Only keep shortcuts not covered in the bottom navigation bar (e.g. "العلامات المرجعية" Bookmarks and Friday Kahf reminder).
- **Interactive Prayer Times & Hijri Calendar Sheet:**
   - Tapping `HomePrayerChip` opens `HomePrayerTimesSheet` with a smooth, staggered animation.
   - Displays day of the week (e.g. "الجمعة"), full Hijri date (e.g. "15 رمضان 1445 هـ"), city name, and all 6 prayer times (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) with visual indicators for past, current, and upcoming prayers.

---

## 3. Detailed Component & Architecture Design

### 3.1 Khatmah Hero & Recitation Logic
- **`ContinueRecitationMapper` (`lib/features/home/domain/services/continue_recitation_mapper.dart`):**
  - Update `map(...)`: Remove the fallback logic for regular Quran browsing (`_fromPage`, `hasOpenedMushaf`, `resumePage`).
  - Return `_fromKhatmah(...)` if and only if `activeKhatmah != null && activeKhatmah.status == KhatmahStatus.active`.
  - Otherwise, return `null`.
- **`HomeStartKhatmahCard` (New Widget):**
  - When `state.continueRecitation == null`:
    Instead of fallback to `ResumeSessionCard` / `NextBestActionCard`, display `HomeStartKhatmahCard`.
    - Design: Glass panel matching `HomeSkin`, inviting Quranic icon, headline ("ابدأ ختمتك القرآنية الآن"), subtitle encouraging daily devotion, and a prominent button ("إنشاء ختمة جديدة") navigating to `AppRoutes.khatmahSetup`.

### 3.2 Contextual Slots & Elimination of Redundancies
- **`HomeSlotKind` (`lib/features/home/domain/entities/home_contextual_slot.dart`):**
  - Deprecate or remove `HomeSlotKind.weeklyReflection`.
- **`HomeCubit` (`lib/features/home/presentation/cubits/home_cubit.dart`):**
  - Remove candidate creation for `weeklyReflection`.
- **`HomeContextualSlot` (`lib/features/home/presentation/widgets/home_contextual_slot.dart`):**
  - Remove UI rendering for `weeklyReflection`.

### 3.3 Interactive Recent Activity Feed (`HomeActivityFeed`)
- **`HomeActivityFeed` (`lib/features/home/presentation/widgets/home_activity_feed.dart`):**
  - Remove the `TextButton` ("عرض الكل") that called `context.go(AppRoutes.progress)`.
  - Wrap each `_ActivityRow` in an `InkWell`:
    - If `event.kind == ActivityEventKind.reading`: navigates to `/quran/page/${event.pageNumber ?? 1}`.
    - If `event.kind == ActivityEventKind.khatmah`: navigates to `/quran/page/${event.pageNumber ?? 1}?mode=khatmah`.
    - If `event.kind == ActivityEventKind.memorize || event.kind == ActivityEventKind.review`: navigates to `AppRoutes.hifzPracticeSurah` or `AppRoutes.memorizationV2Session`.

### 3.4 Direct Action Tiles (`HomeActionTiles`)
- Update `_ActionTile` callbacks:
  - **استمع (Listen):** If `audioResume` is available, resume via `QuranContinuousPlayerService`. Otherwise, start playback of the daily wird page or ayah of the day.
  - **راجع (Review):** Resolve target review session via `AppRoutes.memorizationV2Session` or coach recommendation.
  - **احفظ (Memorize):** Navigate directly to the user's current memorization task/surah practice via `AppRoutes.hifzPracticeSurah`.
  - **اقرأ (Read):** Navigate directly to the user's last read page (from `lastRestorableLocation` or default page 1) in the Quran reader.

### 3.5 Quick Access Optimization (`HomeQuickAccess`)
- Filter out:
  - Azkar item (already has its own primary bottom navigation tab).
  - Khatmah item (already prominent in the hero slot).
- Keep:
  - Bookmarks ("العلامات المرجعية") -> `AppRoutes.quranBookmarks`.
  - Friday Surah Al-Kahf (on Fridays before Maghrib) -> `/quran/surah/18`.

### 3.6 Header Enhancements: Achievement Sheet & Prayer Times Sheet
- **`HomeAchievementSheet` (New Widget):**
  - In `HomeAchievementChip`: When tapped and no certificate award is present, open `HomeAchievementSheet` via modal bottom sheet rather than navigating to `/progress`.
  - Displays user level title, total XP, current progress towards next level, and recently earned badges.
- **Prayer Times Service & Model Updates:**
  - In `lib/core/services/prayer_times_service.dart`:
    - Add all 6 prayer timestamps (`fajr`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`) to `PrayerTimesSnapshot`.
- **`HomePrayerTimesSheet` (New Widget):**
  - In `HomePrayerChip`: Add `onTap` to open `HomePrayerTimesSheet`.
  - Displays:
    1. Day of the week (e.g. "الجمعة") and full Hijri date formatted in Arabic (e.g. "15 رمضان 1445 هـ").
    2. Selected city name (e.g. "مكة المكرمة").
    3. Staggered animated rows for Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha.
    4. Highlight on the current/next prayer with remaining time countdown pill.
    5. Soft checkmark / muted state for prayers that have passed.

---

## 4. Verification Plan

1. **Automated Testing:**
   - Run existing unit and widget tests: `flutter test`.
   - Update `continue_recitation_mapper_test.dart` to verify that `ContinueRecitationMapper.map(...)` returns `null` when no active Khatmah is present.
   - Add/update tests for `HomePrayerTimesSheet` and `HomeStartKhatmahCard`.
2. **Static Analysis:**
   - Run `dart analyze` to verify zero analysis errors or warnings.
3. **Manual Verification:**
   - Verify that when no Khatmah exists, the "ابدأ ختمتك القرآنية الآن" card is rendered.
   - Verify that when a Khatmah is active, "أكمل تلاوتك" is rendered with correct Khatmah progress.
   - Verify that reading a random Quran page does NOT cause "أكمل تلاوتك" to appear.
   - Verify that "هذا الأسبوع" no longer appears in contextual slots.
   - Verify that tapping recent activity rows navigates to the specific page/surah.
   - Verify that tapping the prayer chip opens the full prayer times sheet with Hijri date and weekday.
   - Verify that tapping the achievement chip opens the in-place achievement sheet.
