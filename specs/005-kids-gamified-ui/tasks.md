# Tasks: Kids Gamified Memorization UI (واجهة الحفظ المُلعبة للأطفال)

**Input**: Design documents from `specs/005-kids-gamified-ui/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Included — the feature specification explicitly requires flutter analyze, flutter test, and manual testing.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter app**: `lib/features/memorization_plus/presentation/` for new gamified UI code
- **Theme**: `lib/features/memorization_plus/presentation/theme/`
- **Widgets**: `lib/features/memorization_plus/presentation/widgets/`
- **Pages**: `lib/features/memorization_plus/presentation/pages/`
- **Assets**: `assets/images/kids/`
- **Tests**: `test/features/memorization_plus/presentation/`
- **Localization**: `lib/core/l10n/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization — theme, feature flag, assets, and localization strings

- [X] T001 Create kids gamified theme with color palette constants in `lib/features/memorization_plus/presentation/theme/kids_theme.dart`
- [X] T002 Create runtime-readable feature flag config for `useNewKidsGamifiedUi` in `lib/features/memorization_plus/presentation/pages/kids_gamified_config.dart`, supporting subsequent kids-path navigation rollback without app restart
- [X] T003 [P] Generate house illustration assets (completed, current, locked, review) and save to `assets/images/kids/`
- [X] T004 [P] Generate kid avatar and decorative assets (ribbon banner, star reward, path decoration) and save to `assets/images/kids/`
- [X] T005 Register new assets directory in `pubspec.yaml` under assets section
- [X] T006 [P] Add Arabic localization keys for kids gamified UI in `lib/core/l10n/app_ar.arb`
- [X] T007 [P] Add English localization keys for kids gamified UI in `lib/core/l10n/app_en.arb`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Reusable widgets that ALL user story pages depend on

**⚠️ CRITICAL**: No page implementation can begin until these widgets are complete

- [X] T008 [P] Create `KidsHouseCard` widget with 4 visual states (locked/current/completed/review) in `lib/features/memorization_plus/presentation/widgets/kids_house_card.dart`
- [X] T009 [P] Create `KidsProgressHeader` widget with avatar, greeting, level bar, star count in `lib/features/memorization_plus/presentation/widgets/kids_progress_header.dart`
- [X] T010 [P] Create `KidsMissionCard` widget with last mission info and continue button in `lib/features/memorization_plus/presentation/widgets/kids_mission_card.dart`
- [X] T011 [P] Create `KidsAyahCard` widget with parchment-style Quran text using QcfHifzVerseView in `lib/features/memorization_plus/presentation/widgets/kids_ayah_card.dart`
- [X] T012 [P] Create `KidsStageDetails` widget with ribbon banner header, 3 mission steps, and start button in `lib/features/memorization_plus/presentation/widgets/kids_stage_details.dart`
- [X] T013 [P] Create `KidsRewardDialog` widget with animated stars celebration, earned rewards, and navigation buttons in `lib/features/memorization_plus/presentation/widgets/kids_reward_dialog.dart`
- [X] T014 Create `KidsJourneyMap` widget with CustomPainter curved path and positioned KidsHouseCards in `lib/features/memorization_plus/presentation/widgets/kids_journey_map.dart` (depends on T008)

**Checkpoint**: All reusable widgets ready — page implementation can now begin

---

## Phase 3: User Story 1 — Kids Journey Map Navigation (Priority: P1) 🎯 MVP

**Goal**: Child sees a vertical scrollable journey map with memorization houses connected by a curved path. Houses show locked/current/completed states. Tapping a house navigates to stage details.

**Independent Test**: Navigate to kids path → see journey map with correct visual states → tap a house → navigate to stage details

### Tests for User Story 1

- [X] T015 [P] [US1] Widget test for KidsHouseCard 4 visual states in `test/features/memorization_plus/presentation/widgets/kids_house_card_test.dart`

### Implementation for User Story 1

- [X] T016 [US1] Create `KidsGamifiedJourneyPage` composing KidsJourneyMap with KidsHouseCards, scrollable layout, app bar with back button in `lib/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart`
- [X] T017 [US1] Widget test for KidsGamifiedJourneyPage verifying stage rendering and tap navigation in `test/features/memorization_plus/presentation/pages/kids_gamified_journey_page_test.dart`

**Checkpoint**: Journey map with house navigation is fully functional and testable

---

## Phase 4: User Story 2 — Kids Memorization Home Screen (Priority: P1)

**Goal**: Child sees a welcoming home screen with greeting, level/progress, stars, last mission card, and bottom navigation.

**Independent Test**: Open kids home → see greeting, progress, stars, last mission → tap bottom nav items → navigate correctly

### Implementation for User Story 2

- [X] T018 [US2] Create `KidsGamifiedHomePage` composing KidsProgressHeader, KidsMissionCard, quick-access buttons, and first-release bottom navigation for Mushaf, Journey, and Missions/current mission in `lib/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart`
- [X] T019 [US2] Widget test for KidsGamifiedHomePage verifying greeting, progress, stars, and active first-release bottom navigation destinations in `test/features/memorization_plus/presentation/pages/kids_gamified_home_page_test.dart`

**Checkpoint**: Home screen is fully functional with bottom navigation

---

## Phase 5: User Story 3 — Stage Details & Mission Start (Priority: P1)

**Goal**: Child taps a house and sees stage details with ribbon banner, ayah range, surah name, 3 mission steps, and start button.

**Independent Test**: Tap a house from journey map → see stage details → tap "ابدأ المهمة" → navigate to listen screen

### Implementation for User Story 3

- [X] T020 [US3] Create `KidsGamifiedStagePage` composing KidsStageDetails with ribbon header, mission steps, and start button in `lib/features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart`
- [X] T021 [US3] Widget test for KidsGamifiedStagePage verifying stage info and start button in `test/features/memorization_plus/presentation/pages/kids_gamified_stage_page_test.dart`

**Checkpoint**: Full P1 journey is functional: Home → Map → Stage Details

---

## Phase 6: User Story 4 — Listen & Repeat Flow (Priority: P2)

**Goal**: Child starts a mission and sees ayah on a parchment card with audio controls and microphone button. Reuses existing KidsModeCubit logic.

**Independent Test**: Start mission → see ayah card → play audio → complete loops → mic button works

### Implementation for User Story 4

- [X] T022 [US4] Create `KidsGamifiedListenPage` composing KidsAyahCard, audio play/pause controls, loop indicator, and mic button, wired to existing KidsModeCubit in `lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart`
- [X] T023 [US4] Widget test for KidsGamifiedListenPage verifying ayah display, audio control rendering, microphone control rendering, and loading/unavailable audio message in `test/features/memorization_plus/presentation/pages/kids_gamified_listen_page_test.dart`

**Checkpoint**: Listen & repeat screen works with existing audio logic

---

## Phase 7: User Story 5 — Stage Completion & Rewards (Priority: P2)

**Goal**: After completing all steps, child sees celebration screen with "!أحسنت", animated stars, earned rewards, and navigation buttons.

**Independent Test**: Complete a stage → see celebration with stars → tap "التالي" or "العودة للخريطة" → navigate correctly

### Implementation for User Story 5

- [X] T024 [US5] Create `KidsGamifiedCompletionPage` composing KidsRewardDialog with success message, star animation, earned rewards, and nav buttons in `lib/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart`
- [X] T025 [US5] Wire completion flow from KidsGamifiedListenPage to KidsGamifiedCompletionPage when `isCompleted` is true in `lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart`
- [X] T026 [US5] Widget test for KidsGamifiedCompletionPage verifying success message, earned rewards, Next navigation, and Return to Map navigation in `test/features/memorization_plus/presentation/pages/kids_gamified_completion_page_test.dart`

**Checkpoint**: Full P1+P2 flow is functional: Home → Map → Stage → Listen → Completion

---

## Phase 8: Router Integration & Feature Flag

**Purpose**: Connect all new pages to the app's navigation system with feature flag control

- [X] T027 Add new route constants for gamified stage details and completion screens in `lib/core/router/app_router.dart`
- [X] T028 Modify kids journey route builder in `lib/core/router/app_router.dart` to conditionally use `KidsGamifiedJourneyPage` when runtime `useNewKidsGamifiedUi` is true, falling back to `KidsJourneyPage` on error
- [X] T029 Modify kids mode route builder in `lib/core/router/app_router.dart` to conditionally use `KidsGamifiedListenPage` when runtime `useNewKidsGamifiedUi` is true, falling back to `KidsModePage` on error
- [X] T030 Add route builders for `KidsGamifiedHomePage`, `KidsGamifiedStagePage`, and `KidsGamifiedCompletionPage` in `lib/core/router/app_router.dart`
- [X] T031 Verify all navigation flows: Home → Map → Stage → Listen → Completion → Back to Map. Explicitly confirm child can reach current stage from home in ≤2 taps (SC-001)
- [X] T032 Toggle runtime `useNewKidsGamifiedUi` while the app remains running and verify subsequent kids-path navigation switches to the old kids UI without data loss

**Checkpoint**: Feature flag toggles between old and new UI. All routes work.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, cleanup, and quality assurance

- [X] T033 Run `flutter analyze` and fix all warnings/errors
- [X] T034 Run `flutter test` and verify zero test failures including all new tests
- [X] T035 [P] Verify Arabic RTL layout renders correctly on all 5 new pages and verify no overflow on narrow screens (320px width) per FR-015 and SC-006
- [X] T036 [P] Verify adult memorization paths are completely unaffected (no changes to adult screens, routes, or cubits)
- [X] T037 [P] Verify locked/current/completed/review house states display correctly on the journey map
- [X] T038 Verify navigation from map → stage details → listen → completion → back to map preserves state correctly
- [X] T039 Verify journey map loads within 2 seconds on a representative mid-range device/profile
- [X] T040 Code cleanup: remove any unused imports, add missing const constructors, ensure no dead code

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (theme + assets) — BLOCKS all user stories
- **User Stories (Phase 3–7)**: All depend on Phase 2 (widgets complete)
  - US1 (Journey Map): Can start immediately after Phase 2
  - US2 (Home Screen): Can start in parallel with US1
  - US3 (Stage Details): Can start in parallel with US1/US2
  - US4 (Listen & Repeat): Can start in parallel with US1/US2/US3
  - US5 (Completion): Depends on US4 (listen page must exist for navigation wiring)
- **Router Integration (Phase 8)**: Depends on all user story pages and their tests existing
- **Polish (Phase 9)**: Depends on Phase 8 (complete feature)

### User Story Dependencies

- **US1 (P1 — Journey Map)**: After Phase 2 — No dependencies on other stories
- **US2 (P1 — Home Screen)**: After Phase 2 — Independent of US1
- **US3 (P1 — Stage Details)**: After Phase 2 — Independent of US1/US2
- **US4 (P2 — Listen & Repeat)**: After Phase 2 — Independent of US1/US2/US3
- **US5 (P2 — Completion)**: After Phase 2 + US4 — Needs listen page for navigation wiring

### Within Each User Story

- Widgets (Phase 2) before pages
- Page implementation before widget test for that page
- Core layout before navigation integration

### Parallel Opportunities

- T003, T004: Asset generation can run in parallel
- T006, T007: Localization files can run in parallel
- T008–T013: All 6 independent widgets can be built in parallel
- T016, T018, T020, T022: Page implementations for US1-US4 can run in parallel
- T035, T036, T037: Manual verification tasks can run in parallel

---

## Parallel Example: Foundational Widgets (Phase 2)

```bash
# Launch all independent widgets together:
Task: "Create KidsHouseCard in widgets/kids_house_card.dart"
Task: "Create KidsProgressHeader in widgets/kids_progress_header.dart"
Task: "Create KidsMissionCard in widgets/kids_mission_card.dart"
Task: "Create KidsAyahCard in widgets/kids_ayah_card.dart"
Task: "Create KidsStageDetails in widgets/kids_stage_details.dart"
Task: "Create KidsRewardDialog in widgets/kids_reward_dialog.dart"
# Then after all complete:
Task: "Create KidsJourneyMap in widgets/kids_journey_map.dart" (depends on KidsHouseCard)
```

## Parallel Example: Pages (Phase 3–6)

```bash
# Once widgets are done, launch all independent pages:
Task: "Create KidsGamifiedJourneyPage (US1)"
Task: "Create KidsGamifiedHomePage (US2)"
Task: "Create KidsGamifiedStagePage (US3)"
Task: "Create KidsGamifiedListenPage (US4)"
# Then after US4:
Task: "Create KidsGamifiedCompletionPage (US5)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only — Journey Map)

1. Complete Phase 1: Setup (theme + config + assets + l10n)
2. Complete Phase 2: Foundational (widgets)
3. Complete Phase 3: User Story 1 (Journey Map)
4. **STOP and VALIDATE**: Test journey map independently — verify house states, scrolling, tap navigation
5. Toggle the runtime feature flag to confirm rollback works without app restart

### Incremental Delivery

1. Complete Setup + Foundational → Widgets ready
2. Add US1 (Journey Map) → Test independently → **MVP milestone**
3. Add US2 (Home Screen) + US3 (Stage Details) → Test independently → **P1 complete**
4. Add US4 (Listen) + US5 (Completion) → Test independently → **P1+P2 complete**
5. Router Integration + Polish → **Feature complete**
6. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Old kids UI pages (`KidsJourneyPage`, `KidsModePage`) are NEVER deleted — kept as fallback
- Commit after each task or logical group (conventional commits: `feat:`, `test:`)
- Stop at any checkpoint to validate story independently
- All new strings MUST go through .arb localization files (no hardcoded Arabic in widgets)
- Runtime feature flag `useNewKidsGamifiedUi` allows rollback on subsequent kids-path navigation without app restart
