# Quickstart: QCF Rendering Proof of Concept

## Open the POC

1. Build or run the app in debug/test mode.
2. Navigate directly to the temporary route:

```text
/debug/qcf-rendering-poc
```

3. Confirm the normal Hifz tab and `/hifz/session` behavior are still available and unchanged.

## Verify Required Samples

Check that the screen shows these cases:

- Single verse: Al-Baqarah 255
- Multiple verses: Al-Fatiha 1-7
- Multiple verses: Al-Ikhlas 1-4
- Last verse sample: Ash-Sharh 8
- Full mushaf page attempt

For each case, record whether it is supported, limited, or unsupported. Any limitation must be visible before production Hifz or Memorization Plus screens are changed.

## Verify Isolation

- Opening and closing the POC must not change memorization progress.
- Opening and closing the POC must not change locked or unlocked verses.
- Opening and closing the POC must not create or update checkpoints.
- Removing the POC page and route must leave production Hifz behavior intact.

## Observed POC Findings

- Single verse, multiple verses, last verse, and full-page preview render in the isolated POC.
- The full-page preview must use the standard `QuranPageView` page data count; reducing the page count to a single page caused an out-of-range package error during validation.
- Focused widget validation completed the required sample inspection flow in under 2 minutes.

## Suggested Verification Commands

```powershell
flutter test test\features\memorization_plus\presentation\pages\qcf_rendering_poc_page_test.dart
flutter analyze
```
