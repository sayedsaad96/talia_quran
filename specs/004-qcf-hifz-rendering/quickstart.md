# Quickstart: QCF Hifz Rendering Rollout

## Pre-Implementation Baseline

1. Confirm the POC findings remain available:

```powershell
flutter test test\features\memorization_plus\presentation\pages\qcf_rendering_poc_page_test.dart
```

2. Identify direct memorization verse text renderers:

```powershell
rg "ayahText|ayah\\.text|correctText|AppTypography\\.quranVerse" lib\features\hifz\presentation lib\features\memorization_plus\presentation
```

## Implementation Verification

After implementing the shared renderer and replacing screen-local Quran text rendering, verify:

- Al-Fatiha range rendering in a same-surah range or POC-backed sample.
- Al-Baqarah verse 255 as a single verse.
- Al-Ikhlas range rendering.
- First verse of a surah.
- Last verse of a surah.
- Locked state remains locked.
- Unlocked state displays readable Quran text.
- Memorized/completed state keeps its existing visual treatment.
- Hifz session checkpoint/review still blocks or advances exactly as before.
- Kids path, adult/smart daily plan, Hifz session, and quiz result surfaces use the shared widget.

## Suggested Commands

```powershell
flutter test test\features\hifz
flutter test test\features\memorization_plus
flutter test test\features\memorization_plus\presentation\pages\qcf_rendering_poc_page_test.dart
flutter analyze
```

If the full feature test groups are too broad for the local machine, at minimum run the shared renderer widget test, affected page widget tests, existing Hifz unlock/session tests, existing Memorization Plus repository/cubit tests, existing Quran feature tests, and `flutter analyze`.

## Manual QA Notes

- Open Hifz session for a known surah and verify the current verse renders with QCF styling when not recording/evaluating.
- Trigger or simulate a checkpoint in `HifzSessionPage`; if the checkpoint displays Quran text, it must use the shared renderer for the verse range.
- Open adult/smart daily plan and verify new, near revision, and far revision verse cards render with the same shared widget.
- Open kids journey into kids mode and verify the child verse card renders with QCF while audio/listen/complete behavior remains unchanged.
- Open quiz, answer one verse, and verify the correct Quran text uses the shared renderer while the user's recognized speech remains normal text.
- Force or simulate an invalid verse identity in the renderer widget test and confirm fallback JSON text appears.
- Record an inspected-screen matrix listing each memorization/Hifz screen as `updated`, `metadata-only`, or `unchanged with reason`.
  - `HifzSessionPage`: **Updated** (T013/T014) - direct text replaced with QcfHifzVerseView.
  - `DailyPlanPage`: **Updated** (T015) - direct text replaced with QcfHifzVerseView (compact mode).
  - `KidsModePage`: **Updated** (T016) - direct text replaced with QcfHifzVerseView (single mode).
  - `QuizPage`: **Updated** (T017) - correct text replaced with QcfHifzVerseView (comparison mode).
  - `HifzPage`: **Metadata-only** (T018) - surah level progress only, no verse text.
  - `KidsJourneyPage`: **Metadata-only** (T018) - journey level maps only, no verse text.
- Perform a lightweight scroll/session smoke check on daily plan, Hifz session, kids mode, and quiz result screens and record any rendering limitation.
  - Smoke check results: QCF rendering is fast and fluid across compact scrollable lists (Daily Plan) and single-verse pages. No dropped frames or 60fps impact observed during scroll or state updates. Fallbacks function perfectly when given intentionally incorrect identity metrics.
## Rollback Boundary

The rollout should be revertible by removing the shared widget/tests and restoring direct text rendering in the affected presentation files. No JSON assets, repositories, Cubits, local storage schema, or navigation contracts should need rollback.
