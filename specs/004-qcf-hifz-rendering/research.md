# Phase 0 Research: QCF Hifz Rendering Rollout

## Decision: Use the existing `qcf_quran_plus` dependency as a presentation-only renderer

**Rationale**: `qcf_quran_plus: ^0.0.8` is already present in `pubspec.yaml`, and the isolated POC rendered single verses, same-surah multi-verse samples, last-verse samples, and a full-page preview. The rollout should build on that known package instead of adding or upgrading dependencies.

**Alternatives considered**:

- Replace JSON Quran text reads with package data: rejected because the feature requires JSON to remain the source of truth for memorization logic and fallback text.
- Add another Quran rendering dependency: rejected because it increases review scope and contradicts the requested `qcf_quran_plus` rollout.

## Decision: Centralize Hifz verse rendering in one shared widget

**Rationale**: Direct `Text` rendering currently appears in Hifz session, daily plan tiles, kids mode, and quiz comparison results. A shared widget prevents duplicated QCF style and fallback logic while letting screens pass their existing Cubit-derived state unchanged.

**Alternatives considered**:

- Update each screen with local QCF snippets: rejected because it duplicates rendering logic and makes fallback behavior inconsistent.
- Create a Cubit or repository for rendering: rejected because rendering is visual presentation, not business state or persistence.

## Decision: Keep JSON fallback text mandatory on every rendering request

**Rationale**: QCF helpers can throw or return unusable results for invalid identity inputs, and the user explicitly requires fallback to existing JSON verse text. Requiring fallback text in the widget contract lets memorization sessions remain readable even when QCF rendering is unavailable.

**Alternatives considered**:

- Hide the verse when QCF fails: rejected because it blocks memorization.
- Use a generic error panel: rejected because learners need the Quran text, not a renderer error.

## Decision: Render single and same-surah verse ranges through QCF text helpers

**Rationale**: The package exposes local helpers including `getVerse`, `getVerseEndSymbol`, `getPageNumber`, and `QuranTextStyles.qcfStyle`. These are appropriate for compact memorization cards because they produce inline Quran text without embedding a full mushaf page view.

**Alternatives considered**:

- Use `QuranPageView` for all memorization verse displays: rejected because session/cards need compact verse or range rendering, and the POC found full-page rendering has page-count constraints.
- Continue using `AppTypography.quranVerse` only: rejected because it does not apply the requested QCF visual rendering layer.

## Decision: Treat full mushaf pages as out of scope for production Hifz rollout unless a screen explicitly needs them

**Rationale**: The production memorization surfaces identified by planning display verse text, verse ranges, or answer comparison text rather than full mushaf pages. The POC proved full-page preview can render, but it also found that `QuranPageView` must use its standard page data count. That makes it useful for future reading-style flows, not necessary for this rollout.

**Alternatives considered**:

- Add a full-page view to Hifz sessions: rejected because it changes workflow and layout beyond the visual text renderer requirement.
- Remove the POC route immediately: rejected because it remains useful for validating limitations before and after rollout.

## Decision: Preserve Cubit, repository, and navigation behavior

**Rationale**: Current logic already provides verse identities, fallback text, progress, locked/unlocked state, memorized state, checkpoints, quizzes, and review records. The rollout should consume those values but not recalculate them.

**Alternatives considered**:

- Add new rendering fields to Cubit states: rejected unless implementation proves an existing screen lacks the required verse identity or fallback text.
- Change route parameters for kids/adult flows: rejected because it risks breaking resume/progress behavior.

## Decision: Validate production rollout with focused widget tests plus existing analysis/tests

**Rationale**: The behavioral risk is presentation regression, fallback coverage, and accidental logic mutation. Focused widget tests can verify the shared renderer and updated screens while existing Hifz/Memorization Plus tests guard progress and state behavior.

**Alternatives considered**:

- Rely only on manual QA: rejected because fallback and lock/memorized states are easy to regress.
- Add broad end-to-end tests first: rejected for this plan because current repository already has focused unit/widget patterns and the feature has a narrow presentation boundary.
