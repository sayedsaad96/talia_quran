# Kids Quran Journey Cartoon Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle the whole-Quran kids journey map into a cartoon island adventure (islands, dashed gold road with coins, star cards, Talia on the current island) without changing its data or behaviour.

**Architecture:** Keep the lazy fixed-extent `ListView.builder` in `KidsQuranJourneyMap` (extent 132 → 200). One pure layout function places the island, card and Talia's foot inside a row; the road painter, the row, and a Talia overlay above the list all read it. A new owner-scoped store reports surahs completed since the last visit; the cubit puts them in state and the map plays a one-time star pop and Talia walk.

**Tech Stack:** Flutter 3.47, flutter_bloc, get_it, shared_preferences, mocktail, flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-25-kids-quran-journey-redesign-design.md` (base page design: `docs/superpowers/specs/2026-10-16-kids-quran-journey-design.md`).

## Global Constraints

- Visual layer only: no change to `buildKidsSurahHouses`, house statuses, routing, jump-confirm dialog, or `assets/data/`.
- No real locking: the lock glyph is a visual for `notStarted`; taps behave exactly as today.
- Coins are decorative only: no balance, counter, or persistence.
- All motion stops when `MediaQuery.disableAnimationsOf(context)` is true (`KidsBackground` already wraps content in `KidsMotionScope`, which folds the guardian `reduceMotion` policy into it); final states render immediately.
- Day/night from `KidsWorldPhaseScope.phaseOf(context)` (night when absent). One sprite set serves both phases.
- Island art: eight transparent 512 px PNGs; no text, letters, calligraphy, numbers, signs, logos, people, or watermarks; no baked glow. Owner approves them before integration.
- Do not use `assets/images/kids/house_current.png` on this map.
- New ARB keys go in both `lib/core/l10n/app_ar.arb` and `app_en.arb`; run `flutter gen-l10n`.
- Relative imports in `lib/`. Run `dart format` only on new files; hand-indent edits to existing files and check `git diff --stat` for noise.
- Before any `flutter test`: `$env:TEMP='D:\Flutter\talia_quran\.superpowers\tmp'; $env:TMP=$env:TEMP`. Never run two test commands at once.
- The working tree holds the owner's uncommitted media-notification work on `codex/quran-media-notification`. Do this work on a new branch `feat/kids-quran-journey-redesign` cut from `main`, and `git add` only the files each task names.

## Review Focus

1. Existing page tests call `pumpAndSettle`; Talia's endless breathing would make them time out. The test helper must pump with `disableAnimations: true`, and the new motion tests use bounded `pump(duration)` (Task 5).
2. `currentSurahId` missing from `houses` (path changed): no Talia, no lit road, no crash (Tasks 4, 5).
3. A celebrated surah more than 3 rows from the current one: no walk; Talia simply stands on the current island (Task 5).
4. A star pop must not replay when its row scrolls out and back in (Task 5).
5. Maghrib passing while the page is open: the road and halos must repaint for night (`shouldRepaint` covers `night`) (Task 4).

---

### Task 1: Pure visuals rules (stars, island choice, surah celebration diff)

**Files:**
- Create: `lib/features/memorization_plus/domain/services/kids_quran_map_visuals.dart`
- Modify: `lib/features/memorization_plus/domain/services/kids_map_celebration.dart` (append)
- Test: `test/features/memorization_plus/domain/kids_quran_map_visuals_test.dart`
- Test: `test/features/memorization_plus/domain/kids_map_celebration_test.dart` (append a group)

**Interfaces:**
- Produces:
  - `int kidsSurahStars(KidsSurahHouse house)`: `completed` → 3; otherwise `(house.progress * 3).floor().clamp(0, 3)`. `needsReview` keeps what progress earned.
  - `enum KidsIsland { palmsLantern, domeHouse, waterfall, sandFort, camel, mushafStand, oasisTent, flowerGarden }` with `String get asset => 'assets/images/kids/islands/island_${name}.png'` (file names use the enum name, e.g. `island_palmsLantern.png`).
  - `KidsIsland kidsIslandForRow(int index)` → `KidsIsland.values[index % 8]`. Keyed by row index, not surah id, because path order is not always sequential surah ids and adjacent rows must differ. (Deliberate refinement of the spec's `kidsIslandFor(surahId)`.)
  - In `kids_map_celebration.dart`: `Set<int> kidsCompletedSurahs(List<KidsSurahHouse> houses)` (status `completed` or `needsReview`) and `Set<int> kidsSurahsToCelebrate({required Set<int>? seenCompleted, required List<KidsSurahHouse> houses})` (null → `{}`, else completed minus seen).

- [ ] **Step 1: Write the failing tests**
  - `stars: 0 progress → 0`, `1/3 → 1`, `2/3 → 2`, `3/7 → 1`, `completed → 3`, `needsReview with 5/5 → 3`, `needsReview with 2/6 → 1`, `ayahCount 0 → 0`.
  - `adjacent rows never share an island`: for `i` in `0..113`, `kidsIslandForRow(i) != kidsIslandForRow(i + 1)`.
  - `every island asset path is under assets/images/kids/islands/`.
  - `first visit celebrates nothing`: `kidsSurahsToCelebrate(seenCompleted: null, houses: [completed 1]) == {}`.
  - `needsReview counts as completed; only new ones`: seen `{1}`, houses 1 completed, 2 needsReview, 3 inProgress → `{2}`.
- [ ] **Step 2: Run** `flutter test test/features/memorization_plus/domain/kids_quran_map_visuals_test.dart test/features/memorization_plus/domain/kids_map_celebration_test.dart` → FAIL (undefined names).
- [ ] **Step 3: Implement** the signatures above.
- [ ] **Step 4: Run** the same command → PASS.
- [ ] **Step 5: Commit** `feat(kids-quran-journey): star, island and surah celebration rules`.

### Task 2: Surah celebration store, backup family, cubit state

**Files:**
- Create: `lib/features/memorization_plus/data/datasources/kids_quran_map_celebration_store.dart`
- Modify: `lib/core/di/injection.dart` (register next to `KidsMapCelebrationStore`, ~line 1238; pass it to `KidsQuranJourneyCubit`, ~line 1533)
- Modify: `lib/core/backup/backup_sections.dart` (`ownerSuffixPrefixes` ~line 108; `_specFor` ~line 357)
- Modify: `lib/features/memorization_plus/presentation/cubits/kids_quran_journey_cubit.dart`
- Test: `test/features/memorization_plus/domain/kids_map_celebration_test.dart` (store group)
- Test: `test/core/backup/backup_roundtrip_test.dart`
- Test: `test/features/memorization_plus/presentation/cubits/kids_quran_journey_cubit_test.dart`

**Interfaces:**
- Consumes: `kidsSurahsToCelebrate`, `kidsCompletedSurahs` (Task 1).
- Produces:
  - `class KidsQuranMapCelebrationStore { KidsQuranMapCelebrationStore(SharedPreferences prefs, RecordOwnerProvider owner); Future<Set<int>> takeNewlyCompleted(List<KidsSurahHouse> houses); }`. Key: `'kids_quran_map_seen_completed_${owner.currentOwnerId}'`, a string list of surah ids. Same semantics as `KidsMapCelebrationStore`: records this visit, and returns `{}` on any error.
  - `KidsQuranJourneyLoaded.celebratedSurahIds` (`Set<int>`, default `const {}`, included in `props`).
  - `KidsQuranJourneyCubit(repo, quran, {KidsQuranMapCelebrationStore? celebrationStore, DateTime Function()? clock})`. When the store is null → `{}`.

- [ ] **Step 1: Write failing store tests**, modelled on the `storeFor` helper in `kids_map_celebration_test.dart`: first visit → `{}`; second visit with one more completed → only that id; repeat → `{}`; unreadable stored value `['x']` → `{}`; owner-b after owner-a → `{}` on its first visit.
- [ ] **Step 2: Write failing backup test.** Add `'kids_quran_map_seen_completed_user-a': <String>['1', '2']` to the round-trip fixture. Assert that it exports as `'kids_quran_map_seen_completed_{owner}'` and restores to `user-b`. Mirror the existing `kids_map_seen_completed_` assertions at lines ~298, ~408, ~594.
- [ ] **Step 3: Write failing cubit tests:** with a fake store returning `{3}` → `Loaded.celebratedSurahIds == {3}`; without a store → `{}`.
- [ ] **Step 4: Run** the three test files → FAIL.
- [ ] **Step 5: Implement.** Store. Add `'kids_quran_map_seen_completed_': null` to `ownerSuffixPrefixes`, and return `_intStringList` for that family in `_specFor`. In the cubit, call `takeNewlyCompleted(houses)` after building houses and inside the existing try. Register the store and inject it in DI.
- [ ] **Step 6: Run** the three test files plus `test/integration/account_switch_isolation_test.dart` → PASS.
- [ ] **Step 7: Commit** `feat(kids-quran-journey): remember surahs seen completed for the map celebration`.

### Task 3: Row layout, restyled card, juz ribbon, stars label

**Files:**
- Create: `lib/features/memorization_plus/presentation/widgets/kids_quran_row_layout.dart`
- Modify: `lib/features/memorization_plus/presentation/widgets/kids_quran_journey_map.dart`
- Modify: `lib/core/l10n/app_ar.arb`, `lib/core/l10n/app_en.arb` (+ `flutter gen-l10n`)
- Test: `test/features/memorization_plus/presentation/widgets/kids_quran_row_layout_test.dart`
- Test: `test/features/memorization_plus/presentation/pages/kids_quran_journey_page_test.dart`

**Interfaces:**
- Consumes: `kidsSurahStars`, `kidsIslandForRow`, `KidsIsland.asset` (Task 1).
- Produces:
  - `const double kKidsQuranJourneyItemExtent = 200;`
  - `class KidsQuranRowLayout { final Rect island; final Rect card; final Offset taliaFoot; final Rect? juzRibbon; }`
  - `KidsQuranRowLayout kidsQuranRowLayout({required int index, required Size size, required TextDirection direction, required bool showJuz})`. Values:
    - Island side: directional start for even rows, end for odd rows (as today).
    - Island width `min(size.width * 0.40, 180)`, height `width * 0.8`, horizontal inset 16, bottom 8.
    - Card from 28% of the width on the island side to the far edge minus 16; height 104; vertically centred 12 below the row centre.
    - `taliaFoot` = island top-centre + (0, 12).
    - `juzRibbon` = 120 × 28 at the top, aligned above the card's far edge; null when `!showJuz`.
  - ARB: `kidsHouseStarsLabel(String earned, String total)`. en `"{earned} of {total} stars"`, ar `"{earned} من {total} نجوم"`.
  - `KidsSurahHouseCard` keeps its constructor and adds `final bool popStars` (default false; used by Task 5).

- [ ] **Step 1: Write failing layout tests** (`Size(400, 200)`):
  - index 0 LTR: island on the left (`island.left == 16`).
  - index 0 RTL: island on the right (`island.right == 384`).
  - index 1 mirrors index 0.
  - Card overlaps the island horizontally by > 0 and stays inside the row.
  - `taliaFoot` is inside `island`.
  - Island width caps at 180 on `Size(800, 200)`.
- [ ] **Step 2: Write failing page tests.** In `_app`, wrap with `MediaQuery(data: MediaQueryData(disableAnimations: true))` so existing `pumpAndSettle` calls stay valid (Review Focus 1). Then add:
  - Card shows 3 star icons, filled count = `kidsSurahStars` (completed → 3 filled; `completedCount: 2, ayahCount: 6` → 1 filled).
  - `notStarted` shows `TaliaKidsIcons.lock`; `needsReview` shows `TaliaKidsIcons.refresh`; `completed` shows `TaliaKidsIcons.starFilled` inside the ring (all exist in `lib/core/icons/talia_icon_data.dart`). Stars in the row use `TaliaKidsIcons.starFilled` / `TaliaKidsIcons.star`.
  - Semantics label contains `'2 of 3 stars'` (en).
  - One `Image` per visible island whose asset is under `assets/images/kids/islands/`, wrapped in `ExcludeSemantics`.
  - No overflow exceptions in `ar` RTL and `en` LTR at `textScaler: TextScaler.linear(1.3)` with a 30-character surah name.
  - Existing tests (lazy build, juz, jump-confirm, opens on current) still pass.
- [ ] **Step 3: Run** both test files → FAIL.
- [ ] **Step 4: Implement.**
  - Each row is a `Stack` positioned from `kidsQuranRowLayout`.
  - Island: `Image.asset(..., cacheWidth: (island.width * devicePixelRatio).round(), errorBuilder: → SizedBox.shrink())` inside `ExcludeSemantics`.
  - Card: parchment gradient, 2.5 px border (`parchmentEdge`, or `goldStar` 3 px plus `KidsTheme.goldGlow` when current), radius `KidsTheme.cardRadius`. Contents: name, ayah count, `LinearProgressIndicator`, a row of 3 stars (`goldStar` filled / `parchmentEdge` empty), and a 52 px `CircularProgressIndicator` ring holding the status glyph.
  - `_JuzRibbon`: gold container with a `CustomPaint` folded tail; the existing `kidsQuranJourneyJuz` text.
  - Remove the inline Talia `pointRight` image from the card (Talia moves to the overlay in Task 5).
- [ ] **Step 5: Run** `flutter gen-l10n`, then both test files → PASS.
- [ ] **Step 6: Commit** `feat(kids-quran-journey): island rows, star cards and juz ribbon`.

### Task 4: Road painter: dashes, coins, night glow, fireflies

**Files:**
- Modify: `lib/features/memorization_plus/presentation/widgets/kids_quran_journey_map.dart` (`KidsQuranRoadPainter` and its use in the row; halo behind the island)
- Test: `test/features/memorization_plus/presentation/widgets/kids_quran_road_painter_test.dart`
- Test: `test/features/memorization_plus/presentation/pages/kids_quran_journey_page_test.dart`

**Interfaces:**
- Consumes: `kidsQuranRowLayout` (Task 3).
- Produces: `KidsQuranRoadPainter({required double hereX, required double previousX, required double nextX, required bool isFirst, required bool isLast, required bool incomingLit, required bool outgoingLit, required bool night, required int seed, double shimmer = 0})`.
  - `incomingLit = currentIndex >= 0 && index <= currentIndex && index > 0`.
  - `outgoingLit = currentIndex >= 0 && index < currentIndex`.
  - `hereX`, `previousX`, `nextX` = `taliaFoot.dx` of this, the previous, and the next row's layout.

- [ ] **Step 1: Write failing tests.**
  - `shouldRepaint` is true when only `night` changes, only `incomingLit` changes, or only `outgoingLit` changes; false when nothing changes.
  - Page test: with `current: 3`, rows 0–1 have `outgoingLit == true`, and row 2 has `incomingLit == true, outgoingLit == false`. Find via `find.byWidgetPredicate((w) => w is CustomPaint && w.painter is KidsQuranRoadPainter)`.
  - With `current` absent from houses (e.g. 999), no row is lit (Review Focus 2).
  - Wrapping in `KidsWorldPhaseScope(phase: KidsWorldPhase.day)` gives `night == false`; with no scope, `night == true`.
  - At night a halo (`DecoratedBox` with a `RadialGradient`, keyed `ValueKey('kids-quran-halo-$surahId')`) exists for completed and current houses only; by day there is none.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.**
  - Dashes: 14 px dash / 10 px gap, stroke 7, round caps, sampled along the existing quadratic curves with `PathMetric.extractPath`.
  - Lit colour `KidsTheme.goldStar`; unlit `KidsTheme.creamParchment` at alpha 0.35.
  - Coin: drawn at the outgoing curve midpoint when `outgoingLit`; radius 11, `goldStar` fill, `houseBrown` rim 2 px, and a small 5-point star in `goldLight`. At night, add a `MaskFilter.blur(BlurStyle.normal, 6)` glow behind the coin at alpha 0.5.
  - Fireflies: at night only, 3 dots of radius 2 in `goldLight` at alpha 0.7, positioned from `Random(seed)`, with `seed` = row index.
  - Day: an elliptical ground shadow under each island (black at alpha 0.18, width 70% of the island, height 12, blurred 4). The halo replaces it at night.
  - Coin shimmer: the coin's highlight alpha runs 0 → 0.6 → 0 once over 600 ms (`TweenAnimationBuilder<double>` around the road `CustomPaint`, passing `shimmer` to the painter) when the row is built. It is skipped (value fixed at 0) when animations are disabled. Add `shimmer` to `shouldRepaint`.
  - Wrap the painter in a `RepaintBoundary`.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(kids-quran-journey): dashed gold road with coins and night glow`.

### Task 5: Talia overlay, breathing, star pop and walk

**Files:**
- Create: `lib/features/memorization_plus/presentation/widgets/kids_quran_talia_overlay.dart`
- Modify: `lib/features/memorization_plus/presentation/widgets/kids_quran_journey_map.dart` (centre the current row, host the overlay, track played pops)
- Modify: `lib/features/memorization_plus/presentation/pages/kids_quran_journey_page.dart` (pass `state.celebratedSurahIds`)
- Test: `test/features/memorization_plus/presentation/widgets/kids_quran_talia_overlay_test.dart`
- Test: `test/features/memorization_plus/presentation/pages/kids_quran_journey_page_test.dart`

**Interfaces:**
- Consumes: `kidsQuranRowLayout`, `kKidsQuranJourneyItemExtent` (Task 3); `KidsQuranJourneyLoaded.celebratedSurahIds` (Task 2); `KidsSurahHouseCard.popStars` (Task 3); `KidsTaliaPose.readingQuran` / `.celebrate`.
- Produces:
  - `KidsQuranJourneyMap` gains `final Set<int> celebratedSurahIds` (default `const {}`).
  - `KidsQuranTaliaOverlay({required ScrollController controller, required int currentIndex, required int? walkFromIndex, required TextDirection direction})`. Renders nothing when `currentIndex < 0`. Talia is 72 × 72, her bottom-centre at the foot position (`index * extent + taliaFoot.dy - controller.offset`), inside `ExcludeSemantics` and `IgnorePointer`.
  - `int? kidsQuranWalkOrigin({required List<int> celebratedIndexes, required int currentIndex})`: the celebrated index nearest to `currentIndex` (ties → the smaller one). Returns null when the list is empty, `currentIndex < 0`, the nearest equals `currentIndex`, or the distance is > 3.

- [ ] **Step 1: Write failing tests.**
  - `kidsQuranWalkOrigin`: `[2], 3 → 2`; `[], 3 → null`; `[3], 3 → null`; `[10], 3 → null` (Review Focus 3); `[1, 5], 3 → 1`.
  - Overlay with `disableAnimations: true`: `talia_reading_quran.png` is shown at the current foot; `hasRunningAnimations` is false after one pump.
  - Overlay with `disableAnimations: false`, no walk: after `pump(Duration(seconds: 1))` the `Transform.scale` value is in `[0.98, 1.02]` and not 1.0. Pump only bounded durations here, never `pumpAndSettle`.
  - Walk: `walkFromIndex: 2, currentIndex: 3`.
    - At t = 0 the pose is `celebrate` at row 2's foot.
    - After `pump(Duration(milliseconds: 1600))` the pose is `readingQuran` at row 3's foot.
    - With `disableAnimations: true` she is at row 3 immediately.
  - Page: `current` not in houses → no Talia image (Review Focus 2).
  - Page: `celebratedSurahIds: {2}` gives row 1's card `popStars: true` once.
    - Scroll it out (`drag` -2000) and back. Its `popStars` is now false (Review Focus 4).
  - Page: opening with `current: 60` places row 59 near the viewport centre: the card's centre y is within ±`extent` of the viewport centre. The old 'opens scrolled to the current house' test still passes.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.**
  - Map: keep `initialScrollOffset`. In a post-frame callback, `jumpTo(clamp(index * extent - (viewportDimension - extent) / 2, 0, maxScrollExtent))`.
  - The overlay sits in a `Stack` above the `ListView` and uses `AnimatedBuilder(animation: Listenable.merge([controller, _breath, _walk]))`.
  - Breathing: `_breath` repeats with reverse over 1500 ms, scale `1 + 0.02 * Curves.easeInOut`. It is not started when `MediaQuery.disableAnimationsOf(context)` is true; in `didChangeDependencies`, stop and reset it when that flips to true.
  - Walk: `_walk` runs 1500 ms (`Curves.easeInOut`), lerping the foot from origin to current with a vertical hop of `-8 * sin(pi * 4 * t)`. Run it once in `initState`'s post-frame callback after the star pop's 600 ms delay.
  - Star pop: in the card, when `popStars` is true and animations are allowed, each filled star scales 0 → 1.2 → 1 (`Curves.elasticOut`, 300 ms) with a 150 ms stagger.
  - The map keeps `final Set<int> _popped` and passes `popStars: celebrated.contains(id) && _popped.add(id)`.
- [ ] **Step 4: Run** both files and the whole `test/features/memorization_plus/` folder → PASS.
- [ ] **Step 5: Commit** `feat(kids-quran-journey): Talia on the current island with breathing and walk`.

### Task 6: Island artwork (owner gate)

**Files:**
- Create: `assets/images/kids/islands/island_<KidsIsland.name>.png` × 8
- Create: `assets/images/kids/islands/generated_island_assets.md`
- Modify: `pubspec.yaml` (add `- assets/images/kids/islands/` after line 174)
- Test: `test/assets/kids_island_assets_test.dart`

**Interfaces:**
- Consumes: `KidsIsland` (Task 1).

- [ ] **Step 1: Write a failing asset test.** For every `KidsIsland`, `File(island.asset).existsSync()` is true, and `pubspec.yaml` contains `assets/images/kids/islands/`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Generate the eight images** with an available image-generation tool. Use one shared style prompt: "storybook cartoon 2.5D game-map sprite, floating rock island with grass top, rounded proportions, soft neutral daylight, no glow, transparent background, square, generous padding". Then add the per-island subject from the spec's list. Add to every prompt: "no text, no letters, no calligraphy, no numbers, no signs, no logos, no people, no watermark". For the mushaf stand, add: "book fully closed, plain cover, no markings".
- [ ] **Step 4: Owner approval gate.** Send all eight to the owner with `SendUserFile`. Do not continue until they approve. Regenerate any image they reject, and inspect each one for stray glyphs before sending.
- [ ] **Step 5: Process.** Downscale each image to 512 × 512 PNG with an alpha channel (Pillow is available: `python -I` script in the scratchpad). Write `generated_island_assets.md`: date, tool, shared and per-island prompts, the exclusions, the processing, and the owner approval date. Add the folder to `pubspec.yaml`.
- [ ] **Step 6: Run** the asset test and `test/features/memorization_plus/presentation/pages/kids_quran_journey_page_test.dart` → PASS.
- [ ] **Step 7: Commit** `feat(kids-quran-journey): approved island artwork`.

### Task 7: Verification and review

- [ ] **Step 1:** `flutter analyze` → no new issues in touched files.
- [ ] **Step 2:** `flutter test test/features/memorization_plus test/core/backup test/assets test/integration/account_switch_isolation_test.dart` → all pass. Record the counts.
- [ ] **Step 3:** Run on an emulator. Screenshot the map at night and by day (switch phase in the labs flags page if available, or change the device time). Also screenshot a celebration (complete a short surah or seed the store). Compare against the reference concept and send the screenshots to the owner.
- [ ] **Step 4:** Ask `opus-architecture-reviewer` to review Task 2 (owner-scoped prefs key, backup family, fail-closed behaviour) and the reduce-motion handling in Task 5.
- [ ] **Step 5:** Fix the findings, re-run Step 2, and commit.
