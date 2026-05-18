# Data Model: QCF Rendering Proof of Concept

## RenderingSample

Represents one visual Quran rendering case shown on the temporary POC screen.

**Fields**:

- `id`: Stable sample identifier for tests and diagnostics.
- `title`: Localized display label.
- `surahNumber`: Quran surah number, when the sample is verse-based.
- `surahName`: Localized or Arabic surah label for display.
- `startAyah`: First verse number for verse-based samples.
- `endAyah`: Last verse number for verse-based samples.
- `pageNumber`: Mushaf page number for full-page samples.
- `displayMode`: One of `singleVerse`, `multipleVerses`, `lastVerse`, or `fullPage`.
- `expectedBehavior`: What the tester should see if the mode is supported.

**Validation Rules**:

- `surahNumber` must be between 1 and 114 when present.
- `startAyah` and `endAyah` must be positive when present.
- `endAyah` must be greater than or equal to `startAyah`.
- `pageNumber` must be between 1 and 604 when present.
- Each required display mode must have at least one sample.

## RenderingStatus

Represents the visible result of attempting a sample.

**Fields**:

- `sampleId`: The related `RenderingSample`.
- `state`: One of `supported`, `limited`, or `unsupported`.
- `message`: Localized tester-facing status or limitation note.
- `details`: Optional technical note for the later implementation report.

**Validation Rules**:

- Unsupported or limited statuses must include a non-empty `message`.
- Status must never write to memorization state or progress.

## Required Samples

| Sample | Display Mode | Source |
|---|---|---|
| Al-Baqarah 255 | Single verse | QCF visual renderer |
| Al-Fatiha 1-7 | Multiple verses | QCF visual renderer, if supported |
| Al-Ikhlas 1-4 | Multiple verses | QCF visual renderer, if supported |
| Ash-Sharh 8 | Last verse | QCF visual renderer |
| Full mushaf page | Full page | `QuranPageView`, if supported |

## State Boundaries

No new persistent entity is introduced. Existing memorization state, progress, locked/unlocked verses, and checkpoints remain owned by the existing JSON-backed memorization and Hifz data flows.
