# Feature Specification: QCF Hifz Rendering Rollout

**Feature Branch**: `004-qcf-hifz-rendering`

**Created**: 2026-05-18

**Status**: Draft

**Input**: User description: "Apply qcf_quran_plus rendering to all Hifz memorization flows while keeping JSON as the logic source. Use qcf_quran_plus as the visual Quran rendering layer across all memorization flows, while keeping the existing JSON-based memorization system as the source of truth for logic and progress. Update all Hifz/memorization screens to render Quran verses using qcf_quran_plus, including children Hifz path, adults Hifz path, Smart Hifz system, review screens, checkpoint/test screens, verse memorization screens, and any screen that displays Quran verses inside memorization features. Do not remove existing JSON memorization data. Keep JSON responsible for Hifz plans, progress, locked/unlocked verses, memorized verses, checkpoints, tests, user settings. Use qcf_quran_plus only for visual Quran rendering. Create a shared reusable widget. All Hifz screens must use the shared widget. Preserve existing navigation, state management, Cubit logic, and user progress. Add fallback rendering using existing JSON verse text if qcf_quran_plus fails or does not support a required case. Keep implementation isolated and easy to review."

## Clarifications

### Session 2026-05-18

- Q: Should QCF rendering reveal Quran text in recall/test states where the current flow intentionally hides the answer? → A: Apply QCF only where Quran verse text is already visible today; keep hidden/recall/test prompts hidden.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Render Memorization Verses Consistently (Priority: P1)

As a learner using any Hifz or memorization screen, I want Quran verses to appear with consistent Quran-specific visual rendering, so memorization feels reliable and familiar across children, adults, and smart memorization paths.

**Why this priority**: The feature's core value is consistent verse rendering across all memorization journeys without changing how learners progress.

**Independent Test**: Can be fully tested by opening each memorization path and verifying displayed Quran verses use the shared visual rendering surface while the learner can continue the same flow.

**Acceptance Scenarios**:

1. **Given** a learner opens the adult memorization path, **When** a verse is displayed, **Then** the verse is visually rendered through the shared Hifz verse display while the existing path behavior is preserved.
2. **Given** a child opens the children memorization path, **When** a verse is displayed, **Then** the verse is visually rendered through the shared Hifz verse display while the child path behavior is preserved.
3. **Given** a learner opens a smart memorization, review, verse memorization, checkpoint, or test screen, **When** Quran verse text is displayed, **Then** the same shared Hifz verse display is used.

---

### User Story 2 - Preserve Memorization Logic and State (Priority: P2)

As a returning learner, I want my plans, progress, locked verses, memorized verses, checkpoints, tests, and settings to continue working exactly as before, so visual rendering improvements do not risk my memorization data.

**Why this priority**: Visual rendering must not rewrite or destabilize the memorization system.

**Independent Test**: Can be fully tested by comparing the same saved progress, locks, memorized states, checkpoints, tests, and settings before and after visiting updated screens.

**Acceptance Scenarios**:

1. **Given** a learner has saved memorization progress, **When** they open updated screens, **Then** progress, memorized state, locks, checkpoints, tests, and settings remain governed by the existing memorization data flow.
2. **Given** a verse is locked, **When** it appears in an updated flow, **Then** it remains visually and functionally locked.
3. **Given** a verse is memorized, **When** it appears in an updated flow, **Then** its existing memorized visual state is preserved.

---

### User Story 3 - Fall Back Safely When Visual Rendering Cannot Be Used (Priority: P3)

As a learner, I want verses to remain readable even if the enhanced renderer cannot display a required verse or case, so memorization sessions are not blocked.

**Why this priority**: Rendering limitations must degrade safely rather than interrupting memorization.

**Independent Test**: Can be fully tested by forcing or simulating an unsupported rendering case and confirming the existing verse text still appears.

**Acceptance Scenarios**:

1. **Given** the enhanced renderer cannot display a verse, **When** the verse appears in a memorization screen, **Then** the screen displays the existing verse text fallback.
2. **Given** fallback rendering is used, **When** the learner continues the flow, **Then** progress, locks, memorized state, checkpoints, tests, and navigation continue normally.
3. **Given** a rendering limitation is observed, **When** implementation findings are reported, **Then** the limitation is documented before the rollout is finalized.

### Edge Cases

- The enhanced renderer cannot display a first verse, last verse, long standalone verse, or multi-verse checkpoint sequence.
- The enhanced renderer cannot display a required surah sample such as Al-Fatiha, Al-Ikhlas, or Al-Baqarah verse 255.
- A locked verse should not reveal unavailable memorization content while still showing the expected locked state.
- Recall, recording, and test prompts that currently hide the correct verse should remain hidden until the existing flow already reveals the verse text.
- A memorized verse should keep its existing visual state after the rendering layer changes.
- A checkpoint or test screen displays multiple verses and must not duplicate rendering code.
- Existing Quran reading screens outside memorization should remain unchanged unless they are directly required for memorization rendering safety.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: All Hifz and memorization screens that display Quran verses MUST use one shared Hifz verse rendering surface.
- **FR-002**: The shared Hifz verse rendering surface MUST visually render Quran verses through the enhanced Quran renderer when the requested verse or verse group is supported.
- **FR-003**: The shared Hifz verse rendering surface MUST accept verse identity, locked state, memorized state, and optional display mode information needed by memorization screens.
- **FR-004**: The existing JSON memorization data MUST remain the source of truth for Hifz plans, progress, locked and unlocked verses, memorized verses, checkpoints, tests, and user settings.
- **FR-005**: Existing navigation, state management, Cubit behavior, and user progress MUST be preserved.
- **FR-006**: The rollout MUST NOT remove existing JSON files or replace the JSON-backed memorization system.
- **FR-007**: The rollout MUST provide fallback display using the existing verse text whenever enhanced rendering fails or does not support a required case.
- **FR-008**: Locked verses MUST remain locked and visibly distinguishable after the rendering update.
- **FR-009**: Unlocked verses MUST display correctly after the rendering update.
- **FR-010**: Memorized verses MUST preserve their existing visual state after the rendering update.
- **FR-011**: Children, adults, smart memorization, review, checkpoint, test, and verse memorization flows MUST be covered by the shared rendering surface.
- **FR-012**: The implementation MUST avoid duplicated Quran verse rendering logic across memorization screens.
- **FR-013**: Existing Quran reading features outside memorization MUST continue to work after the rollout.
- **FR-014**: The rollout MUST include validation for Al-Fatiha, Al-Baqarah verse 255, Al-Ikhlas, first verse cases, last verse cases, locked verses, unlocked verses, memorized verses, multi-verse checkpoints, children path, adults path, smart memorization path, review screens, and test/checkpoint screens.
- **FR-015**: Final reporting MUST list changed files, what was updated, what was not changed, and any rendering limitations found.
- **FR-016**: QCF rendering MUST be applied only to Quran verse text that is already visible in the current memorization flow; recall, recording, and test prompts that intentionally hide correct verse text MUST remain hidden until the existing flow reveals that text.

### Key Entities

- **Hifz Verse Display**: The shared visual surface used by memorization screens to display a verse or verse group while preserving memorization states.
- **Verse Rendering Request**: The information needed to display a Quran verse in a memorization context, including verse identity, locked state, memorized state, display mode, and fallback text.
- **Rendering Fallback**: The existing verse text display used when enhanced rendering cannot safely render a requested case.
- **Memorization State**: Existing plans, progress, locks, memorized markers, checkpoints, tests, and settings that remain governed by the JSON-backed memorization flow.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of identified memorization screens that display Quran verses use the shared Hifz verse rendering surface.
- **SC-002**: 0 existing memorization progress, lock/unlock, memorized verse, checkpoint, test, or settings records are changed solely by opening updated screens.
- **SC-003**: All required sample cases can be verified across the updated memorization flows without blocking the learner.
- **SC-004**: Fallback text appears in 100% of simulated unsupported rendering cases.
- **SC-005**: Existing Quran reading screens outside memorization pass their existing validation after the rollout.
- **SC-006**: Reviewers can identify all changed files and all unchanged logic boundaries from the final implementation report.

## Assumptions

- The proof-of-concept feature has already established that the enhanced renderer can render the required core samples with known full-page preview limitations.
- The shared Hifz verse display will be introduced only inside memorization-related presentation surfaces unless planning discovers a directly required shared presentation location.
- The existing JSON-backed verse text remains available for fallback in every updated memorization screen.
- Existing Hifz and Memorization Plus Cubits will be treated as logic boundaries and changed only if planning proves a small adapter change is unavoidable.
- Any unrelated Quran reading screen changes are out of scope unless needed to keep existing reading behavior passing.
