# Tablet spread prototype: performance gate

Date: 2026-10-23
Plan: `docs/superpowers/plans/2026-10-22-roadmap-phase-3.md`, H2.

## Decision

**Pending measurement. Do not integrate H3 or enable `tabletSpread`.**
Automated layout tests cannot establish QCF rendering performance. No frame
times or memory measurements have been captured.

The committed prototype is the layout shell and page policy. A profile harness
that passes the reader's actual guarded QCF page rendering into `pageBuilder`
is still required before the device run. H2 Step 3 remains open for that work;
the placeholder-based widget tests do not complete that requirement.

## Available environment

- `flutter devices`: exit 0; Windows desktop, Chrome and Edge only.
- `flutter emulators`: exit 0; no emulators available.
- These commands required access to Flutter's SDK cache outside the workspace.
- No Android tablet or Android emulator is available for the planned profile run.

## Required measurement before H3

1. Use an Android tablet or emulator with a landscape viewport of 1280 × 800
   logical pixels; record device, Android version and viewport.
2. Run in profile mode and render the existing single-page QCF content through
   the spread's page builder. Do not substitute placeholder pages for this check.
3. Capture a single-page baseline and a two-page run under matching conditions.
   Turn 30 pages and inspect frame timing and memory in DevTools.
4. Record average frame time, worst frame after initial loading, and memory for
   each run. Record the measured memory ratio.
5. Proceed only if average frame time is below 16 ms, no frame exceeds 50 ms
   after initial loading, and memory is at most twice the single-page baseline.
   If a threshold fails, stop H3 and keep the flag disconnected.

| Measurement | Single page | Spread | Result |
|---|---|---|---|
| Average frame time | Unmeasured | Unmeasured | Pending |
| Maximum frame time after initial load | Unmeasured | Unmeasured | Pending |
| Memory under matching conditions | Unmeasured | Unmeasured | Pending |

## Page ordering

The plan records the owner's R3 approval: `kOddPageOnRight = true`.
This overrides the older roadmap specification's opposite ordering. No Quran
text, source data, or persisted page identifiers are changed by the prototype.

## Automated prototype checks

- H1: nine policy tests passed after the expected initial missing-source
  failure, including exhaustive coverage of all 604 pages under both parity
  choices, inverse indexing and invalid bounds.
- H2: four widget tests passed after the initial missing-source failure and a
  separate null-right-page regression failure. At 1280 × 800, physical left/right
  positions are stable under both RTL and LTR. A missing page keeps its half
  empty and is never passed to the page builder.
- The combined H1/H2 test run passed all 13 tests. These tests use placeholder
  widgets to isolate layout behavior; they do not measure QCF font rendering,
  frame timing, memory, reader navigation, rotation or progress credit.
- Final `flutter analyze --no-pub`: exit 0, `No issues found!` (22.4 s).
  Focused analysis of the four changed source/test files also passed. An
  earlier full run stalled alongside abandoned analyzer attempts; those task
  processes were stopped before the successful clean retry.
- No reader integration, flag activation, audio changes, home widget changes,
  or group-khatmah changes are included in this initial batch.
