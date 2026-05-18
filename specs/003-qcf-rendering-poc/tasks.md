# Tasks: QCF Rendering Proof of Concept

**Input**: Design documents from `specs/003-qcf-rendering-poc/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/qcf-rendering-poc-ui.md, quickstart.md

**Tests**: Included. The project constitution requires tests for non-trivial feature work, and the plan requires focused widget coverage for this temporary POC screen.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the POC can use existing project wiring without dependency or data-source churn.

- [x] T001 Verify `qcf_quran_plus: ^0.0.8` remains present without version changes in `pubspec.yaml`
- [x] T002 Verify existing QCF startup font loading remains unchanged in `lib/main.dart`
- [x] T003 [P] Review current temporary-route insertion point in `lib/core/router/app_router.dart`
- [x] T004 [P] Review existing Hifz entry points for regression boundaries in `lib/features/hifz/presentation/pages/hifz_page.dart` and `lib/features/hifz/presentation/pages/hifz_session_page.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared presentation scaffolding and localized labels needed before any story can be implemented.

**Critical**: No user story work can begin until this phase is complete.

- [x] T005 Add QCF POC localization keys for title, section labels, status labels, and limitation messages in `lib/core/l10n/app_en.arb`
- [x] T006 Add matching Arabic QCF POC localization keys in `lib/core/l10n/app_ar.arb`
- [x] T007 Regenerate localization outputs in `lib/core/l10n/app_localizations.dart`, `lib/core/l10n/app_localizations_en.dart`, and `lib/core/l10n/app_localizations_ar.dart`
- [x] T008 Create the temporary POC page file with `RenderingSample` and `RenderingStatus` presentation-only value objects in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`
- [x] T009 Create the widget test file and shared pump helper in `test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart`

**Checkpoint**: Foundation ready. User story implementation can now begin.

---

## Phase 3: User Story 1 - Open Isolated Rendering Test Screen (Priority: P1) MVP

**Goal**: A developer or tester can open a separate temporary screen without changing existing Hifz behavior.

**Independent Test**: Open `/debug/qcf-rendering-poc`, confirm the POC screen appears, then confirm normal `/hifz` and `/hifz/session` route behavior remains untouched.

### Tests for User Story 1

- [x] T010 [P] [US1] Add widget test for POC title, isolation notice, and no-production-adoption notice in `test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart`
- [x] T011 [US1] Add route-level test or router assertion for `/debug/qcf-rendering-poc` without altering `/hifz` route constants in `test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart`

### Implementation for User Story 1

- [x] T012 [US1] Implement the POC page scaffold, app bar, intro isolation notice, and findings section shell in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`
- [x] T013 [US1] Add the temporary route constant and page import in `lib/core/router/app_router.dart`
- [x] T014 [US1] Add the `/debug/qcf-rendering-poc` GoRoute guarded for debug/test visibility in `lib/core/router/app_router.dart`
- [x] T015 [US1] Verify the POC page has no imports from `lib/features/hifz/domain/`, `lib/features/hifz/data/`, or Hifz cubits in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`

**Checkpoint**: User Story 1 is independently functional and testable.

---

## Phase 4: User Story 2 - Validate Verse-Level Rendering Coverage (Priority: P2)

**Goal**: The temporary screen visually renders the required single-verse, multi-verse, and last-verse Quran samples, or clearly reports a limitation.

**Independent Test**: Open the POC screen and verify Al-Baqarah 255, Al-Fatiha, Al-Ikhlas, and Ash-Sharh verse 8 each have visible sample labels and support status.

### Tests for User Story 2

- [x] T016 [P] [US2] Add widget test coverage for required verse sample labels in `test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart`
- [x] T017 [US2] Add widget test coverage for supported/limited/unsupported status text on verse samples in `test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart`

### Implementation for User Story 2

- [x] T018 [US2] Implement the Al-Baqarah 255 single-verse rendering sample using `qcf_quran_plus` visual helpers in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`
- [x] T019 [US2] Implement the Al-Fatiha 1-7 multi-verse rendering sample with limitation fallback in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`
- [x] T020 [US2] Implement the Al-Ikhlas 1-4 multi-verse rendering sample with limitation fallback in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`
- [x] T021 [US2] Implement the Ash-Sharh 8 last-verse rendering sample and final-verse label in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`
- [x] T022 [US2] Add per-sample status rows for verse rendering support and limitations in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`

**Checkpoint**: User Story 2 is independently functional and testable.

---

## Phase 5: User Story 3 - Assess Full Page Rendering and Limitations (Priority: P3)

**Goal**: The temporary screen attempts a full mushaf page render and shows visible limitation findings before production adoption.

**Independent Test**: Open the full-page section and confirm either a rendered mushaf page or a clear limitation note appears, then verify findings summarize every limited or unsupported mode.

### Tests for User Story 3

- [x] T023 [P] [US3] Add widget test coverage for the full-page section and visible limitation fallback in `test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart`
- [x] T024 [US3] Add widget test coverage for the findings summary listing limited or unsupported modes in `test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart`

### Implementation for User Story 3

- [x] T025 [US3] Implement a constrained full mushaf page attempt using `QuranPageView` and a local `PageController` in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`
- [x] T026 [US3] Add safe fallback UI when full-page rendering is unavailable or unsuitable inside the POC layout in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`
- [x] T027 [US3] Implement the visible support and limitation findings summary in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`
- [x] T028 [US3] Ensure the POC disposes any local page controller and keeps all state ephemeral in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`

**Checkpoint**: All user stories are independently functional and testable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verify isolation, revertability, formatting, and quickstart commands.

- [x] T029 [P] Confirm no production Hifz files were modified for rendering adoption in `lib/features/hifz/`
- [x] T030 [P] Confirm no JSON Quran datasource or memorization persistence behavior was replaced in `lib/features/quran/data/`, `lib/features/hifz/data/`, and `lib/features/memorization_plus/data/`
- [x] T031 Format changed Dart files in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`, `lib/core/router/app_router.dart`, and `test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart`
- [x] T032 Run `flutter test test\features\memorization_plus\presentation\pages\qcf_rendering_poc_page_test.dart` and address failures in `test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart`
- [x] T033 Run `flutter analyze` and address POC-related diagnostics in `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`, `lib/core/router/app_router.dart`, and `test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart`
- [x] T034 Update limitation findings discovered during implementation in `specs/003-qcf-rendering-poc/quickstart.md`
- [x] T035 Add a no-write regression test that pumps and disposes the POC screen, then verifies memorization progress, lock/unlock, and checkpoint state remain unchanged in `test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart`
- [x] T036 Record quickstart validation that all required samples can be opened and inspected in under 2 minutes in `specs/003-qcf-rendering-poc/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion; blocks all user stories.
- **User Stories (Phase 3+)**: Depend on Foundational completion.
- **Polish (Phase 6)**: Depends on all implemented user stories.

### User Story Dependencies

- **User Story 1 (P1)**: Starts after Foundational; no dependency on US2 or US3.
- **User Story 2 (P2)**: Starts after Foundational; can be built after US1 for route access, but the verse rendering section remains independently testable through widget tests.
- **User Story 3 (P3)**: Starts after Foundational; can be built after US1 for route access, but the full-page section remains independently testable through widget tests.

### Within Each User Story

- Tests first, and they should fail before implementation.
- Page/value-object structure before route integration.
- Rendering implementation before findings summary assertions.
- Story checkpoint validation before moving to the next priority.

### Parallel Opportunities

- T003 and T004 can run in parallel during setup.
- T010 can run independently before T011, but both edit the same test file and should not be assigned in parallel.
- T016 can run independently before T017, but both edit the same test file and should not be assigned in parallel.
- T023 can run independently before T024, but both edit the same test file and should not be assigned in parallel.
- T029 and T030 can run in parallel during polish verification.

---

## Parallel Example: User Story 2

```text
Task: "T016 Add widget test coverage for required verse sample labels in test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart"
```

---

## Parallel Example: User Story 3

```text
Task: "T023 Add widget test coverage for the full-page section and visible limitation fallback in test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: User Story 1.
4. Stop and validate route isolation before adding rendering samples.

### Incremental Delivery

1. Add isolated POC route and scaffold.
2. Add verse-level samples and limitation statuses.
3. Add full-page attempt and findings summary.
4. Run quickstart validation and report limitations before production adoption.

### Revert Strategy

Remove the temporary route from `lib/core/router/app_router.dart`, delete `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`, remove POC localization keys and generated accessors, and delete `test/features/memorization_plus/presentation/pages/qcf_rendering_poc_page_test.dart`.

---

## Notes

- [P] tasks use different files or are independent checks.
- [US1], [US2], and [US3] labels map directly to the user stories in `spec.md`.
- Keep `qcf_quran_plus` limited to visual rendering.
- Do not modify existing Hifz logic.
- Do not remove or replace current JSON data sources.
- Report all rendering limitations before any production Hifz or Memorization Plus screen changes.
