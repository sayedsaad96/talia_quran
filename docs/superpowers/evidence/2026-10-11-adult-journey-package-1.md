# Adult Journey Package 1 — evidence

## Phase A (2026-10-13)

Base: HEAD `3cc1b57d` with a clean tree before the work. Changes are uncommitted.

### Baseline (Task 0, before any change)

- `flutter analyze`: no issues.
- `flutter test test/features/onboarding test/features/home test/core/journey test/core/router test/core/identity test/features/memorization_plus/presentation/navigation test/features/memorization_plus/domain/services/plan_schedule_policy_test.dart test/integration/account_switch_isolation_test.dart test/features/settings`: 384 passed, exit 0.

### After Phase A

- `flutter analyze`: no issues.
- `flutter test test/features/adult_journey test/core/identity test/features/home test/features/settings test/features/onboarding test/core/journey test/core/router test/integration/account_switch_isolation_test.dart test/features/memorization_plus/presentation/navigation`: 490 passed (before the review fixes).
- After the review fixes: `flutter test test/features/adult_journey test/features/settings`: 206 passed.
- Full `flutter test`: 3993 passed, 1 failed — `test/design_system/design_token_guard_test.dart` flags hex colors in `certificate_widget.dart`, `kids_learning_game_page.dart`, `kids_name_ribbon.dart`, `kids_world_scene.dart`. None of those files is touched by this package; the failure comes from committed kids work and is tracked separately.

### Review

`opus-architecture-reviewer` (static): no P0–P2. Four P3 findings fixed:

1. Save completing after a hide re-showed the overlay → visibility counter in the cubit; test added.
2. Owner change without a barrier event left old state on screen → `_syncOwner` on stale results; test added.
3. Newer-schema record showed an undismissable invite → `unsupported` hides; test added.
4. Settings tile gated on `isAdultPath` (accepts a stale `mem_plus_track`) → `memorizationProfile?.isAdult`; widget tests for adult/child/no path/flags off.

Also fixed: same-owner barrier events (Khatmah writes) no longer hide the overlay; a failed time save now shows an error on the card; the unused `adultJourneyMatchesGoal` string was removed.

### Not verified

- No Android/device run (Task 6 manual matrix belongs to Phase C).
- ~~No widget test of `AdultJourneyHomeSlot`~~ — closed in Phase B: `adult_journey_home_slot_test.dart` (wiring through `HomeCubit`, first-run rule, child/no-track gating, snooze).
- ~~Dark-mode and semantics checks~~ — closed in Phase B: light/dark × ar/en at 320 px against `textContrastGuideline`, `labeledTapTargetGuideline`, `androidTapTargetGuideline`.
- All rollout flags remain off: the shipped Home and Settings are unchanged until `adult_journey_flag_personalization` is set on a device.

## Phase B (2026-10-13)

Base: `4438e529` (Phase A) on `feat/adult-journey-phase-a`. Phase A re-verified first: `flutter analyze` clean; 413 related tests passed.

Changes: `application/adult_journey_launch_resolver.dart` (new); `AdultJourneyCubit.resolveLaunch`; the today card resolves on tap inside its double-tap guard; DI registers the resolver over `MemorizationNavigationResolver.resolve()`.

Rules: memorize → `todayPlanLocation` and review → `reviewQuizLocation`, both re-resolved at tap time and used verbatim (no `blockSize`/`origin`/`intent` rewrite). Review that falls back to plan setup opens the hub (which explains, as the hub itself does). Plan setup → custom plan screen. Child profile, owner change or barrier generation change during the lookup → no navigation. A failed lookup → hub. Resume → its section only; reading/khatmah use the current Home load's route.

- `flutter analyze`: no issues.
- `flutter test test/features/adult_journey`: 145 passed (new: 14 resolver tests, 5 cubit `resolveLaunch` tests).
- `flutter test test/features/home test/features/settings test/core/identity test/core/journey test/integration/account_switch_isolation_test.dart test/features/memorization_plus/presentation/navigation test/features/memorization_plus/domain/navigation`: 288 passed.
- Not run: full suite (only adult-journey files and two DI registrations changed since the Phase A full run); no device run.

### Phase A gaps closed with Phase B

- `test/features/adult_journey/presentation/adult_journey_home_slot_test.dart`: 11 tests, including a non-vacuous accessibility matrix.
- Final: `flutter analyze` clean; `flutter test test/features/adult_journey test/features/home test/features/settings test/core/identity test/core/journey test/integration/account_switch_isolation_test.dart test/features/memorization_plus/presentation/navigation test/features/memorization_plus/domain/navigation`: 444 passed.
- Still open: device run (owner, Phase C matrix).
