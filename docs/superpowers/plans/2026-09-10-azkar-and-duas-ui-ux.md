# Azkar and Duas UI/UX Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Azkar and Duas experience in Talia Quran with a dynamic contextual Hub, modern full-card tap and auto-advance recitation mode, instant-search Duas library with persistent bookmarks, and enriched authentic supplications.

**Architecture:** Clean modular Flutter architecture utilizing `Bloc`/`Cubit` state management, `SharedPreferences` for persistence (`AzkarFavoritesStore`), reactive time-context calculations for the daily Hero card, and seamless full-card gesture handling with micro-haptics.

**Tech Stack:** Flutter (Dart 3.x), `flutter_bloc`, `shared_preferences`, `flutter_animate`, `get_it` DI.

## Global Constraints

- Never break existing JSON schemas in `assets/data/azkar_release.json`; every record must satisfy `approved_azkar_content.dart` (valid id, text, citation, sourceType, datasetVersion, reviewStatus='approved').
- Fully responsive on mobile and tablet form factors with `ConstrainedBox(maxWidth: 800)`.
- Strict contrast ratios ≥ 4.5:1 for WCAG AA compliance across both Light and Dark themes.
- Support `MediaQuery.disableAnimationsOf(context)` for all custom animations.
- Connect to running app with `dtd` and trigger `hot_reload` when editing Dart files if the app is active.

---

### Task 1: Enriched Authentic Supplications & Category Normalization

**Files:**
- Modify: `assets/data/azkar_release.json`
- Test: `test/core/content/approved_azkar_content_test.dart`
- Test: `test/features/azkar/data/azkar_local_datasource_release_test.dart`

**Interfaces:**
- Consumes: `ZikrModel.fromJson`, `approved_azkar_content.dart` contract
- Produces: Normalized `subcategory` labels (`"أدعية من القرآن"`, `"أدعية نبوية"`, `"دعاء ختم القرآن"`, `"جوامع الدعاء ومناسبات"`) and new authentic supplications (`dua_istikhara`, `dua_travel`, `dua_relief`, `dua_sick_visit`, `dua_sayyid_istighfar`).

- [ ] **Step 1: Write the failing test for new authentic duas and normalized categories**

```dart
// in test/features/azkar/data/azkar_local_datasource_release_test.dart
test('azkar_release.json contains newly added authentic supplications and no duplicate subcategories', () async {
  final jsonStr = await rootBundle.loadString('assets/data/azkar_release.json');
  final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
  final duas = decoded['duas'] as List<dynamic>;

  final ids = duas.map((d) => d['id'] as String).toSet();
  expect(ids.contains('dua_istikhara'), isTrue);
  expect(ids.contains('dua_travel'), isTrue);
  expect(ids.contains('dua_relief'), isTrue);
  expect(ids.contains('dua_sick_visit'), isTrue);

  final subcategories = duas.map((d) => d['subcategory'] as String).toSet();
  expect(subcategories.contains('أدعية قرآنية'), isFalse,
      reason: 'Should be normalized to أدعية من القرآن');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/azkar/data/azkar_local_datasource_release_test.dart`
Expected: FAIL due to missing IDs.

- [ ] **Step 3: Update `assets/data/azkar_release.json`**

Normalize old `"subcategory": "أدعية قرآنية"` to `"أدعية من القرآن"`.
Add new verified authentic supplications:
- `dua_istikhara` (دعاء صلاة الاستخارة - صحيح البخاري)
- `dua_travel` (دعاء السفر - صحيح مسلم)
- `dua_relief` (دعاء تفريج الكرب وقضاء الدين - سنن الترمذي)
- `dua_sick_visit` (دعاء عيادة المريض - سنن أبي داود والترمذي)
- `dua_sayyid_istighfar` (سيد الاستغفار - صحيح البخاري)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/azkar/data/azkar_local_datasource_release_test.dart`
Expected: PASS

- [ ] **Step 5: Run approved content test to guarantee religious release safety**

Run: `flutter test test/core/content/approved_azkar_content_test.dart`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add assets/data/azkar_release.json test/features/azkar/data/azkar_local_datasource_release_test.dart
git commit -m "feat(azkar): normalize dua categories and add authentic supplications"
```

---

### Task 2: Persistent Favorites Store (`AzkarFavoritesStore`)

**Files:**
- Create: `lib/features/azkar/data/datasources/azkar_favorites_store.dart`
- Modify: `lib/core/di/injection.dart`
- Test: `test/features/azkar/data/azkar_favorites_store_test.dart`

**Interfaces:**
- Consumes: `SharedPreferences`
- Produces: `AzkarFavoritesStore` API:
  - `Set<String> getFavorites()`
  - `bool isFavorite(String id)`
  - `Future<bool> toggleFavorite(String id)`
  - `ValueListenable<Set<String>> get favoritesListenable` (or stream/notifier for UI updates)

- [ ] **Step 1: Write unit tests for `AzkarFavoritesStore`**

```dart
// test/features/azkar/data/azkar_favorites_store_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_favorites_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late AzkarFavoritesStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = AzkarFavoritesStore(prefs);
  });

  test('initially has empty favorites', () {
    expect(store.getFavorites(), isEmpty);
    expect(store.isFavorite('dq1'), isFalse);
  });

  test('toggleFavorite adds and removes IDs persistently', () async {
    final added = await store.toggleFavorite('dq1');
    expect(added, isTrue);
    expect(store.isFavorite('dq1'), isTrue);
    expect(store.getFavorites(), contains('dq1'));

    final removed = await store.toggleFavorite('dq1');
    expect(removed, isFalse);
    expect(store.isFavorite('dq1'), isFalse);
    expect(store.getFavorites(), isNot(contains('dq1')));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/azkar/data/azkar_favorites_store_test.dart`
Expected: FAIL (file doesn't exist yet).

- [ ] **Step 3: Implement `AzkarFavoritesStore` and register in DI**

Create `lib/features/azkar/data/datasources/azkar_favorites_store.dart` with `ValueNotifier<Set<String>>` for reactive widget updates.
Register in `lib/core/di/injection.dart` as a lazy singleton.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/azkar/data/azkar_favorites_store_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/azkar/data/datasources/azkar_favorites_store.dart lib/core/di/injection.dart test/features/azkar/data/azkar_favorites_store_test.dart
git commit -m "feat(azkar): add persistent AzkarFavoritesStore"
```

---

### Task 3: Full-Card Tap & Auto-Advance in Azkar Recitation Screen

**Files:**
- Modify: `lib/features/azkar/presentation/pages/azkar_category_page.dart`
- Test: `test/features/azkar/presentation/azkar_category_page_test.dart`

**Interfaces:**
- Consumes: `AzkarCubit`, `AzkarLoaded`, `ZikrSession`
- Produces: Full-card tap gesture detection, auto-advance animation trigger, top bar auto-advance toggle, integrated progress arc.

- [ ] **Step 1: Write widget test for full-card tap & auto-advance**

```dart
// test/features/azkar/presentation/azkar_category_page_test.dart
testWidgets('tapping reading card increments zikr counter', (tester) async {
  // Build AzkarCategoryView with loaded cubit
  // Tap anywhere on the card
  // Verify count increments by 1
});
```

- [ ] **Step 2: Run test to verify initial behavior**

Run: `flutter test test/features/azkar/presentation/azkar_category_page_test.dart`

- [ ] **Step 3: Implement full-card tap, haptics, and auto-advance in `_ActiveAzkarScreenState`**

1. In `_ZikrReaderPage`:
   - Wrap the card container with a `GestureDetector(onTap: onTap, onLongPress: onLongPress)`.
   - Add a subtle pulse/border glow on tap.
   - Refactor the bottom circular counter to be elegantly embedded, displaying `current / total` and circular arc progress.
2. In `_ActiveAzkarScreenState`:
   - Add `bool _autoAdvance = true;` (persisted or stored in session).
   - Add toggle action in the AppBar (`Icons.auto_awesome_rounded` or `Icons.autorenew_rounded`) with tooltip.
   - In `_handleCounterTap`: when `willComplete` is true and `_autoAdvance` is enabled, schedule auto-navigation:
     ```dart
     Future.delayed(const Duration(milliseconds: 350), () {
       if (mounted && _autoAdvance && !state.allDone) {
         _pageController.nextPage(
           duration: const Duration(milliseconds: 300),
           curve: Curves.easeInOut,
         );
       }
     });
     ```
   - Respect `MediaQuery.disableAnimationsOf(context)`.

- [ ] **Step 4: Run tests and verify resolution**

Run: `flutter test test/features/azkar/presentation/azkar_release_ui_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/azkar/presentation/pages/azkar_category_page.dart test/features/azkar/presentation/
git commit -m "feat(azkar): implement full-card tap and auto-advance in recitation screen"
```

---

### Task 4: Instant Search, Normalized Tabs, Bookmarks & Font Scale in Duas

**Files:**
- Modify: `lib/features/azkar/presentation/pages/general_azkar_page.dart`
- Test: `test/features/azkar/presentation/general_azkar_page_test.dart`

**Interfaces:**
- Consumes: `AzkarCubit`, `AzkarFavoritesStore`, `SocialShareSheet`
- Produces: Search bar with instant text filtering, Favorites tab, favorite toggle button with micro-haptic feedback, font scaling control in AppBar.

- [ ] **Step 1: Write widget test for Duas search and favorites filtering**

```dart
// test/features/azkar/presentation/general_azkar_page_test.dart
testWidgets('searching for keyword filters duas list in real time', (tester) async {
  // Enter search text "استخارة"
  // Verify only matching dua is shown
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/azkar/presentation/general_azkar_page_test.dart`

- [ ] **Step 3: Implement Search Bar, Favorites Tab, and Font Size Selector in `GeneralAzkarPage`**

1. Add `TextEditingController _searchController` and `String _searchQuery = ''`.
2. Add `int _fontSizeIndex = 1;` with 3 font sizes (20.0, 24.0, 28.0) and cycling button in `SliverAppBar`.
3. Read `AzkarFavoritesStore` from DI:
   - Add `"المفضلة ❤️"` as a first-class tab alongside normalized categories.
   - Filter items dynamically by selected tab AND search query.
4. Enhance `_ZikrCard`:
   - Add bookmark icon button:
     ```dart
     IconButton(
       icon: Icon(isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isFav ? AppColors.gold : textSecondary),
       onPressed: () => favoritesStore.toggleFavorite(zikr.id),
     )
     ```
   - Support dynamic font size scaling.
   - Add beautiful empty search state when no results match.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/azkar/presentation/general_azkar_page_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/azkar/presentation/pages/general_azkar_page.dart test/features/azkar/presentation/
git commit -m "feat(azkar): add search, bookmarks, font scaling, and cleaned tabs to duas library"
```

---

### Task 5: Dynamic Time-Context Hero & Bento Grid in Azkar Hub

**Files:**
- Create: `lib/features/azkar/presentation/widgets/free_tasbeeh_sheet.dart`
- Modify: `lib/features/azkar/presentation/pages/azkar_page.dart`
- Test: `test/features/azkar/presentation/azkar_page_test.dart`

**Interfaces:**
- Consumes: `AzkarCompletionStore`, `AzkarRepository`, `AppColors`, `AppTypography`
- Produces: Time-context calculation (`isMorningWindow`), dynamic Hero card with live completion stats and 1-tap continuation button, 2x2 Bento grid, and interactive Free Tasbeeh bottom sheet.

- [ ] **Step 1: Create `FreeTasbeehBottomSheet`**

Create `lib/features/azkar/presentation/widgets/free_tasbeeh_sheet.dart`:
- Interactive circular counter with target selector (33, 100, open).
- Haptic feedback per tap.
- Reset counter button with confirmation.

- [ ] **Step 2: Write widget test for Azkar Hub dynamic hero card**

```dart
// test/features/azkar/presentation/azkar_page_test.dart
testWidgets('AzkarPage renders dynamic hero card and bento grid sections', (tester) async {
  // Verify hero card displays current window's azkar title and start button
  // Verify Bento grid cards for morning, evening, duas, and free tasbeeh exist
});
```

- [ ] **Step 3: Refactor `AzkarPage` with Hero Card & Bento Grid**

1. Calculate `isMorning`: `final hour = DateTime.now().hour; final isMorning = hour >= 4 && hour < 15;`.
2. Connect `AzkarCompletionStore` to display live completion counts on the Hero card.
3. Hero Card features:
   - Ambient gradient (Morning: dawn gold & teal; Evening: night sky teal & ink).
   - "أذكار الصباح" / "أذكار المساء" title + subtitle.
   - Linear progress bar showing completed count vs total count.
   - Large prominent button: "متابعة الورد" / "ابدأ الآن".
4. Bento Grid features:
   - 2-column layout with cards for Morning Azkar, Evening Azkar, Duas Library, and Free Tasbeeh.
   - Smooth press animations.
   - Tapping Free Tasbeeh opens `FreeTasbeehBottomSheet.show(context)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/azkar/presentation/azkar_page_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/azkar/presentation/widgets/free_tasbeeh_sheet.dart lib/features/azkar/presentation/pages/azkar_page.dart test/features/azkar/presentation/
git commit -m "feat(azkar): add contextual hero card, bento grid, and free tasbeeh to azkar hub"
```

---

### Task 6: Full Verification, Static Analysis & Polish

**Files:**
- Run static analysis across entire project.
- Execute full Azkar test suite.

- [ ] **Step 1: Run static analysis**

Run: `dart analyze`
Expected: No errors, no warnings.

- [ ] **Step 2: Run all Azkar and Content tests**

Run: `flutter test test/features/azkar/ test/core/content/`
Expected: All tests PASS.

- [ ] **Step 3: Commit any final polish and update walkthrough**

```bash
git commit -am "test(azkar): verify full azkar & duas ui/ux test suite and static analysis"
```
