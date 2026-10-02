# Kids Adventure P2 — Daily Missions, Reading Mission, Treasures, Regions — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the Adventure layer on top of the existing kids learning path:

- «مهماتي اليوم»: up to 3 cards. P2 ships learning + reading; P3 adds the home mission.
- A reading mission the child confirms in the kids Mushaf.
- «كنوزي» (treasures): kids certificates plus region badges.
- Five map regions over the unchanged `KidsJourneyPath`.

**Architecture:** No parallel progress store. Mission and region state is **derived**:

- Today's learning status comes from the kids session logs (immutable, already deduped).
- Reading status comes from a new owner-scoped `KidsReadingReceiptStore`.
- Memorized surahs come from canonical reward logs plus surah ayah counts.

Pure rules live in `domain/services`. Cubits and pages read them.

**Tech Stack:** Flutter, flutter_bloc, get_it, go_router, SharedPreferences, ARB l10n, flutter_test + mockito/mocktail.

**Spec:**
- [Roadmap & decisions](2026-10-02-talia-adventure-v1-roadmap.md)
- [Adventure design §2, §4, §10](../specs/2026-09-30-talia-adventure-design.md)
- Depends on [P1](2026-10-02-kids-adventure-p1-foundation-world.md): `KidsWorldPalette`, `KidsTaliaPose.happy`, `KidsChunkyButton`.

## Global Constraints

- Everything in P1's Global Constraints applies.
- The Mushaf and free reading are never locked behind a mission. Missions never raise the new-ayah limit (`KidsDailyBudget` stays the only gate).
- Opening a page, or playing audio, never completes a mission. Only an explicit confirmation does.
- At most **3** mission cards per day. P2 fills at most 2.
- Day key = the local calendar date `yyyy-MM-dd` (`DateTime.now()` local).
- Region names are UI copy (non-religious). No Quran or hadith text is added.
- Owner-scoped storage: every new SharedPreferences key embeds `RecordOwnerProvider.currentOwnerId`.

## Review Focus

1. **The child confirms the same page twice, or two pages in one day:** the reading mission completes once, and the receipt keeps unique pages. Pinned in Task 2.
2. **Day rollover while the app stays open (23:59 → 00:01):** cards for the new day show as available after a home refresh. Pinned in Task 1 (rule) and Task 4 (refresh on resume reuses the existing `load`).
3. **The daily limit is reached:** the learning card shows the existing day-complete card, and the reading card stays available. Pinned in Task 4.
4. **A surah is memorized partly from cloud-merged logs** (logs from another device): the treasures and regions count it once. Pinned in Task 5.
5. **Account switch:** receipts and treasures of owner A never show for owner B. Pinned in Tasks 2 and 6.

---

### Task 1: Daily missions rule (pure)

**Files:**
- Create: `lib/features/memorization_plus/domain/services/kids_daily_missions.dart`
- Test: `test/features/memorization_plus/domain/kids_daily_missions_test.dart`

**Interfaces:**
- Produces:

```dart
enum KidsDailyMissionKind { learning, reading, home }
enum KidsDailyMissionStatus { available, completed }
final class KidsDailyMission extends Equatable {
  const KidsDailyMission({required this.id, required this.kind, required this.status, this.learning, this.homeMissionId});
  final String id;            // '$dayKey:${kind.name}' (home: '$dayKey:home:$homeMissionId')
  final KidsDailyMissionKind kind;
  final KidsDailyMissionStatus status;
  final KidsNextMission? learning;
  final String? homeMissionId; // P3
}
String kidsDayKey(DateTime localNow);   // 'yyyy-MM-dd'
const int kKidsMaxDailyMissions = 3;
List<KidsDailyMission> resolveKidsDailyMissions({
  required DateTime now, required KidsNextMission? learning, required bool dayGoalReached,
  required List<KidsSessionLog> logs, required Set<int> pagesReadToday,
  int maxMissions = kKidsMaxDailyMissions,
});
```

- [ ] **Step 1: Write the failing tests.**
  - `learning card first, reading second`: kinds `[learning, reading]`, both `available` when there are no logs today and no pages.
  - `learning completes after any positive log today`: a log with `completedAt` today and `pointsEarned > 0` → learning `completed`; the card still carries `learning` (the child may continue).
  - `yesterday's log does not complete today` (log at the previous local day 23:59).
  - `reading completes with one confirmed page`.
  - `day goal reached and no learning mission`: the learning card is present as `completed` when there is a log today, and **absent** when there is none. Reading is always present.
  - `maxMissions: 1` returns only the learning card. `maxMissions: 0` returns `[]`.
  - `ids are stable per day`: `'2026-10-02:learning'`, `'2026-10-02:reading'`.
- [ ] **Step 2: Run them to verify they fail.** Expected: compile error.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests to verify they pass.** Expected: PASS.

---

### Task 2: `KidsReadingReceiptStore`

**Files:**
- Create: `lib/features/memorization_plus/data/datasources/kids_reading_receipt_store.dart`
- Modify: `lib/core/di/injection.dart` (lazy singleton next to `KidsMapCelebrationStore`)
- Test: `test/features/memorization_plus/data/kids_reading_receipt_store_test.dart`

**Interfaces:**
- Produces:

```dart
class KidsReadingReceiptStore {
  KidsReadingReceiptStore(SharedPreferences prefs, RecordOwnerProvider owner, {DateTime Function()? clock});
  /// Records [pageNumber] (1..604) for today; returns today's unique pages.
  Future<Set<int>> recordPage(int pageNumber);
  Future<Set<int>> pagesOn(String dayKey);
  static const int retainDays = 60;
}
```

The key is `'kids_reading_receipts_${owner.currentOwnerId}'`. The value is a JSON map `dayKey → sorted unique pages`. Entries older than `retainDays` are pruned on write.

- [ ] **Step 1: Write the failing tests.**
  - The same page twice gives `{12}`.
  - Two pages give `{12, 13}`.
  - `pagesOn` for another day is empty.
  - Owner B sees nothing owner A recorded.
  - Page `0` or `605` throws `ArgumentError`.
  - Corrupt JSON → `pagesOn` returns `{}`, and the next `recordPage` overwrites it cleanly.
  - Entries 61 days old are pruned.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement**, and register the store in DI.
- [ ] **Step 4: Run the tests to verify they pass.**

---

### Task 3: «قرأت هذه الصفحة» in the kids Mushaf

**Files:**
- Modify: `lib/features/quran/presentation/pages/kids_quran_reader_page.dart:115-225`
- Modify: `app_ar.arb`, `app_en.arb`
  - `kidsReaderConfirmPage`: «قرأت هذه الصفحة» / "I read this page"
  - `kidsReaderPageConfirmed`: «أحسنت! سُجّلت قراءتك» / "Well done! Your reading is saved"
- Test: `test/features/quran/kids_quran_reader_page_test.dart`

**Interfaces:**
- Consumes: `KidsReadingReceiptStore.recordPage` (Task 2), `QuranPageCubit.confirmRead(pageNumber)` (existing, ordinary reading; the kids reader is free reading, not Khatmah), `KidsChunkyButton` (P1), and `KidsTaliaPose.happy` (P1).

- [ ] **Step 1: Write the failing tests.**
  - `confirm button records the page once`: tap `ValueKey('kids-reader-confirm-page')`. Expect `confirmRead(page)` to be called once, the store to hold `{page}`, and the button to be replaced by the confirmed chip (`kidsReaderPageConfirmed` text).
  - `turning to another page shows the button again`.
  - `confirmation failure keeps the button and shows no success`: the store throws, so no success chip appears.
  - `the button never appears while audio plays` (no reward for playback).
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.**
  - Add a `KidsChunkyButton(tone: green, icon: Icons.check_rounded)` below the Mushaf page.
  - On tap, call `await _quranPageCubit.confirmRead(page)`. If it returns true, `await store.recordPage(page)`, then show a 2-second `KidsTaliaCompanion(pose: happy)` toast.
  - Read the store via `getIt` when registered; hide the button otherwise.
- [ ] **Step 4: Run** `flutter test test/features/quran`. Expected: PASS.

---

### Task 4: «مهماتي اليوم» on the kids home

**Files:**
- Modify: `kids_journey_state.dart` (add `final List<KidsDailyMission> dailyMissions;`, default `const []`, plus `copyWith` and props)
- Modify: `kids_journey_cubit.dart:58-...` (with `followFrontier`, also load today's pages and compute missions)
- Create: `lib/features/memorization_plus/presentation/widgets/kids_daily_mission_tile.dart`
- Modify: `kids_gamified_home_page.dart:258-300` (after the existing learning card or day-complete card, render a tile for each non-learning mission, plus a header «مهماتي اليوم»)
- Modify: `injection.dart` (pass `readingPagesLoader` to `KidsJourneyCubit`)
- Modify: ARB keys
  - `kidsDailyMissionsTitle`: «مهماتي اليوم» / "Today's missions"
  - `kidsReadingMissionTitle`: «اقرأ صفحة من مصحفك» / "Read a page of your Mushaf"
  - `kidsMissionDone`: «تمّت ✓» / "Done ✓"
- Test: `test/features/memorization_plus/presentation/cubits/kids_journey_cubit_test.dart`, `.../pages/kids_gamified_home_page_test.dart`

**Interfaces:**
- Consumes: Task 1 and Task 2.
- Produces:
  - `typedef KidsReadingPagesLoader = Future<Set<int>> Function();` (today's pages). It is a new named constructor parameter `readingPagesLoader` on `KidsJourneyCubit`. When `null`, the reading mission is omitted.
  - `KidsDailyMissionTile({required KidsDailyMission mission, required VoidCallback onTap})`. The reading tile's `onTap` opens `kidsQuranReaderLocation(state.surahId)`.

- [ ] **Step 1: Write the failing tests.**
  - Cubit: with logs from today and pages `{5}`, `state.dailyMissions` has kinds `[learning, reading]`, both `completed`.
  - Cubit: a loader error leads to the reading mission being omitted (fail-open, no error state).
  - Home: the reading tile is visible with `kidsReadingMissionTitle`. With `dailyGoalCap: 3`, the day-complete card **and** the reading tile both show.
  - Home: a completed tile shows `kidsMissionDone` and keeps `Semantics(label: …)` with its title.
  - Home at 320 px, Arabic, text scale 1.3: no exception.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.** The learning card stays the existing `KidsMissionCard`/`KidsDayCompleteCard`; the list adds the rest. The «مهماتي اليوم» header text uses `KidsWorldPalette.of(context).onScene`.
- [ ] **Step 4: Run** `flutter test test/features/memorization_plus`. Expected: PASS.

---

### Task 5: Regions and memorized surahs (pure)

**Files:**
- Create: `lib/features/memorization_plus/domain/services/kids_adventure_regions.dart`
- Test: `test/features/memorization_plus/domain/kids_adventure_regions_test.dart`

**Interfaces:**
- Produces:

```dart
enum KidsRegionId { beginning, palmOasis, flowerValley, starMountain, pearlSea }
final class KidsAdventureRegion { const KidsAdventureRegion(this.id, this.surahIds); final KidsRegionId id; final List<int> surahIds; }
const List<KidsAdventureRegion> kKidsAdventureRegions = [
  KidsAdventureRegion(KidsRegionId.beginning, [1]),
  KidsAdventureRegion(KidsRegionId.palmOasis, [114, 113, 112, 111, 110, 109]),
  KidsAdventureRegion(KidsRegionId.flowerValley, [108, 107, 106, 105, 104, 103, 102, 101, 100]),
  KidsAdventureRegion(KidsRegionId.starMountain, [99, 98, 97, 96, 95, 94, 93, 92, 91, 90]),
  KidsAdventureRegion(KidsRegionId.pearlSea, [89, 88, 87, 86, 85, 84, 83, 82, 81, 80, 79, 78]),
];
Set<int> kidsMemorizedSurahIds(List<KidsSessionLog> logs, Map<int, int> ayahCountBySurah);
final class KidsRegionProgress { final KidsAdventureRegion region; final int memorized; bool get isComplete; }
List<KidsRegionProgress> kidsRegionProgress(Set<int> memorizedSurahIds);
KidsAdventureRegion kidsRegionOf(int surahId);   // StateError when the surah is off the path
```

- [ ] **Step 1: Write the failing tests.**
  - `regions cover KidsJourneyPath.surahIds exactly once, in path order`: flattening `kKidsAdventureRegions` equals `KidsJourneyPath.surahIds`.
  - `a surah is memorized when every ayah has a canonical log`: use `KidsSessionLogsCloudMerge.isCanonicalRewardLog` and union each log's `ayahNumbers` with `ayahNumber`. With 114 (6 ayahs) and logs for ayahs 1–6 → `{114}`; logs for 1–5 → `{}`.
  - Review-only logs (`pointsEarned > 0`, `missionType == dueReview`) do not count.
  - Duplicate logs from two devices for the same ayah → counted once.
  - `kidsRegionProgress({1, 114})`: `beginning` complete, `palmOasis` memorized 1 of 6.
  - `kidsRegionOf(112) == palmOasis`. `kidsRegionOf(2)` throws `StateError`.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests to verify they pass.**

---

### Task 6: «كنوزي» — treasures page

**Files:**
- Create: `lib/features/memorization_plus/presentation/cubits/kids_treasures_cubit.dart` (+ state in the same file, `part`-free)
- Create: `lib/features/memorization_plus/presentation/pages/kids_treasures_page.dart`
- Modify: `lib/core/router/app_router.dart` (`AppRoutes.memorizationPlusKidsTreasures = '/memorization-plus/kids-treasures'`, with redirect `MemorizationRouteGuard.kidsOnlyRedirect()`)
- Modify: `kids_progress_header.dart` (a «كنوزي» chip with `ValueKey('kids-home-treasures')` that pushes the route; the header gets an optional `VoidCallback? onTreasuresTap`)
- Modify: `kids_gamified_home_page.dart` (wire the callback)
- Modify: `injection.dart` (factory)
- Modify: ARB keys
  - `kidsTreasuresTitle`: «كنوزي» / "My treasures"
  - `kidsTreasuresEmpty`: «احفظ أول سورة لتجد أول كنز!» / "Memorize your first surah to find your first treasure!"
  - `kidsRegionBeginning`: «البداية» / "The beginning"
  - `kidsRegionPalmOasis`: «واحة النخيل» / "Palm Oasis"
  - `kidsRegionFlowerValley`: «وادي الأزهار» / "Flower Valley"
  - `kidsRegionStarMountain`: «جبل النجوم» / "Star Mountain"
  - `kidsRegionPearlSea`: «بحر اللؤلؤ» / "Pearl Sea"
  - `kidsRegionProgress`: «{memorized} من {total} سور» / "{memorized} of {total} surahs" (placeholders as `int`, rendered with `context.numText`)
- Test: `test/features/memorization_plus/presentation/cubits/kids_treasures_cubit_test.dart`, `.../pages/kids_treasures_page_test.dart`

**Interfaces:**
- Consumes:
  - Task 5.
  - `AchievementService.getEarnedCertificates(isKids: true)`.
  - `MemorizationPlusRepository.getKidsSessionLogs()`.
  - `QuranRepository.getSurahs()` (`Surah.ayahCount`).
- Produces:

```dart
sealed class KidsTreasuresState
class KidsTreasuresLoading
class KidsTreasuresLoaded(List<KidsRegionProgress> regions, List<CertificateAward> certificates)
class KidsTreasuresError(String message)   // cubit message code
class KidsTreasuresCubit extends Cubit<KidsTreasuresState> { Future<void> load(); }
```

- [ ] **Step 1: Write the failing tests.**
  - Cubit: logs completing 114 plus one kids certificate → `regions[1].memorized == 1` and `certificates.length == 1`.
  - Cubit: a surahs-load failure → `KidsTreasuresError`.
  - Page: five region cards in order, each with its name and progress text. A complete region shows a gold badge (`Icons.workspace_premium_rounded`).
  - Page: no certificates and no memorized surah → `kidsTreasuresEmpty` with Talia `encourage`.
  - Page: an adult profile is redirected (router guard test, following the existing kids routes' guard tests).
  - Page at 320 px, Arabic, text scale 1.3 → no exception.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.** The page uses `KidsBackground` and `KidsTopBar`; region cards are opaque cream cards (P1 style); certificates reuse `CertificateAward.titleAr/titleEn`.
- [ ] **Step 4: Run** `flutter test test/features/memorization_plus test/core/router`. Expected: PASS.

---

### Task 7: Region banner on the journey map

**Files:**
- Modify: `kids_gamified_journey_page.dart` (a banner above the map: region name + `kidsRegionProgress`, with Talia `mapGuide` from P1 alongside)
- Modify: `kids_journey_cubit.dart`/`kids_journey_state.dart` (`final KidsRegionProgress? currentRegion;`, computed with the same loaders as Task 6. `null` when the surah is off the path or a loader fails)
- Test: `.../pages/kids_gamified_journey_page_test.dart`, `.../cubits/kids_journey_cubit_test.dart`

- [ ] **Step 1: Write the failing tests.**
  - The journey for surah 113, with 114 memorized, shows `واحة النخيل` and `١ من ٦ سور` (Arabic digits via `numText`).
  - The banner is absent when `currentRegion == null`.
  - Completing the last surah of a region shows the gold badge on the banner.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Full verification.** Run `flutter gen-l10n`, then `flutter analyze` → `No issues found!`, then `flutter test` → `All tests passed!`. Add home (with missions) and treasures (day and night) to P1's preview test and review the PNGs. Hand off to the owner for commit.
