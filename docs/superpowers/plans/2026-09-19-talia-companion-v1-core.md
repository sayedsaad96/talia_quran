# Talia Companion V1 Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the complete visual and context-aware Talia Companion Core for adult and kids surfaces, with central decisions, local presentation, governed content, deterministic presence, strict Quran/audio suppression, and the Kids Voice Pilot independently disabled.

**Architecture:** A feature-local `CompanionCoordinator` consumes narrow read-only adapters and pure policies, then emits one immutable `CompanionDecision`. Eligible screens render that decision in local slots; `AppShell` supplies visibility only and never renders Talia. Persistence is owner/profile scoped where durable and device-local where transient.

**Tech Stack:** Flutter 3.47.1, Dart, `flutter_bloc`/Cubit, `get_it`, `go_router`, `shared_preferences`, existing identity/memorization/prayer/notification services, ARB localization, Flutter animation/image APIs.

**Spec:** `docs/superpowers/specs/2026-09-19-talia-companion-v1-design.md`

**Audit:** `docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md`

## Global Constraints

- Preserve feature ownership: Talia selects and presents existing opportunities; it does not recalculate memorization, review, resume, prayer, SmartCoach, Daily Wird, or Kids Journey logic.
- Do not create Daily Question or Share Good adapters; neither runtime feature exists in the audited repository.
- Central intelligence, local presentation; never place a Talia widget in `AppShell` or another global overlay.
- Focused Quran routes `/quran/surah/:surahId`, `/quran/page/:pageNumber`, redirected `/quran/daily`, and `/memorization-plus/kids-quran` always resolve to hidden.
- Global Quran audio, local learning playback, recording/evaluation, inactive lifecycle, inactive indexed branch, feature disable, user disable, or Hide Today suppress motion and proactive output immediately.
- Adult Home renders at most one message and one primary CTA. Non-Home adult presence is a compact inline strip.
- Manual Off/Minimal/Companion overrides adaptive presence. Promotion requires 3 useful interactions across at least 2 sessions; one Hide Today or Less Often signal demotes adaptive Companion to Minimal.
- Greeting is eligible at most once per local calendar day; Hide Today and cooldowns are device-local/transient. Durable preference and adaptive state are owner scoped.
- Every visible semantic pose defines motion. Reduced motion, background, and offstage states use a static fallback and zero active ticker/sequence timer.
- Do not alter `assets/images/character/Talia_Master_Character.png` or `assets/images/character/talia_hero.png` or their consumers.
- Register and use the audited static files already in `assets/talia/`; never synthesize sequence frames from a still image.
- Before Task 7, obtain approved frame packs for `wave` and `celebrate` with an explicit ordered manifest. `listening` belongs to the Voice plan. If absent, stop at the Task 7 gate; do not substitute fake production assets.
- Religious/persona copy is a finite ARB-backed ID catalog. No runtime religious generation, guilt language, raw Quran/hadith/tafsir/fatwa output, or runtime TTS.
- Core must pass with `CompanionFeatureFlags.isVoicePilotEnabled == false`; no Core task may depend on Voice Pilot code.
- Keep the documented baseline in mind: the two date-sensitive Prayer Companion notification tests may fail only for their known fixture date. Any other failure is a regression.
- Re-read overlapping dirty files immediately before editing and preserve unrelated user changes.

## Review Focus

- A stale animation callback after route/profile/lifecycle change must not restore a hidden or superseded pose; Task 7 tests cancellation tokens and widget disposal.
- An inactive `StatefulShellRoute.indexedStack` branch must have no ticker or frame timer even though its widget remains mounted; Task 6 tests branch activity transitions.
- Account/profile switching must not reuse another owner's preferences, greeting day, or adaptive counters; Task 5 extends account-switch isolation tests.
- A technical memorization/audio failure must remain neutral and never map to encouragement; Task 4 tests `technicalUnavailable`, `speechIssue`, and `audioFailed` separately from learner retry.
- Home candidate churn must not stack CTAs or let an old notification/SmartCoach candidate force stale state; Tasks 3, 9, and 13 test single-winner recalculation.

---

## File Map

### New Core files

| File | Responsibility |
|---|---|
| `lib/features/talia_companion/domain/entities/companion_models.dart` | Semantic enums/value objects and the immutable `CompanionDecision`; no Flutter imports. |
| `lib/features/talia_companion/domain/services/companion_suppression_policy.dart` | Pure P0-P3 suppression precedence. |
| `lib/features/talia_companion/domain/services/companion_priority_policy.dart` | Pure selection of one eligible candidate. |
| `lib/features/talia_companion/domain/services/companion_presence_policy.dart` | Manual/adaptive adult presence rules. |
| `lib/features/talia_companion/domain/services/companion_message_selector.dart` | Deterministic rotation and per-type cooldowns using an injected clock. |
| `lib/features/talia_companion/domain/messages/companion_message_catalog.dart` | Exhaustive message-ID-to-localization resolution. |
| `lib/features/talia_companion/application/companion_context_snapshot.dart` | Narrow context DTOs and five adapter contracts. |
| `lib/features/talia_companion/application/companion_coordinator.dart` | Cubit that combines adapters/policies into one decision and cancels stale work. |
| `lib/features/talia_companion/application/companion_visibility.dart` | Lifecycle + route + indexed-branch activity projection. |
| `lib/features/talia_companion/application/companion_celebration_arbiter.dart` | One-channel celebration ownership. |
| `lib/features/talia_companion/data/companion_preferences.dart` | Owner-scoped durable preferences and device-local day/cooldown state. |
| `lib/features/talia_companion/data/companion_feature_flags.dart` | Independent Core and Voice local kill switches; Voice defaults false. |
| `lib/features/talia_companion/data/companion_adapters.dart` | Concrete identity, snapshot, audio, prayer, and Home projections. |
| `lib/features/talia_companion/presentation/widgets/talia_character_renderer.dart` | Semantic pose renderer, decode sizing, micro-motion, reduced-motion fallback. |
| `lib/features/talia_companion/presentation/widgets/talia_png_sequence.dart` | Manifest-driven, cancellation-safe sequence rendering. |
| `lib/features/talia_companion/presentation/widgets/adult_home_companion_hero.dart` | One-message/one-CTA Home composition. |
| `lib/features/talia_companion/presentation/widgets/compact_companion_assist_strip.dart` | Restrained adult non-Home slot. |
| `lib/features/talia_companion/presentation/widgets/kids_journey_companion_guide.dart` | Kids Home/Journey/Stage/exercise guide slot. |
| `lib/features/talia_companion/presentation/widgets/companion_quick_actions_sheet.dart` | At most two contextual actions plus Help, Hide Today, Settings. |
| `lib/features/talia_companion/notifications/companion_notification_copy.dart` | Selective copy/payload projection into the existing scheduler. |
| `integration_test/talia_companion_runtime_test.dart` | Route, lifecycle, indexed branch, animation, scroll, memory/decode runtime checks. |

### Existing files to modify

| File | Exact change |
|---|---|
| `pubspec.yaml` | Register `assets/talia/` only; preserve legacy asset entries. |
| `lib/core/di/injection.dart` | Register flags, preferences, adapters, policies, visibility, and coordinator. |
| `lib/app.dart` | Forward the existing `_TaliaAppState.didChangeAppLifecycleState` value to `CompanionVisibility`; do not add a second observer. |
| `lib/core/widgets/app_shell.dart` | Publish current indexed-branch activity; do not render Talia. |
| `lib/core/identity/account_data_reset.dart` | Clear owner-scoped Talia keys explicitly on account reset. |
| `lib/features/home/presentation/pages/home_page.dart` | Add a local hero seam around the already-resolved primary action. |
| `lib/features/memorization_plus/presentation/pages/memorization_hub_page.dart` | Insert compact strip in `_sectionsFor` only when decision targets this surface. |
| `lib/features/progress/presentation/pages/progress_page.dart` | Insert compact strip in `_ProgressContent`; never compete with certificate/share UI. |
| `lib/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart` | Add local guide slot. |
| `lib/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart` | Add map guide slot using existing `KidsJourneyCubit` state. |
| `lib/features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart` | Add stage-start guide slot. |
| `lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart` | Expose a narrow immutable activity projection and add the guide slot; no Voice mic in Core. |
| `lib/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart` | Respect celebration arbitration. |
| `lib/core/widgets/celebration_overlay.dart` | Accept/observe channel ownership without globally activating the dormant overlay. |
| `lib/core/services/notification_scheduler.dart` | Accept approved Talia-aware copy while preserving budgets, quiet hours, and route resolution. |
| `lib/core/l10n/app_ar.arb`, `lib/core/l10n/app_en.arb` | Add the finite Core message/settings/action keys. |
| `test/core/content/no_ungoverned_religious_output_test.dart` | Include the Talia catalog and prohibit bypass copy. |

---

### Task 1: Freeze semantic contracts and independent flags

**Files:**
- Create: `lib/features/talia_companion/domain/entities/companion_models.dart`
- Create: `lib/features/talia_companion/data/companion_feature_flags.dart`
- Test: `test/features/talia_companion/domain/companion_models_test.dart`
- Test: `test/features/talia_companion/data/companion_feature_flags_test.dart`

**Interfaces:**
- Consumes: no Talia code.
- Produces: `CompanionAudience`, `CompanionSurface`, `CompanionPresence`, `CompanionPose`, `CompanionMotion`, `CompanionInteractionMode`, `CompanionSuppressionReason`, `CompanionMessageId`, `CompanionAction`, `CompanionCandidate`, `CompanionDecision`, and `CompanionFeatureFlags`.

- [ ] **Step 1: Write failing value/flag tests**

```dart
test('hidden decision carries no content or action', () {
  final decision = CompanionDecision.hidden(
    CompanionSuppressionReason.quranFocus,
  );
  expect(decision.surface, CompanionSurface.none);
  expect(decision.messageId, isNull);
  expect(decision.primaryAction, isNull);
});

test('voice remains independently disabled by default', () {
  const flags = CompanionFeatureFlags();
  expect(flags.isEnabled, isFalse);
  expect(flags.isVoicePilotEnabled, isFalse);
});
```

- [ ] **Step 2: Run tests and confirm missing-type failures**

Run: `flutter test test/features/talia_companion/domain/companion_models_test.dart test/features/talia_companion/data/companion_feature_flags_test.dart`

Expected: FAIL because the types do not exist.

- [ ] **Step 3: Implement the exact immutable contracts**

```dart
enum CompanionSurface { none, adultHomeHero, memorizationInline, progressInline, kidsHomeGuide, kidsJourneyGuide, kidsStageGuide, kidsExerciseGuide, kidsCompletion }
enum CompanionPresence { hidden, minimal, companion, guide }
enum CompanionInteractionMode { none, quickActionsOpen }

final class CompanionDecision extends Equatable {
  const CompanionDecision({required this.surface, required this.presence,
    required this.pose, required this.motion, this.messageId,
    this.primaryAction, this.secondaryAction,
    this.interactionMode = CompanionInteractionMode.none,
    this.suppressionReason});
  const CompanionDecision.hidden(CompanionSuppressionReason reason)
      : this(surface: CompanionSurface.none, presence: CompanionPresence.hidden,
          pose: CompanionPose.resting, motion: CompanionMotion.none,
          suppressionReason: reason);
  final CompanionSurface surface;
  final CompanionPresence presence;
  final CompanionPose pose;
  final CompanionMotion motion;
  final CompanionMessageId? messageId;
  final CompanionAction? primaryAction;
  final CompanionAction? secondaryAction;
  final CompanionInteractionMode interactionMode;
  final CompanionSuppressionReason? suppressionReason;
  @override
  List<Object?> get props => <Object?>[
    surface, presence, pose, motion, messageId, primaryAction,
    secondaryAction, interactionMode, suppressionReason,
  ];
}

final class CompanionFeatureFlags {
  const CompanionFeatureFlags({
    this.isEnabled = bool.fromEnvironment('TALIA_COMPANION_ENABLED', defaultValue: false),
    this.isVoicePilotEnabled = bool.fromEnvironment('TALIA_KIDS_VOICE_PILOT_ENABLED', defaultValue: false),
  });
  final bool isEnabled;
  final bool isVoicePilotEnabled;
}
```

- [ ] **Step 4: Run tests and static analysis**

Run: `dart format lib/features/talia_companion/domain/entities/companion_models.dart lib/features/talia_companion/data/companion_feature_flags.dart test/features/talia_companion/domain/companion_models_test.dart test/features/talia_companion/data/companion_feature_flags_test.dart && flutter test test/features/talia_companion/domain/companion_models_test.dart test/features/talia_companion/data/companion_feature_flags_test.dart && flutter analyze`

Expected: PASS; Voice stays false independently.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/domain/entities/companion_models.dart lib/features/talia_companion/data/companion_feature_flags.dart test/features/talia_companion/domain/companion_models_test.dart test/features/talia_companion/data/companion_feature_flags_test.dart
git commit -m "feat(talia): define companion core contracts"
```

### Task 2: Implement strict suppression and single-winner priority

**Files:**
- Create: `lib/features/talia_companion/domain/services/companion_suppression_policy.dart`
- Create: `lib/features/talia_companion/domain/services/companion_priority_policy.dart`
- Test: `test/features/talia_companion/domain/companion_suppression_policy_test.dart`
- Test: `test/features/talia_companion/domain/companion_priority_policy_test.dart`

**Interfaces:**
- Consumes: Task 1 models.
- Produces: `CompanionSuppressionPolicy.evaluate(CompanionPolicyInput) -> CompanionSuppressionReason?` and `CompanionPriorityPolicy.select(Iterable<CompanionCandidate>) -> CompanionCandidate?`.

- [ ] **Step 1: Write precedence and tie-break tests**

```dart
test('focused reader beats every candidate', () {
  final reason = policy.evaluate(input.copyWith(
    routeLocation: '/quran/page/12',
    hasActiveQuranAudio: true,
    isRecording: true,
  ));
  expect(reason, CompanionSuppressionReason.quranFocus);
});

test('priority returns one stable winner', () {
  expect(policy.select([greeting, reviewDue, achievement]), reviewDue);
  expect(policy.select([reviewDue, reviewDueLater]), reviewDue);
});

test('technical failure never becomes encouragement', () {
  final candidates = CompanionCandidate.fromLearning(
    verdict: CompanionLearningVerdict.technicalUnavailable,
  );
  expect(candidates, isEmpty);
});
```

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/domain/companion_suppression_policy_test.dart test/features/talia_companion/domain/companion_priority_policy_test.dart`

Expected: FAIL because policies are missing.

- [ ] **Step 3: Implement P0-P10 with explicit route matching**

```dart
CompanionSuppressionReason? evaluate(CompanionPolicyInput input) {
  if (!input.rolloutEnabled || !input.userEnabled) return CompanionSuppressionReason.disabled;
  if (_isFocusedReader(input.routeLocation)) return CompanionSuppressionReason.quranFocus;
  if (!input.isAppActive || !input.isSurfaceVisible) return CompanionSuppressionReason.notVisible;
  if (input.hasActiveQuranAudio) return CompanionSuppressionReason.quranAudio;
  if (input.isRecording || input.isEvaluating) return CompanionSuppressionReason.recording;
  if (input.hiddenToday) return CompanionSuppressionReason.hiddenToday;
  return null;
}
```

Use explicit priority values and original-list order for deterministic ties. Do not import feature Cubits here.

- [ ] **Step 4: Run policy tests and analysis**

Run: `dart format lib/features/talia_companion/domain/services test/features/talia_companion/domain && flutter test test/features/talia_companion/domain/companion_suppression_policy_test.dart test/features/talia_companion/domain/companion_priority_policy_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/domain/services/companion_suppression_policy.dart lib/features/talia_companion/domain/services/companion_priority_policy.dart test/features/talia_companion/domain/companion_suppression_policy_test.dart test/features/talia_companion/domain/companion_priority_policy_test.dart
git commit -m "feat(talia): enforce suppression and priority"
```

### Task 3: Define snapshots and read-only adapters

**Files:**
- Create: `lib/features/talia_companion/application/companion_context_snapshot.dart`
- Create: `lib/features/talia_companion/data/companion_adapters.dart`
- Test: `test/features/talia_companion/application/companion_context_snapshot_test.dart`
- Test: `test/features/talia_companion/data/companion_adapters_test.dart`

**Interfaces:**
- Consumes: `MemorizationPathResolver.currentProfile()`, `RecordOwnerProvider.currentOwnerId`, `GetMemorizationSnapshotUsecase`, `QuranAudioPlayerState.hasActiveAudio`, local `MSActive`/`KidsModeLoaded`, `PrayerTimesService`, `GetPrayerCompanionDaySummary`, and loaded `HomeState`.
- Produces: `CompanionIdentityAdapter.read()`, `CompanionMemorizationSnapshotAdapter.read()`, `CompanionAudioActivityAdapter.read({required QuranAudioPlayerState global, MSActive? session, KidsModeLoaded? kids})`, `CompanionPrayerAdapter.read()`, `CompanionHomeContextAdapter.from(HomeState)`, and `CompanionContextSnapshot`.

- [ ] **Step 1: Write adapter boundary tests with fakes**

```dart
test('home adapter projects existing candidates without recalculating them', () {
  final projection = adapter.fromState(homeStateWithReviewAndDailyWird);
  expect(projection.reviewDue, isTrue);
  expect(projection.smartCoach, same(existingRecommendation));
  expect(projection.dailyQuestion, isNull);
});

test('audio projection combines global and local owners', () {
  expect(adapter.read(global: playing, local: recording).isSuppressed, isTrue);
});
```

- [ ] **Step 2: Verify missing-contract failures**

Run: `flutter test test/features/talia_companion/application/companion_context_snapshot_test.dart test/features/talia_companion/data/companion_adapters_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement narrow DTOs and adapters**

```dart
abstract interface class CompanionIdentityAdapter {
  Future<CompanionIdentityContext> read();
}
abstract interface class CompanionMemorizationSnapshotAdapter {
  Future<CompanionMemorizationContext> read();
}
abstract interface class CompanionPrayerAdapter {
  Future<CompanionPrayerContext> read();
}

final class CompanionContextSnapshot extends Equatable {
  const CompanionContextSnapshot({required this.identity, required this.visibility,
    required this.audio, required this.memorization, required this.prayer,
    required this.home, required this.now});
  final CompanionIdentityContext identity;
  final CompanionVisibilityContext visibility;
  final CompanionAudioContext audio;
  final CompanionMemorizationContext memorization;
  final CompanionPrayerContext prayer;
  final CompanionHomeContext home;
  final DateTime now;
  @override
  List<Object?> get props => <Object?>[
    identity, visibility, audio, memorization, prayer, home, now,
  ];
}
```

The concrete Home adapter must expose Daily Wird and SmartCoach only. It must not add Daily Question/Share Good stubs.

- [ ] **Step 4: Run tests and analysis**

Run: `dart format lib/features/talia_companion/application/companion_context_snapshot.dart lib/features/talia_companion/data/companion_adapters.dart test/features/talia_companion && flutter test test/features/talia_companion/application/companion_context_snapshot_test.dart test/features/talia_companion/data/companion_adapters_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/application/companion_context_snapshot.dart lib/features/talia_companion/data/companion_adapters.dart test/features/talia_companion/application/companion_context_snapshot_test.dart test/features/talia_companion/data/companion_adapters_test.dart
git commit -m "feat(talia): project existing feature context"
```

### Task 4: Map memorization state without owning learning logic

**Files:**
- Create: `lib/features/talia_companion/data/companion_memorization_mapper.dart`
- Test: `test/features/talia_companion/data/companion_memorization_mapper_test.dart`

**Interfaces:**
- Consumes: previous/current `MemorizationSessionState`, `SessionPhase`, `RecitationVerdict`, and local activity flags.
- Produces: `CompanionMemorizationMapper.map(previous, current) -> CompanionCandidate?`; never writes scoring/progression.

- [ ] **Step 1: Write the full transition table as failing tests**

```dart
final cases = <({CompanionLearningInput input, CompanionPose? pose})>[
  (input: learningAudio, pose: CompanionPose.listening),
  (input: reciting, pose: null),
  (input: evaluating, pose: CompanionPose.thinking),
  (input: passedTransition, pose: CompanionPose.happy),
  (input: remediation, pose: CompanionPose.encourage),
  (input: technicalUnavailable, pose: null),
];
for (final value in cases) {
  expect(mapper.map(value.input)?.pose, value.pose);
}
```

Also assert completion emits only on transition into `MSCompleted`, not rebuilds of the same state.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/data/companion_memorization_mapper_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement a pure transition mapper**

Use typed state/verdict checks. Return `null` for reciting and technical failures. Deduplicate completion by semantic previous/current transition, never by arbitrary debounce time.

- [ ] **Step 4: Run tests**

Run: `dart format lib/features/talia_companion/data/companion_memorization_mapper.dart test/features/talia_companion/data/companion_memorization_mapper_test.dart && flutter test test/features/talia_companion/data/companion_memorization_mapper_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/data/companion_memorization_mapper.dart test/features/talia_companion/data/companion_memorization_mapper_test.dart
git commit -m "feat(talia): map memorization transitions safely"
```

### Task 5: Persist preferences, adaptive presence, and clock boundaries

**Files:**
- Create: `lib/features/talia_companion/data/companion_preferences.dart`
- Create: `lib/features/talia_companion/domain/services/companion_presence_policy.dart`
- Modify: `lib/core/identity/account_data_reset.dart`
- Test: `test/features/talia_companion/data/companion_preferences_test.dart`
- Test: `test/features/talia_companion/domain/companion_presence_policy_test.dart`
- Test: `test/integration/account_switch_isolation_test.dart`

**Interfaces:**
- Consumes: `SharedPreferences`, `RecordOwnerProvider`, `AccountDataReset`, injected `CompanionClock.now()`.
- Produces: `CompanionPreferencesRepository.load/save/clearOwner`, `CompanionPreferences`, and `CompanionPresencePolicy.resolve(CompanionPresenceInput input) -> CompanionPresence`.

- [ ] **Step 1: Write failing persistence and policy tests**

Cover signed-in owner isolation, guest namespace, local-day rollover, logout cleanup, manual override, 3 interactions/2 sessions promotion, Hide Today demotion, and no cross-account counters.

```dart
expect(policy.resolve(manualMinimal), CompanionPresence.minimal);
expect(policy.resolve(adaptiveThreeUsesTwoSessions), CompanionPresence.companion);
expect(policy.resolve(adaptiveWithHideToday), CompanionPresence.minimal);
```

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/data/companion_preferences_test.dart test/features/talia_companion/domain/companion_presence_policy_test.dart test/integration/account_switch_isolation_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement versioned keys and deterministic policy**

```dart
abstract interface class CompanionClock { DateTime now(); }
abstract interface class CompanionPreferencesRepository {
  Future<CompanionPreferences> load(String ownerId);
  Future<void> save(String ownerId, CompanionPreferences value);
  Future<void> clearOwner(String ownerId);
}
```

Use `talia_companion.v1.owner.<ownerId>.*` for durable owner state and `talia_companion.v1.device.*` for Hide Today/cooldowns. Add only owner keys to account reset; keep device motion preference as explicitly retained.

- [ ] **Step 4: Run focused and isolation tests**

Run: `dart format lib/features/talia_companion/data/companion_preferences.dart lib/features/talia_companion/domain/services/companion_presence_policy.dart lib/core/identity/account_data_reset.dart test/features/talia_companion test/integration/account_switch_isolation_test.dart && flutter test test/features/talia_companion/data/companion_preferences_test.dart test/features/talia_companion/domain/companion_presence_policy_test.dart test/integration/account_switch_isolation_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/data/companion_preferences.dart lib/features/talia_companion/domain/services/companion_presence_policy.dart lib/core/identity/account_data_reset.dart test/features/talia_companion/data/companion_preferences_test.dart test/features/talia_companion/domain/companion_presence_policy_test.dart test/integration/account_switch_isolation_test.dart
git commit -m "feat(talia): persist isolated presence preferences"
```

### Task 6: Add lifecycle and indexed-branch visibility

**Files:**
- Create: `lib/features/talia_companion/application/companion_visibility.dart`
- Modify: `lib/app.dart`
- Modify: `lib/core/widgets/app_shell.dart`
- Test: `test/features/talia_companion/application/companion_visibility_test.dart`

**Interfaces:**
- Consumes: existing `_TaliaAppState.didChangeAppLifecycleState`, `StatefulNavigationShell.currentIndex`, route location, and target surface branch.
- Produces: `CompanionVisibility.value`, `setLifecycle(AppLifecycleState)`, `setActiveBranch(int)`, `setRoute(String)`, and `isSurfaceVisible(CompanionSurface)`.

- [ ] **Step 1: Write failing visibility tests**

Test active→inactive, branch 0→1, reader route, resume recalculation event, and disposal with no late notification.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/application/companion_visibility_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement a read-only bridge**

```dart
final class CompanionVisibility extends ChangeNotifier {
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  int _activeBranch = 0;
  String _route = '/';
  bool isSurfaceVisible(CompanionSurface surface) =>
      _lifecycle == AppLifecycleState.resumed &&
      _branchFor(surface) == _activeBranch && !_isReader(_route);
}
```

Forward events from existing owners. `AppShell` must contain no `TaliaCharacterRenderer`, `AdultHomeCompanionHero`, or guide widget.

- [ ] **Step 4: Run tests and architecture grep**

Run: `dart format lib/app.dart lib/core/widgets/app_shell.dart lib/features/talia_companion/application/companion_visibility.dart test/features/talia_companion/application/companion_visibility_test.dart && flutter test test/features/talia_companion/application/companion_visibility_test.dart && rg -n "TaliaCharacterRenderer|AdultHomeCompanionHero|KidsJourneyCompanionGuide" lib/core/widgets/app_shell.dart && flutter analyze`

Expected: test PASS; `rg` returns no matches; analyze PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app.dart lib/core/widgets/app_shell.dart lib/features/talia_companion/application/companion_visibility.dart test/features/talia_companion/application/companion_visibility_test.dart
git commit -m "feat(talia): stop work outside active surfaces"
```

### Task 7: Register assets and build the renderer

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/talia_companion/presentation/widgets/talia_character_renderer.dart`
- Create: `lib/features/talia_companion/presentation/widgets/talia_png_sequence.dart`
- Test: `test/features/talia_companion/presentation/talia_character_renderer_test.dart`
- Test: `test/features/talia_companion/presentation/talia_png_sequence_test.dart`

**Interfaces:**
- Consumes: Task 1 `CompanionPose`/`CompanionMotion`, Task 6 visibility, `MediaQuery.disableAnimationsOf`, and approved `assets/talia/` files/manifests.
- Produces: `TaliaCharacterRenderer(pose, motion, size, isVisible, semanticLabel)` and `TaliaPngSequence(manifest, playMode, isEnabled, onCompleted)`.

- [ ] **Step 1: Enforce the asset gate**

Run: `Get-ChildItem assets/talia -Recurse -File | Select-Object -ExpandProperty FullName`

Expected before proceeding: all audited static poses plus approved ordered manifests/frame packs for `wave` and `celebrate`. If either pack is absent, stop this task and request the approved assets; do not create frames.

- [ ] **Step 2: Write failing renderer/sequence tests**

Test every pose maps to an existing asset; `wave`/`celebrate` are one-shot; reduced motion uses final static pose; `isVisible=false` leaves no active ticker/timer; size computes bounded cache width; disposal ignores delayed callbacks.

- [ ] **Step 3: Implement minimal manifest and renderer APIs**

```dart
final class TaliaSequenceManifest {
  const TaliaSequenceManifest({required this.frames, required this.frameDuration,
    required this.fallbackAsset});
  final List<String> frames;
  final Duration frameDuration;
  final String fallbackAsset;
}
```

Register `assets/talia/`. Use `cacheWidth` near physical display size, clamped to audited 256/384/640/960 buckets. Precache only current/next likely state.

- [ ] **Step 4: Run tests, asset validation, and analysis**

Run: `dart format lib/features/talia_companion/presentation/widgets test/features/talia_companion/presentation && flutter pub get && flutter test test/features/talia_companion/presentation/talia_character_renderer_test.dart test/features/talia_companion/presentation/talia_png_sequence_test.dart && flutter analyze`

Expected: PASS; no missing asset exception.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml lib/features/talia_companion/presentation/widgets/talia_character_renderer.dart lib/features/talia_companion/presentation/widgets/talia_png_sequence.dart test/features/talia_companion/presentation/talia_character_renderer_test.dart test/features/talia_companion/presentation/talia_png_sequence_test.dart assets/talia
git commit -m "feat(talia): render semantic poses and motion"
```

### Task 8: Add governed messages, rotation, and quick actions

**Files:**
- Create: `lib/features/talia_companion/domain/messages/companion_message_catalog.dart`
- Create: `lib/features/talia_companion/domain/services/companion_message_selector.dart`
- Create: `lib/features/talia_companion/presentation/widgets/companion_quick_actions_sheet.dart`
- Modify: `lib/core/l10n/app_ar.arb`
- Modify: `lib/core/l10n/app_en.arb`
- Modify: `test/core/content/no_ungoverned_religious_output_test.dart`
- Test: `test/features/talia_companion/domain/companion_message_catalog_test.dart`
- Test: `test/features/talia_companion/domain/companion_message_selector_test.dart`
- Test: `test/features/talia_companion/presentation/companion_quick_actions_sheet_test.dart`

**Interfaces:**
- Consumes: Task 1 IDs/actions, Task 5 repository/clock, generated `AppLocalizations`.
- Produces: exhaustive `CompanionMessageCatalog.resolve(id, l10n)`, deterministic `CompanionMessageSelector.select(type, variants, history)`, and bounded quick-actions UI.

- [ ] **Step 1: Write failing exhaustiveness/governance/cooldown tests**

Assert every enum ID resolves in Arabic and English, no raw religious string appears in Talia Dart files, the last variant is not immediately repeated, greeting crosses local-day boundaries correctly, and the sheet renders no more than 2 contextual + 3 fixed actions.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/domain/companion_message_catalog_test.dart test/features/talia_companion/domain/companion_message_selector_test.dart test/features/talia_companion/presentation/companion_quick_actions_sheet_test.dart test/core/content/no_ungoverned_religious_output_test.dart`

Expected: FAIL.

- [ ] **Step 3: Add approved finite keys and implementation**

Use product-reviewed Arabic/English copy for greeting, continue, review, help, Hide Today, settings, kids guidance, neutral technical status, and celebration. Do not add Daily Question/Share Good strings.

- [ ] **Step 4: Generate localization and run tests**

Run: `flutter gen-l10n && dart format lib/features/talia_companion test/features/talia_companion test/core/content/no_ungoverned_religious_output_test.dart && flutter test test/features/talia_companion/domain/companion_message_catalog_test.dart test/features/talia_companion/domain/companion_message_selector_test.dart test/features/talia_companion/presentation/companion_quick_actions_sheet_test.dart test/core/content/no_ungoverned_religious_output_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/domain/messages lib/features/talia_companion/domain/services/companion_message_selector.dart lib/features/talia_companion/presentation/widgets/companion_quick_actions_sheet.dart lib/core/l10n test/features/talia_companion test/core/content/no_ungoverned_religious_output_test.dart
git commit -m "feat(talia): add governed companion messaging"
```

### Task 9: Compose and register the coordinator

**Files:**
- Create: `lib/features/talia_companion/application/companion_coordinator.dart`
- Modify: `lib/core/di/injection.dart`
- Test: `test/features/talia_companion/application/companion_coordinator_test.dart`

**Interfaces:**
- Consumes: Tasks 1-8 flags, adapters, policies, preferences, visibility, mapper, selector.
- Produces: `CompanionCoordinator extends Cubit<CompanionCoordinatorState>`, `refresh({required CompanionSurface surface, CompanionLocalContext? local})`, `recordInteraction(CompanionInteractionSignal)`, `hideToday()`, `openQuickActions()`, `closeQuickActions()`.

- [ ] **Step 1: Write failing orchestration tests**

Cover Core-on/Voice-off, disabled short circuit, reader/audio/background suppression, one Home winner, local-surface mismatch hidden, stale refresh generation discarded, and profile switch reload.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/application/companion_coordinator_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement generation-safe Cubit orchestration**

```dart
Future<void> refresh({required CompanionSurface surface,
    CompanionLocalContext? local}) async {
  final generation = ++_generation;
  final snapshot = await _snapshotReader.read(surface: surface, local: local);
  if (generation != _generation || isClosed) return;
  final reason = _suppression.evaluate(snapshot.policyInput);
  emit(reason == null ? _resolve(snapshot) :
      CompanionCoordinatorState(CompanionDecision.hidden(reason)));
}
```

Register one lazy coordinator and its dependencies using existing `get_it` conventions. Do not provide a global visual widget.

- [ ] **Step 4: Run coordinator tests and analysis**

Run: `dart format lib/features/talia_companion/application/companion_coordinator.dart lib/core/di/injection.dart test/features/talia_companion/application/companion_coordinator_test.dart && flutter test test/features/talia_companion/application/companion_coordinator_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/application/companion_coordinator.dart lib/core/di/injection.dart test/features/talia_companion/application/companion_coordinator_test.dart
git commit -m "feat(talia): coordinate companion decisions"
```

### Task 10: Integrate the Adult Home Hero

**Files:**
- Create: `lib/features/talia_companion/presentation/widgets/adult_home_companion_hero.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart`
- Test: `test/features/talia_companion/presentation/adult_home_companion_hero_test.dart`
- Test: `test/features/home/hero_coach_coherence_test.dart`

**Interfaces:**
- Consumes: existing resolved `_PrimaryAction`/`_JourneyHeroAction`, `HomeHeroSection`, and `CompanionDecision` targeting `adultHomeHero`.
- Produces: `AdultHomeCompanionHero(decision, onPrimaryAction, onTapTalia)`; it owns layout only.

- [ ] **Step 1: Write failing widget tests**

Test 320/360 logical px, text scale 1.0/1.3/2.0, light/dark, RTL, one message, one CTA, hidden suppression, and that existing route callback is invoked exactly once.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/presentation/adult_home_companion_hero_test.dart test/features/home/hero_coach_coherence_test.dart`

Expected: FAIL.

- [ ] **Step 3: Extract only the presentation seam and render locally**

Do not copy `HomePrimaryActionResolver`, SmartCoach, resume, or navigation logic. Convert the already-resolved Home action into a `CompanionAction` candidate and pass the existing callback through the hero.

- [ ] **Step 4: Run tests and analysis**

Run: `dart format lib/features/home/presentation/pages/home_page.dart lib/features/talia_companion/presentation/widgets/adult_home_companion_hero.dart test/features && flutter test test/features/talia_companion/presentation/adult_home_companion_hero_test.dart test/features/home/hero_coach_coherence_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/pages/home_page.dart lib/features/talia_companion/presentation/widgets/adult_home_companion_hero.dart test/features/talia_companion/presentation/adult_home_companion_hero_test.dart test/features/home/hero_coach_coherence_test.dart
git commit -m "feat(talia): integrate adult home hero"
```

### Task 11: Integrate adult compact strips

**Files:**
- Create: `lib/features/talia_companion/presentation/widgets/compact_companion_assist_strip.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/memorization_hub_page.dart`
- Modify: `lib/features/progress/presentation/pages/progress_page.dart`
- Test: `test/features/talia_companion/presentation/compact_companion_assist_strip_test.dart`
- Test: `test/features/memorization_plus/presentation/pages/memorization_hub_companion_test.dart`
- Test: `test/features/progress/presentation/progress_companion_strip_test.dart`

**Interfaces:**
- Consumes: surface-targeted `CompanionDecision` plus existing navigation/progress callbacks.
- Produces: `CompactCompanionAssistStrip(decision, onAction)` with one line/CTA and no overlay behavior.

- [ ] **Step 1: Write failing compactness/scope tests**

Assert hidden when irrelevant/Kids/reader; maximum one CTA; no certificate/share overlap; no fixed positioning; 320/360 widths and text scaling do not clip.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/presentation/compact_companion_assist_strip_test.dart test/features/memorization_plus/presentation/pages/memorization_hub_companion_test.dart test/features/progress/presentation/progress_companion_strip_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement local insertions**

Insert the Memorization strip through `_sectionsFor` and Progress strip through `_ProgressContent`; invoke existing navigation callbacks and never compute plan/progress inside the widget.

- [ ] **Step 4: Run tests and analysis**

Run: `dart format lib/features/talia_companion/presentation/widgets/compact_companion_assist_strip.dart lib/features/memorization_plus/presentation/pages/memorization_hub_page.dart lib/features/progress/presentation/pages/progress_page.dart test/features && flutter test test/features/talia_companion/presentation/compact_companion_assist_strip_test.dart test/features/memorization_plus/presentation/pages/memorization_hub_companion_test.dart test/features/progress/presentation/progress_companion_strip_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/presentation/widgets/compact_companion_assist_strip.dart lib/features/memorization_plus/presentation/pages/memorization_hub_page.dart lib/features/progress/presentation/pages/progress_page.dart test/features/talia_companion/presentation/compact_companion_assist_strip_test.dart test/features/memorization_plus/presentation/pages/memorization_hub_companion_test.dart test/features/progress/presentation/progress_companion_strip_test.dart
git commit -m "feat(talia): add adult contextual strips"
```

### Task 12: Integrate Kids Journey Guide and celebration arbitration

**Files:**
- Create: `lib/features/talia_companion/presentation/widgets/kids_journey_companion_guide.dart`
- Create: `lib/features/talia_companion/application/companion_celebration_arbiter.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart`
- Modify: `lib/core/widgets/celebration_overlay.dart`
- Test: `test/features/talia_companion/presentation/kids_journey_companion_guide_test.dart`
- Test: `test/features/talia_companion/application/companion_celebration_arbiter_test.dart`
- Test: `test/features/memorization_plus/presentation/pages/kids_gamified_home_page_test.dart`
- Test: `test/features/memorization_plus/presentation/pages/kids_gamified_journey_page_test.dart`
- Test: `test/features/memorization_plus/presentation/pages/kids_gamified_stage_page_test.dart`
- Test: `test/features/memorization_plus/presentation/pages/kids_gamified_listen_page_test.dart`
- Test: `test/features/memorization_plus/presentation/pages/kids_gamified_completion_page_test.dart`
- Test: `test/features/auth/presentation/certificate_kids_restore_test.dart`

**Interfaces:**
- Consumes: local `KidsJourneyCubit`/`KidsModeCubit` state, Task 4 activity projection, Task 9 decisions.
- Produces: `KidsJourneyCompanionGuide(decision, onAction)` and `CompanionCelebrationArbiter.resolve(existingOwner, requested) -> CelebrationOwner`.

- [ ] **Step 1: Write failing route/activity/celebration tests**

Cover guide on Kids Home/Journey/Stage, companion on simple exercise, hidden during playback/recording/evaluation, no mic, no Quran Reader rendering, and certificate owner beating Talia.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/presentation/kids_journey_companion_guide_test.dart test/features/talia_companion/application/companion_celebration_arbiter_test.dart test/features/memorization_plus/presentation/pages/kids_gamified_home_page_test.dart test/features/memorization_plus/presentation/pages/kids_gamified_journey_page_test.dart test/features/memorization_plus/presentation/pages/kids_gamified_stage_page_test.dart test/features/memorization_plus/presentation/pages/kids_gamified_listen_page_test.dart test/features/memorization_plus/presentation/pages/kids_gamified_completion_page_test.dart`

Expected: FAIL only for missing guide/arbiter behavior.

- [ ] **Step 3: Implement local slots and narrow activity projection**

Keep `KidsModeCubit` business logic in Memorization. The Core guide accepts immutable booleans/semantic state only. Do not render a Push-to-Talk control in this plan.

- [ ] **Step 4: Run Kids/certificate tests and analysis**

Run: `dart format lib/features/talia_companion lib/features/memorization_plus/presentation/pages lib/core/widgets/celebration_overlay.dart test/features && flutter test test/features/talia_companion/presentation/kids_journey_companion_guide_test.dart test/features/talia_companion/application/companion_celebration_arbiter_test.dart test/features/memorization_plus/presentation/pages test/features/auth/presentation/certificate_kids_restore_test.dart && flutter analyze`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion lib/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart lib/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart lib/features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart lib/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart lib/core/widgets/celebration_overlay.dart test/features
git commit -m "feat(talia): guide kids journey locally"
```

### Task 13: Add selective Talia-aware notifications

**Files:**
- Create: `lib/features/talia_companion/notifications/companion_notification_copy.dart`
- Modify: `lib/core/services/notification_scheduler.dart`
- Test: `test/features/talia_companion/notifications/companion_notification_copy_test.dart`
- Test: `test/core/services/notification_scheduler_companion_test.dart`
- Test: `test/core/services/notification_budget_test.dart`
- Test: `test/core/services/notification_quiet_hours_test.dart`

**Interfaces:**
- Consumes: existing eligible notification context and route payload.
- Produces: `CompanionNotificationCopy.forContext(context, l10n) -> NotificationCopy?`; `null` for technical/system contexts.

- [ ] **Step 1: Write failing selection tests**

Assert review/resume/prayer companion contexts may resolve approved copy; permission/sync/internal errors return null; payload retains normal destination and never serializes a `CompanionDecision`.

- [ ] **Step 2: Verify failures**

Run: `flutter test test/features/talia_companion/notifications/companion_notification_copy_test.dart test/core/services/notification_scheduler_test.dart`

Expected: FAIL for missing copy adapter only.

- [ ] **Step 3: Implement copy projection at scheduler seam**

Preserve budget, quiet-hours, category, scheduling, and route resolver logic. Opening the notification navigates normally; coordinator recalculates after navigation.

- [ ] **Step 4: Run notification suite**

Run: `dart format lib/features/talia_companion/notifications lib/core/services/notification_scheduler.dart test/features/talia_companion/notifications && flutter test test/features/talia_companion/notifications test/core/services --concurrency=1 && flutter analyze`

Expected: PASS except only the already-documented date-sensitive Prayer fixture if its date has not been repaired separately.

- [ ] **Step 5: Commit**

```bash
git add lib/features/talia_companion/notifications/companion_notification_copy.dart lib/core/services/notification_scheduler.dart test/features/talia_companion/notifications/companion_notification_copy_test.dart
git commit -m "feat(talia): add selective notification identity"
```

### Task 14: Verify runtime, accessibility, performance, and release switches

**Files:**
- Create: `integration_test/talia_companion_runtime_test.dart`

**Interfaces:**
- Consumes: completed Core.
- Produces: reproducible runtime evidence; no production API.

- [ ] **Step 1: Add runtime scenarios**

Cover Home→Quran Reader immediate hide, indexed tab switch with zero hidden frame advances, background/resume recalculation, global Quran audio start, local recording start, 50 pose transitions without memory growth trend, Home scrolling, reduced motion, 320/360 widths, text scale 2.0, dark/light, RTL, and Core-on/Voice-off.

- [ ] **Step 2: Run targeted unit/widget suite**

Run: `flutter test test/features/talia_companion test/features/home/hero_coach_coherence_test.dart test/features/memorization_plus/presentation/pages test/features/progress/presentation/progress_companion_strip_test.dart test/core/content/no_ungoverned_religious_output_test.dart --concurrency=1`

Expected: PASS.

- [ ] **Step 3: Run runtime tests on the approved Android device/emulator**

First run `flutter devices` and ensure exactly the project-approved Android test target is connected, then run: `flutter test integration_test/talia_companion_runtime_test.dart --profile`

Expected: PASS with recorded frame timings, stable memory after settling, bounded decode sizes, and zero frame progression while hidden/offstage.

- [ ] **Step 4: Run formatting, analysis, complete suite, and diff checks**

Run: `dart format --output=none --set-exit-if-changed lib test integration_test && flutter analyze && flutter test --concurrency=1 && git diff --check`

Expected: format/analyze/diff PASS; full tests PASS apart from the two precisely documented date-sensitive Prayer Companion fixture failures if still present. Investigate every other failure.

- [ ] **Step 5: Verify forbidden architecture and assets**

Run: `rg -n "Talia(Character|Companion|Journey)|talia_companion" lib/core/widgets/app_shell.dart; rg -n "DailyQuestion|ShareGood" lib/features/talia_companion; git diff -- assets/images/character`

Expected: no global-shell renderer, no invented absent feature adapter, and no legacy-character diff.

- [ ] **Step 6: Commit**

```bash
git add integration_test/talia_companion_runtime_test.dart
git commit -m "test(talia): verify core runtime behavior"
```

## Completion Gate

- Core is complete only when every focused test passes, the approved Core sequence assets exist, religious copy is reviewed, runtime evidence is captured on the approved Android matrix, and `TALIA_KIDS_VOICE_PILOT_ENABLED=false` still yields the full visual companion.
- Do not start the Voice plan merely because Core compiles. Review the Core diff and runtime evidence first, then execute the separate Voice plan.
