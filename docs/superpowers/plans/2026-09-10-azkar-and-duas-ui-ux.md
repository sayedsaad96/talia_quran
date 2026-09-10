# Azkar and Duas UI/UX Modernization Implementation Plan (Revised)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernize the Azkar and Duas experience in Talia Quran with a dynamic contextual Hub, modern full-card tap and guarded auto-advance recitation mode, instant-search Duas library with persistent bookmarks and Arabic normalization, lightweight session-based Free Tasbeeh, and rigorous religious content safety.

**Architecture:** Clean modular architecture extending Talia Quran's existing layers: `AzkarCubit` for recitation session flow, existing `AzkarCompletionStore` for daily progress, a unified `AzkarPreferencesStore` (`SharedPreferences`) for user preferences (favorites, auto-advance, font size, tasbeeh target), reusable `ArabicNormalizer` for search, and a standalone `AzkarTimeContext` helper.

**Tech Stack:** Flutter 3.x (Dart 3.x), `flutter_bloc`, `shared_preferences`, `flutter_animate`, `get_it` DI, `ArabicNormalizer`.

---

## Global Constraints & Mandatory Safety Gates

1. **Strict Religious Content Safety Gate (NON-NEGOTIABLE):**
   - The AI must NEVER author, reconstruct from memory, paraphrase, abbreviate, or alter any Quranic or Hadith text, nor invent citations or translations.
   - Any new supplication text that is not already verified in an approved project dataset or explicitly verified by the project owner is **BLOCKED FOR CONTENT VERIFICATION**.
   - Category label normalization (e.g. mapping `"أدعية قرآنية"` to `"أدعية من القرآن"`) is taxonomy-only and must preserve sacred text and citations 100% unchanged.
   - All records must pass `test/core/content/approved_azkar_content_test.dart`.
2. **Architecture & Persistence Discipline:**
   - No direct raw `SharedPreferences` calls inside presentation widgets. All Azkar preferences are mediated through `AzkarPreferencesStore` registered in `getIt`.
   - Never duplicate existing project infrastructure: reuse `lib/core/utils/arabic_normalizer.dart` for search normalization; reuse `AzkarCompletionStore` for daily completion.
3. **Auto-Advance Concurrency & Animation Safety:**
   - Single source of truth for auto-advance in `AzkarCubit`. Prevent duplicate/overlapping `Future.delayed` navigations.
   - Guard transitions with `_isAutoAdvancing`, `mounted`, `_pageController.hasClients`, and respect `MediaQuery.disableAnimationsOf(context)`.
4. **WCAG AA Accessibility & RTL:**
   - Contrast ratio ≥ 4.5:1 for functional text in both Light and Dark themes.
   - Respect system text scale factor without overflow (`ConstrainedBox(maxWidth: 800)`).
   - Ensure natural RTL layout and gesture directions.

---

## Dependency Graph

```
Task 0: Current-State & Architecture Inspection (Foundation audit)
   │
   ▼
Task 1: Preferences / Favorites Foundation (AzkarPreferencesStore + DI)
   │
   ├───────────────────────────────┐
   ▼                               ▼
Task 2: Azkar Recitation UX    Task 3: Duas Library UX
(Full-card tap, safe advance)  (Search, normalizer, favs)
   │                               │
   └───────────────┬───────────────┘
                   ▼
Task 4: Azkar Hub + Free Tasbeeh
(Contextual Hero, Bento, Free Tasbeeh)
                   │
                   ▼
Task 5: Verified Religious Content Update
(Taxonomy normalization + Content safety gate)
                   │
                   ▼
Task 6: Full Automated + Runtime Verification
(Dart analyze, test suites, emulator runtime QA)
```

---

### Task 0: Current-State & Architecture Inspection

**Files Inspected:**
- Data & Repositories: `lib/features/azkar/data/datasources/azkar_local_datasource.dart`, `lib/features/azkar/data/datasources/azkar_completion_store.dart`, `lib/features/azkar/data/repositories/azkar_repository_impl.dart`
- Domain: `lib/features/azkar/domain/entities/azkar_entities.dart`, `lib/features/azkar/domain/usecases/get_azkar_usecase.dart`
- Presentation & State: `lib/features/azkar/presentation/cubits/azkar_cubit.dart`, `lib/features/azkar/presentation/pages/azkar_page.dart`, `lib/features/azkar/presentation/pages/azkar_category_page.dart`, `lib/features/azkar/presentation/pages/general_azkar_page.dart`
- Reusable Core Utilities: `lib/core/utils/arabic_normalizer.dart` (ALREADY EXISTS), `lib/core/theme/app_colors.dart`, `lib/core/theme/app_typography.dart`, `lib/core/constants/app_spacing.dart`, `lib/core/di/injection.dart`
- Content Manifest & Rules: `assets/data/content_manifest.json`, `lib/core/content/approved_azkar_content.dart`

**Key Findings & Architectural Decisions:**
1. `AzkarCompletionStore` already handles daily counts and completion tracking atomically with `_serialize`. It will be reused for Hub daily progress.
2. `ArabicNormalizer.normalize(text)` in `lib/core/utils/arabic_normalizer.dart` already strips tashkeel, normalizes alef/yaa/hamza, taa marbuta, and whitespace. It will be reused for Dua search.
3. `AzkarCubit.increment()` currently hardcodes a 400ms delay that emits a new index when a zikr completes. This must be refactored to accept an `autoAdvance` boolean parameter so the Cubit remains the single source of truth and does not fire when auto-advance is toggled off.
4. Auto-advance, favorite Dua IDs, font size scale, and last Tasbeeh target will be unified in a clean `AzkarPreferencesStore` backed by `SharedPreferences`.

- [ ] **Step 1: Document architecture inspection and confirm baseline tests pass**

Run: `flutter test test/features/azkar/`
Expected: ALL PASS.

- [ ] **Step 2: Commit inspection baseline**

```bash
git commit --allow-empty -m "chore(azkar): verify current-state architecture inspection baseline"
```

---

### Task 1: Preferences / Favorites Foundation (`AzkarPreferencesStore`)

**Files:**
- Create: `lib/features/azkar/data/datasources/azkar_preferences_store.dart`
- Modify: `lib/core/di/injection.dart:316`
- Test: `test/features/azkar/data/azkar_preferences_store_test.dart`

**Interfaces:**
- Consumes: `SharedPreferences`
- Produces: `AzkarPreferencesStore`
  - `Set<String> getFavoriteDuaIds()`
  - `bool isFavorite(String id)`
  - `Future<bool> toggleFavorite(String id)`
  - `ValueListenable<Set<String>> get favoritesListenable`
  - `bool getAutoAdvance()`
  - `Future<void> setAutoAdvance(bool enabled)`
  - `ValueListenable<bool> get autoAdvanceListenable`
  - `double getFontScale()` (e.g. 0.9 = Small, 1.0 = Medium, 1.2 = Large)
  - `Future<void> setFontScale(double scale)`
  - `ValueListenable<double> get fontScaleListenable`
  - `int getLastTasbeehTarget()` (default 33)
  - `Future<void> setLastTasbeehTarget(int target)`

- [ ] **Step 1: Write unit tests for `AzkarPreferencesStore`**

Create `test/features/azkar/data/azkar_preferences_store_test.dart`:
- Test default values (`favorites` empty, `autoAdvance` true, `fontScale` 1.0, `tasbeehTarget` 33).
- Test toggling favorites adds/removes persistently and updates `favoritesListenable`.
- Test changing autoAdvance persists and updates `autoAdvanceListenable`.
- Test changing fontScale persists and updates `fontScaleListenable`.
- Test persistence after store re-instantiation with same `SharedPreferences`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/azkar/data/azkar_preferences_store_test.dart`
Expected: FAIL (class not implemented).

- [ ] **Step 3: Implement `AzkarPreferencesStore`**

Write `lib/features/azkar/data/datasources/azkar_preferences_store.dart`:
- Backed by `SharedPreferences` keys: `'azkar_favorite_duas'`, `'azkar_auto_advance'`, `'azkar_font_scale'`, `'azkar_tasbeeh_target'`.
- Uses `ValueNotifier` for reactive listening without widget rebuild bloat.
- Register in `lib/core/di/injection.dart` as a `LazySingleton`:
  ```dart
  getIt.registerLazySingleton<AzkarPreferencesStore>(
    () => AzkarPreferencesStore(getIt<SharedPreferences>()),
  );
  ```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/azkar/data/azkar_preferences_store_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/azkar/data/datasources/azkar_preferences_store.dart lib/core/di/injection.dart test/features/azkar/data/azkar_preferences_store_test.dart
git commit -m "feat(azkar): add AzkarPreferencesStore with persistence and reactive listenables"
```

---

### Task 2: Azkar Recitation UX (Full-Card Tap, Progress & Safe Auto-Advance)

**Files:**
- Modify: `lib/features/azkar/presentation/cubits/azkar_cubit.dart:55-117`
- Modify: `lib/features/azkar/presentation/pages/azkar_category_page.dart`
- Create/Modify: `lib/features/azkar/presentation/widgets/font_scale_selector_sheet.dart`
- Test: `test/features/azkar/presentation/azkar_cubit_test.dart`
- Test: `test/features/azkar/presentation/azkar_category_page_test.dart`

**Interfaces:**
- Consumes: `AzkarCubit`, `AzkarPreferencesStore`, `AppColors`, `AppTypography`
- Produces: Guarded `increment({bool autoAdvance = true})` in Cubit, full-card gesture detection with micro-haptics, top bar `Aa` font scale selector (Small/Medium/Large) with persistence, top bar Auto-Advance toggle with persistent state, integrated progress arc indicator.

- [ ] **Step 1: Write unit tests in `azkar_cubit_test.dart` for conditional auto-advance**

Verify that:
1. `increment(autoAdvance: true)` on last count advances `currentIndex` after delay.
2. `increment(autoAdvance: false)` on last count marks zikr as done but does NOT advance `currentIndex`.
3. Decrementing preserves state correctly.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/azkar/presentation/azkar_cubit_test.dart`
Expected: FAIL (parameter `autoAdvance` not accepted yet).

- [ ] **Step 3: Refactor `AzkarCubit.increment`**

Update `increment({bool autoAdvance = true})`:
```dart
Future<void> increment({bool autoAdvance = true}) =>
    _enqueueMutation(() => _increment(autoAdvance: autoAdvance));

Future<void> _increment({bool autoAdvance = true}) async {
  ...
  emit(state.copyWith(sessions: sessions, allDone: allDone));

  if (autoAdvance && session.isDone && !allDone) {
    await Future.delayed(const Duration(milliseconds: 350));
    if (isClosed) return;
    final latestState = this.state;
    if (latestState is AzkarLoaded && latestState.currentIndex == idx) {
      int nextIndex = latestState.sessions.indexWhere(
        (s) => !s.isDone,
        idx + 1,
      );
      if (nextIndex == -1) {
        nextIndex = latestState.sessions.indexWhere((s) => !s.isDone);
      }
      if (nextIndex != -1) {
        emit(latestState.copyWith(currentIndex: nextIndex));
      }
    }
  }
}
```

- [ ] **Step 4: Update `AzkarCategoryPage` presentation**

1. In `_ActiveAzkarScreenState`:
   - Inject/read `AzkarPreferencesStore`.
   - Read `autoAdvance` from store.
   - When tapping counter or card: call `cubit.increment(autoAdvance: store.getAutoAdvance())`.
   - Add transition guard `bool _isAutoAdvancing = false;` in `BlocListener`:
     ```dart
     listener: (context, state) {
       if (state is AzkarLoaded && _pageController.hasClients && !_isAutoAdvancing) {
         _isAutoAdvancing = true;
         final disableAnimations = MediaQuery.disableAnimationsOf(context);
         if (disableAnimations) {
           _pageController.jumpToPage(state.currentIndex);
           _isAutoAdvancing = false;
         } else {
           _pageController.animateToPage(
             state.currentIndex,
             duration: const Duration(milliseconds: 300),
             curve: Curves.easeInOut,
           ).then((_) {
             if (mounted) _isAutoAdvancing = false;
           });
         }
       }
     }
     ```
   - Top bar:
     - Replace font cycling with `Aa` button opening `FontScaleSelectorSheet` (Small 0.85x, Medium 1.0x, Large 1.25x) updating `AzkarPreferencesStore`.
     - Add Auto-Advance toggle button (`Icons.autorenew_rounded` / tooltip) connected to `AzkarPreferencesStore`.
2. In `_ZikrReaderPage`:
   - Wrap reading area container with `GestureDetector(onTap: onTap, onLongPress: onLongPress)` so reciters can tap anywhere.
   - Refactor counter layout into an integrated progress arc displaying `${session.currentCount}/${session.zikr.totalCount}`.
   - Format "فضل الذكر" / virtues in a distinct styled container if present.
   - Long-press / 3-second undo button remains available.

- [ ] **Step 5: Write and run widget tests**

Create `test/features/azkar/presentation/azkar_category_page_test.dart`:
- Tapping reading card increments count with haptic call.
- Auto-advance disabled: does not animate page.
- Auto-advance enabled: animates to next page on completion.
- Animations-disabled mode: uses `jumpToPage` without jank.
- Rapid tapping does not cause duplicate index transitions.

Run: `flutter test test/features/azkar/presentation/azkar_category_page_test.dart`
Expected: ALL PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/azkar/presentation/cubits/azkar_cubit.dart lib/features/azkar/presentation/pages/azkar_category_page.dart lib/features/azkar/presentation/widgets/font_scale_selector_sheet.dart test/features/azkar/
git commit -m "feat(azkar): implement full-card tap and guarded auto-advance in recitation screen"
```

---

### Task 3: Duas Library UX (Search, Arabic Normalizer, Favorites & Reading Preferences)

**Files:**
- Modify: `lib/features/azkar/presentation/pages/general_azkar_page.dart`
- Test: `test/features/azkar/presentation/general_azkar_page_test.dart`

**Interfaces:**
- Consumes: `AzkarCubit`, `AzkarPreferencesStore`, `ArabicNormalizer` (`lib/core/utils/arabic_normalizer.dart`)
- Produces: Instant search with Arabic normalization, "المفضلة ❤️" tab, bookmark button with haptic feedback, `Aa` font scale selector with persistence, empty state widgets.

- [ ] **Step 1: Write widget test for Duas search and favorites**

Create `test/features/azkar/presentation/general_azkar_page_test.dart`:
- Search matches query with different Hamza/diacritic variants (e.g. searching "الله" matches "اللَّهُ", searching "استخاره" matches "الاستخارة").
- Tapping favorite bookmark adds/removes ID in `AzkarPreferencesStore`.
- Selecting "المفضلة" tab shows only favorited Duas.
- Empty search results shows empty state widget with clear button.
- Clearing search restores full list.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/azkar/presentation/general_azkar_page_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement Search, Normalization, Favorites, and Font Scale in `GeneralAzkarPage`**

1. Search filtering logic:
   ```dart
   final normalizedQuery = ArabicNormalizer.normalize(_searchQuery);
   final filtered = sessions.where((s) {
     if (isFavoritesTab && !prefsStore.isFavorite(s.zikr.id)) return false;
     if (!isFavoritesTab && _selectedSubcategory.isNotEmpty && s.zikr.subcategory != _selectedSubcategory) return false;
     if (normalizedQuery.isEmpty) return true;
     final textNorm = ArabicNormalizer.normalize(s.zikr.text);
     final refNorm = ArabicNormalizer.normalize(s.zikr.reference);
     final subNorm = ArabicNormalizer.normalize(s.zikr.subcategory);
     return textNorm.contains(normalizedQuery) || refNorm.contains(normalizedQuery) || subNorm.contains(normalizedQuery);
   }).toList();
   ```
2. AppBar:
   - Add Search Bar (or expandable search action with clear button).
   - Add `Aa` font scale selector opening `FontScaleSelectorSheet` connected to `AzkarPreferencesStore`.
3. Category Chips:
   - Normalize category names on the fly: map `"أدعية قرآنية"` to `"أدعية من القرآن"`.
   - Add `"المفضلة ❤️"` as a first-class tab.
4. `_ZikrCard`:
   - Add bookmark icon button (`Icons.bookmark_rounded` vs `Icons.bookmark_border_rounded`).
   - Dynamic font size according to `fontScale` from `AzkarPreferencesStore`.
   - Keep Copy and Share (`SocialShareSheet`) actions.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/azkar/presentation/general_azkar_page_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/azkar/presentation/pages/general_azkar_page.dart test/features/azkar/presentation/general_azkar_page_test.dart
git commit -m "feat(azkar): enhance duas library with normalized arabic search, bookmarks, and font scaling"
```

---

### Task 4: Azkar Hub + Free Tasbeeh (Contextual Hero, Bento & Lightweight Tasbeeh)

**Files:**
- Create: `lib/features/azkar/domain/services/azkar_time_context.dart`
- Create: `lib/features/azkar/presentation/widgets/free_tasbeeh_sheet.dart`
- Modify: `lib/features/azkar/presentation/pages/azkar_page.dart`
- Test: `test/features/azkar/domain/services/azkar_time_context_test.dart`
- Test: `test/features/azkar/presentation/azkar_page_test.dart`

**Interfaces:**
- Consumes: `AzkarCompletionStore`, `AzkarRepository`, `AzkarPreferencesStore`, `AppColors`
- Produces: `AzkarTimeContext` service, dynamic Hero card with live completion stats, 2-column Bento grid, `FreeTasbeehSheet` with session counter.

- [ ] **Step 1: Write unit tests for `AzkarTimeContext`**

Create `test/features/azkar/domain/services/azkar_time_context_test.dart`:
- Tests `04:00` -> `AzkarPeriod.morning`
- Tests `10:30` -> `AzkarPeriod.morning`
- Tests `15:29` -> `AzkarPeriod.morning`
- Tests `15:30` -> `AzkarPeriod.evening`
- Tests `22:00` -> `AzkarPeriod.evening`
- Tests `03:59` -> `AzkarPeriod.evening`

- [ ] **Step 2: Implement `AzkarTimeContext`**

Create `lib/features/azkar/domain/services/azkar_time_context.dart`:
```dart
enum AzkarPeriod { morning, evening }

abstract class AzkarTimeContext {
  static AzkarPeriod resolvePeriod([DateTime? now]) {
    final time = now ?? DateTime.now();
    final hour = time.hour;
    if (hour >= 4 && (hour < 15 || (hour == 15 && time.minute < 30))) {
      return AzkarPeriod.morning;
    }
    return AzkarPeriod.evening;
  }
}
```

- [ ] **Step 3: Run unit test to verify it passes**

Run: `flutter test test/features/azkar/domain/services/azkar_time_context_test.dart`
Expected: PASS.

- [ ] **Step 4: Create `FreeTasbeehSheet`**

Create `lib/features/azkar/presentation/widgets/free_tasbeeh_sheet.dart`:
- Lightweight, session-only counter (`StatefulWidget`).
- Target options: 33, 100, 0 (Open/Unlimited).
- Persists user's last target choice in `AzkarPreferencesStore.setLastTasbeehTarget`.
- Large interactive tap surface with `HapticFeedback.selectionClick()`.
- Reset button with simple confirmation prompt to prevent accidental clears.

- [ ] **Step 5: Refactor `AzkarPage` (Hub)**

1. Calculate `period = AzkarTimeContext.resolvePeriod()`.
2. Inspect counts from `_loadCounts()`. If all categories empty/under review, retain `EmptyStateWidget(key: const ValueKey('azkar-content-under-review'))` to guarantee safety test compliance!
3. Build Contextual Hero Card:
   - Morning (Sun icon, dawn gradient) or Evening (Crescent icon, night gradient).
   - Reads today's completion state from `AzkarCompletionStore`.
   - Linear progress bar (`completedCount / totalCount`).
   - 1-tap continuation button: "ابدأ أذكار الصباح / المساء" or "متابعة الورد".
4. Bento Grid:
   - Morning Azkar card, Evening Azkar card, Duas card, and Free Tasbeeh card.
   - Tapping Free Tasbeeh calls `FreeTasbeehSheet.show(context)`.

- [ ] **Step 6: Write and run widget tests in `azkar_page_test.dart`**

Verify:
- Morning context displays morning hero.
- Evening context displays evening hero.
- Under review state is preserved when repository returns no approved records.
- Bento cards route to appropriate destinations.
- Tapping Free Tasbeeh opens bottom sheet.

Run: `flutter test test/features/azkar/presentation/azkar_page_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/azkar/domain/services/azkar_time_context.dart lib/features/azkar/presentation/widgets/free_tasbeeh_sheet.dart lib/features/azkar/presentation/pages/azkar_page.dart test/features/azkar/
git commit -m "feat(azkar): implement contextual hero card, bento grid, and free tasbeeh in azkar hub"
```

---

### Task 5: Verified Religious Content Update (Taxonomy Normalization & Safety Gate)

**Files:**
- Modify: `assets/data/azkar_release.json`
- Test: `test/core/content/approved_azkar_content_test.dart`
- Test: `test/features/azkar/data/azkar_local_datasource_release_test.dart`

**Safety Rules:**
- DO NOT generate, reconstruct, or add unverified religious Arabic text.
- Normalize only the subcategory taxonomy string: replace `"subcategory": "أدعية قرآنية"` with `"subcategory": "أدعية من القرآن"`.
- New prospective supplications (Istikhara, Travel, Debt relief, Sick visit) are documented as **BLOCKED FOR CONTENT VERIFICATION** until the project owner confirms the exact approved Arabic text and citations.

- [ ] **Step 1: Write regression test verifying category taxonomy normalization**

```dart
// in test/features/azkar/data/azkar_local_datasource_release_test.dart
test('duas subcategories do not contain duplicate "أدعية قرآنية"', () async {
  final jsonStr = await rootBundle.loadString('assets/data/azkar_release.json');
  final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
  final duas = decoded['duas'] as List<dynamic>;
  final subcategories = duas.map((d) => d['subcategory'] as String).toSet();
  expect(subcategories.contains('أدعية قرآنية'), isFalse);
});
```

- [ ] **Step 2: Update `assets/data/azkar_release.json` taxonomy**

Replace the 3 occurrences of `"subcategory": "أدعية قرآنية"` with `"subcategory": "أدعية من القرآن"`.
Ensure no text, citation, or grade is touched.

- [ ] **Step 3: Run approved content and datasource tests**

Run: `flutter test test/core/content/approved_azkar_content_test.dart`
Run: `flutter test test/features/azkar/data/azkar_local_datasource_release_test.dart`
Expected: ALL PASS.

- [ ] **Step 4: Commit**

```bash
git add assets/data/azkar_release.json test/features/azkar/data/azkar_local_datasource_release_test.dart
git commit -m "fix(azkar): normalize dua category taxonomy without altering religious content"
```

---

### Task 6: Full Automated + Runtime Verification

**Files:**
- Run full automated test suite and static analysis.
- Execute real runtime QA on device/emulator.

- [ ] **Step 1: Run static analysis**

Run: `dart analyze`
Expected: No errors, no warnings across the entire repository.

- [ ] **Step 2: Run complete project test suite**

Run: `flutter test`
Expected: All tests pass without regressions.

- [ ] **Step 3: Perform Mandatory Runtime QA Checklist on Emulator/Device**

| Test Case | Verification Check | Expected Result |
|-----------|--------------------|-----------------|
| **RTL & Arabic Typography** | Open Azkar Hub and Recitation | Natural RTL layout, correct Amiri & Noto Naskh font rendering, no reversed brackets/citations. |
| **Light & Dark Theme** | Toggle theme in settings | All card borders, texts, counter buttons maintain ≥ 4.5:1 contrast, no washed-out text in dark mode. |
| **Full-Card Tap** | Tap anywhere on recitation card | Counter increments with light tactile click; heavy vibration when target is reached. |
| **Guarded Auto-Advance** | Complete zikr with auto-advance ON | Smooth 300ms transition to next zikr; rapid tapping does NOT double-advance. |
| **Disabled Auto-Advance** | Toggle auto-advance OFF in AppBar | Completing zikr shows checkmark but stays on current zikr; user swipes manually. |
| **Screen Exit during Delay** | Tap last count and instantly press Back | No exceptions in log; no delayed navigation on dead context. |
| **Reading Font Scaling** | Open `Aa` selector, switch Small/Med/Large | Text resizes immediately; persists after app restart; no RenderFlex overflow. |
| **Arabic Search** | Search "شفاء", "استغفار", "الله" | Instant matching regardless of tashkeel or hamza forms; clear button resets list. |
| **Favorites Bookmark** | Tap bookmark on 2 Duas, open "المفضلة" | Exactly 2 Duas appear; survives app restart; unmarking removes immediately. |
| **Free Tasbeeh** | Open from Hub, tap count, switch target, reset | Counter increments with haptics; reset shows confirmation prompt; target choice persists. |
| **Device Form Factors** | Test on standard phone & tablet | Constrained to 800px max width; Bento grid and Hero look proportional. |
| **Animations Disabled** | Enable `prefers-reduced-motion` | Page transitions jump immediately without animation; zero crashes. |

- [ ] **Step 4: Commit final verification artifact**

```bash
git commit --allow-empty -m "chore(azkar): complete full automated and runtime verification"
```
