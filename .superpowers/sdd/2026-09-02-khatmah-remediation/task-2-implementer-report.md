# Task 2 Implementer Report

## Implemented behavior

- `KhatmahCubit` is now the reader-progress presentation owner. Digital and physical commands call `RecordKhatmahReadingUsecase`; it exposes paused, retryable progress-failure, and persisted-history completion states.
- A single late page no longer fabricates completion. The E2E flow records digital coverage explicitly through the Cubit and validates the archive result.
- `QuranPageCubit.confirmRead` is ordinary confirmation only and returns `Future<bool>`; it has no Khatmah dependency.
- The reader records a Khatmah page only after generic confirmation succeeds. It listens once for persisted completion (typed `KhatmahReadingResult` route extra) and exposes retryable failures.
- Reader session UI renders paused/failure states and offers retry. DI removes reachable `CompleteKhatmahUsecase` and `UpdateKhatmahProgressUsecase` wiring; scheduling uses a narrowly named persistence use case.

## RED evidence

- `flutter test test/features/khatmah/presentation/cubits/khatmah_cubit_test.dart` failed because `KhatmahPaused` did not exist.
- `flutter test test/features/quran/presentation/cubits/quran_page_cubit_khatmah_test.dart` failed because `confirmRead` returned `void`.
- `flutter test test/features/khatmah/integration/khatmah_e2e_flow_test.dart` failed to compile against the removed legacy Quran/Khatmah constructor dependencies, proving the E2E was still wired to cursor-progress/completion behavior.

## GREEN evidence

- Focused Cubit test: 4 passing.
- Focused Quran confirmation test: 2 passing.
- Reader mode test: 6 passing.
- Required combined four-file command completed all visible assertions through 14 tests, but did not print the normal final summary; this matches the known E2E teardown/non-exit behavior and is not claimed as passing.
- `dart analyze lib/features/khatmah lib/features/quran lib/core/di/injection.dart lib/core/router/app_router.dart`: no issues.
- `git diff --check`: clean (existing line-ending warnings only).

## Files

- Khatmah/Quran Cubits, reader page/session bar, DI/router, schedule-only use case, and Task 2 focused/E2E tests.

## Self-review

- Completion navigation requires a persisted result and is guarded against repeated state delivery.
- The reader never asks Khatmah storage to progress before ordinary confirmation succeeds.
- The untracked user-owned Islamic UX plan was not touched or staged.

## Concerns

- The specified E2E suite still appears to hang after assertions during teardown; the Task 1 report documents the same pre-existing symptom. No timed-out/non-exiting command is reported as passed.
- Existing broad dashboard fixtures still use the old Cubit constructor and need a follow-up fixture-only migration before running the entire presentation suite.

## Review-fix follow-up

### Implemented

- Paused reader commands now preserve `KhatmahPaused` and never invoke record storage.
- Khatmah progress writes now have an in-flight guard, cleared in `finally`, so concurrent commands collapse to one durable operation and failures remain retryable.
- Failure state no longer fabricates an empty plan; it carries the last authoritative plan when one is known.
- Reader confirmation feedback no longer cancels its Khatmah subscription.
- Schedule persistence now fetches the active plan and accepts explicit schedule metadata only, preserving coverage and status.
- Dashboard fixture wiring was migrated to record-reading/schedule-only dependencies.

### RED / GREEN

- RED: focused Cubit test exposed paused commands entering `KhatmahProgressFailure` and two concurrent calls reaching record storage twice.
- GREEN: `flutter test test/features/khatmah/presentation/cubits/khatmah_cubit_test.dart` — 6 passing.
- `dart analyze lib/features/khatmah lib/features/quran lib/core/di/injection.dart lib/core/router/app_router.dart` — no issues.

### Remaining concern

- The dashboard runner again did not yield a normal final summary after loading; the broader reader lifecycle interaction and E2E teardown diagnosis need another pass before claiming the full required combined command is green.

## Rescue / fix round (2026-09-03)

### Phase 1 reproduction and root-cause hypothesis

- `flutter test test/features/khatmah/presentation/pages/khatmah_dashboard_page_test.dart --reporter expanded`, under a 120-second external watchdog, exited normally with code 1: 3 passed and 3 failed. The final event was `(tearDownAll)`. Two failures came from a missing Mocktail fallback for `KhatmahReadingSource`; the unmatched matcher then contaminated the pause/resume test.
- `flutter test test/features/quran/presentation/pages/quran_reader_page_mode_test.dart --reporter expanded`, under the same watchdog, exited normally with code 0: 6 passed and `All tests passed!`.
- `flutter test test/features/khatmah/integration/khatmah_e2e_flow_test.dart --reporter expanded`, under the same watchdog, reached 3 passing assertions but never emitted a final summary or process exit. The final event was the reader UI integration test name.
- Minimal isolation with `--plain-name` reproduced the E2E stall in the reader UI test alone. Stage markers proved `setUp` completed through GetIt registration and audio construction; the first test-body await, `khatmahRepository.createPlan(khatmahPlan)`, never completed.
- Root-cause hypothesis: the real SharedPreferences-backed repository mutation is awaited inside `testWidgets` fake async before any pump, so the platform-fake completion is not advanced. The same mutation completes in the nearby plain `test` lifecycle case, while the working reader widget test injects a mock Cubit and performs no real persistence. The minimal hypothesis test is to run only that setup mutation through `tester.runAsync`.

## Final GREEN verification (2026-09-03)

- Root cause fixed: real SharedPreferences-backed `createPlan` setup in the widget E2E runs through `tester.runAsync`, allowing platform-fake completion without fake-async teardown hangs.
- Removed temporary E2E stage diagnostics after confirming the fix.
- Reader mode suite: 11 passing; dashboard suite: 9 passing; E2E suite: 3 passing; schedule-only usecase suite: 3 passing.
- Required combined four-file command: 26 passing, exit 0.
- Analyzer: `dart analyze lib/features/khatmah lib/features/quran lib/core/di/injection.dart lib/core/router/app_router.dart` — no issues.
- `git diff --check` clean.
- Completion state now preserves `newlyCompletedPages` through typed reader navigation; retry selection is deterministic and completion replay remains exactly once.

## Fix Round 3 (2026-09-03)

### RED evidence

- Added deterministic Completer coverage for identical in-flight deduplication, ordered distinct page queueing against the result plan, failure recovery with later retry, pause/resume cache retention, abandonment cache clearing, and authoritative schedule responses.
- Added dashboard widget RED coverage for known-plan progress failure and null-plan load failure. Both initially failed because the queue/cache/UI behavior was absent.

### GREEN evidence

- Cubit suite: 19 passing.
- Dashboard suite: 11 passing.
- Focused analyzer (`lib/features/khatmah`, `lib/features/quran`, DI/router): no issues.

### Architectural rationale

- Replaced the global drop-on-busy guard with a FIFO request queue keyed only by `(source, page)`: duplicate in-flight calls share one Completer, while distinct confirmed pages are retained and executed serially.
- Queue execution resolves the active plan from current state/cache after each prior result, so later pages persist against the newest authoritative coverage; failures complete their own request and do not poison the queue.
- `_lastKnownPlan` transitions are updated only on successful load/record/pause/resume/schedule results and cleared on completed/abandoned plans; failure states retain that cache without fabricating a plan.
- Schedule controls now emit/cache the plan returned by persistence. Dashboard failures retain the plan when known with a retry action, while null-plan load errors provide a dedicated reload state.

## Fix Round 4 (2026-09-03)

### RED evidence

- Added deterministic close-drain coverage for a blocked page 2 followed by page 3: closing while page 2 is pending must drain both writes FIFO, resolve page 3 from page 2's authoritative result, reject page 4 after closing begins, and finish closed without an uncaught emission error.
- Added durable failure coverage for page 2 failing while queued page 3 succeeds, proving the page 2 failure remains retryable with the latest plan; added a two-failure case proving one retry does not discard the other.
- These regressions characterize the prior inherited-close/active-drain race and state-derived retry loss identified by the latest review.

### GREEN evidence

- Cubit suite: 22 passing (19 existing + 3 Fix Round 4 regressions).
- Dashboard suite: 11 passing; reader suite: 11 passing; E2E suite: 3 passing; schedule suite: 3 passing.
- Required combined four-file command: 47 passing, exit 0 (44-test pre-fix baseline plus the 3 new Cubit regressions).
- Focused analyzer (`dart analyze lib/features/khatmah lib/features/quran lib/core/di/injection.dart lib/core/router/app_router.dart`): no issues.
- `git diff --check`: clean. The user-owned Islamic UX plan remains unmodified and unstaged.

### Lifecycle and retry design

- `KhatmahCubit.close` gates new submissions, awaits the single tracked FIFO drain, and only then calls `super.close`; all emissions are guarded while closing/closed.
- Internal authoritative plan cache drives queued requests independently of listeners. Failed requests are retained by `(source, page)` with insertion order; successful writes remove only their own key, and retry selects the most recent outstanding failure.

## Fix Round 5 (2026-09-03)

### RED evidence

- Added regressions for bounded shutdown with a never-resolving write, memoized double-close, completed physical coverage pruning an earlier digital failure, replacement-plan isolation, abandonment cleanup, and accumulated multi-failure retries.
- Against the Round 4 drain loop, the focused suite failed four behaviors: stalled close exceeded the one-second test bound, double-close returned distinct futures, completion was overwritten by the retained digital failure, and a replacement plan remained contaminated by the old-plan failure.

### GREEN evidence

- Cubit suite: 29 passing; dashboard suite: 11 passing; reader suite: 11 passing; E2E suite: 3 passing; schedule suite: 3 passing.
- Required combined four-file command: 54 passing, exit 0.
- Focused analyzer (`dart analyze lib/features/khatmah lib/features/quran lib/core/di/injection.dart lib/core/router/app_router.dart`): no issues.

### Simplification rationale

- Replaced the mutable queue plus nullable drain/cleanup state with one always-settling `Future<void>` tail. Enqueueing installs a plan-scoped Completer before synchronously appending its closure, so deduplication, FIFO order, and close ownership have one source of truth and no restart race.
- Request and failure identity is `(planId, source, page)`. Each closure revalidates the latest internal plan before and after persistence, catches its own failure, settles its request, and leaves the tail successful.
- Successful results prune every covered failure for their plan; completion clears that plan's failures and remains the final emitted state. Successful load replacement/no-plan and abandonment discard stale failures, while retry considers only the active plan.
- `close()` synchronously gates submissions, memoizes one Future, waits for the captured tail only up to the named production shutdown timeout, and calls `super.close()` once. Late storage completion performs safe internal cleanup without emitting to a closed Cubit.

## Fix Round 6 (2026-09-03)

### RED evidence

- The prior close-timeout path memoized shutdown but did not settle the caller-visible storage request when persistence never completed, so the old stalled-close regression still left the request future hanging even though the Cubit closed.

### GREEN evidence

- Shutdown now settles a never-completed storage request to `false`, cancels a queued request before it starts, and safely consumes a late storage error after close.
- Identical in-flight deduplication now proves both callers receive the same shared future.
- Verified totals from the controller pass remain green: Cubit suite 30/30 exit 0; dashboard + reader + E2E + schedule combined 28/28 exit 0; required four-file command 46/46 exit 0.
- `dart analyze lib/features/khatmah lib/features/quran lib/core/di/injection.dart lib/core/router/app_router.dart`: no issues.

### Files

- `lib/features/khatmah/presentation/cubits/khatmah_cubit.dart`
- `test/features/khatmah/presentation/cubits/khatmah_cubit_test.dart`

### Self-review

- Close now has one explicit shutdown signal for accepted work, so timed-out teardown settles request futures without starting later queued writes.
- Late success or failure after shutdown is detached from UI state changes and only contributes safe internal cleanup.
- No dedication behavior was removed; living/deceased dedication support remains intact.
