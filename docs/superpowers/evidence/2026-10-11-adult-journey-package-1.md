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
- No widget test of `AdultJourneyHomeSlot` with a real `HomeCubit`; the first-run/invite rule is covered only by code review.
- Dark-mode checks for the today card and invite card; semantics/screen-reader checks.
- All rollout flags remain off: the shipped Home and Settings are unchanged until `adult_journey_flag_personalization` is set on a device.
