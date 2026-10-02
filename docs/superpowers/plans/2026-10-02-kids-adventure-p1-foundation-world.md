# Kids Adventure P1 — Foundation, Day/Night World, Talia Everywhere — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the pre-expansion risks (R1 double review scheduling, R5 reward motion), give every kids screen one world that is day from Fajr to Maghrib and night from Maghrib to Fajr, and put Talia (official `assets/talia` poses) on every kids screen.

**Architecture:**
- **R1:** a kids twin of `V2ReviewOutcomeCommitter`. One Isar transaction writes the evidence, the SM-2 projection and the checkpoint, keyed `sessionId|taskId|final`, so a retry is a no-op. The reward reuses the same stable session id, so `awardKidsPoints` dedupes too.
- **World:** a pure phase function plus a `ValueNotifier` controller fed by `PrayerTimesService`. `KidsBackground` (which every kids screen already uses) becomes phase-aware, and a single palette keeps text contrast ≥ 4.5:1 in both phases.

**Tech Stack:** Flutter, flutter_bloc, get_it, Isar 3, `adhan` via `PrayerTimesService`, ARB l10n, flutter_test + mockito, Python + Pillow (asset crop script).

**Spec:**
- [Roadmap & decisions](2026-10-02-talia-adventure-v1-roadmap.md)
- [Adventure design §4, §7, §10](../specs/2026-09-30-talia-adventure-design.md)
- [Gap update R1/R5/R6/N1/N2](../../audits/TALIA_ADVENTURE_GAP_REVIEW_UPDATE_2026-10-02.md)
- [Session UI spec](../specs/2026-10-02-kids-session-playful-ui-design.md)

## Global Constraints

- Quran text and `MemorizationAyahDisplay` are never altered. Any credible risk to Quran text or numbering is P0.
- Adult path unchanged. Shared code only gains optional parameters whose defaults keep today's behaviour (e.g. `audience` defaults to `MemorizationAudience.adult`).
- **Day** = `fajr <= now < maghrib`, **night** otherwise. With no prayer times configured: **day = 06:00 ≤ local time < 18:00**. With no controller registered: **night**.
- Nothing loops under `MediaQuery.disableAnimations`, and nothing moves while recitation audio plays or the child records.
- Every text drawn directly on the scene uses `KidsWorldPalette.onScene` or `.onSceneMuted`. Contrast must be ≥ 4.5:1 against every scene colour, in both phases.
- New ARB keys go in both `app_ar.arb` and `app_en.arb`, then `flutter gen-l10n`.
- Run `dart format` only on files you **created**. For existing files, hand-indent edits and check `git diff --stat` for noise. Relative imports in `lib/`.
- Before `flutter test`: `export TEMP=D:/Flutter/talia_quran/.superpowers/tmp TMP=$TEMP`. Never run two test processes at once.
- **No commits.** The owner reviews and commits. Each task ends with a verification checkpoint.
- Edit `kids_gamified_home_page.dart` and `child_detail_page.dart` surgically. Do not format them.

## Review Focus

1. **App killed after the review commit but before the reward:** reopening and completing again must leave `totalReviews` at +1 and the session log written once. Pinned in Task 2.
2. **A child device with prayer times disabled or no city:** the world still switches at 06:00/18:00 and never throws. Pinned in Task 4.
3. **App left open across Maghrib or Fajr:** the background flips without leaving the screen, and again on resume after sleeping past a boundary. Pinned in Task 5.
4. **Account switch between two sessions:** a kids commit for owner A is invisible to owner B and does not dedupe B's commit. Pinned in Task 1.
5. **Text scale 1.3 on a 320 px Arabic screen with Talia bubbles and the banded top bar:** no overflow on home, journey, stage, completion or session. Pinned in Tasks 7 and 9.

---

### Task 0: Precondition — session UI work is committed

- [ ] **Step 1:** Run `git status --short`. Expected: no changes under `lib/features/memorization_plus/presentation/` and no untracked `assets/images/talia/`. If there are, stop and ask the owner to commit the 2026-10-02 session UI work (N3) first.
- [ ] **Step 2:** Run `flutter test test/features/memorization_plus`. Expected: `All tests passed!` (baseline).

---

### Task 1: `KidsReviewOutcomeCommitter` — idempotent kids review commit (R1, core)

**Files:**
- Modify: `lib/core/memorization/v2/review_outcome_commit_support.dart:16-46` (add the `audience` parameter)
- Create: `lib/core/memorization/v2/kids_review_outcome_committer.dart`
- Test: `test/core/memorization/v2/kids_review_outcome_committer_isar_test.dart`

**Interfaces:**
- Produces:

```dart
// review_outcome_commit_support.dart
static IsarV2Session checkpointFromState(V2SessionState state, {
  required String ownerId, required String sessionId,
  required LearningLaunchContext? launchContext,
  MemorizationAudience audience = MemorizationAudience.adult});

// kids_review_outcome_committer.dart
final class KidsReviewOutcomeCommitter {
  KidsReviewOutcomeCommitter({required Isar isar, required RecordOwnerProvider owner,
    required ScheduleNextReviewUsecase scheduler, CloudSyncQueue? cloudSyncQueue,
    DateTime Function()? now, String Function()? idGenerator});
  /// Returns V2ReviewOutcomeCommitResult (reused from review_outcome_committer.dart).
  Future<V2ReviewOutcomeCommitResult> commitPass({
    required V2SessionState sessionState, required String taskId,
    required PerformanceRating rating, required bool manuallyAssessed,
    double? similarityScore});
}
```

- [ ] **Step 1: Write the failing tests.** Use the Isar harness from `test/core/memorization/v2/review_outcome_committer_isar_test.dart:23-75`: same four schemas, `FixedRecordOwnerProvider`, fixed `now` 2026-10-02 12:00Z, deterministic ids.
  - `first pass schedules once and checkpoints the kids session`:
    - `result.alreadyCommitted == false`.
    - The record at `ReviewRecordIdentity(ownerUserId: 'owner-a', audience: ReviewRecordReadScope.kids, surahId: 114, ayahNumber: 3).storageKey` has `totalReviews == 1`, `createdByModeIndex == ReviewRecordCreatedByMode.kidsMode.index`, `audience == 'kids'`, `cloudDirty == true`.
    - One `IsarReviewEvidenceEvent` exists with `audience == 'kids'` and `idempotencyKey == '${result.sessionId}|114:3:newMemorization|final'`.
    - The `IsarV2Session` under `IsarV2Session.keyFor(ownerId: 'owner-a', audience: MemorizationAudience.kids, surahId: 114)` has `sessionId == result.sessionId`.
    - `isarReviewEffectOutboxs.count() == 0`.
  - `retrying the same session and task changes nothing`: call `commitPass` twice with the same state and `taskId`. The second call returns `alreadyCommitted == true` and the same `sessionId`, and `totalReviews` stays `1`.
  - `a new session for the same ayah counts again`: after the first commit, delete the kids `IsarV2Session`, commit again, and `totalReviews == 2`.
  - `review missions use the review session key`: with `sessionState.isReview == true`, the checkpoint is stored under `keyFor(..., review: true)`.
  - `owner isolation`: commit as `owner-a`, then build a committer with `owner-b` and commit the same ayah/task. B's result has `alreadyCommitted == false`, and A's record keeps `totalReviews == 1`.
  - `adult checkpoint default unchanged`: `checkpointFromState(state, ownerId: 'o', sessionId: 's', launchContext: null).audienceIndex == MemorizationAudience.adult.index`, and with `audience: MemorizationAudience.kids` it equals `MemorizationAudience.kids.index`.

- [ ] **Step 2: Run them to verify they fail.** Run `flutter test test/core/memorization/v2/kids_review_outcome_committer_isar_test.dart`. Expected: compile error, `KidsReviewOutcomeCommitter` not found.

- [ ] **Step 3: Add `audience` to `checkpointFromState`** and pass it into `IsarV2Session.create(audience: audience)`.

- [ ] **Step 4: Implement `KidsReviewOutcomeCommitter.commitPass`.** Mirror `V2ReviewOutcomeCommitter.commitAutomaticPass` (`review_outcome_committer.dart:71-225`) with these exact differences:
  - `audience = ReviewRecordReadScope.kids`, and session key audience `MemorizationAudience.kids` with `review: sessionState.isReview`.
  - The rating is the caller's `rating` (the kids mastery rule, K31), not `ratingFor`. `createdByMode` is `ReviewRecordCreatedByMode.kidsMode` on both the base and the scheduled record.
  - The checkpoint is `checkpointFromState(sessionState, ..., audience: MemorizationAudience.kids)`, so a retry resumes at the recitation step.
  - **No outbox rows.** The `sync` effect uploads adult evidence only.
  - After the transaction, when `!alreadyCommitted`, call `unawaited(_cloudSyncQueue?.enqueue(CloudSyncQueueKind.productionPush))` inside `try/catch`. This is the same push `saveReviewRecord` triggers today (`memorization_plus_repository_impl.dart:296`).
  - Dedupe by `idempotencyKey` only (no caller-supplied `eventId`). `eventId = 'event-${_idGenerator()}'`.

- [ ] **Step 5: Run the tests to verify they pass.** Same command. Expected: `All tests passed!`. Also run `flutter test test/core/memorization/v2/review_outcome_committer_isar_test.dart`. Expected: pass (adult unchanged).

- [ ] **Step 6: Checkpoint.** `flutter analyze lib/core/memorization/v2 test/core/memorization/v2` → `No issues found!`. Run `dart format` on the two new files only.

---

### Task 2: Wire the committer into `KidsModeCubit` (R1, flow)

**Files:**
- Modify: `lib/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart:55-67` (constructor), `:745-860` (`markCompleted`)
- Modify: `lib/core/di/injection.dart:~880-912` (the `KidsModeCubit` factory) and add a `KidsReviewOutcomeCommitter` lazy singleton next to `V2ReviewOutcomeCommitter` (`:610`)
- Test: `test/features/memorization_plus/presentation/cubits/kids_mode_cubit_test.dart`

**Interfaces:**
- Consumes: `KidsReviewOutcomeCommitter.commitPass` (Task 1).
- Produces:
  - A new trailing optional positional constructor parameter `KidsReviewOutcomeCommitter? reviewOutcomeCommitter` (after `activityRecorder`).
  - The task id helper `static String kidsReviewTaskId(int surahId, int ayahNumber, KidsMissionType type) => '$surahId:$ayahNumber:${type.name}'` on `KidsModeCubit`.

- [ ] **Step 1: Write the failing tests.** Extend the file's existing cubit builder (`:89-110`) with a `committer` argument. Use a real `KidsReviewOutcomeCommitter` on the test Isar the file already opens.
  - `completion goes through the kids committer`: after a successful completion, the kids record has `totalReviews == 1`, and the session log passed to `awardKidsPoints` has id `'kids_${commitSessionId}_114_3'`.
  - `award failure then retry does not reschedule`:
    - First run: make `awardKidsPoints` return `Left` once, so the state is `KidsModeError`.
    - Second run: build a new cubit, `load` the same mission (it restores the checkpoint), and complete it again.
    - Expected: `totalReviews == 1`, exactly one kids session log with that id, and the final state is `isCompleted == true`.
  - `without a committer the legacy recordPass path still runs`: the existing tests stay green unchanged.

- [ ] **Step 2: Run them to verify they fail.** Run `flutter test test/features/memorization_plus/presentation/cubits/kids_mode_cubit_test.dart --plain-name "kids committer"`. Expected: FAIL.

- [ ] **Step 3: Implement.** In `markCompleted`, when `_reviewOutcomeCommitter != null`:
  - Replace `_reviewAdapter.recordPass(...)` with `commitPass(sessionState: st.sessionState, taskId: kidsReviewTaskId(st.surahId, st.ayahNumber, _missionType), rating: masteryRating, manuallyAssessed: manualGrade, similarityScore: automaticSimilarity)`.
  - On exception, emit `recordingError: CubitMessageCodes.hifzReviewSaveFailed` and return, as today.
  - Then pass `sessionId: 'kids_${commit.sessionId}_${st.surahId}_${st.ayahNumber}'` to `_awardPoints`.
  - Leave the `null` path unchanged. Register the DI singleton with `cloudSyncQueue: getIt.isRegistered<CloudSyncQueue>() ? getIt<CloudSyncQueue>() : null`.

- [ ] **Step 4: Run the tests to verify they pass.** Run `flutter test test/features/memorization_plus/presentation/cubits/kids_mode_cubit_test.dart`. Expected: `All tests passed!`.

- [ ] **Step 5: Checkpoint.** Run `flutter analyze lib/features/memorization_plus lib/core/di` and `flutter test test/features/memorization_plus test/integration/account_switch_isolation_test.dart`. Expected: pass.

---

### Task 3: Reward image respects reduced motion (R5)

**Files:**
- Modify: `lib/features/memorization_plus/presentation/widgets/kids_reward_dialog.dart:162-176`
- Test: `test/features/memorization_plus/presentation/pages/kids_gamified_completion_page_test.dart`

- [ ] **Step 1: Write the failing test** `reward image is still under reduced motion`. Pump `KidsGamifiedCompletionContent` inside `MediaQuery(data: MediaQueryData(disableAnimations: true))`, then `await tester.pump()`. Expect `tester.hasRunningAnimations` to be `isFalse`.
- [ ] **Step 2: Run it to verify it fails.** Expected: FAIL (the 650 ms tween is running).
- [ ] **Step 3: Implement.** Set `duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 650)`.
- [ ] **Step 4: Run the test to verify it passes.** Expected: PASS.

---

### Task 4: Kids world phase rule (pure)

**Files:**
- Create: `lib/features/memorization_plus/domain/services/kids_world_phase.dart`
- Test: `test/features/memorization_plus/domain/kids_world_phase_test.dart`

**Interfaces:**
- Produces:

```dart
enum KidsWorldPhase { day, night }
KidsWorldPhase kidsWorldPhaseAt(DateTime now, {DateTime? fajr, DateTime? maghrib});
/// The next instant the phase flips (strictly after [now]).
DateTime kidsWorldNextBoundary(DateTime now, {DateTime? fajr, DateTime? maghrib});
const int kKidsWorldFallbackDayStartHour = 6;
const int kKidsWorldFallbackNightStartHour = 18;
```

- [ ] **Step 1: Write the failing tests.** Use local `DateTime(2026, 10, 2, h, m)`, with `fajr = 04:30` and `maghrib = 17:40`.
  - `kidsWorldPhaseAt(04:29) == night`, `(04:30) == day`, `(17:39) == day`, `(17:40) == night`, `(23:59) == night`.
  - Fallback (both null): `(05:59) == night`, `(06:00) == day`, `(17:59) == day`, `(18:00) == night`.
  - Only one of `fajr`/`maghrib` supplied → the fallback is used.
  - `kidsWorldNextBoundary(10:00, ...) == 17:40` today. `(20:00, ...) == ` tomorrow's `04:30` (today's Fajr + 1 day). `(02:00, ...) == 04:30` today.
  - Fallback boundaries: `(12:00) → 18:00`, `(19:00) → next day 06:00`.
- [ ] **Step 2: Run them to verify they fail.** Expected: compile error.
- [ ] **Step 3: Implement both functions.** Compare instants. Approximate tomorrow's Fajr as `fajr.add(Duration(days: 1))`; the controller recomputes on every boundary.
- [ ] **Step 4: Run the tests to verify they pass.** Run `flutter test test/features/memorization_plus/domain/kids_world_phase_test.dart`. Expected: PASS.

---

### Task 5: `KidsWorldPhaseController` — live phase with boundary timer and resume refresh

**Files:**
- Create: `lib/features/memorization_plus/presentation/world/kids_world_phase_controller.dart`
- Modify: `lib/core/di/injection.dart` (register it) and `lib/app.dart:62-72` (refresh on resume)
- Test: `test/features/memorization_plus/presentation/world/kids_world_phase_controller_test.dart`

**Interfaces:**
- Consumes: Task 4.
- Produces:

```dart
typedef KidsWorldPrayerTimesLoader = Future<({DateTime fajr, DateTime maghrib})?> Function();
class KidsWorldPhaseController extends ValueNotifier<KidsWorldPhase> {
  KidsWorldPhaseController({required KidsWorldPrayerTimesLoader prayerTimes,
    DateTime Function() clock = DateTime.now});   // initial value: night
  /// Idempotent; first call resolves the phase and arms the boundary timer.
  void ensureStarted();
  /// Re-reads prayer times, updates value, re-arms the timer.
  Future<void> refresh();
  @override void dispose();   // cancels the timer
}
```

- [ ] **Step 1: Write the failing tests** with `fakeAsync` and a mutable fake clock.
  - `starts at night, resolves to day after ensureStarted at 10:00` (loader returns 04:30/17:40).
  - `flips to night at maghrib without a refresh call`: advance the clock and `async.elapse` to 17:40:01. Expect `value == night`.
  - `loader throwing or returning null uses the 06:00/18:00 fallback`.
  - `refresh after sleeping past fajr updates the value`.
  - `dispose cancels the timer`: `async.pendingTimers` is empty.
- [ ] **Step 2: Run them to verify they fail.** Expected: compile error.
- [ ] **Step 3: Implement.** Arm the timer at `kidsWorldNextBoundary(...) + 1 s`. Catch every loader error and treat it as `null`.
  - DI: `registerLazySingleton<KidsWorldPhaseController>`. The loader calls `getIt<PrayerTimesService>().current(isArabic: true)` and returns `(fajr: s.fajr!, maghrib: s.maghrib!)` when both are non-null, otherwise `null`.
  - `app.dart`: in the `resumed` branch, `if (getIt.isRegistered<KidsWorldPhaseController>()) unawaited(getIt<KidsWorldPhaseController>().refresh());`.
- [ ] **Step 4: Run the tests to verify they pass.** Expected: PASS.

---

### Task 6: `KidsWorldScene` (day + night) and `KidsWorldPalette`

**Files:**
- Create: `lib/features/memorization_plus/presentation/world/kids_world_palette.dart`
- Rename and modify: `presentation/widgets/kids_session_scene.dart` → `presentation/world/kids_world_scene.dart` (class `KidsSessionScene` → `KidsWorldScene`)
- Modify: `kids_gamified_listen_page.dart` and its tests (update references)
- Test: `test/features/memorization_plus/presentation/world/kids_world_palette_test.dart`, `.../kids_world_scene_test.dart`

**Interfaces:**
- Produces:

```dart
final class KidsWorldPalette {
  static const day = KidsWorldPalette._(skyStops: [Color(0xFF5AB6E5), Color(0xFFA8E0F0), Color(0xFF88D2B4)],
      hills: [Color(0xFF8FD18F), Color(0xFF6CBF73)], onScene: Color(0xFF1F2937), onSceneMuted: Color(0xFF374151));
  static const night = KidsWorldPalette._(skyStops: [Color(0xFF0B1437), Color(0xFF1A2E5A), Color(0xFF16384A)],
      hills: [Color(0xFF0F3D35), Color(0xFF0A2925)], onScene: Color(0xFFF8FAFC), onSceneMuted: Color(0xFFCBD5E1));
  final List<Color> skyStops; final List<Color> hills; final Color onScene; final Color onSceneMuted;
  static KidsWorldPalette forPhase(KidsWorldPhase phase);
  /// Phase from the nearest KidsWorldPhaseScope; night when absent.
  static KidsWorldPalette of(BuildContext context);
}
class KidsWorldPhaseScope extends InheritedWidget {   // same file
  const KidsWorldPhaseScope({super.key, required this.phase, required super.child});
  final KidsWorldPhase phase;
  static KidsWorldPhase phaseOf(BuildContext context);  // night when absent
}
class KidsWorldScene extends StatefulWidget {
  const KidsWorldScene({super.key, required this.phase, required this.child, this.animate = true});
}
```

- [ ] **Step 1: Write the failing tests.**
  - Palette: for each phase, for every `c` in `skyStops + hills`, `contrast(onScene, c) >= 4.5` and `contrast(onSceneMuted, c) >= 4.5`. Define `contrast` in the test as `(L1 + 0.05) / (L2 + 0.05)` with `computeLuminance()`.
  - Scene: `night scene never animates under reduced motion` (`hasRunningAnimations` is false). `day scene drifts when animate is true`. `animate: false freezes both phases`.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.**
  - The day painter is the current one with colours taken from `KidsWorldPalette.day`.
  - The night painter draws: the palette sky gradient; about 40 stars at fixed seeded positions in the upper 60 %, each with alpha `0.5 + 0.5*sin(2π(t + i/7))` (constant `0.8` when not animating); a crescent moon (two `0xFFFDE68A` / sky-coloured circles) top-start; and the night hills.
  - One `AnimationController` (60 s repeat) drives clouds by day and twinkle by night, under the same `animate && !disableAnimations` rule.
- [ ] **Step 4: Run the tests to verify they pass.** Also run `kids_gamified_listen_page_test.dart`. Expected: PASS.

---

### Task 7: Phase-aware `KidsBackground`, banded `KidsTopBar`, scene-safe text

**Files:**
- Modify: `lib/features/memorization_plus/presentation/widgets/kids_ui.dart` (`KidsBackground`, `KidsTopBar`)
- Modify: `kids_gamified_listen_page.dart` (use `KidsBackground(animate: !calm)`, delete `_KidsSessionTopBand` and `KidsWorldScene` usage, keep the status shell on `KidsBackground`)
- Modify (text colours on the scene → `KidsWorldPalette.of(context).onScene/onSceneMuted`):
  - `kids_loading_widget.dart` (loading and error texts)
  - `kids_progress_header.dart` (greeting, level, labels drawn outside its own surfaces)
  - `kids_journey_signpost.dart`
  - `kids_house_card.dart` (labels under houses only)
  - `kids_gamified_home_page.dart`, `kids_gamified_journey_page.dart`, `kids_gamified_stage_page.dart` (any direct `Colors.white`/`shellTextPrimary` text not on a card)
- Test: `test/features/memorization_plus/presentation/world/kids_background_test.dart`, plus the existing page tests

**Interfaces:**
- Consumes: Tasks 5 and 6.
- Produces: `KidsBackground({Key? key, required Widget child, bool animate = true})`.
  - It reads `getIt<KidsWorldPhaseController>()` when registered (calling `ensureStarted()` once, via `ValueListenableBuilder`), otherwise uses `KidsWorldPhase.night`.
  - It wraps `child` in `KidsWorldPhaseScope` over `KidsWorldScene`.
  - `KidsTopBar` always paints the `heroCardGradient` band (radius `AppSpacing.radiusXl`, `card25DShadow`) and keeps its white text.

- [ ] **Step 1: Write the failing tests.**
  - `without a registered controller the background is night`: `KidsWorldPhaseScope.phaseOf` inside equals `night`.
  - `with a controller at day the background is day and flips live`: register a controller with a fake loader and clock, pump, set `controller.value = night`, pump. The scope reports `night`.
  - `top bar title sits on the band in both phases`: find the `DecoratedBox` with `heroCardGradient` as an ancestor of the title.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement**, then update the listed files' scene-text colours. Text inside its own opaque card keeps its colours.
- [ ] **Step 4: Run** `flutter test test/features/memorization_plus test/features/quran/kids_quran_reader_page_test.dart`. Expected: `All tests passed!`.

---

### Task 8: Remaining Talia poses and the design reference (R6)

**Files:**
- Create: `tools/crop_talia_poses.py` (the crop used on 2026-10-02: alpha bbox → top 56 % → re-trim → 360 px high, Lanczos, optimized PNG)
- Create: `assets/images/talia/talia_{idle,wave,happy,reading_quran}.png` (generated by the script)
- Create: `docs/superpowers/assets/talia-companion-reference.png` (a byte copy of `assets/talia/talia_reading_quran.png`; the spec's `![...](../assets/talia-companion-reference.png)` link then resolves)
- Modify: `kids_talia_companion.dart` (enum)
- Test: `test/assets/talia_assets_test.dart`

**Interfaces:**
- Produces: `KidsTaliaPose` gains `idle`, `wave`, `happy`, `readingQuran` (assets `assets/images/talia/talia_<name>.png`, with `readingQuran` → `talia_reading_quran.png`).

- [ ] **Step 1: Write the failing test** `every KidsTaliaPose asset is bundled`. For each `KidsTaliaPose.values`, `File(pose.asset).existsSync()` is true and the PNG height (bytes 20–23 of the IHDR) equals `360`.
- [ ] **Step 2: Run it to verify it fails.**
- [ ] **Step 3: Implement.** Run `python tools/crop_talia_poses.py idle wave happy reading_quran`; the script also reproduces the six existing crops when given their names. Add the enum values and copy the reference image.
- [ ] **Step 4: Run** `flutter test test/assets/talia_assets_test.dart`. Expected: PASS.

---

### Task 9: Talia on home, journey, stage, completion and reader (N2)

**Files:**
- Create: `lib/features/memorization_plus/presentation/widgets/kids_talia_moments.dart` (pure pose and bubble selection for non-session screens)
- Modify:
  - `kids_gamified_home_page.dart` (insert a companion after `KidsProgressHeader`)
  - `kids_gamified_journey_page.dart` (companion above the map)
  - `kids_gamified_stage_page.dart` (companion above `KidsStageDetails`)
  - `kids_gamified_completion_page.dart` (celebrating companion above `KidsRewardDialog`)
  - `features/quran/presentation/pages/kids_quran_reader_page.dart` (a 40 px static `readingQuran` avatar as the top bar trailing widget, no bubble)
- Modify: `app_ar.arb`, `app_en.arb`
- Test: `test/features/memorization_plus/presentation/widgets/kids_talia_moments_test.dart`, plus the existing page tests

**Interfaces:**
- Consumes: Task 8's poses, and `KidsTaliaCompanion` (existing).
- Produces:

```dart
enum KidsTaliaMoment { guide, welcomeBack, farewell, journeyDone, mapGuide, stageReady, celebrate }
KidsTaliaMoment kidsHomeTaliaMoment(KidsJourneyLoaded state);
KidsTaliaPose kidsTaliaPoseForMoment(KidsTaliaMoment moment);
String kidsTaliaMomentBubble(BuildContext context, KidsTaliaMoment moment);
```

| Moment | Pose | ARB key | ar | en |
|---|---|---|---|---|
| guide | pointRight | `kidsTaliaGuideBubble` | مهمتك جاهزة، هيا نبدأ! | Your mission is ready, let's go! |
| welcomeBack | wave | `kidsTaliaWelcomeBackBubble` | اشتقت إليك! | I missed you! |
| farewell | wave | `kidsTaliaFarewellBubble` | أحسنت اليوم! نلتقي غدًا | Great work today! See you tomorrow |
| journeyDone | celebrate | `kidsTaliaJourneyDoneBubble` | أتممت رحلتك كلها! | You finished the whole journey! |
| mapGuide | pointRight | `kidsTaliaMapBubble` | هيا نكمل المغامرة! | Let's continue the adventure! |
| stageReady | idle | `kidsTaliaStageReadyBubble` | هل أنت مستعد؟ | Are you ready? |
| celebrate | celebrate | (existing) `kidsTaliaCelebrateBubble` | — | — |

- [ ] **Step 1: Write the failing tests.**
  - `kidsHomeTaliaMoment`, using the same precedence as the home body (`kids_gamified_home_page.dart:258-300`):
    - `dailyGoalCap != null` → `farewell`;
    - `currentStage == null && nextMission == null && progress.ayahsCompleted > 0` → `journeyDone`;
    - `isReturningAfterBreak` → `welcomeBack`;
    - otherwise → `guide`.
  - Page tests:
    - home shows `find.byType(KidsTaliaCompanion)` and the guide bubble text;
    - completion shows the celebrate bubble;
    - the reader shows `Image` with asset `talia_reading_quran.png` and no `KidsTaliaCompanion`;
    - each of home, journey, stage and completion at `Size(320, 640)`, Arabic, `textScaler: TextScaler.linear(1.3)` → `tester.takeException()` is null.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.**
  - Companions on these screens use `animate: true` (they never coexist with recitation playback).
  - The reader avatar never animates.
  - Add the ARB keys and run `flutter gen-l10n`.
- [ ] **Step 4: Run** `flutter test test/features/memorization_plus test/features/quran`. Expected: `All tests passed!`.

---

### Task 10: Day/night preview goldens and final verification

**Files:**
- Create: `test/features/memorization_plus/presentation/kids_world_preview_capture_test.dart`, plus goldens `test/features/memorization_plus/presentation/preview/kids_{home,journey,stage,session,completion}_{day,night}.png`

- [ ] **Step 1: Write the preview test**, following `test/features/home/presentation/widgets/home_preview_capture_test.dart`:
  - Load the real fonts.
  - Register a `KidsWorldPhaseController` whose value is forced to `day`, then `night`.
  - Render at 390×1100 at dpr 2 with Arabic locale and reduced motion on.
  - Use verbatim ayah text read from `assets/data/quran.json` (114:3), never typed.
- [ ] **Step 2: Generate.** Run `flutter test <file> --update-goldens`, then open all 10 PNGs and check:
  - every text is readable on its background;
  - nothing overlaps Talia's bubble;
  - the night scene shows the moon and stars;
  - the day scene shows the sun and clouds.
- [ ] **Step 3: Full verification.** Run `flutter gen-l10n`, then `dart run build_runner build --delete-conflicting-outputs` (no schema change is expected; this confirms it), then `flutter analyze` → `No issues found!`, then `flutter test` → `All tests passed!`.
- [ ] **Step 4: Hand off.** Send the owner the 10 previews and `git status --short`. The owner commits.
