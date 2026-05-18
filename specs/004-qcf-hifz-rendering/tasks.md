# Tasks: QCF Hifz Rendering Rollout

**Input**: Design documents from `specs/004-qcf-hifz-rendering/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/hifz-verse-rendering-ui.md](./contracts/hifz-verse-rendering-ui.md), [quickstart.md](./quickstart.md)

**Tests**: Required by the feature specification and constitution. Write focused widget tests before implementation where practical, then run affected feature tests and `flutter analyze`.

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with other marked tasks in the same phase because it touches different files and does not depend on incomplete work.
- **[Story]**: Maps the task to a user story from [spec.md](./spec.md).
- Each task includes exact file paths.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the current rendering surface and dependency baseline before code changes.

- [ ] T001 Confirm `qcf_quran_plus: ^0.0.8` remains available in `pubspec.yaml` and note no dependency change is required in `specs/004-qcf-hifz-rendering/tasks.md`
- [ ] T002 Run `rg "ayahText|ayah\\.text|correctText|AppTypography\\.quranVerse" lib\\features\\hifz\\presentation lib\\features\\memorization_plus\\presentation` and record an inspected-screen matrix in `specs/004-qcf-hifz-rendering/quickstart.md` with each screen marked `updated`, `metadata-only`, or `unchanged with reason`
- [ ] T003 Run `flutter test test\\features\\memorization_plus\\presentation\\pages\\qcf_rendering_poc_page_test.dart` to preserve the POC baseline for `lib/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build the shared presentation-only renderer required by every user story.

**CRITICAL**: No production screen should be converted until the shared widget and core fallback tests exist.

- [x] T004 [P] Create failing widget tests for single verse, same-surah range, fallback, locked state, and memorized state in `test/core/widgets/qcf_hifz_verse_view_test.dart`
- [x] T005 Create `HifzVerseDisplayMode` and `QcfHifzVerseView` in `lib/core/widgets/qcf_hifz_verse_view.dart`
- [x] T006 Implement QCF rendering via `qcf.getVerse`, `qcf.getVerseEndSymbol`, `qcf.getPageNumber`, and `qcf.QuranTextStyles.qcfStyle` in `lib/core/widgets/qcf_hifz_verse_view.dart`
- [x] T007 Implement fallback rendering, invalid identity handling, RTL direction, locked styling, and memorized styling in `lib/core/widgets/qcf_hifz_verse_view.dart`
- [x] T008 Run `flutter test test\\core\\widgets\\qcf_hifz_verse_view_test.dart` for `test/core/widgets/qcf_hifz_verse_view_test.dart`

**Checkpoint**: Shared renderer exists, is presentation-only, and can be tested independently.

---

## Phase 3: User Story 1 - Render Memorization Verses Consistently (Priority: P1) MVP

**Goal**: Visible Quran verse text in Hifz and Memorization Plus screens uses the shared QCF Hifz verse view.

**Independent Test**: Open or widget-test Hifz session, daily plan, kids mode, and quiz result surfaces; every currently visible Quran verse display uses `QcfHifzVerseView`, while hidden recall/test prompts remain hidden.

### Tests for User Story 1

- [x] T009 [P] [US1] Add Hifz session widget coverage for visible current ayah rendering and recording-prompt non-reveal behavior in `test/features/hifz/presentation/pages/hifz_session_page_test.dart`
- [x] T010 [P] [US1] Add daily plan widget coverage for new, near revision, and far revision ayah tiles using the shared renderer in `test/features/memorization_plus/presentation/pages/daily_plan_page_test.dart`
- [x] T011 [P] [US1] Add kids mode widget coverage for child verse card rendering through the shared renderer in `test/features/memorization_plus/presentation/pages/kids_mode_page_test.dart`
- [x] T012 [P] [US1] Add quiz page widget coverage showing correct Quran text through the shared renderer while user-recited text remains normal text in `test/features/memorization_plus/presentation/pages/quiz_page_test.dart`

### Implementation for User Story 1

- [x] T013 [US1] Replace visible current ayah `Text` rendering with `QcfHifzVerseView` in `lib/features/hifz/presentation/pages/hifz_session_page.dart`
- [x] T014 [US1] Preserve Hifz recording, evaluating, similarity result, and checkpoint gating UI without revealing hidden correct text in `lib/features/hifz/presentation/pages/hifz_session_page.dart`
- [x] T015 [US1] Replace `planAyah.ayahText` in `_AyahPlanTile` with `QcfHifzVerseView` using compact display mode in `lib/features/memorization_plus/presentation/pages/daily_plan_page.dart`
- [x] T016 [US1] Replace `state.ayahText` in `_AyahCard` with `QcfHifzVerseView` using single display mode in `lib/features/memorization_plus/presentation/pages/kids_mode_page.dart`
- [x] T017 [US1] Replace the correct Quran text comparison with `QcfHifzVerseView` and leave `userText` as normal recognized text in `lib/features/memorization_plus/presentation/pages/quiz_page.dart`
- [x] T018 [US1] Inspect `lib/features/hifz/presentation/pages/hifz_page.dart` and `lib/features/memorization_plus/presentation/pages/kids_journey_page.dart`; change only if actual visible Quran verse text is found, otherwise record them as metadata-only in `specs/004-qcf-hifz-rendering/quickstart.md`
- [x] T019 [US1] Run `flutter test test\\features\\hifz\\presentation\\pages\\hifz_session_page_test.dart test\\features\\memorization_plus\\presentation\\pages\\daily_plan_page_test.dart test\\features\\memorization_plus\\presentation\\pages\\kids_mode_page_test.dart test\\features\\memorization_plus\\presentation\\pages\\quiz_page_test.dart` for the updated presentation pages

**Checkpoint**: User Story 1 is fully functional and can be validated without modifying memorization logic.

---

## Phase 4: User Story 2 - Preserve Memorization Logic and State (Priority: P2)

**Goal**: Existing JSON-backed logic, progress, locks, memorized state, checkpoints, tests, routes, and Cubits behave exactly as before.

**Independent Test**: Existing Hifz and Memorization Plus tests still pass; opening updated screens does not create or mutate progress records.

### Tests for User Story 2

- [x] T020 [P] [US2] Add or update assertion that `QcfHifzVerseView` reads only constructor inputs and performs no repository, Cubit, route, or storage access in `test/core/widgets/qcf_hifz_verse_view_test.dart`
- [x] T021 [P] [US2] Add or update Hifz state regression coverage for locked/unlocked and memorized state preservation in `test/features/hifz/hifz_unlock_rules_test.dart`
- [x] T022 [P] [US2] Add or update Memorization Plus regression coverage for review record and daily plan preservation in `test/features/memorization_plus/memorization_plus_repository_impl_test.dart`

### Implementation for User Story 2

- [x] T023 [US2] Verify no imports of `qcf_quran_plus` were added outside presentation files by checking `lib/features/hifz/domain`, `lib/features/hifz/data`, `lib/features/memorization_plus/domain`, and `lib/features/memorization_plus/data`
- [x] T024 [US2] Verify no changes are made to JSON assets, Quran local data source, Hifz repositories, Memorization Plus repositories, or Cubit logic in `lib/features/quran/data/datasources/quran_local_datasource.dart`
- [x] T025 [US2] Preserve route contracts for `/hifz/session`, `/memorization-plus/daily-plan`, `/memorization-plus/kids`, and `/memorization-plus/quiz` in `lib/core/router/app_router.dart`
- [x] T026 [US2] Run `flutter test test\\features\\hifz test\\features\\memorization_plus` to validate existing Hifz and Memorization Plus behavior after presentation conversion

**Checkpoint**: User Story 2 proves the rollout did not rewrite memorization logic or persistence.

---

## Phase 5: User Story 3 - Fall Back Safely When Visual Rendering Cannot Be Used (Priority: P3)

**Goal**: Unsupported or invalid QCF cases display existing JSON verse text and do not block memorization flows.

**Independent Test**: Simulated invalid identities and unsupported rendering cases show fallback text in the shared renderer and affected screens continue to operate.

### Tests for User Story 3

- [x] T027 [P] [US3] Add invalid surah, invalid verse, reversed range, and empty fallback cases in `test/core/widgets/qcf_hifz_verse_view_test.dart`
- [x] T028 [P] [US3] Add Al-Fatiha, Al-Baqarah 255, Al-Ikhlas, first-verse, last-verse, and long-verse sample coverage in `test/core/widgets/qcf_hifz_verse_view_test.dart`
- [x] T029 [P] [US3] Add fallback continuation coverage for daily plan evaluation buttons in `test/features/memorization_plus/presentation/pages/daily_plan_page_test.dart`
- [x] T030 [P] [US3] Add fallback continuation coverage for kids mode audio/listen/complete controls in `test/features/memorization_plus/presentation/pages/kids_mode_page_test.dart`

### Implementation for User Story 3

- [x] T031 [US3] Harden guarded QCF rendering and fallback selection in `lib/core/widgets/qcf_hifz_verse_view.dart`
- [x] T032 [US3] Ensure fallback rendering preserves current text alignment, RTL direction, and theme colors in `lib/core/widgets/qcf_hifz_verse_view.dart`
- [x] T033 [US3] Update limitation and validation notes for any unsupported cases found in `specs/004-qcf-hifz-rendering/quickstart.md`
- [x] T034 [US3] Run `flutter test test\\core\\widgets\\qcf_hifz_verse_view_test.dart test\\features\\memorization_plus\\presentation\\pages\\daily_plan_page_test.dart test\\features\\memorization_plus\\presentation\\pages\\kids_mode_page_test.dart`

**Checkpoint**: User Story 3 ensures QCF limitations degrade safely to existing JSON text.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, formatting, and implementation report.

- [x] T035 [P] Run `dart format lib\\core\\widgets\\qcf_hifz_verse_view.dart lib\\features\\hifz\\presentation\\pages\\hifz_session_page.dart lib\\features\\memorization_plus\\presentation\\pages\\daily_plan_page.dart lib\\features\\memorization_plus\\presentation\\pages\\kids_mode_page.dart lib\\features\\memorization_plus\\presentation\\pages\\quiz_page.dart test\\core\\widgets\\qcf_hifz_verse_view_test.dart test\\features\\hifz\\presentation\\pages\\hifz_session_page_test.dart test\\features\\memorization_plus\\presentation\\pages\\daily_plan_page_test.dart test\\features\\memorization_plus\\presentation\\pages\\kids_mode_page_test.dart test\\features\\memorization_plus\\presentation\\pages\\quiz_page_test.dart`
- [x] T036 Run `flutter analyze` for the full Flutter project rooted at `D:\Sayed\Flutter\talia_quran`
- [x] T037 Run `flutter test test\\features\\memorization_plus\\presentation\\pages\\qcf_rendering_poc_page_test.dart test\\features\\hifz test\\features\\memorization_plus test\\features\\quran` for final validation
- [x] T038 [P] Update final changed-files, updated-screens, unchanged-boundaries, and limitation notes in `specs/004-qcf-hifz-rendering/quickstart.md`
- [x] T039 Verify no duplicated QCF rendering logic remains outside `lib/core/widgets/qcf_hifz_verse_view.dart` by running `rg "qcf\\.getVerse|QuranTextStyles\\.qcfStyle|getVerseEndSymbol" lib\\features`
- [x] T040 Run a lightweight scroll/session smoke check for daily plan, Hifz session, kids mode, and quiz result rendering, then document any 60 fps or visual limitation in `specs/004-qcf-hifz-rendering/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup and blocks all user-story implementation.
- **User Story 1 (Phase 3)**: Depends on Foundational. This is the MVP.
- **User Story 2 (Phase 4)**: Depends on Foundational and can run after or alongside US1 validation, but final assertions require any converted screens to exist.
- **User Story 3 (Phase 5)**: Depends on Foundational and can run in parallel with US1/US2 tests once the shared widget exists.
- **Polish (Phase 6)**: Depends on all desired stories being complete.

### User Story Dependencies

- **US1 (P1)**: Requires the shared renderer from Phase 2; no dependency on US2 or US3.
- **US2 (P2)**: Requires the shared renderer and benefits from US1 conversions to validate logic boundaries.
- **US3 (P3)**: Requires the shared renderer; fallback tests can be developed in parallel with screen conversions.

### Parallel Opportunities

- T004 can be written while setup validation completes.
- T009, T010, T011, and T012 touch different test files and can run in parallel.
- T020, T021, and T022 touch different regression test files and can run in parallel.
- T027, T028, T029, and T030 can run in parallel after the shared widget API is known.
- T035 and T038 can run in parallel after implementation is complete.

---

## Parallel Example: User Story 1

```text
Task: "Add Hifz session widget coverage in test/features/hifz/presentation/pages/hifz_session_page_test.dart"
Task: "Add daily plan widget coverage in test/features/memorization_plus/presentation/pages/daily_plan_page_test.dart"
Task: "Add kids mode widget coverage in test/features/memorization_plus/presentation/pages/kids_mode_page_test.dart"
Task: "Add quiz page widget coverage in test/features/memorization_plus/presentation/pages/quiz_page_test.dart"
```

---

## Parallel Example: User Story 3

```text
Task: "Add invalid identity fallback coverage in test/core/widgets/qcf_hifz_verse_view_test.dart"
Task: "Add daily plan fallback continuation coverage in test/features/memorization_plus/presentation/pages/daily_plan_page_test.dart"
Task: "Add kids mode fallback continuation coverage in test/features/memorization_plus/presentation/pages/kids_mode_page_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 setup.
2. Complete Phase 2 shared renderer and renderer tests.
3. Complete Phase 3 screen conversions for visible Quran text only.
4. Stop and validate Hifz session, daily plan, kids mode, and quiz result rendering.

### Incremental Delivery

1. Shared renderer with fallback tests.
2. US1 visible verse rendering across memorization screens.
3. US2 logic/state preservation regression checks.
4. US3 fallback and sample coverage hardening.
5. Polish with formatting, `flutter analyze`, and final test commands.

### Safety Notes

- Do not delete or replace JSON files.
- Do not move memorization logic into widgets.
- Do not change Cubit/repository behavior unless a task explicitly proves an adapter change is unavoidable.
- Do not reveal correct Quran text in recall, recording, or test prompts where the current flow intentionally hides it.
- Do not modify unrelated Quran reading screens under `lib/features/quran/`.
