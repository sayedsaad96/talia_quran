# Data Model: QCF Hifz Rendering Rollout

This feature introduces presentation-only data shapes. Existing JSON, repository, Cubit, progress, checkpoint, test, and settings models are not replaced.

## HifzVerseRenderingRequest

Represents one request to display a Quran verse or same-surah verse range in a memorization context.

### Fields

- `surahNumber`: `int`, required, valid Quran surah number `1..114`.
- `startVerseNumber`: `int`, required, first verse to render.
- `endVerseNumber`: `int?`, optional, defaults to `startVerseNumber`; must be greater than or equal to `startVerseNumber`.
- `fallbackText`: `String`, required, existing JSON-backed verse text or joined range text.
- `isUnlocked`: `bool`, required, copied from existing memorization logic.
- `isMemorized`: `bool`, required, copied from existing memorization progress/review state.
- `displayMode`: `HifzVerseDisplayMode`, optional, defaults to `single`.
- `textAlign`: optional presentation alignment for existing card layouts.

### Validation Rules

- Invalid surah or verse identity must use `fallbackText`.
- Empty QCF output must use `fallbackText`.
- Locked requests must preserve existing locked visuals and must not reveal hidden text if the current screen previously hid it.
- Memorized requests must keep the existing completed/memorized styling affordance.

## HifzVerseDisplayMode

Controls compact presentation variants without changing memorization logic.

### Values

- `single`: one verse, used by Hifz session, kids mode, and quiz answer result.
- `range`: same-surah verse range, used by checkpoints or multi-verse review contexts if text is displayed.
- `compact`: list/tile-friendly view, used by daily plan cards.
- `comparison`: answer-result view that renders the correct Quran text while user-recited text remains normal recognized text.

## HifzVerseRenderingResult

Internal conceptual result for tests and fallback reporting; it does not need to be persisted.

### Fields

- `source`: `qcf` or `fallback`.
- `displayText`: rendered visible string when using fallback, or QCF span content when supported.
- `pageNumber`: optional QCF page number derived from the first verse.
- `limitation`: optional human-readable reason for fallback, used only in debug/test assertions or final reporting.

### State Transitions

- `requested` -> `qcfRendered` when QCF helpers resolve all requested verses and style can be created.
- `requested` -> `fallbackRendered` when identity is invalid, QCF throws, QCF returns empty text, or range support is not safe.
- `qcfRendered` -> `fallbackRendered` if a widget build exception is caught in guarded rendering.

## Existing Models Consumed Without Ownership Changes

- `Ayah`: provides `numberInSurah` and JSON-backed `text` for existing Hifz session fallback.
- `DailyPlanAyah`: provides `surahId`, `ayahNumber`, `ayahText`, and optional `record`.
- `AyahReviewRecord`: provides memorized state through `isMemorized` and strength/review metadata.
- `KidsModeLoaded`: provides `surahId`, `ayahNumber`, `ayahText`, and child progress state.
- `QuizQuestion` and `QuizAnswerResult`: provide `surahId`, `ayahNumber`, `correctText`, and user-recited text.
- `KidsJourneyStage`: provides stage lock/progress metadata; it is not a Quran text source unless future implementation adds visible verse text to stages.
