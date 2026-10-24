# Tablet spread prototype: performance gate

Date: 2026-10-23
Plan: `docs/superpowers/plans/2026-10-22-roadmap-phase-3.md`, H2.

## Decision

**Pending measurement. Do not integrate H3 or enable `tabletSpread`.**
Automated layout tests cannot establish QCF rendering performance. No frame
times or memory measurements have been captured.

H2 Step 3 now shares `AppQuranPageContent` between the existing reader and the
standalone profile harness. The shared leaf preserves the font guard, repaint
boundary, system text scale, zoom, canonical model ID and QCF options. Only
spread panes get a local bounded `MediaQuery`; ordinary reader sizing remains
unchanged. Composed widget tests cover real leaf construction, highlights,
physical page order and canonical IDs after resize. They do not certify actual
QCF glyph display or device performance.

## Running the prepared harness

Run the two modes in separate fresh Android processes on the same device.
Replace `DEVICE` and `REVISION` with the actual device ID and source revision.
Both mode and run ID are required; debug/release runs are rejected as evidence.

```text
flutter run --profile -d DEVICE -t lib/benchmarks/quran_spread_profile.dart --dart-define=QURAN_PROFILE_MODE=single --dart-define=QURAN_PROFILE_RUN_ID=baseline-01 --dart-define=QURAN_PROFILE_REVISION=REVISION
flutter run --profile -d DEVICE -t lib/benchmarks/quran_spread_profile.dart --dart-define=QURAN_PROFILE_MODE=spread --dart-define=QURAN_PROFILE_RUN_ID=spread-01 --dart-define=QURAN_PROFILE_REVISION=REVISION
```

Each automated run starts at page 1 and completes 30 adjacent turns, using
300 ms linear animations and 500 ms dwell. Initial visible fonts are awaited;
subsequent font loads remain part of the workload. Both modes use the same
604-entry highlight fixture (the first canonical ayah on every page), light
theme, tajweed enabled and radius-8 prefetch around visible pages. The fixture
is derived from existing QCF models and changes no text or stored data.

The harness prints `QURAN_PROFILE_FILE` with the local temporary JSON artifact
path after recording. Retrieve that file before clearing the device's cache.
It contains raw timestamped frames, per-turn boundaries/pages/font readiness,
mean/max/p95 build/raster/total times, frames at or above 16 ms and above 50 ms,
process RSS samples and peak RSS, viewport/DPR, run ID and platform metadata.
Frames are filtered by their timestamps, including late batches, with duplicate
timestamps deduplicated. Empty or overflowed windows are marked invalid.
The harness always leaves its performance and visual verdicts pending.

Add `--dart-define=QURAN_PROFILE_AUTOMATE=false` for manual glyph, highlight,
zoom and page-boundary checks. This does not produce an automated timing report.
Record Flutter/engine versions, renderer, GPU, refresh rate and disk-cache state
alongside the artifact. Inspect DevTools and Android memory evidence as well;
the JSON file alone does not certify the memory gate. Thirty spread turns visit
twice as many new canonical pages as thirty single-page turns; disclose that
workload difference when interpreting retained-font memory.

## Available environment

- `flutter devices`: exit 0; Windows desktop, Chrome and Edge only.
- `flutter emulators`: exit 0; no emulators available.
- These commands required access to Flutter's SDK cache outside the workspace.
- The original check had no Android target. A read-only ADB recheck on
  2026-10-24 found `127.0.0.1:5555`, API 28, reported model `NE2211`.
  Its device type and suitability for a 1280 × 800 logical viewport have not
  been verified, and no harness was installed or measured on it. The gate
  remains pending.

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
- No spread routing integration, flag activation, audio changes, home widget changes,
  or group-khatmah changes are included in this initial batch.

## Continuation: safety prerequisite and independent I1

- Fixed the existing font guard's fail-open and stale-completion paths. A
  page remains a skeleton unless its current request and loader confirm that
  page's font is registered. Five unsafe paths were reproduced before repair;
  eight deterministic guard tests and four existing reader tests passed.
  This is a control-flow repair, not a runtime glyph-correctness certificate.
- I1's pure hands-free round engine is implemented and reviewed. Fourteen tests
  cover oldest-first due selection within one surah, adult/corpus eligibility,
  immutable transitions, interruption and prompt duration. It has no audio,
  persistence or SRS write path. I2/I3 audio and UI remain pending.
- Remaining minor coverage: the guard's default QCF adapter still needs a real
  font-registration check; two stale-completion orderings are not explicit in
  its deterministic tests. The composed real-leaf spread test covers RTL and
  resize; null halves and LTR are covered by the separate layout-shell tests.

## Final verification of this increment

- `flutter test --no-pub test/features/quran test/benchmarks test/core/memorization/hands_free test/assets/corpus_integrity_test.dart --reporter expanded`:
  exit 0, **269 tests passed** (26 s). `TEMP` and `TMP` were set to the
  repository's `.superpowers/tmp` directory in the same command.
- Final `flutter analyze --no-pub`: exit 0, **No issues found!** (8.4 s).
- The shared renderer and benchmark review findings were addressed, including
  the final per-turn timing-marker correction with a fresh-frame test.
- No profile build, Android runtime check, actual glyph comparison, frame-time
  measurement or memory comparison was performed. The full application test
  suite was not run; the command above states the tested scope.
- H2 Step 3 is ready; H2 measurement/decision and H3 remain pending.

## Phase checkpoint: 2026-10-24

The 269-test result above belongs to the renderer increment. Later phase-wide
verification passed all **5,170 tests** with concurrency 4 and a bounded `2x`
test-timeout multiplier; analysis reported no issues. This supplies no frame,
glyph or memory measurement. H2 remains pending. See the
[current phase status](2026-10-24-roadmap-phase-3-status.md) for native build,
device and server gates.
