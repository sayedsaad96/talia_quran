# Kids Path Improvements (K31–K37) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the seven remaining kids-path improvements (honest STT mastery, word-level feedback, gentle return, simpler rewards, parent tip, session-time note, map glow) without touching the adult path.

**Architecture:** Each piece is a small pure rule (Dart, no Flutter) plus a thin UI change. Rules live next to their feature (`domain/services`, `domain/entities`, cubit state); UI reads them through existing cubits/pages. Shared code is only extended with optional parameters whose defaults keep today's behaviour.

**Tech Stack:** Flutter, flutter_bloc Cubits, get_it, SharedPreferences, ARB l10n (`flutter gen-l10n`), flutter_test + mocktail/mockito.

**Spec:** `docs/superpowers/specs/2026-09-29-kids-path-improvements-design.md`

## Global Constraints

- Quran text is never generated or altered; highlighted text must reassemble to the original string character-for-character.
- Adult path unchanged: shared widgets/engine only gain optional parameters with backwards-compatible defaults.
- Fail-open for learning (a storage/read error never blocks a child); fail-closed for decoration (no glow on read error).
- Spoken/recognized text is never persisted; it may exist in memory only.
- New ARB keys go in both `lib/core/l10n/app_ar.arb` and `app_en.arb`, then `flutter gen-l10n`.
- `dart format` only the files you edited — never whole directories (the tree holds the owner's uncommitted work). `child_detail_page.dart`, `family_dashboard_page.dart`, `kids_gamified_home_page.dart` contain owner work: edit surgically, do not format them.
- **No commits** — the owner reviews and commits. Each task ends with a verification checkpoint instead.
- Verify each task: `flutter analyze <edited files>` → "No issues found!", then the task's tests.

## Review Focus

- A long ayah whose Uthmani text contains standalone waqf marks (e.g. `ۖ`) as whitespace-separated tokens — word highlights must stay aligned and the text unchanged (Task 2).
- A child whose `lastSessionAt` is null (never practised) must not see "welcome back" (Task 3).
- Session-time note when today's logs have zero duration (old logs) — must not trigger (Task 6).
- The first ever visit to a surah's map must not make every completed house glow (Task 7).
- Reduced motion on the map glow: no animation controller runs (Task 7).

---

### Task 1: K31 — Only an exact recitation is "excellent"

**Files:**
- Modify: `lib/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart` (`startRecording` → `markCompleted`, `_masteryRatingFor`)
- Test: `test/features/memorization_plus/presentation/cubits/kids_mode_cubit_test.dart`

**Interfaces:**
- Produces: `markCompleted({bool manualGrade = false, String? automaticSpokenText, double? automaticSimilarity})`

- [ ] **Step 1: Write the failing tests** — add an optional `V2SessionEngine? engine` parameter to the test's `buildCubit` (`engine ?? V2SessionEngine()`), then add:

```dart
group('only an exact recitation is excellent (K31)', () {
  KidsModeCubit fuzzyCubit(String words) {
    repository.awardCompleter = Completer()
      ..complete(Right(KidsCompletionResult(
        progress: const KidsProgress.initial().addPoints(10),
        pointsEarned: 10, starsEarned: 1, alreadyCompleted: false)));
    return buildCubit(
      recorder: _FakeKidsRecitationRecorder(
        result: KidsRecitationCaptureResult.captured(words: words)),
      policy: KidsSessionPolicy.forAge(6),
      engine: V2SessionEngine().withPassThreshold(kKidsPassThreshold),
    );
  }

  test('a near-exact pass is average, without the excellence bonus', () async {
    await cubit.close();
    cubit = fuzzyCubit('one two three four wrong'); // 4/5 = 0.8
    await cubit.load(114, 1, 'one two three four five');
    cubit.debugSetLoopCount(3);
    await cubit.tryFromMemory();
    await cubit.startRecording();
    expect((cubit.state as KidsModeLoaded).isCompleted, isTrue);
    expect(repository.lastMasteryRating, PerformanceRating.average);
  });

  test('an exact pass stays excellent', () async {
    await cubit.close();
    cubit = fuzzyCubit('one two three four five');
    await cubit.load(114, 1, 'one two three four five');
    cubit.debugSetLoopCount(3);
    await cubit.tryFromMemory();
    await cubit.startRecording();
    expect(repository.lastMasteryRating, PerformanceRating.excellent);
  });
});
```

- [ ] **Step 2: Run** `flutter test test/features/memorization_plus/presentation/cubits/kids_mode_cubit_test.dart --plain-name "K31"` — expect the near-exact test to FAIL (rating excellent).

- [ ] **Step 3: Implement** — in `startRecording`, pass the score: `await markCompleted(automaticSpokenText: capture.recognizedWords, automaticSimilarity: evalResult.similarityScore);`. Add `double? automaticSimilarity` to `markCompleted`, and cap the rating:

```dart
final masteryRating = _masteryRatingFor(
  failureCount: failureCount,
  hintLevel: effectiveHint,
  // K31: STT tolerance (kKidsPassThreshold) lets a near match pass, but
  // only an exact recitation is evidence of excellent mastery.
  exactRecitation: manualGrade || (automaticSimilarity ?? 1.0) >= 1.0,
);
```

```dart
PerformanceRating _masteryRatingFor({
  required int failureCount,
  required V2HintLevel hintLevel,
  bool exactRecitation = true,
}) {
  if (hintLevel == V2HintLevel.fullAyah || failureCount >= 2) {
    return PerformanceRating.weak;
  }
  if (hintLevel == V2HintLevel.firstWord || failureCount == 1 || !exactRecitation) {
    return PerformanceRating.average;
  }
  return PerformanceRating.excellent;
}
```

- [ ] **Step 4: Run** the K31 tests and the whole `kids_mode_cubit_test.dart` — PASS.
- [ ] **Step 5: Checkpoint** — `dart format` + `flutter analyze` on the two files.

---

### Task 2: K32 — Show which words were right after a miss

**Files:**
- Create: `lib/features/memorization_plus/domain/services/kids_recalled_words.dart`
- Modify: `lib/core/widgets/memorization_ayah_display.dart` (optional `wordHighlights`)
- Modify: `lib/features/memorization_plus/presentation/widgets/kids_ayah_card.dart` (pass-through)
- Modify: `kids_mode_state.dart` (`recalledWords`), `kids_mode_cubit.dart` (set/clear), `kids_gamified_listen_page.dart` (pass to card)
- Test: `test/features/memorization_plus/domain/kids_recalled_words_test.dart`, `test/core/widgets/memorization_ayah_display_highlight_test.dart`, cubit test

**Interfaces:**
- Produces: `List<bool> kidsRecalledWords({required String targetText, required String spokenText})` — one flag per `\S+` token of `targetText`, in order.
- Produces: `List<InlineSpan> highlightWordSpans(String text, List<bool> flags, {required TextStyle highlight})` in `memorization_ayah_display.dart`.
- Produces: `KidsModeLoaded.recalledWords` (`List<bool>?`).

- [ ] **Step 1: Failing tests**

```dart
// kids_recalled_words_test.dart
test('flags each target word in order and ignores extra spoken words', () {
  expect(
    kidsRecalledWords(targetText: 'a b c d', spokenText: 'a x c d extra'),
    [true, false, true, true],
  );
});
test('silence recalls nothing', () {
  expect(kidsRecalledWords(targetText: 'a b', spokenText: ''), [false, false]);
});

// memorization_ayah_display_highlight_test.dart
test('highlight spans reassemble the original text exactly', () {
  const text = 'قُلْ هُوَ  ٱللَّهُ ۖ أَحَدٌ';
  final spans = highlightWordSpans(text, [true, false, true, false, true],
      highlight: const TextStyle(backgroundColor: Colors.green));
  expect(spans.map((s) => (s as TextSpan).text).join(), text);
});
test('mismatched flag counts fall back to plain text', () {
  expect(highlightWordSpans('a b', [true], highlight: const TextStyle()), isEmpty);
});
```

Cubit test: after a mismatch (`captured(words: 'different words')` against `'ayah text'`), `state.recalledWords` equals `[false, false]`; after the next `startRecording` begins it is null.

- [ ] **Step 2: Run** — FAIL (missing symbols).

- [ ] **Step 3: Implement**

```dart
// kids_recalled_words.dart
import '../../../../core/memorization/v2/recitation_word_diff.dart';

/// K32 — for each word of the ayah, in order, whether the child recited it.
/// Extra spoken words are dropped and nothing spoken is kept.
List<bool> kidsRecalledWords({required String targetText, required String spokenText}) {
  final diff = const RecitationWordDiffer().diff(targetText: targetText, spokenText: spokenText);
  return [
    for (final word in diff.words)
      if (word.status != RecitationWordStatus.extra)
        word.status == RecitationWordStatus.match,
  ];
}
```

```dart
// memorization_ayah_display.dart (top level)
/// Splits [text] into its original words and separators; word i takes
/// [highlight] when flags[i] is true. Returns [] when the counts differ, so the
/// caller renders plain text — the Quran text is never re-assembled wrongly.
List<InlineSpan> highlightWordSpans(String text, List<bool> flags, {required TextStyle highlight}) {
  final words = RegExp(r'\S+').allMatches(text).toList();
  if (words.length != flags.length) return const [];
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (var i = 0; i < words.length; i++) {
    final match = words[i];
    if (match.start > cursor) spans.add(TextSpan(text: text.substring(cursor, match.start)));
    spans.add(TextSpan(text: match.group(0), style: flags[i] ? highlight : null));
    cursor = match.end;
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return spans;
}
```

In `MemorizationAyahDisplay` add `this.wordHighlights` (`List<bool>?`) and `this.highlightColor` (`Color?`); render `Text.rich(TextSpan(children: spans), …)` with the same key, alignment and `textStyle(color: textColor)` when `highlightWordSpans` returns a non-empty list, else the existing `Text`. `KidsAyahCard` gains `recalledWords` and passes `wordHighlights: recalledWords, highlightColor: KidsTheme.forestGreen.withValues(alpha: 0.18)`.

State: `final List<bool>? recalledWords;` + `copyWith({List<bool>? recalledWords, bool clearRecalledWords = false})` + props. Cubit: on mismatch emit `recalledWords: kidsRecalledWords(targetText: current.ayahText, spokenText: capture.recognizedWords)`; at recording start and on pass emit `clearRecalledWords: true`. Listen page passes `recalledWords: state.recalledWords` to `KidsAyahCard` (only shown while the text is visible, i.e. remediation).

- [ ] **Step 4: Run** the new tests, the cubit test, `kids_gamified_listen_page_test.dart`, and every adult test using `MemorizationAyahDisplay` (`flutter test test/features/memorization_plus test/core/widgets`) — PASS.
- [ ] **Step 5: Checkpoint** — format/analyze the edited files.

---

### Task 3: K33 — Gentle welcome back after a break

**Files:**
- Create: `lib/features/memorization_plus/domain/services/kids_return_policy.dart`
- Create: `lib/features/memorization_plus/presentation/widgets/kids_welcome_back_card.dart`
- Modify: `kids_journey_state.dart` (`isReturningAfterBreak`), `kids_journey_cubit.dart` (compute), `kids_gamified_home_page.dart` (one insertion above the mission card)
- ARB: `kidsWelcomeBackTitle` "أهلاً بعودتك!" / "Welcome back!", `kidsWelcomeBackSubtitle` "نبدأ بخطوة سهلة" / "Let's start with an easy step"
- Test: `test/features/memorization_plus/domain/kids_return_policy_test.dart`, home page test

**Interfaces:**
- Produces: `bool kidsIsReturningAfterBreak(DateTime? lastSessionAt, DateTime now)`; `KidsJourneyLoaded.isReturningAfterBreak` (bool, default false).

- [ ] **Step 1: Failing tests**

```dart
test('three local days away is a return; two is not; never practised is not', () {
  final now = DateTime(2026, 9, 30, 9);
  expect(kidsIsReturningAfterBreak(DateTime(2026, 9, 27, 23), now), isTrue);
  expect(kidsIsReturningAfterBreak(DateTime(2026, 9, 28, 1), now), isFalse);
  expect(kidsIsReturningAfterBreak(null, now), isFalse);
});
```

Home widget test: `KidsGamifiedHomeContent` with `_loadedState.copyWith(isReturningAfterBreak: true)` shows `'Welcome back!'`; with false it does not.

- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement**

```dart
/// K33 — three or more local days since the last session deserve a warm
/// welcome (no streak-loss wording). A child who never practised is new, not
/// returning.
bool kidsIsReturningAfterBreak(DateTime? lastSessionAt, DateTime now) {
  if (lastSessionAt == null) return false;
  final last = lastSessionAt.toLocal();
  final today = now.toLocal();
  final days = DateTime(today.year, today.month, today.day)
      .difference(DateTime(last.year, last.month, last.day))
      .inDays;
  return days >= 3;
}
```

Cubit: `isReturningAfterBreak: kidsIsReturningAfterBreak(progress.lastSessionAt, DateTime.now())`. Card: parchment-coloured `Container` with a `waving_hand_rounded` icon, title and subtitle (`KidsTheme` colours). Home: `if (state.isReturningAfterBreak) ...[const KidsWelcomeBackCard(), const SizedBox(height: AppSpacing.md)]` directly before the mission/day/journey card block.

- [ ] **Step 4: Run** tests + `kids_journey_cubit_test.dart` + home test — PASS.
- [ ] **Step 5: Checkpoint.**

---

### Task 4: K34 — No zero counters; streak from two days

**Files:**
- Modify: `lib/features/memorization_plus/presentation/widgets/kids_progress_header.dart` (`_ProgressHeaderBody`)
- Test: `test/features/memorization_plus/presentation/widgets/kids_progress_header_test.dart`

- [ ] **Step 1: Failing tests**

```dart
testWidgets('a one-day streak and zero stars show no counters (K34)', (tester) async {
  // pump KidsProgressHeader with currentStreak: 1, starsEarned: 0
  expect(find.byKey(const ValueKey('kids-streak-badge')), findsNothing);
  expect(find.byIcon(Icons.star_rounded), findsNothing);
});
testWidgets('a two-day streak shows the badge', (tester) async {
  // currentStreak: 2
  expect(find.byKey(const ValueKey('kids-streak-badge')), findsOneWidget);
});
```

- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** — `static const _minStreakDays = 2;` render `_StreakBadge` only when `streakDays >= _minStreakDays`; render `_StarCounter` (both layouts) only when `starsEarned > 0`. Update any existing header test that pumps a 1-day streak expecting the badge.
- [ ] **Step 4: Run** header, home, journey and RTL-narrow tests — PASS.
- [ ] **Step 5: Checkpoint.**

---

### Task 5: K35 — A practical tip under "needs support"

**Files:**
- Create: `lib/features/memorization_plus/presentation/widgets/parent_support_tip.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/child_detail_page.dart` (`_LearningSupportCard`: wrap `Wrap` in a `Column`, add the tip when `dashboard.ayahsNeedingSupport > 0`) — surgical edit, no formatting of the file
- ARB: `parentSupportTip` "جرّبا معاً: استمعا للآية مرتين، ثم دع طفلك يبدأ بأول كلمة" / "Try together: listen to the ayah twice, then let your child start with the first word"
- Test: `test/features/memorization_plus/presentation/widgets/parent_support_tip_test.dart`

- [ ] **Step 1: Failing test** — pump `const ParentSupportTip()` (en) and expect `find.textContaining('Try together')`.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** — a tinted `Container` with `Icons.tips_and_updates_rounded` and `context.l10n.parentSupportTip` (uses the page's existing tokens: `context.tokens` if the file uses them, else `Theme.of(context).colorScheme`).
- [ ] **Step 4: Run** the tip test + `child_detail_guardian_unlink_contract_test.dart` + `family_dashboard_page_test.dart` — PASS.
- [ ] **Step 5: Checkpoint.**

---

### Task 6: K36 — "That's enough for today" after the session goal

**Files:**
- Modify: `lib/features/memorization_plus/domain/services/kids_daily_budget.dart` (`sessionSecondsToday`)
- Modify: `lib/features/memorization_plus/domain/navigation/memorization_navigation_resolver.dart` (`KidsMissionAfterCompletion` gains `sessionGoalReached`)
- Modify: `kids_gamified_completion_page.dart`, `kids_reward_dialog.dart` (note)
- ARB: `kidsGamifiedEnoughForToday` "أحسنت! هذا وقت كافٍ لليوم، يمكنك التوقف." / "Well done! That's enough time for today — you can stop here."
- Test: resolver test (`kids_next_mission_resolver_test.dart` budget group), navigation resolver test, completion page test

**Interfaces:**
- Produces: `KidsDailyBudget.sessionSecondsToday` (int); `bool KidsDailyBudget.sessionGoalReached(int goalMinutes)` (false when `goalMinutes <= 0`).
- Produces: record `({KidsNextMission? mission, int? dailyGoalCap, bool sessionGoalReached})`.

- [ ] **Step 1: Failing tests**

```dart
test('sums only today\'s session time', () {
  final budget = KidsDailyBudget.fromLogs(
    logs: [log('a', DateTime(2026, 9, 1, 8), KidsMissionType.newMemorization, seconds: 300),
           log('b', DateTime(2026, 8, 31, 20), KidsMissionType.dueReview, seconds: 900),
           log('c', DateTime(2026, 9, 1, 9), KidsMissionType.dueReview, seconds: 120)],
    policy: KidsSessionPolicy.forAge(6), now: DateTime(2026, 9, 1, 12));
  expect(budget.sessionSecondsToday, 420);
  expect(budget.sessionGoalReached(7), isTrue);
  expect(budget.sessionGoalReached(8), isFalse);
  expect(budget.sessionGoalReached(0), isFalse);
});
```

(extend the local `log` helper with `int seconds = 0` → `durationSeconds: seconds`). Navigation test: logs with 400s today + `ParentSettings(sessionGoalMinutes: 6)` → `outcome.sessionGoalReached` true. Completion test: `KidsGamifiedCompletionContent(sessionGoalReached: true, …)` shows `"That's enough time for today"` and still shows `'Start mission'`.

- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** — in `fromLogs` accumulate `seconds += log.durationSeconds` for today's logs (all mission types); `bool sessionGoalReached(int goalMinutes) => goalMinutes > 0 && sessionSecondsToday >= goalMinutes * 60;`. Resolver: `final goal = settings.sessionGoalMinutes ?? KidsSessionPolicy.forChildAge(profile?.childAge).maxSessionMinutes;` (settings via `_repository.getParentSettings()`, fail-open to `false`). Completion page stores it; `KidsRewardDialog(sessionGoalReached: …)` renders the note (same style as the daily-limit note) above the actions, only when `dailyGoalCap == null`.
- [ ] **Step 4: Run** the three test files + `kids_journey_cubit_test.dart` — PASS.
- [ ] **Step 5: Checkpoint.**

---

### Task 7: K37 — A newly completed house glows once

**Files:**
- Create: `lib/features/memorization_plus/domain/services/kids_map_celebration.dart` (pure rule + prefs store)
- Modify: `kids_house_card.dart` (`celebrate` flag + one-shot glow), `kids_journey_segment.dart` (pass-through), `kids_gamified_journey_page.dart` (load set, pass per stage)
- Test: `test/features/memorization_plus/domain/kids_map_celebration_test.dart`, `kids_house_card_test.dart`

**Interfaces:**
- Produces: `Set<int> kidsHousesToCelebrate({required Set<int>? seenCompleted, required List<KidsJourneyStage> stages})`; `class KidsMapCelebrationStore { KidsMapCelebrationStore(SharedPreferences, RecordOwnerProvider); Future<Set<int>> takeNewlyCompleted(int surahId, List<KidsJourneyStage> stages); }`
- Produces: `KidsHouseCard(celebrate: bool = false)`.

- [ ] **Step 1: Failing tests**

```dart
test('first visit celebrates nothing; later completions glow once', () {
  final stages = [stage(1, completed: true), stage(2, completed: true), stage(3)];
  expect(kidsHousesToCelebrate(seenCompleted: null, stages: stages), isEmpty);
  expect(kidsHousesToCelebrate(seenCompleted: {1}, stages: stages), {2});
  expect(kidsHousesToCelebrate(seenCompleted: {1, 2}, stages: stages), isEmpty);
});
test('store remembers per owner and surah, and fails closed', () async {
  SharedPreferences.setMockInitialValues({});
  final store = KidsMapCelebrationStore(await SharedPreferences.getInstance(),
      const FixedRecordOwnerProvider('owner-a'));
  expect(await store.takeNewlyCompleted(114, [stage(1, completed: true)]), isEmpty);
  expect(await store.takeNewlyCompleted(114, [stage(1, completed: true), stage(2, completed: true)]), {2});
  expect(await store.takeNewlyCompleted(114, [stage(1, completed: true), stage(2, completed: true)]), isEmpty);
});
```

House card: `celebrate: true` → `find.byKey(ValueKey('kids-house-celebration'))` present; with `MediaQueryData(disableAnimations: true)` it is present but `tester.hasRunningAnimations` is false.

- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** — completed = status `completed` or `needsReview`. Rule: `seenCompleted == null ? {} : completed.difference(seenCompleted)`. Store key `kids_map_seen_completed_${owner}_$surahId` as a `List<String>`; read errors → return `{}` without writing. Journey page state: `Set<int> _celebrate = {}` loaded in `initState` via `getIt<KidsMapCelebrationStore>()` (register lazily in `injection.dart` next to other kids registrations) and `setState`. House card wraps the landmark in `_CelebrationGlow` (key `kids-house-celebration`): an `AnimationController` of 1400 ms played forward once, a gold `BoxShadow` whose blur follows the curve up and back; with `disableAnimations` it draws a static soft gold border and never starts the controller.
- [ ] **Step 4: Run** the new tests + `kids_gamified_journey_page_test.dart` + `kids_gamified_rtl_narrow_test.dart` — PASS.
- [ ] **Step 5: Checkpoint.**

---

### Task 8: Final verification

- [ ] `flutter gen-l10n` (after all ARB edits) and `flutter analyze` on every edited file.
- [ ] Full kids + engine + l10n suites: `flutter test test/core/memorization/v2 <all kids/guardian/child_detail/family_dashboard/navigation/l10n test files>` — all pass.
- [ ] Update the spec's status table (K31–K37 → done) with test counts.
