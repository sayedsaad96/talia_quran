# Phase 0 Research: QCF Rendering Proof of Concept

## Decision: Use the existing `qcf_quran_plus` dependency only for visual output

**Rationale**: The package is already listed in `pubspec.yaml` and `QcfFontLoader.setupFontsAtStartup` is already called during app startup. Using the existing dependency avoids dependency churn and matches the proof-of-concept rule that QCF is for rendering only.

**Alternatives considered**:

- Add or upgrade a Quran rendering dependency: rejected because the POC is explicitly about `qcf_quran_plus` and should remain easy to revert.
- Replace existing JSON Quran data reads with package helpers: rejected because the spec requires JSON to remain the source for memorization state, progress, locks, unlocks, and checkpoints.

## Decision: Keep the POC presentation-only

**Rationale**: The screen displays static rendering samples and limitation notes. It does not need repository calls, persistence, Cubits, or use-cases, and adding those would increase the chance of touching Hifz behavior.

**Alternatives considered**:

- Add a Cubit for the POC: rejected because there is no business state; local widget state is sufficient for temporary visual inspection.
- Integrate into existing Hifz session screens: rejected because the spec forbids modifying existing Hifz logic and requires limitations before production adoption.

## Decision: Use a temporary debug/test route rather than normal navigation

**Rationale**: A direct route such as `/debug/qcf-rendering-poc` lets testers open the screen while keeping normal Hifz and Memorization Plus flows unchanged. Guarding or hiding it from normal user navigation keeps the feature isolated and easy to remove.

**Alternatives considered**:

- Add a visible button to Hifz or Memorization Plus pages: rejected because that changes production navigation and increases revert scope.
- Reuse an existing Quran reader route: rejected because the POC needs all required samples and limitation reporting in one focused screen.

## Decision: Validate three display modes explicitly

**Rationale**: The package exposes a full `QuranPageView`, verse helpers such as `getVerse`, `getVerseCount`, and `getPageNumber`, and existing app code already uses `QuranPageView` for mushaf pages. The POC should therefore test:

- Single verse: Al-Baqarah 255
- Multiple verses from same surah: Al-Fatiha and Al-Ikhlas
- Full mushaf page: page resolved through known samples, plus a direct page attempt

**Alternatives considered**:

- Assume multi-verse and full-page support from package API names: rejected; the screen must report observed limitations.
- Test only one sample: rejected because the spec requires four Quran coverage cases.

## Decision: Use Ash-Sharh verse 8 as the last-verse boundary sample

**Rationale**: Ash-Sharh is short, commonly recognized, and verse 8 is its final verse. It is compact enough for a POC screen while still validating end-of-surah behavior distinct from Al-Fatiha and Al-Ikhlas.

**Alternatives considered**:

- Use Al-Baqarah 286: valid but visually long for a compact POC and already adjacent to the required Al-Baqarah 255 test.
- Use An-Nas verse 6: valid but less useful because it is also the final verse of the Mushaf, which may blur surah-boundary and end-of-book behavior.

## Decision: Report unsupported modes in the POC surface and planning notes

**Rationale**: The user explicitly asked to report limitations before applying changes to production screens. The POC should show whether each sample rendered, rendered with caveats, or was unsupported.

**Alternatives considered**:

- Rely on console logs or developer comments: rejected because testers need visible limitation status.
- Fail hard when a mode is unsupported: rejected because unsupported rendering is an expected discovery outcome.
