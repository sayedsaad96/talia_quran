# UI Contract: Shared Hifz Verse Rendering

## Shared Widget

Recommended name: `QcfHifzVerseView`.

Recommended location: `lib/core/widgets/qcf_hifz_verse_view.dart`.

## Public Constructor Contract

```dart
const QcfHifzVerseView({
  super.key,
  required int surahNumber,
  required int verseNumber,
  int? endVerseNumber,
  required String fallbackText,
  required bool isUnlocked,
  required bool isMemorized,
  HifzVerseDisplayMode displayMode = HifzVerseDisplayMode.single,
  TextAlign textAlign = TextAlign.center,
});
```

## Required Behavior

- Use `qcf_quran_plus` only to render visual Quran text.
- Use existing `fallbackText` for all fallback rendering.
- Preserve RTL Quran text direction.
- Preserve locked/unlocked and memorized/completed visual state passed by the caller.
- Render same-surah ranges by joining QCF verse text and end symbols in order.
- Never read or write memorization progress, checkpoints, tests, locks, settings, repositories, or JSON files.
- Never trigger navigation, audio, speech recognition, evaluation, or Cubit events.

## Fallback Rules

Fallback text must render when:

- `surahNumber` is outside `1..114`.
- `verseNumber` or `endVerseNumber` is invalid.
- `endVerseNumber` is less than `verseNumber`.
- `qcf.getVerse`, `qcf.getPageNumber`, or QCF style creation throws.
- QCF returns empty or unusable verse text.
- The caller marks a verse as locked and the existing screen's previous behavior did not show verse text.

## Screen Integration Contract

- `HifzSessionPage`: Replace the displayed current ayah text with `QcfHifzVerseView`; preserve recording/evaluating/result UI and checkpoint gating. If checkpoint text is displayed, pass a same-surah range with fallback text built from existing state.
- `DailyPlanPage`: Replace `planAyah.ayahText` rendering in `_AyahPlanTile`; pass `isMemorized`/completed style from `plan.isCompleted(...)` and `planAyah.record?.isMemorized`.
- `KidsModePage`: Replace `state.ayahText` rendering in `_AyahCard`; preserve audio loop and completion controls.
- `QuizPage`: Replace only the correct Quran text comparison in `_ComparisonCard` or split it into a Quran-text variant; do not render `userText` through QCF.
- `KidsJourneyPage` and `HifzPage`: No replacement is required unless implementation finds actual Quran verse text, because current visible text is metadata/stage/surah labels.
- Existing Quran reading screens under `lib/features/quran/` must not be changed by this feature.

## Test Contract

Widget tests must cover:

- Single verse QCF rendering path.
- Same-surah range rendering path.
- Fallback path for invalid identity.
- Locked state behavior.
- Memorized/completed state behavior.
- Daily plan tile uses shared renderer.
- Kids mode card uses shared renderer.
- Quiz correct-text comparison uses shared renderer while user-recited text remains normal.

## Reporting Contract

Final implementation report must list:

- Changed files.
- Screens updated.
- Screens inspected but not changed.
- Tests run.
- Any QCF limitation found, including whether fallback handled it.
