# Quran Khatmah Plan, Reader Context Isolation, and Khatm Du'a Design

Date: 2026-09-02  
Status: Approved Design — Ready for Implementation Plan  
Review: Passed (8 critical gaps resolved, 5 improvements incorporated)

---

## 1. Context & Problem Statement

Talia is an offline-first Quran companion. While memorization (`features/memorization_plus`) has structured learning paths, users who select **Quran Reading** (`OnboardingGoal.reading`) currently lack a dedicated, structured completion journey:
1. **No Khatmah Journey:** Daily reading was previously simulated by selecting a pseudo-random page daily, rather than supporting a structured, sequential Khatmah (1 to 604 pages).
2. **Lack of Session Isolation:** Previously, reading any Surah (e.g. Surah Al-Kahf on Friday) would record pages into general storage (`read_pages`), risking unintended shifts in the user's reading position.
3. **No Dedication Support:** Users often intend their Quran completion as a dedicated gift/supplication for parents, loved ones, deceased relatives, or sick family members.
4. **No Completion Milestone & Du'a:** There is no authentic, verified Du'a Khatm al-Quran presented upon finishing page 604, nor an archived history of past Khatmahs.

---

## 2. Core Architectural Principle: Complete Context Isolation

A core requirement is the **absolute separation of concerns** between three distinct reading behaviors:

```
+------------------------------------------------------------------------+
|                        Talia Reading Contexts                          |
+----------------------+------------------------+------------------------+
| 1. Free Quran Reading| 2. General Daily Wird  | 3. Khatmah Track       |
|    (Free browsing)   |    (Independent habit)  |    (Structured plan)   |
+----------------------+------------------------+------------------------+
| - Browsing any Surah | - Independent daily    | - Dedicated plan (1..  |
| - Surah Al-Kahf, etc.|   habit                |   604 pages)           |
| - Updates last       | - Does not disrupt or  | - Explicit session mode|
|   general location   |   advance Khatmah      | - Only Khatmah mode    |
| - NEVER affects      | - Independent tracking |   advances progress    |
|   Khatmah progress   |                        | - Isolated persistence |
| - Counts toward      |                        | - Does NOT update      |
|   streak             |                        |   lastRestorableLocation|
|                      |                        | - Counts toward streak |
+----------------------+------------------------+------------------------+
```

---

## 3. Data Models & Entities (`features/khatmah/domain/entities`)

### 3.1 `DedicationCondition` (enum)
```dart
enum DedicationCondition { alive, deceased, sick }
```

### 3.2 `KhatmahDedication`
Captures the intention and dedication of the Khatmah:
- `isDedicated` (`bool`): Whether the Khatmah is dedicated to someone else.
- `recipientName` (`String?`): Name of the individual (e.g., "Ahmad"). Nullable when `isDedicated == false`.
- `relationship` (`String?`): Relationship label. Nullable when `isDedicated == false`.
- `condition` (`DedicationCondition?`): Nullable when `isDedicated == false`.
- `customNote` (`String?`): Optional personal intention note.

### 3.3 `KhatmahStatus` (enum)
```dart
enum KhatmahStatus { active, paused, completed }
```

### 3.4 `KhatmahPlan`
Represents the active Khatmah state and schedule:
- `id` (`String`): Unique identifier (UUID).
- `title` (`String`): Descriptive name (auto-generated from dedication or user-provided).
- `startPage` (`int`): Default 1.
- `currentPage` (`int`): Last completed page in this Khatmah (0 = no pages read yet, 1..604).
- `targetPagesPerDay` (`int`): Daily page quota (e.g., 2, 4, 10, 20).
- `targetDays` (`int`): Target duration in days.
- `startDate` (`DateTime`): Timestamp when plan was created/started.
- `expectedEndDate` (`DateTime`): Target completion date.
- `status` (`KhatmahStatus`): `active`, `paused`, `completed`.
- `dedication` (`KhatmahDedication`): Dedication details.
- `lastReadDate` (`DateTime?`): Date of the most recent reading session.
- `pausedAt` (`DateTime?`): When the plan was paused (null if active/completed).

**Computed getters (not persisted):**
```dart
int get completedPagesCount => currentPage < startPage ? 0 : currentPage - startPage + 1;
double get progressPercentage => completedPagesCount / 604;
int get remainingPages => 604 - currentPage;
```

### 3.5 `KhatmahHistoryEntry`
Archival entry for completed Khatmahs:
- `id` (`String`): Entry ID.
- `khatmahNumber` (`int`): Ordinal Khatmah number (1, 2, 3...).
- `title` (`String`): Title of the completed Khatmah.
- `startDate` (`DateTime`): Start date.
- `completedDate` (`DateTime`): Finish date.
- `totalDays` (`int`): Days taken.
- `dedication` (`KhatmahDedication?`): Dedication metadata.
- `certificateId` (`String?`): Generated milestone certificate ID.

---

## 4. Calculation & Adaptive Scheduling Engine

### 4.1 Dual-Directional Plan Setup
1. **By Pages Per Day:**
   - Quick presets: 2 pages (~302 days), 4 pages (~151 days), 10 pages (~60 days), 20 pages / 1 Juz (~30 days), or custom input.
   - Days Remaining = ceil((604 - currentPage) / pagesPerDay).
   - Expected End Date = today + Days Remaining.
2. **By Target Duration or Date:**
   - Presets: 30 days, 60 days, 90 days, 180 days, 365 days, or specific calendar date (e.g., first Ramadan).
   - Daily Pages = ceil((604 - currentPage) / targetDays).

### 4.2 Today's Wird Computation
- wirdStartPage = currentPage + 1.
- wirdEndPage = min(wirdStartPage + targetPagesPerDay - 1, 604).
- Range displayed: "Khatmah wird today: pages {wirdStartPage} to {wirdEndPage}".

### 4.3 Gentle Adaptive Catch-Up (Non-Judgmental)
When days are missed, no red alerts or negative feedback are presented. The UI provides two one-tap remedies:
1. **Calm Adjustment:** Keep the same comfortable daily pages, smoothly extending the expected completion date. Formula: `expectedEndDate = today + ceil(remainingPages / targetPagesPerDay)`.
2. **Mild Compensation:** Add 1 or 2 extra pages per day until back on original schedule.

### 4.4 Pause / Resume Behavior
- When paused: `pausedAt` is set to current timestamp. The daily wird stops showing. `expectedEndDate` is frozen.
- When resumed: `expectedEndDate` is recalculated as `today + ceil(remainingPages / targetPagesPerDay)`. `pausedAt` is cleared.

### 4.5 Physical Mushaf Manual Logging
A simple interface in the Khatmah dashboard: a page-number input (with +/- stepper or direct entry) allowing users who read from a physical paper Mushaf to set `currentPage` in one tap.

---

## 5. Reader Mode & Context Isolation

### 5.1 Route Parameterization
Uses the **existing** reader route with an optional query parameter:
- **Free Reading Route:** `/quran/page/:pageNumber` (default, no query param or `mode=free`).
- **Khatmah Reading Route:** `/quran/page/:pageNumber?mode=khatmah`.

The `QuranReaderPage` constructor gains a new optional parameter:
```dart
class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage({
    super.key,
    this.surahId,
    this.pageNumber,
    this.readerMode = QuranReaderMode.free, // NEW
  });
  final int? surahId;
  final int? pageNumber;
  final QuranReaderMode readerMode; // NEW
}

enum QuranReaderMode { free, khatmah }
```

Router change in `app_router.dart`:
```dart
GoRoute(
  path: '/quran/page/:pageNumber',
  builder: (context, state) {
    final pageNumber = int.tryParse(state.pathParameters['pageNumber'] ?? '1') ?? 1;
    final mode = state.uri.queryParameters['mode'] == 'khatmah'
        ? QuranReaderMode.khatmah
        : QuranReaderMode.free;
    return QuranReaderPage(pageNumber: pageNumber, readerMode: mode);
  },
),
```

### 5.2 Visual Reader Experience (`mode=khatmah`)
- A non-intrusive, serene header pill (KhatmahReaderSessionBar widget):
  - "Khatmah session [dedicated to: ...] -- page {current} ({index} of {dailyTarget} of today's wird)"
- Quick action: "Save and exit" (Save and exit session).
- The header bar reads the active `KhatmahPlan` from the `KhatmahCubit` provided above in the widget tree.

### 5.3 Confirmation & Progress Hook (Decorator Pattern)
When `QuranPageCubit.confirmRead()` is called:
1. It always calls `SaveReadPageUsecase` (records page in general `read_pages` for progress stats).
2. It always calls `StreakService.recordActivity()` (counts toward streak).
3. **NEW:** If `readerMode == khatmah`, it additionally calls `UpdateKhatmahProgressUsecase` which:
   - Advances `KhatmahPlan.currentPage` to the confirmed page number.
   - Checks if `currentPage >= wirdEndPage` and emits a "wird completed" event.
   - Checks if `currentPage == 604` and emits a "khatmah completed" event.

```dart
// Inside QuranPageCubit.confirmRead():
if (_readerMode == QuranReaderMode.khatmah) {
  await _updateKhatmahProgress(pageNumber);
}
```

### 5.4 `lastRestorableLocation` Protection
In `mode=khatmah`, the reader does **NOT** call `AppSessionService.setLastRestorableLocation()`. This ensures free-reading resume position is never overwritten by khatmah progress. The khatmah's own position is tracked independently in `KhatmahPlan.currentPage`.

---

## 6. Home Page Integration

### 6.1 HomeLoaded State Extension
`HomeLoaded` gains a new field:
```dart
final KhatmahPlan? activeKhatmah; // loaded from KhatmahRepository
```

`HomeCubit.load()` additionally calls `GetActiveKhatmahUsecase` and includes the result in `HomeLoaded`.

### 6.2 Khatmah Hero Card Placement
- **If an active khatmah exists:** `KhatmahHeroCard` renders immediately after the main `UnifiedHeroActionCard` (if present), before the daily wird and quick-action chips.
- **If no khatmah exists and user goal is `reading`:** A promotional card "Start your first Khatmah" appears in the same position, linking to `KhatmahSetupPage`.
- The khatmah hero card is **independent** from `UnifiedJourneyEngine` — it does not compete with memorization priorities.

### 6.3 Onboarding Integration
The onboarding flow remains **2 steps** (unchanged). Instead:
- After onboarding completes for a user with `OnboardingGoal.reading`, the home page shows the "Start your first Khatmah" promotional card on first visit.
- This avoids complicating the onboarding flow while still guiding reading-goal users toward the khatmah feature.

---

## 7. Completion Flow & Du'a Khatm al-Quran

### 7.1 Reaching Page 604
Confirming page 604 in Khatmah mode triggers the celebratory completion sequence:
1. **Celebratory Screen (`KhatmahCompletionPage`):**
   - Islamic geometry decoration, warm gold accents, Amiri calligraphy.
   - Congratulatory message.
   - Summary: start date, completion date, days taken.
   - Prominent dedication section if dedicated.
2. **Du'a Khatm al-Quran:**
   - Text sourced from the printed du'a at the end of the King Fahd Complex Mushaf.
   - **Content classification:** `tier: guidance` (per `09_dua.md` — this du'a is not a Quranic verse or an authenticated prophetic hadith; it is a widely-used scholarly supplication printed in the Mushaf appendix).
   - **Storage:** `assets/data/khatm_dua.json` containing:
     ```json
     {
       "tier": "guidance",
       "source": "King Fahd Complex Mushaf (appendix)",
       "sourceNote": "Widely-used du'a printed at the end of the Mushaf; not a prophetic hadith.",
       "arabicText": "...(full diacritized text)...",
       "transliteration": null,
       "translation_en": null,
       "dedicationInserts": {
         "deceased": "...",
         "sick": "...",
         "alive": "..."
       }
     }
     ```
   - Dynamic dedication supplication paragraph inserted based on `DedicationCondition`.
   - Typography controls: font size scaler, full diacritics, copy/share passages.
3. **Archiving & Next Steps:**
   - Archiving entry into `KhatmahHistory`.
   - Milestone certificate via existing `CertificateAward` with new type `khatmahReading`.
   - Share card via `SocialShareSheet` with new category `SocialShareCategory.khatmah`.
   - CTA: "Start a new Khatmah".

### 7.2 Permanent Access to Du'a
- A permanent route `/quran/khatm-dua` accessible from the Quran index/drawer.
- Also accessible from the Khatmah dashboard and history entries.

---

## 8. Integration with Existing Systems

### 8.1 Streak Integration
Reading in khatmah mode calls `StreakService.recordActivity()` — same as free reading. Khatmah reading counts toward the daily streak.

### 8.2 Social Share Integration
Add `khatmah` to `SocialShareCategory` enum and create `SocialShareData.khatmah()` factory:
```dart
SocialShareData.khatmah({
  required int khatmahNumber,
  required int totalDays,
  required KhatmahDedication? dedication,
  String? userName,
})
```

### 8.3 Certificate Integration
Add `khatmahReading` to `CertificateType` enum (distinct from existing `fullQuran` which is for memorization). The `AchievementService` checks for khatmah completion and issues the certificate.

### 8.4 Notification Integration (Optional)
An optional daily reminder scheduled via `NotificationScheduler`:
- Default: disabled.
- User can enable it from the khatmah dashboard.
- Notification text: gentle reminder with today's wird range.

### 8.5 Cloud Sync (Deferred to V2)
- **V1 (this phase):** Local-only storage via SharedPreferences (JSON serialization, same pattern as `MemorizationPlansStorageMixin`).
- **Preparation:** Add `khatmah_cloud_dirty` flag in SharedPreferences from day one. Set to `true` on any khatmah data mutation. This allows V2 cloud sync to know what needs pushing without any V1 migration.
- **V2 (future):** Supabase table `khatmah_plans` with the same dirty-flag sync pattern used by `PlanCloudDirtyKeys`.

---

## 9. Directory Structure & Architecture

```
lib/features/khatmah/
+-- data/
|   +-- datasources/
|   |   +-- khatmah_local_datasource.dart
|   |   +-- khatm_dua_datasource.dart
|   +-- models/
|   |   +-- khatmah_plan_model.dart          (toJson/fromJson)
|   |   +-- khatmah_dedication_model.dart    (toJson/fromJson)
|   |   +-- khatmah_history_model.dart       (toJson/fromJson)
|   +-- repositories/
|       +-- khatmah_repository_impl.dart
+-- domain/
|   +-- entities/
|   |   +-- khatmah_plan.dart
|   |   +-- khatmah_dedication.dart
|   |   +-- khatmah_history_entry.dart
|   |   +-- khatmah_scheduling_engine.dart   (pure calculation logic)
|   +-- repositories/
|   |   +-- khatmah_repository.dart          (abstract)
|   +-- usecases/
|       +-- get_active_khatmah_usecase.dart
|       +-- create_khatmah_usecase.dart
|       +-- update_khatmah_progress_usecase.dart
|       +-- complete_khatmah_usecase.dart
|       +-- get_khatm_dua_usecase.dart
|       +-- pause_resume_khatmah_usecase.dart
+-- presentation/
    +-- cubits/
    |   +-- khatmah_cubit.dart
    |   +-- khatmah_setup_cubit.dart
    |   +-- khatm_dua_cubit.dart
    +-- pages/
    |   +-- khatmah_setup_page.dart
    |   +-- khatmah_dashboard_page.dart
    |   +-- khatmah_completion_page.dart
    |   +-- khatm_dua_page.dart
    +-- widgets/
        +-- khatmah_hero_card.dart
        +-- khatmah_progress_gauge.dart
        +-- khatmah_dedication_form.dart
        +-- khatmah_reader_session_bar.dart

assets/data/
+-- khatm_dua.json                           (NEW: du'a text with source metadata)
```

**Files modified in existing features:**
- `lib/core/router/app_router.dart` — add khatmah routes, add `mode` query param to reader route.
- `lib/features/quran/presentation/pages/quran_reader_page.dart` — add `readerMode` param, conditional session bar, conditional `lastRestorableLocation` write.
- `lib/features/quran/presentation/cubits/quran_page_cubit.dart` — add khatmah progress hook in `confirmRead()`.
- `lib/features/home/presentation/cubits/home_cubit.dart` — load active khatmah.
- `lib/features/home/presentation/cubits/home_state.dart` — add `activeKhatmah` field.
- `lib/features/home/presentation/pages/home_page.dart` — render `KhatmahHeroCard`.
- `lib/core/di/injection.dart` — register khatmah datasource, repository, usecases, cubits.
- `lib/core/widgets/social_share/social_share_model.dart` — add `khatmah` category.
- `lib/features/certificate/domain/entities/certificate_award.dart` — add `khatmahReading` type.
- `lib/core/l10n/app_ar.arb` and `app_en.arb` — add ~30 new localization keys.

---

## 10. Verification Strategy

1. **Unit Tests:**
   - `KhatmahSchedulingEngine` — page counts, remaining days, date projections, pause/resume recalculation.
   - Entity serialization round-trip (toJson/fromJson).
   - Storage isolation test: khatmah progress does not affect `read_pages` list.
   - Dedication supplication formatter tests for all 3 conditions.
2. **Widget Tests:**
   - Setup wizard interaction (pages/day selection, date selection, dedication toggle).
   - KhatmahHeroCard rendering with/without active plan.
   - KhatmahReaderSessionBar rendering and wird progress display.
   - Du'a screen rendering, font scale changes, copy actions.
3. **Integration Verification:**
   - Verify `lastRestorableLocation` is NOT written in khatmah mode.
   - Verify free reading does NOT advance khatmah `currentPage`.
   - Verify page 604 confirmation in khatmah mode triggers completion flow.
   - Connect via `dtd` tool and execute `hot_reload` after edits.
