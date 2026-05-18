# Feature Specification: QCF Rendering Proof of Concept

**Feature Branch**: `003-qcf-rendering-poc`

**Created**: 2026-05-18

**Status**: Draft

**Input**: User description: "Create an isolated proof-of-concept for using qcf_quran_plus inside the Hifz/memorization flow. Rules: Do not modify the existing Hifz logic. Do not remove or replace the current JSON data source. Use JSON only for memorization state, progress, locked/unlocked verses, and checkpoints. Use qcf_quran_plus only for rendering Quran verses visually. Add a temporary test page/screen that displays: one single verse; multiple verses from the same surah if supported; a full mushaf page if supported. Test with Al-Fatiha, Al-Baqarah verse 255, Al-Ikhlas, and the last verse of a surah. Report any limitation before applying changes to production screens. Keep changes isolated and easy to revert."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open Isolated Rendering Test Screen (Priority: P1)

As a developer or tester evaluating memorization display options, I want a temporary screen that can be opened without changing the existing Hifz experience, so I can compare Quran verse rendering separately from memorization logic.

**Why this priority**: The proof of concept is only valuable if it is isolated and cannot alter the current user-facing memorization flow.

**Independent Test**: Can be fully tested by opening the temporary screen and confirming that existing Hifz entry points, memorization behavior, and saved progress remain unchanged.

**Acceptance Scenarios**:

1. **Given** the app contains the current Hifz/memorization flow, **When** a tester opens the temporary rendering test screen, **Then** the screen appears as a separate proof-of-concept surface.
2. **Given** a tester uses the current Hifz flow, **When** they start, continue, or review memorization, **Then** the flow behaves as it did before the proof of concept.
3. **Given** the proof-of-concept screen is removed, **When** the app is rebuilt, **Then** no production memorization behavior depends on it.

---

### User Story 2 - Validate Verse-Level Rendering Coverage (Priority: P2)

As a developer or tester, I want the temporary screen to display required Quran samples, so I can confirm whether the visual renderer supports the memorization display cases needed before production adoption.

**Why this priority**: The decision to use the renderer depends on concrete sample coverage across short surahs, a well-known standalone ayah, and boundary verses.

**Independent Test**: Can be fully tested by viewing the proof-of-concept screen and checking each required sample independently.

**Acceptance Scenarios**:

1. **Given** the temporary screen is open, **When** the single-verse sample is displayed, **Then** Al-Baqarah verse 255 is visually rendered as one verse.
2. **Given** the temporary screen is open, **When** the multiple-verse sample is displayed, **Then** Al-Fatiha and Al-Ikhlas are visually rendered as multi-verse surah samples when supported.
3. **Given** the temporary screen is open, **When** the boundary sample is displayed, **Then** the last verse of a selected surah is visually rendered and clearly identified.

---

### User Story 3 - Assess Full Page Rendering and Limitations (Priority: P3)

As a developer or tester, I want the temporary screen to attempt full mushaf page rendering and report unsupported cases, so production screens are not changed until limitations are known.

**Why this priority**: Full-page display may influence future memorization experiences, but it must not block the smaller verse-level proof of concept.

**Independent Test**: Can be fully tested by opening the full-page section and confirming either a rendered page or a clear limitation note is shown.

**Acceptance Scenarios**:

1. **Given** full mushaf page rendering is supported, **When** the tester opens the full-page section, **Then** a complete page is visually rendered in the temporary screen.
2. **Given** full mushaf page rendering is not supported, **When** the tester opens the full-page section, **Then** the screen shows a clear limitation note instead of failing silently.
3. **Given** any required rendering sample is unsupported, **When** the tester reviews the proof-of-concept report, **Then** the limitation is listed before any production-screen adoption is considered.

### Edge Cases

- The renderer cannot display multiple verses from the same surah as a grouped visual unit.
- The renderer cannot display a full mushaf page.
- A required verse or page sample is unavailable, misidentified, or visually incomplete.
- The proof-of-concept screen is reachable in a release build by accident.
- Existing memorization state, progress, locked or unlocked verses, or checkpoints are affected by opening the temporary screen.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The proof of concept MUST add a temporary, isolated test screen for evaluating visual Quran rendering in the memorization area.
- **FR-002**: The proof of concept MUST NOT modify existing Hifz or memorization logic.
- **FR-003**: The proof of concept MUST NOT remove, replace, or change the current JSON Quran data source used by the app.
- **FR-004**: Memorization state, progress, locked and unlocked verses, and checkpoints MUST continue to rely only on the existing JSON-backed behavior.
- **FR-005**: The proof of concept MUST use the new visual renderer only to display Quran verse text or page visuals.
- **FR-006**: The temporary screen MUST display a single-verse sample using Al-Baqarah verse 255.
- **FR-007**: The temporary screen MUST display multiple verses from the same surah using Al-Fatiha and Al-Ikhlas when this display mode is supported.
- **FR-008**: The temporary screen MUST include Ash-Sharh verse 8 as the last-verse sample.
- **FR-009**: The temporary screen MUST attempt to display a full mushaf page when this display mode is supported.
- **FR-010**: Unsupported display modes MUST be reported clearly on the proof-of-concept screen or in the proof-of-concept findings.
- **FR-011**: The proof of concept MUST document all observed limitations before any changes are made to production Hifz or memorization screens.
- **FR-012**: All proof-of-concept changes MUST be easy to locate and revert without affecting production memorization behavior.

### Key Entities

- **Rendering Sample**: A Quran display case used to verify visual output, including surah identity, verse range or page identity, display mode, and expected support status.
- **Limitation Report**: A short record of unsupported, incomplete, or risky display behavior discovered during proof-of-concept testing.
- **Memorization State**: Existing user progress, locks, unlocks, and checkpoints that must remain governed by the current memorization data flow.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of existing Hifz and memorization user journeys available before the proof of concept remain available and unchanged after it is added.
- **SC-002**: Testers can open the temporary proof-of-concept screen and inspect all required samples in under 2 minutes.
- **SC-003**: The proof of concept identifies support or limitation status for single-verse, multiple-verse, last-verse, and full-page display modes.
- **SC-004**: No memorization state, progress, lock/unlock status, or checkpoint data changes after a tester opens and exits the proof-of-concept screen.
- **SC-005**: All files or routes added for the proof of concept can be removed without requiring changes to production Hifz behavior.

## Assumptions

- The target users for this proof of concept are developers, QA testers, and product reviewers rather than end users.
- The proof-of-concept screen may be hidden from normal navigation as long as testers have a documented way to open it.
- The last-verse boundary validation uses Ash-Sharh verse 8.
- Production Hifz screens will not adopt the renderer until the proof-of-concept limitations are reviewed.
- The existing memorization identity and guardian-linking work remains separate from this proof of concept.
