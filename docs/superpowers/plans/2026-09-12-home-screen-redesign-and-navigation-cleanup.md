# Home Screen Redesign & Navigation Cleanup Implementation Plan (Updated)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Home Screen to strictly link "أكمل تلاوتك" to active Khatmah plans, eliminate all 5 accidental redirections to the progress page, extract a pure `HomePrimaryActionResolver` for the smart priority hero contract, turn action tiles into direct execution links, optimize quick access, and add an interactive animated prayer times sheet with full Hijri calendar data.

**Architecture:** 
- Strict Khatmah mapping in `ContinueRecitationMapper` returning null when no active Khatmah exists.
- Pure `HomePrimaryActionResolver` in `lib/features/home/domain/services/home_primary_action_resolver.dart` deciding between `khatmahContinue`, `journeyHero` (with contextual `startKhatmah`), and `startKhatmah`.
- Preserved flag-off fallback for `ResumeSessionCard` / `NextBestActionCard` when `JourneyFeatureFlags.unifiedJourneyEnabled == false` to keep existing validation suites passing.
- Redundant `/progress` route elimination across `HomeCubit`, `HomeContextualSlot`, `HomeActivityFeed`, `HomeContextBar`, and `HomeMomentumStrip` (informative stats only).
- Extended `PrayerTimesSnapshot` with all 6 daily prayer times rendered in an animated `HomePrayerTimesSheet`.
- Dual localization (`app_ar.arb` and `app_en.arb`) for all new user-facing strings.
- Derived XP levels in `HomeAchievementSheet` via `XpService.getCurrentLevel` and `XpService.progressToNextLevel`.

**Tech Stack:** Flutter, Dart, BLoC (`flutter_bloc`), `adhan` package, `go_router`, `shared_preferences`, `intl`.

## Global Constraints

- Never hardcode Arabic or English user-facing text; always update both `app_ar.arb` and `app_en.arb`.
- Preserve existing comments and docstrings.
- Follow Clean Code, SOLID, DRY, and KISS principles.
- Run `flutter test` and `dart analyze` to guarantee zero errors or warnings.
- Keep legacy flag-off suites (`smart_coach_home_validation_test.dart` and `responsive_home_widgets_test.dart`) passing unmodified.

---

### Task 1: Localization, XpService & PrayerTimesService Enhancement

**Files:**
- Modify: `lib/core/l10n/app_ar.arb`
- Modify: `lib/core/l10n/app_en.arb`
- Modify: `lib/core/services/prayer_times_service.dart`
- Modify: `lib/core/services/xp_service.dart`
- Test: `test/core/services/prayer_times_service_test.dart`
- Test: `test/core/services/xp_service_test.dart`

**Interfaces:**
- Produces: 
  - `PrayerTimesSnapshot.allTimes`: `Map<String, DateTime>` mapping `'fajr'`, `'sunrise'`, `'dhuhr'`, `'asr'`, `'maghrib'`, `'isha'` to their calculated times.
  - `XpService.progressToNextLevel(int xp)`: public method exposing progress ratio towards the next level `(0.0..1.0)`.
  - Localization keys: `homeStartKhatmahTitle`, `homeStartKhatmahSubtitle`, `homeStartKhatmahAction`, `homePrayerTimesSheetTitle`, `homeAchievementSheetTitle`, `homeAchievementSheetSubtitle`.

- [ ] **Step 1: Write the failing unit test for `PrayerTimesService` and `PrayerTimesSnapshot`**

Add a test in `test/core/services/prayer_times_service_test.dart` verifying that `PrayerTimesSnapshot` provides `allTimes` containing all 6 prayer entries.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/prayer_times_service_test.dart`
Expected: FAIL (missing `allTimes` property or constructor argument).

- [ ] **Step 3: Update `PrayerTimesSnapshot`, `PrayerTimesService`, and `XpService`**

1. In `lib/core/services/prayer_times_service.dart`:
Add `final Map<String, DateTime> allTimes;` to `PrayerTimesSnapshot`.
In `PrayerTimesService.current()`, populate `allTimes`:
```dart
final allTimes = <String, DateTime>{
  'fajr': times.fajr,
  'sunrise': times.sunrise,
  'dhuhr': times.dhuhr,
  'asr': times.asr,
  'maghrib': times.maghrib,
  'isha': times.isha,
};
```
Pass `allTimes: allTimes` to `PrayerTimesSnapshot`.

2. In `lib/core/services/xp_service.dart`:
Expose `double progressToNextLevel(int xp) => _getProgress(xp);`.

- [ ] **Step 4: Add localization strings to `app_ar.arb` and `app_en.arb`**

In `lib/core/l10n/app_ar.arb`:
```json
  "homeStartKhatmahTitle": "ابدأ ختمتك القرآنية الآن",
  "homeStartKhatmahSubtitle": "رتّب وِردك اليومي وحدد مدة الختمة لتنال أجر التلاوة المستمرة",
  "homeStartKhatmahAction": "إنشاء ختمة جديدة",
  "homePrayerTimesSheetTitle": "مواقيت الصلاة",
  "homeAchievementSheetTitle": "إنجازاتك ومستواك",
  "homeAchievementSheetSubtitle": "واصل التلاوة والحفظ لترقية مستواك القرآني"
```
In `lib/core/l10n/app_en.arb`:
```json
  "homeStartKhatmahTitle": "Start Your Quran Khatmah Now",
  "homeStartKhatmahSubtitle": "Set your daily portion and pace to maintain a regular Quran habit",
  "homeStartKhatmahAction": "Create New Khatmah",
  "homePrayerTimesSheetTitle": "Prayer Times",
  "homeAchievementSheetTitle": "Your Achievements & Level",
  "homeAchievementSheetSubtitle": "Continue reciting and memorizing to advance your rank"
```
Run: `flutter gen-l10n`

- [ ] **Step 5: Run tests and verify PASS**

Run: `flutter test test/core/services/prayer_times_service_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/core/l10n/ lib/core/services/prayer_times_service.dart lib/core/services/xp_service.dart test/core/services/prayer_times_service_test.dart
git commit -m "feat(prayer,l10n,xp): add allTimes to PrayerTimesSnapshot, expose progressToNextLevel in XpService, and add home redesign l10n strings"
```

---

### Task 2: Strict Khatmah-Only Linkage in `ContinueRecitationMapper`

**Files:**
- Modify: `lib/features/home/domain/services/continue_recitation_mapper.dart:16-60`
- Test: `test/features/home/domain/services/continue_recitation_mapper_test.dart`

**Interfaces:**
- Consumes: `KhatmahPlan? activeKhatmah`
- Produces: `ContinueRecitation? map(...)` returning non-null ONLY when `activeKhatmah != null && activeKhatmah.status == KhatmahStatus.active`.

- [ ] **Step 1: Write failing unit and regression tests**

In `test/features/home/domain/services/continue_recitation_mapper_test.dart`:
1. Regression test: opening a regular Quran page without an active Khatmah returns `null`.
2. Regression test: having confirmed read pages without an active Khatmah returns `null`.
3. Unit test: having an active Khatmah returns `ContinueRecitation` with `mode=khatmah` route.

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/features/home/domain/services/continue_recitation_mapper_test.dart`
Expected: FAIL (regression tests will fail because current code returns non-null).

- [ ] **Step 3: Update `ContinueRecitationMapper.map`**

In `lib/features/home/domain/services/continue_recitation_mapper.dart`:
```dart
ContinueRecitation? map({
  required bool isArabic,
  UnifiedJourneyAction? heroAction,
  String? lastRestorableLocation,
  QuranPageDetail? dailyWirdPageDetail,
  KhatmahPlan? activeKhatmah,
  DateTime? now,
  int confirmedReadPages = 0,
}) {
  final moment = now ?? DateTime.now();
  if (activeKhatmah != null && activeKhatmah.status == KhatmahStatus.active) {
    return _fromKhatmah(
      isArabic: isArabic,
      plan: activeKhatmah,
      page: dailyWirdPageDetail,
      now: moment,
    );
  }
  // User explicitly requires "أكمل تلاوتك" to ONLY appear when an active
  // Khatmah is in progress. Regular page reads or memorization sessions
  // must not trigger this card.
  return null;
}
```

- [ ] **Step 4: Run tests and verify PASS**

Run: `flutter test test/features/home/domain/services/continue_recitation_mapper_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/domain/services/continue_recitation_mapper.dart test/features/home/domain/services/continue_recitation_mapper_test.dart
git commit -m "fix(home): restrict continue recitation card strictly to active khatmah"
```

---

### Task 3: Elimination of `/progress` Redundancies & `weeklyReflection` Removal

**Files:**
- Modify: `lib/features/home/domain/entities/home_contextual_slot.dart`
- Modify: `lib/features/home/presentation/cubits/home_cubit.dart`
- Modify: `lib/features/home/presentation/widgets/home_contextual_slot.dart`
- Modify: `lib/features/home/presentation/widgets/home_momentum_strip.dart`
- Test: `test/features/home/presentation/cubits/home_cubit_test.dart`

**Interfaces:**
- Consumes: `HomeLoaded`
- Produces: `HomeState` where `activeSlot?.kind` is never `weeklyReflection`, and `HomeMomentumStrip` renders streak stats without any `onTap` redirecting to progress.

- [ ] **Step 1: Write test verifying `weeklyReflection` is never chosen as active slot**

In `test/features/home/presentation/cubits/home_cubit_test.dart`, add a test on Friday/Saturday verifying `activeSlot?.kind != HomeSlotKind.weeklyReflection`.

- [ ] **Step 2: Run test to verify it fails if slot is emitted**

Run: `flutter test test/features/home/presentation/cubits/home_cubit_test.dart`

- [ ] **Step 3: Remove `weeklyReflection` candidate generation and slot rendering**

1. In `lib/features/home/presentation/cubits/home_cubit.dart`:
Remove lines 590-595 (`weeklyReflection` candidate).
2. In `lib/features/home/domain/entities/home_contextual_slot.dart`:
Remove or deprecate `weeklyReflection`.
3. In `lib/features/home/presentation/widgets/home_contextual_slot.dart`:
Remove `HomeSlotKind.weeklyReflection` cases from title and body switch expressions.
4. In `lib/features/home/presentation/widgets/home_momentum_strip.dart`:
Remove line 50 `onTap: () => context.go(AppRoutes.progress)` and make the strip an informative, non-redirecting card showing streak stats only (no celebration sheet, since streak achievement is covered by `HomeAchievementSheet`).

- [ ] **Step 4: Run tests and verify PASS**

Run: `flutter test test/features/home/presentation/cubits/home_cubit_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/domain/entities/home_contextual_slot.dart lib/features/home/presentation/cubits/home_cubit.dart lib/features/home/presentation/widgets/home_contextual_slot.dart lib/features/home/presentation/widgets/home_momentum_strip.dart test/features/home/presentation/cubits/home_cubit_test.dart
git commit -m "refactor(home): remove weeklyReflection slot and momentum strip redirect to progress"
```

---

### Task 4: Interactive Activity Feed (`HomeActivityFeed`)

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_activity_feed.dart`
- Test: `test/features/home/presentation/widgets/home_activity_feed_test.dart`

**Interfaces:**
- Consumes: `HomeLoaded.recentActivity`, `HomeLoaded.activeKhatmah`
- Produces: Interactive rows navigating directly to content, with no "عرض الكل" text button, and khatmah fallback to active khatmah's next unread page.

- [ ] **Step 1: Write widget test for `HomeActivityFeed`**

Verify that:
1. "عرض الكل" button is NOT rendered.
2. Tapping a reading activity navigates to `/quran/page/$pageNumber`.
3. Tapping a khatmah activity navigates to `/quran/page/${event.pageNumber ?? state.activeKhatmah?.nextUnreadPage ?? 1}?mode=khatmah`.
4. Tapping a review activity navigates to `AppRoutes.memorizationV2Session`.

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/home/presentation/widgets/home_activity_feed_test.dart`

- [ ] **Step 3: Implement direct tap handling and remove "عرض الكل"**

In `lib/features/home/presentation/widgets/home_activity_feed.dart`:
1. Remove `TextButton(onPressed: () => context.go(AppRoutes.progress), ...)` from the header row.
2. In `_ActivityRow`, wrap in `InkWell`:
```dart
onTap: () {
  switch (event.kind) {
    case ActivityEventKind.reading:
      if (event.pageNumber != null) {
        context.push('/quran/page/${event.pageNumber}');
      } else if (event.surahId != null) {
        context.push('/quran/surah/${event.surahId}');
      } else {
        context.push(AppRoutes.quran);
      }
      break;
    case ActivityEventKind.khatmah:
      final page = event.pageNumber ?? state.activeKhatmah?.nextUnreadPage ?? 1;
      context.push('/quran/page/$page?mode=khatmah');
      break;
    case ActivityEventKind.memorize:
      if (event.surahId != null) {
        context.push(AppRoutes.hifzPracticeSurah, extra: {'surahId': event.surahId});
      } else {
        context.push(AppRoutes.memorizationHub);
      }
      break;
    case ActivityEventKind.review:
      context.push(AppRoutes.memorizationV2Session);
      break;
  }
}
```

- [ ] **Step 4: Run test and verify PASS**

Run: `flutter test test/features/home/presentation/widgets/home_activity_feed_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/home_activity_feed.dart test/features/home/presentation/widgets/home_activity_feed_test.dart
git commit -m "feat(home): make recent activity rows direct-navigating and remove view-all progress link"
```

---

### Task 5: Direct Action Tiles (`HomeActionTiles`)

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_action_tiles.dart`
- Test: `test/features/home/presentation/widgets/home_action_tiles_test.dart`

**Interfaces:**
- Consumes: `HomeLoaded`
- Produces: 4 distinct direct action handlers for Listen, Review, Memorize, and Read.

- [ ] **Step 1: Write widget test for `HomeActionTiles`**

Verify each of the 4 tiles invokes its distinct intended action instead of routing identically to `memorizationHub`.

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/home/presentation/widgets/home_action_tiles_test.dart`

- [ ] **Step 3: Implement distinct direct routes in `HomeActionTiles`**

In `lib/features/home/presentation/widgets/home_action_tiles.dart`:
- **Listen:**
  ```dart
  if (state.audioResume != null) {
    final audio = state.audioResume!;
    getIt<QuranContinuousPlayerService>().playAyah(
      audio.surahId,
      audio.ayahNumber,
      reciter: audio.reciter,
      scope: audio.scope,
    );
  } else if (state.ayahOfDay != null) {
    getIt<QuranContinuousPlayerService>().playAyah(
      state.ayahOfDay!.surahId,
      state.ayahOfDay!.ayahNumber,
    );
  } else {
    context.push(AppRoutes.quran);
  }
  ```
- **Review:**
  Navigate to `AppRoutes.memorizationV2Session`.
- **Memorize:**
  Navigate to `AppRoutes.hifzPracticeSurah`.
- **Read:**
  If `state.lastRestorableLocation != null && state.lastRestorableLocation!.startsWith('/quran/page/')`:
    `context.push(state.lastRestorableLocation!);`
  Else:
    `context.push(AppRoutes.quran);`

- [ ] **Step 4: Run test and verify PASS**

Run: `flutter test test/features/home/presentation/widgets/home_action_tiles_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/home_action_tiles.dart test/features/home/presentation/widgets/home_action_tiles_test.dart
git commit -m "feat(home): convert action tiles into direct execution routes"
```

---

### Task 6: Quick Access Optimization (`HomeQuickAccess`)

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_quick_access.dart`
- Test: `test/features/home/presentation/widgets/home_quick_access_test.dart`

**Interfaces:**
- Consumes: `HomeLoaded`
- Produces: 2-3 dynamic quick chips (Bookmarks, Time-of-day Azkar, Friday Kahf).

- [ ] **Step 1: Write test for `HomeQuickAccess`**

Verify that:
1. Bookmarks chip is present.
2. Dynamic time-of-day Azkar chip is present.
3. Redundant generic Khatmah chip is removed.
4. On Friday before 18:00, Kahf chip is present.

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/home/presentation/widgets/home_quick_access_test.dart`

- [ ] **Step 3: Update `HomeQuickAccess`**

In `lib/features/home/presentation/widgets/home_quick_access.dart`:
Remove static `AppRoutes.khatmahDashboard` item. Keep Bookmarks, dynamic time-of-day Azkar, and Friday Kahf.

- [ ] **Step 4: Run test and verify PASS**

Run: `flutter test test/features/home/presentation/widgets/home_quick_access_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/home_quick_access.dart test/features/home/presentation/widgets/home_quick_access_test.dart
git commit -m "refactor(home): streamline quick access chips and remove redundant khatmah chip"
```

---

### Task 7: Pure `HomePrimaryActionResolver`, `HomeStartKhatmahCard`, and Hero Contract Integration

**Files:**
- Create: `lib/features/home/domain/services/home_primary_action_resolver.dart`
- Create: `lib/features/home/presentation/widgets/home_start_khatmah_card.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart:230-250, 399-445`
- Test: `test/features/home/domain/services/home_primary_action_resolver_test.dart`
- Test: `test/features/home/presentation/widgets/home_start_khatmah_card_test.dart`

**Interfaces:**
- `HomePrimaryActionResolver`: pure class returning `HomePrimaryActionDecision(kind: HomePrimaryActionKind, showContextualStartKhatmah: bool)`
- `HomeStartKhatmahCard`: widget with headline, subtitle, and button to `AppRoutes.khatmahSetup`.

- [ ] **Step 1: Write unit tests for `HomePrimaryActionResolver`**

In `test/features/home/domain/services/home_primary_action_resolver_test.dart`:
1. Active khatmah (`continueRecitation != null`) -> `khatmahContinue` (regardless of `heroAction`).
2. No khatmah, `heroAction` has priority `p1ActiveSession`, `p2CriticalAlert`, `p3ReviewBacklog`, or `p4SmartPlan` (priority index <= p4 index), and `unifiedJourneyEnabled == true` -> `journeyHero` with `showContextualStartKhatmah == true`.
3. No khatmah, `heroAction` has priority `p5DailyGoal` or `p6FreeExploration` -> `startKhatmah` with `showContextualStartKhatmah == false`.
4. No khatmah, `heroAction == null` -> `startKhatmah`.

- [ ] **Step 2: Implement pure `HomePrimaryActionResolver`**

Create `lib/features/home/domain/services/home_primary_action_resolver.dart`:
```dart
import '../../../../core/journey/unified_journey_action.dart';
import '../entities/continue_recitation.dart';

enum HomePrimaryActionKind {
  khatmahContinue,
  journeyHero,
  startKhatmah,
}

class HomePrimaryActionDecision {
  const HomePrimaryActionDecision({
    required this.kind,
    this.showContextualStartKhatmah = false,
  });

  final HomePrimaryActionKind kind;
  final bool showContextualStartKhatmah;
}

class HomePrimaryActionResolver {
  const HomePrimaryActionResolver();

  HomePrimaryActionDecision resolve({
    required ContinueRecitation? continueRecitation,
    required UnifiedJourneyAction? heroAction,
    required bool unifiedJourneyEnabled,
  }) {
    if (continueRecitation != null) {
      return const HomePrimaryActionDecision(
        kind: HomePrimaryActionKind.khatmahContinue,
      );
    }

    if (unifiedJourneyEnabled &&
        heroAction != null &&
        heroAction.priority.index <= UnifiedJourneyPriority.p4SmartPlan.index) {
      return const HomePrimaryActionDecision(
        kind: HomePrimaryActionKind.journeyHero,
        showContextualStartKhatmah: true,
      );
    }

    return const HomePrimaryActionDecision(
      kind: HomePrimaryActionKind.startKhatmah,
    );
  }
}
```

- [ ] **Step 3: Implement `HomeStartKhatmahCard`**

Create `lib/features/home/presentation/widgets/home_start_khatmah_card.dart`:
- Match `HomeSkin` gradient, gold icon (`Icons.auto_stories_rounded`).
- Text from `context.l10n.homeStartKhatmahTitle` and `context.l10n.homeStartKhatmahSubtitle`.
- Elevated/filled button with `context.l10n.homeStartKhatmahAction` calling `context.push(AppRoutes.khatmahSetup)`.

- [ ] **Step 4: Wire Resolver into `HomePage` & preserve legacy flag-off fallback in `_PrimaryAction`**

In `lib/features/home/presentation/pages/home_page.dart`:
Use `const HomePrimaryActionResolver().resolve(...)`:
- If `decision.kind == HomePrimaryActionKind.khatmahContinue`: Render `HomeContinueCard`.
- If `decision.kind == HomePrimaryActionKind.journeyHero`: Render `_PrimaryAction` (which shows `HomeHeroSection`), followed by `HomeStartKhatmahCard`.
- If `decision.kind == HomePrimaryActionKind.startKhatmah`:
  - When `JourneyFeatureFlags.unifiedJourneyEnabled`: Render `HomeStartKhatmahCard`.
  - When `!JourneyFeatureFlags.unifiedJourneyEnabled`: Keep legacy fallback `_PrimaryAction` (`ResumeSessionCard` / `NextBestActionCard`) untouched so existing tests (`smart_coach_home_validation_test.dart`, `responsive_home_widgets_test.dart`) pass.

- [ ] **Step 5: Run tests and verify PASS**

Run: `flutter test test/features/home/domain/services/home_primary_action_resolver_test.dart`
Run: `flutter test test/features/home/presentation/widgets/home_start_khatmah_card_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/domain/services/home_primary_action_resolver.dart lib/features/home/presentation/widgets/home_start_khatmah_card.dart lib/features/home/presentation/pages/home_page.dart test/features/home/domain/services/home_primary_action_resolver_test.dart test/features/home/presentation/widgets/home_start_khatmah_card_test.dart
git commit -m "feat(home): add HomePrimaryActionResolver and HomeStartKhatmahCard with smart priority hero contract"
```

---

### Task 8: In-Place Achievement Sheet (`HomeAchievementSheet`)

**Files:**
- Create: `lib/features/home/presentation/widgets/home_achievement_sheet.dart`
- Modify: `lib/features/home/presentation/widgets/home_context_bar.dart:200-265`
- Test: `test/features/home/presentation/widgets/home_achievement_sheet_test.dart`

**Interfaces:**
- Consumes: `Progress` state, `int totalXp`, `isKids` flag.
- Produces: `showModalBottomSheet` displaying level title via `XpService.getCurrentLevel(totalXp)` and progress via `XpService.progressToNextLevel(totalXp)`.

- [ ] **Step 1: Write test for `HomeAchievementSheet`**

Verify level rank from `XpService`, total XP display, progress indicator, and badge list.

- [ ] **Step 2: Implement `HomeAchievementSheet`**

Create `lib/features/home/presentation/widgets/home_achievement_sheet.dart`:
- Takes `Progress progress`, `int totalXp`, `bool isKids`.
- Uses `getIt<XpService>().getCurrentLevel(totalXp)` and `getIt<XpService>().progressToNextLevel(totalXp)`.
- Displays level title, total XP, current progress toward next milestone, and list of achievements.
- Has header with trophy icon and `context.l10n.homeAchievementSheetTitle`.

- [ ] **Step 3: Update `HomeAchievementChip` in `home_context_bar.dart`**

In `lib/features/home/presentation/widgets/home_context_bar.dart`:
Pass `totalXp: state.totalXp` to `HomeAchievementChip`.
When `award == null`:
Replace `context.go(AppRoutes.progress);` with:
```dart
showModalBottomSheet<void>(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (ctx) => HomeAchievementSheet(
    progress: progress,
    totalXp: totalXp,
    isKids: isKids,
  ),
);
```

- [ ] **Step 4: Run tests and verify PASS**

Run: `flutter test test/features/home/presentation/widgets/home_achievement_sheet_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/home_achievement_sheet.dart lib/features/home/presentation/widgets/home_context_bar.dart test/features/home/presentation/widgets/home_achievement_sheet_test.dart
git commit -m "feat(home): add HomeAchievementSheet using XpService and eliminate achievement chip progress redirect"
```

---

### Task 9: Interactive Prayer Times & Hijri Calendar Sheet (`HomePrayerTimesSheet`)

**Files:**
- Create: `lib/features/home/presentation/widgets/home_prayer_times_sheet.dart`
- Modify: `lib/features/home/presentation/widgets/home_night_header.dart:271-309`
- Test: `test/features/home/presentation/widgets/home_prayer_times_sheet_test.dart`

**Interfaces:**
- Consumes: `PrayerTimesSnapshot` (with `allTimes`), `hijriLabel`, city name.
- Produces: `HomePrayerTimesSheet` with smooth staggered animation, day of week, full Hijri date, and 6 prayer times with status indicators.

- [ ] **Step 1: Write widget test for `HomePrayerTimesSheet`**

Verify:
1. Hijri date and day of week are rendered.
2. All 6 prayers (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) are rendered with formatted times.
3. Active/next prayer is highlighted with remaining time.

- [ ] **Step 2: Implement `HomePrayerTimesSheet`**

Create `lib/features/home/presentation/widgets/home_prayer_times_sheet.dart`:
- Derive day of week (e.g. `DateFormat('EEEE', context.isArabic ? 'ar' : 'en').format(DateTime.now())`).
- Display Hijri date header with elegant Islamic ornament / badge styling.
- Display city name.
- Animated staggered list for all 6 prayer entries.
- Highlight next prayer with gold accent, glow border, and "متبقي X دقيقة".

- [ ] **Step 3: Connect `HomePrayerChip` in `home_night_header.dart`**

In `lib/features/home/presentation/widgets/home_night_header.dart`:
In `HomePrayerChip.build`:
Add `onTap` to `_HeroChip`:
```dart
onTap: () {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => HomePrayerTimesSheet(
      snapshot: snapshot,
      hijriLabel: state.hijriLabel,
      skin: skin,
    ),
  );
},
```

- [ ] **Step 4: Run tests and verify PASS**

Run: `flutter test test/features/home/presentation/widgets/home_prayer_times_sheet_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/widgets/home_prayer_times_sheet.dart lib/features/home/presentation/widgets/home_night_header.dart test/features/home/presentation/widgets/home_prayer_times_sheet_test.dart
git commit -m "feat(home): add animated HomePrayerTimesSheet with Hijri date and wire to HomePrayerChip"
```

---

### Task 10: Full Static Analysis, Test Suite Verification, and Hot Reload Check

**Files:**
- Entire codebase

- [ ] **Step 1: Run static analysis across entire project**

Run: `dart analyze`
Expected: 0 errors, 0 warnings.

- [ ] **Step 2: Run all unit and widget tests (including legacy flag-off suites)**

Run: `flutter test`
Expected: All tests PASS, including `smart_coach_home_validation_test.dart` and `responsive_home_widgets_test.dart`.

- [ ] **Step 3: DTD Hot Reload Check**

Proactively connect to running app if available and trigger hot reload.

- [ ] **Step 4: Final commit & Walkthrough**

Document all completed tasks in `walkthrough.md`.
