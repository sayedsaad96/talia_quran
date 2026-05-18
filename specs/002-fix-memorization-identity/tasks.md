# Tasks: Fix Memorization User Identity & Guardian-Linking Flow

**Input**: Design documents from `specs/002-fix-memorization-identity/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create `MemorizationProfile` entity in `lib/features/memorization_plus/domain/entities/memorization_profile.dart`
- [x] T002 [P] Create `PairingSession` entity in `lib/features/memorization_plus/domain/entities/pairing_session.dart`
- [x] T003 [P] Create `SmartMemorizationSettings` entity in `lib/features/memorization_plus/domain/entities/smart_memorization_settings.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Implement `MemorizationIdentityLocalDataSource` for `shared_preferences` in `lib/features/memorization_plus/data/datasources/memorization_identity_local_data_source.dart`
- [x] T005 [P] Update `MemorizationPlusRepository` interface to include identity read/write methods in `lib/features/memorization_plus/domain/repositories/memorization_plus_repository.dart`
- [x] T006 Implement repository methods in `lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart`
- [x] T007 Register new data sources and repositories in DI container `lib/core/di/injection.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - First-Time Path Selection (Priority: P1) 🎯 MVP

**Goal**: Present mandatory path choice (Child vs. Adult) on first entry to memorization.

**Independent Test**: Fresh install -> open Memorization -> see path selection. Kill app -> reopen -> jumps to correct flow.

### Implementation for User Story 1

- [x] T008 [US1] Create `MemorizationIdentityCubit` to manage path selection state in `lib/features/memorization_plus/presentation/cubits/memorization_identity_cubit.dart`
- [x] T009 [US1] Create `PathSelectionPage` UI in `lib/features/memorization_plus/presentation/pages/path_selection_page.dart`
- [x] T010 [US1] Add routing for `PathSelectionPage` and route guard in `lib/core/router/app_router.dart`
- [x] T011 [US1] Ensure saving the path navigates correctly (Adult -> memorization flow; Child -> next step).

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Child Path Guardian Linking (Priority: P1)

**Goal**: Force child users to see guardian linking step, with options to link or skip.

**Independent Test**: Select child path -> see guardian linking screen. Skip -> never see it again.

### Implementation for User Story 2

- [x] T012 [US2] Create `GuardianLinkingCubit` to manage pairing state in `lib/features/memorization_plus/presentation/cubits/guardian_linking_cubit.dart`
- [x] T013 [US2] Create `GuardianLinkingPage` UI in `lib/features/memorization_plus/presentation/pages/guardian_linking_page.dart`
- [x] T014 [US2] Implement pairing code generation logic (15 min expiry) in `MemorizationPlusRepositoryImpl`
- [x] T015 [US2] Implement logic to handle "Continue without guardian" (skip) and save to `MemorizationProfile`
- [x] T016 [US2] Update routing to direct Child path to `GuardianLinkingPage` automatically.
- [x] T017 [US2] Implement check to prevent re-linking if `guardianLinkStatus` is already linked.

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Adult Path Direct Flow (Priority: P1)

**Goal**: Ensure Adult path skips all guardian-linking prompts.

**Independent Test**: Select Adult -> no guardian screens appear during onboarding or in Smart Memorization.

### Implementation for User Story 3

- [x] T018 [US3] Ensure `GuardianLinkingPage` route guard blocks navigation if path is Adult.
- [x] T019 [US3] Ensure Smart Memorization entry flows read `MemorizationProfile` and skip linking for adults in `lib/features/hifz/presentation/pages/hifz_page.dart`.

**Checkpoint**: All P1 user stories should now be independently functional

---

## Phase 6: User Story 4 - Parent/Guardian Mode via Settings (Priority: P2)

**Goal**: Let an adult optionally toggle parent mode from settings and scan a code.

**Independent Test**: Enable setting -> scan child code -> child becomes linked, parent sees child data. Parent disables setting -> link is silently removed.

### Implementation for User Story 4

- [x] T020 [US4] Add "I am a parent/guardian" toggle tile in `lib/features/settings/presentation/pages/settings_page.dart`
- [x] T021 [US4] Add scan QR code UI flow in settings when parent mode is enabled.
- [x] T022 [US4] Implement logic to accept a pairing code and set `linkedChildId` on parent, `guardianId` on child.
- [x] T023 [US4] Implement silent revert (link severed) when parent disables the toggle in `SettingsCubit`.

---

## Phase 7: User Story 5 - Smart Memorization Respects Path Identity (Priority: P2)

**Goal**: Smart Memorization changes don't overwrite the core identity.

**Independent Test**: Change daily schedule -> close app -> path and guardian link remain active. Reset path -> schedule is preserved.

### Implementation for User Story 5

- [x] T024 [US5] Implement independent save/load for `SmartMemorizationSettings` in local data source so it does not overwrite `MemorizationProfile`.
- [x] T025 [US5] Add "Reset / Change path" action in `lib/features/settings/presentation/pages/settings_page.dart`.
- [x] T026 [US5] Implement reset logic in `MemorizationPlusRepositoryImpl` to wipe `MemorizationProfile` fields but preserve `SmartMemorizationSettings`.
- [x] T027 [US5] Ensure route guards redirect to `PathSelectionPage` if `selectedPath` is reset.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T028 [P] Add unit tests for `MemorizationIdentityCubit` in `test/features/memorization_plus/presentation/cubits/`
- [x] T029 [P] Add unit tests for `GuardianLinkingCubit` in `test/features/memorization_plus/presentation/cubits/`
- [x] T030 Add localization strings to ARB files (`lib/core/l10n/`) for all new UI text.
- [x] T031 Clean up unused imports and verify strict layer separation.
- [x] T032 Verify offline safety: wrapped `Supabase.instance.client` calls to prevent uninitialized crashes (Audit Report P0 Fix).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - Can proceed sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2)
- **User Story 2 (P1)**: Depends on US1 (Path selection must occur before child guardian linking)
- **User Story 3 (P1)**: Depends on US1
- **User Story 4 (P2)**: Depends on US1 (Adult path required)
- **User Story 5 (P2)**: Depends on US1 & US4

### Parallel Opportunities

- Entities in Phase 1 can be created in parallel.
- Repositories/Datasources updates in Phase 2 can be developed alongside DI registration.
- Unit tests in Phase 8 can run in parallel.
