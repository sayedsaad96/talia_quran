---
description: "Task list for Full Application Feature Audit & Integration Validation"
---

# Tasks: Full Application Feature Audit & Integration Validation

**Input**: Design documents from `specs/feature-audit/`

**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**Note**: This is a read-only audit followed by safe incremental fixes. No large refactors.
Tasks marked **[AUDIT]** are analysis-only. Tasks marked **[FIX]** modify source files.

---

## Phase 1: Setup (Audit Infrastructure)

**Purpose**: Prepare the audit report document and confirm tooling.

- [x] T001 Create `specs/feature-audit/audit-report.md` with section headings from data-model.md (Feature Inventory, Fully Working, Conditionally Reachable, Partially Working, Hidden/Unused, Broken, UX Problems, Logic Problems, Dead/Duplicate Code, Performance Concerns, Suggested Fixes)
- [x] T002 [P] Confirm `flutter analyze` runs cleanly — run from repo root and capture output to `specs/feature-audit/analyze-output.txt`
- [x] T003 [P] List all files under `lib/features/` and `lib/core/services/` to validate the 14-feature + 6-service inventory matches `research.md` — document any discrepancies in `audit-report.md`

---

## Phase 2: Foundational (Full Feature Inventory — US1)

**Purpose**: Build the complete FeatureEntry inventory before any validation begins.
**Blocks**: All subsequent phases depend on this map.

- [x] T004 [US1] Audit `auth` feature — document layers (data ✅, domain ✅, presentation ✅), entry point `LoginPage`, route `/login`, DI: `AuthCubit` + `AuthRepository` — add FeatureEntry to `audit-report.md`
- [x] T005 [P] [US1] Audit `azkar` feature — document layers, entry point `AzkarPage`, shell tab route `/azkar`, Cubit `AzkarCubit`, datasource `AzkarLocalDatasource` — add FeatureEntry to `audit-report.md`
- [x] T006 [P] [US1] Audit `certificate` feature — document layers (presentation only), entry point `CertificatePage`, route `/certificate` (requires `extra`), no Cubit in DI — add FeatureEntry to `audit-report.md`
- [x] T007 [P] [US1] Audit `hifz` feature — document layers (data ✅, domain ✅, presentation ✅), entry point `HifzPage`, shell tab `/hifz`, sub-route `/hifz/session`, Cubits `HifzCubit` + `HifzSessionCubit` — add FeatureEntry to `audit-report.md`
- [x] T008 [P] [US1] Audit `home` feature — document layers (presentation only), entry point `HomePage`, shell tab `/`, Cubit `HomeCubit` — add FeatureEntry to `audit-report.md`
- [x] T009 [P] [US1] Audit `memorization_plus` feature — document layers, entry point `TrackSelectionPage`, route `/memorization-plus` + 5 sub-routes, Cubits: `TrackSelectionCubit`, `DailyPlanCubit`, `KidsModeCubit`, `KidsJourneyCubit`, `ParentDashboardCubit`, `CustomPlanCubit`, `QuizCubit` — add FeatureEntry to `audit-report.md`
- [x] T010 [P] [US1] Audit `onboarding` feature — document layers, entry point `OnboardingPage`, route `/onboarding`, no Cubit in DI — add FeatureEntry to `audit-report.md`
- [x] T011 [P] [US1] Audit `progress` feature — document layers (data ✅, domain ✅, presentation ✅), entry point `ProgressPage`, shell tab `/progress`, Cubit `ProgressCubit` — add FeatureEntry to `audit-report.md`
- [x] T012 [P] [US1] Audit `quran` feature — document layers, entry point `QuranPage`, shell tab `/quran`, sub-routes `/quran/surah/:id` + `/quran/page/:num`, Cubits: `SurahListCubit`, `SurahDetailCubit`, `QuranPageCubit`, `SearchQuranCubit` — add FeatureEntry to `audit-report.md`
- [x] T013 [P] [US1] Audit `settings` feature — document layers, entry point `SettingsPage`, route `/settings`, Cubits: `ProfileCubit`, `ThemeCubit`, `LocaleCubit` — add FeatureEntry to `audit-report.md`
- [x] T014 [P] [US1] Audit `splash` feature — document layers (presentation only), entry point `SplashPage`, route `/splash` (initial), no Cubit — add FeatureEntry to `audit-report.md`
- [x] T015 [P] [US1] Audit `streak` feature — document layers (data ✅, domain ✅, presentation/cubits ✅, NO pages, NO route), Cubit `StreakCubit` registered — add FeatureEntry to `audit-report.md`
- [x] T016 [P] [US1] Audit `tutorial_guide` feature — document layers (presentation only), route `/tutorial-guide`, no Cubit in DI — add FeatureEntry to `audit-report.md`
- [x] T017 [P] [US1] Audit `xp` feature — document layers (data/models only, NO domain, NO presentation, NO route, NO Cubit) — add FeatureEntry to `audit-report.md`
- [x] T018 [US1] Audit 6 core services — for each (`XpService`, `StreakService`, `AchievementService`, `SubscriptionService`, `AudioCacheService`, `AppSessionService`): document registration type, consuming Cubits, usage status — add CoreServiceEntry rows to `audit-report.md`
- [x] T019 [US1] Cross-reference all routes in `app_router.dart` against feature inventory — produce RouteEntry table in `audit-report.md` with `path`, `target_widget`, `requires_params`, `reachability`, `feature_id`

**Checkpoint**: Feature inventory complete — every module and service has a FeatureEntry. Ready for validation phases.

---

## Phase 3: US2 — Runtime Integration Validation

**Goal**: Confirm each feature is actually wired, navigable, and state-connected.

**Independent Test**: Each feature's Cubit registration in DI, route presence, and upstream widget connection can be verified independently by tracing code paths.

- [x] T020 [US2] Validate `auth` runtime integration — trace: `SplashPage` → session check → login redirect; verify `AuthCubit` state transitions (`unauthenticated` → `authenticated`); check `AppSessionService` usage; document findings in `audit-report.md` under Runtime Integration
- [x] T021 [P] [US2] Validate `azkar` runtime integration — trace `AzkarPage` → category tap → `/azkar/:category`; verify `AzkarCubit` loads from `AzkarLocalDatasource`; check morning/evening/general/duas routing — document in `audit-report.md`
- [x] T022 [P] [US2] Validate `certificate` runtime integration — trace upstream trigger (search `AchievementService` + `HifzSessionCubit` + `ProgressCubit` for `context.go('/certificate', extra: ...)` calls); confirm `CertificateAward` is constructed and passed correctly — document in `audit-report.md`
- [x] T023 [P] [US2] Validate `hifz` runtime integration — trace `HifzPage` → surah tap → `/hifz/session?surahId=X`; verify `HifzSessionCubit` receives all 11 dependencies from DI; check SRS interval logic path; verify `StreakService` + `XpService` calls — document in `audit-report.md`
- [x] T024 [P] [US2] Validate `home` runtime integration — trace `HomeCubit` data load (progress, hifz progress, quran page, custom plan); verify "Continue Reading" card navigation; check `AppSessionService` session tracking — document in `audit-report.md`
- [x] T025 [P] [US2] Validate `memorization_plus` runtime integration — trace `TrackSelectionPage` → track select → daily-plan/kids-journey routes; verify `surahId` passed correctly via `extra`; check `ParentDashboardCubit` PIN/QR flow wiring; verify `QuizCubit` receives ayah numbers — document in `audit-report.md`
- [x] T026 [P] [US2] Validate `onboarding` runtime integration — trace `SplashPage` → first-launch check (SharedPreferences key) → `/onboarding`; verify onboarding completion marks flag and navigates to `/` — document in `audit-report.md`
- [x] T027 [P] [US2] Validate `progress` runtime integration — trace `ProgressPage` → `ProgressCubit.loadProgress()` → `GetProgressUsecase` → `ProgressRepository`; verify achievement unlock triggers; check activity heatmap data source — document in `audit-report.md`
- [x] T028 [P] [US2] Validate `quran` runtime integration — trace `QuranPage` → surah tap → `/quran/surah/:id`; verify `QuranPageCubit` saves read page via `SaveReadPageUsecase`; check audio playback via `AudioCacheService`; verify bookmark persistence — document in `audit-report.md`
- [x] T029 [P] [US2] Validate `settings` runtime integration — trace theme/locale toggles → `ThemeCubit`/`LocaleCubit` → SharedPreferences; verify notification toggles call `TaliaNotificationService`; check profile name persistence via `ProfileCubit` — document in `audit-report.md`
- [x] T030 [P] [US2] Validate `splash` + `tutorial_guide` runtime integration — trace splash timer/logic → routing decision; trace `/tutorial-guide` trigger point; verify tutorial completion state (StatefulWidget vs persistent) — document in `audit-report.md`
- [x] T031 [P] [US2] Validate `streak` + `xp` runtime integration — confirm `StreakCubit` is provided to widget tree (search for `BlocProvider<StreakCubit>`); confirm `XpService` calls result in persisted Isar writes; verify no XP display surface exists — document in `audit-report.md`
- [x] T032 [US2] Validate `SubscriptionService` + `AudioCacheService` + `AppSessionService` usage — search codebase for all call sites; document consuming features; flag `SubscriptionService` as stub/unused if no gating logic found — document in `audit-report.md`

**Checkpoint**: Every feature has a validated runtime integration status. Ready for issue categorisation.

---

## Phase 4: US3 — Issue Detection & Categorisation

**Goal**: Classify all problems by type and severity into report sections.

**Independent Test**: Each category section in `audit-report.md` can be reviewed independently. All items have a severity label and affected files.

- [x] T033 [US3] Populate `audit-report.md` § "Broken Features" — from T020–T032 findings, list features whose primary flow cannot be completed; assign severity; include FIND-004 (no auth gate) as Critical — document root cause + affected files
- [x] T034 [P] [US3] Populate `audit-report.md` § "Conditionally Reachable" — list `certificate`, `memorization_plus` sub-routes, `tutorial_guide`; for each: document upstream trigger status (present/missing/broken) and severity escalation if trigger is absent
- [x] T035 [P] [US3] Populate `audit-report.md` § "Partially Working Features" — list `streak` (no route), `xp` (no presentation), `tutorial_guide` (no persistent state), `onboarding` (if flag logic incomplete); document specific missing pieces
- [x] T036 [P] [US3] Populate `audit-report.md` § "Hidden / Unused Features" — list `SubscriptionService` (registered, no consumer); flag `HapticService` + `QuranAudioService` (not in DI); document FIND-001 and FIND-009
- [x] T037 [P] [US3] Populate `audit-report.md` § "UX Problems" — scan each feature page for: missing empty states, missing error states, missing loading states, zero error feedback on actions, layout overflow risks (search for fixed heights on small screens); assign severity per tier (structural vs flagrant quality)
- [x] T038 [P] [US3] Populate `audit-report.md` § "Logic Problems" — document FIND-010 (bootstrap StateError on missing `.env`), FIND-007 (silent redirect on bad memorization_plus params), any `Either` unwrapping without error handling found in T020–T032
- [x] T039 [P] [US3] Populate `audit-report.md` § "Dead / Duplicate Code" — document `SubscriptionService` stub (FIND-001), `xp` feature directory with no active logic, any duplicated business logic found across features in T020–T032
- [x] T040 [P] [US3] Populate `audit-report.md` § "Performance Concerns" — document any synchronous heavy computation on main isolate found, any list without pagination exceeding 50 items, any audio not using cache manager

**Checkpoint**: All issue categories populated. Ready for architecture assessment.

---

## Phase 5: US4 — Architecture & Stability Assessment

**Goal**: Flag Clean Architecture violations and stability risks.

**Independent Test**: Architecture findings are self-contained — produced by static import analysis without running the app.

- [x] T041 [US4] Run import violation scan — search all `lib/features/*/presentation/` files for direct imports from `lib/features/*/data/`; document any violations in `audit-report.md` § "Logic Problems" as architecture violations with severity High
- [x] T042 [P] [US4] Scan async operations in all Cubits — check for `async` methods missing `try/catch` or not returning `Either`; check for missing `emit` after awaited calls; document unsafe patterns in `audit-report.md`
- [x] T043 [P] [US4] Scan for duplicate business logic — check if the same surah/ayah data transformation logic appears in more than one feature outside `core/`; check for duplicated SRS interval arrays; document in `audit-report.md` § "Dead / Duplicate Code"
- [x] T044 [P] [US4] Audit DI lifecycle correctness — verify all Cubits are registered as `factory` (not `singleton`); verify all repositories are `lazySingleton`; flag any Cubit registered as singleton (memory leak risk) in `audit-report.md`
- [x] T045 [P] [US4] Validate `flutter analyze` output — review `specs/feature-audit/analyze-output.txt` from T002; categorise each warning/info by severity and affected feature; add to `audit-report.md` § "Logic Problems" if High+

**Checkpoint**: Architecture and stability assessment complete.

---

## Phase 6: US5 — Prioritised Fix Recommendations

**Goal**: Generate one Recommendation per Finding, sorted Critical → Low.

**Independent Test**: Each recommendation references a real finding and provides a concrete, targeted fix approach with affected files.

- [x] T046 [US5] Write recommendations for **Critical** findings — starting with FIND-004 (add `GoRouter` `redirect` callback for auth gate in `lib/core/router/app_router.dart`); include root cause, safe approach, risk level, requires_test flag
- [x] T047 [P] [US5] Write recommendations for **High** findings — FIND-010 (make Supabase config optional at bootstrap; fallback to offline-only mode if `.env` missing); FIND-005 (verify + document certificate upstream trigger; add guard in `AchievementService`)
- [x] T048 [P] [US5] Write recommendations for **Medium** findings — FIND-001 (`SubscriptionService`: remove DI registration or add TODO comment); FIND-002 (`xp`: add XP display widget to `ProgressPage`); FIND-006 (`tutorial_guide`: persist completion flag via SharedPreferences); FIND-007 (add user-facing snackbar on bad-param redirect); FIND-009 (register `HapticService` + `QuranAudioService` via GetIt)
- [x] T049 [P] [US5] Write recommendations for **Low** findings — FIND-003 (`streak`: add streak summary to `ProgressPage` or `HomePage`); FIND-008 (document certificate transient design as intentional in code comment); any Low-severity UX items from T037
- [x] T050 [US5] Sort all recommendations in `audit-report.md` § "Suggested Fixes" by severity descending (Critical → High → Medium → Low); verify every finding from T033–T045 has a linked recommendation (SC-002 compliance check)

**Checkpoint**: All recommendations written. Audit report is complete.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and safe incremental fix implementation for Critical + High items.

- [x] T051 Validate `audit-report.md` completeness — confirm all 14 features + 6 services have a FeatureEntry (SC-001); confirm all findings have recommendations (SC-002); confirm zero source files were modified during audit phases T001–T050 (SC-005)
- [x] T052 [P] **[FIX — Critical]** Add `GoRouter` `redirect` guard for authentication — in `lib/core/router/app_router.dart` add `redirect` callback that checks `AuthCubit` state from `getIt<AuthCubit>()` and redirects unauthenticated users to `/login`; preserve existing route structure; write unit test in `test/core/router/auth_redirect_test.dart`
- [x] T053 [P] **[FIX — High]** Make Supabase bootstrap non-fatal when `.env` is absent — in `lib/main.dart` wrap Supabase init in try/catch; if credentials missing, continue without Supabase (offline mode) rather than throwing `StateError`; document offline degradation in code comment
- [x] T054 [P] **[FIX — Medium]** Register `HapticService` in DI — in `lib/core/di/injection.dart` add `getIt.registerLazySingleton<HapticService>(() => HapticService())`; update any direct instantiation callsites to use `getIt<HapticService>()`
- [x] T055 [P] **[FIX — Medium]** Add user-facing feedback on bad memorization_plus param redirect — in `lib/core/router/app_router.dart` in the 4 routes that fall back to `TrackSelectionPage()`, schedule a `SchedulerBinding.instance.addPostFrameCallback` snackbar with an explanatory message before returning the fallback widget
- [x] T056 Run `flutter analyze` after all FIX tasks complete — confirm zero new warnings introduced; update `specs/feature-audit/analyze-output.txt` with post-fix output

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (US1 — Inventory)**: Depends on Phase 1; BLOCKS all subsequent phases
- **Phase 3 (US2 — Runtime Validation)**: Depends on Phase 2 completion
- **Phase 4 (US3 — Categorisation)**: Depends on Phase 3; runs after runtime findings exist
- **Phase 5 (US4 — Architecture)**: Depends on Phase 2; can run in parallel with Phase 3
- **Phase 6 (US5 — Recommendations)**: Depends on Phases 4 + 5 completion
- **Phase 7 (Polish + Fixes)**: Depends on Phase 6; FIX tasks are independent of each other

### Parallel Opportunities

```bash
# Phase 2 (after T003 completes): run all T004–T018 in parallel
T004 || T005 || T006 || T007 || T008 || T009 || T010 ||
T011 || T012 || T013 || T014 || T015 || T016 || T017 || T018

# Phase 3: run all validation tasks in parallel
T020 || T021 || T022 || T023 || T024 || T025 || T026 ||
T027 || T028 || T029 || T030 || T031 || T032

# Phase 4 + Phase 5: run simultaneously after Phase 3
(T033..T040) || (T041..T045)

# Phase 7 FIX tasks: all independent, run in parallel
T052 || T053 || T054 || T055
```

### Within Each Phase

- Audit tasks [P]: different files, no shared write conflicts
- Fix tasks [FIX]: each touches different files — safe to parallelise
- T050 (sort recommendations) MUST run after T046–T049
- T051 (validation) MUST run after T050
- T056 (final analyze) MUST run after T052–T055

---

## Implementation Strategy

### MVP First (US1 + US2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Full inventory (US1)
3. Complete Phase 3: Runtime validation (US2)
4. **STOP and REVIEW**: Share `audit-report.md` with team — inventory + integration status alone is actionable
5. Proceed to US3–US5 for full categorisation + recommendations

### Incremental Delivery

1. Setup → Inventory → **Share draft report**
2. Add Runtime Validation → **Share updated report**
3. Add Issue Categorisation → **Share full findings**
4. Add Recommendations → **Share actionable report** ← production-ready audit output
5. Apply Critical + High fixes → **Ship hardened app**

---

## Notes

- `[P]` = parallelisable (different files, no write conflicts)
- `[US#]` = maps task to user story for traceability
- `[AUDIT]` = read-only analysis, zero source changes
- `[FIX]` = modifies source files, requires test first (Constitution §III)
- All audit tasks (T001–T051) MUST complete with zero source file modifications
- Commit after each phase checkpoint
- Stop at any checkpoint to review `audit-report.md` independently
