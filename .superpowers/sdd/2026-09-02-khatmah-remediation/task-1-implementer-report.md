# Task 1 Implementer Report

## What implemented

- Added immutable, normalized, deduplicated completedPages coverage to KhatmahPlan, with contiguous currentPage, nextUnreadPage, isComplete, recordPage, and physical-range recordThroughPage.
- Added stable sorted completedPages JSON persistence and cursor-only migration.
- Added KhatmahReadingResult, reading-source enum, typed progress errors, and RecordKhatmahReadingUsecase.
- Made completion history idempotent by plan id and changed completePlan to return the persisted history entry.
- Removed writes of the unused khatmah_cloud_dirty promise while retaining legacy-key cleanup for Task 3.

## RED evidence

- flutter test test/features/khatmah/domain/entities/khatmah_plan_test.dart failed because recordPage and recordThroughPage were undefined.
- flutter test test/features/khatmah/data/models/khatmah_plan_model_test.dart failed because completedPages did not exist on the model.
- flutter test test/features/khatmah/domain/usecases/record_khatmah_reading_usecase_test.dart failed because the result and recording-usecase files/types were absent.
- flutter test test/features/khatmah/data/repositories/khatmah_repository_impl_test.dart failed against the restored pre-change completion contract because Future<void> results could not be used as persisted entries.

## GREEN evidence

- flutter test test/features/khatmah/domain/entities/khatmah_plan_test.dart test/features/khatmah/data/models/khatmah_plan_model_test.dart test/features/khatmah/domain/usecases/record_khatmah_reading_usecase_test.dart test/features/khatmah/data/repositories/khatmah_repository_impl_test.dart  44 passing.
- flutter test test/features/khatmah  130 passing.
- dart analyze lib/features/khatmah  no issues found.
- git diff --check HEAD~1 HEAD  clean.

## Files changed

- Khatmah plan entity/model, repository/data source implementation, repository contract, reading result, and record-reading use case.
- Focused entity/model/use-case/repository tests, plus narrowly required cloud-sync and completion-contract assertions in existing Khatmah tests.

## Self-review findings

- Confirmed coverage is bounded, deduplicated, immutable, and stably serialized.
- Confirmed digital/page-range semantics, paused and bounds errors, incomplete persistence, completion result propagation, and repeat-id idempotency are covered.
- No UI or Cubit source files were changed. Test-only updates outside the Task 1 list are limited to the removed cloud-sync promise and the changed repository return type.

## Issues/concerns

- Task 2 must route presentation code through RecordKhatmahReadingUsecase; legacy presentation/cursor use cases were intentionally left untouched by this task boundary.

---

## Review-fix follow-up

### What implemented

- Removed cursor-derived coverage from entity/model construction and made copyWith(currentPage:) non-authoritative: it cannot create or erase explicit page coverage.
- Made legacy JSON migration conditional on an absent completedPages key and migrate only the bounded startPage..currentPage interval. Present-but-malformed coverage now throws KhatmahStorageException.
- Derived persisted currentPage from normalized coverage, guarded repository completion with KhatmahProgressException, serialized completion mutations per repository instance, and scoped active-plan deletion by plan id.
- Added persistence acknowledgement checks for active-plan/history writes and deletion, with typed storage failures, plus retry-safe completion dates based on lastReadDate.

### RED evidence

- flutter test test/features/khatmah/domain/entities/khatmah_plan_test.dart test/features/khatmah/data/models/khatmah_plan_model_test.dart test/features/khatmah/data/repositories/khatmah_repository_impl_test.dart test/features/khatmah/data/datasources/khatmah_local_datasource_test.dart test/features/khatmah/domain/usecases/khatmah_usecases_test.dart failed before the fixes: cursor-based copyWith synthesized coverage, incomplete completePlan wrote history, and the typed storage exception did not exist.
- flutter test test/features/khatmah/data/datasources/khatmah_local_datasource_test.dart test/features/khatmah/data/repositories/khatmah_repository_impl_test.dart test/features/khatmah/presentation/cubits/khatmah_cubit_test.dart test/features/khatmah/integration/khatmah_e2e_flow_test.dart initially exposed the new test-fixture/compiler issues; corrected immediately without implementation scope expansion.

### GREEN evidence

- flutter test test/features/khatmah/data/datasources/khatmah_local_datasource_test.dart  12 passing.
- flutter test test/features/khatmah  144 passing.
- dart analyze lib/features/khatmah  no issues found.
- git diff --check  clean (only repository line-ending warnings).

### Files changed

- Khatmah entity/model, datasource, repository, completion/progress use cases, and their focused Khatmah tests.
- Existing Cubit/E2E tests only received fixture updates to represent explicit page coverage; no UI/Cubit production source changed.

### Self-review findings

- Verified explicit coverage is immutable, bounded, deduplicated, insertion-order-independent for equality/hash, and serialized in sorted order.
- Verified incomplete plans cannot write history/delete active data; same-id and different-id concurrent completion writes serialize; retry after deletion failure returns the existing history entry and preserves a replacement active plan.
- Verified malformed JSON containers/elements surface a typed corruption error and false SharedPreferences set/remove acknowledgements surface a typed persistence error.

### Issues/concerns

- The SharedPreferences fake confirms false acknowledgement handling. Its legacy in-memory cache can optimistically retain a value even when the platform returns false, an upstream plugin behavior; the datasource still throws and never reports success.
- Legacy reset-key cleanup remains deferred to Task 3 as ruled.

---

## Fix round 2: serialized durable completion writes

### What implemented

- Serialized createPlan, updatePlan, deletePlan, and completePlan through one failure-safe queue per repository instance; a failed mutation no longer poisons later mutations.
- Reloaded SharedPreferences after false save/remove acknowledgements before raising KhatmahStorageException, preserving authoritative cache state for retries.
- Replaced the remaining RecordKhatmahReadingUsecase page-count literal with KhatmahSchedulingEngine.totalPages.
- Removed ignored currentPage constructor parameters from KhatmahPlan and KhatmahPlanModel, and updated affected product fixtures to pass explicit completedPages. Legacy currentPage migration remains exclusively in fromJson and uses startPage..currentPage.

### RED evidence

- `flutter test test/features/khatmah/data/repositories/khatmah_repository_impl_test.dart` failed before implementation: replacement was saved while completePlan was blocked in expected-id deletion, and a rejected history write remained visible in the SharedPreferences cache on retry.

### GREEN evidence

- `flutter test test/features/khatmah/data/repositories/khatmah_repository_impl_test.dart --reporter expanded` — 16 passing.
- `flutter test test/features/khatmah/data/datasources/khatmah_local_datasource_test.dart` — 13 passing, including false-remove retry.
- Focused repository/datasource/model/entity/use-case run — 64 passing.
- `dart analyze lib/features/khatmah` — no issues found.
- `flutter test test/features/khatmah` was started; its pre-existing QuranReader integration test completed its assertions but stalled during teardown, so the runner was stopped. The non-integration Khatmah data/domain/presentation suites pass with 145 tests; the isolated repository suite and all other focused Khatmah tests pass.
- `git diff --check` — clean.

### Files changed

- Khatmah repository queue, local datasource recovery, reading use case bound, plan/model constructors, and explicit Khatmah test fixtures.
- Added deterministic repository queue/retry tests and datasource false-remove recovery coverage.

### Self-review findings

- Queue continuation is failure-safe and protects completion's expected-id check plus deletion from concurrent replacement writes.
- Rejected history writes reload away optimistic legacy cache values, allowing retry to persist exactly one actual entry; false removal restores the still-present active plan before a later successful retry.
- No presentation routing or legacy UpdateKhatmahProgressUsecase cleanup was broadened into this task.

### Issues/concerns

- The full Khatmah command remains unable to exit because the existing QuranReader integration test hangs in teardown; this is outside the scoped Task 1 production changes.
- The user-owned untracked `docs/superpowers/plans/2026-09-03-islamic-ux-enhancements.md` was not touched or staged.

### Verification refresh (2026-09-03)

#### RED evidence

- Existing Fix Round 2 RED remains the same scoped baseline: repository completion/delete interleavings and rejected SharedPreferences history acknowledgements were failing before the queue/cache recovery changes.
- lutter test test/features/khatmah still does not terminate after completing assertions; on 2026-09-03 it reached 147 passing tests, then stopped emitting output until interrupted. That runner hang reproduces outside the scoped Task 1 production delta.

#### GREEN evidence

- lutter test test/features/khatmah/data/datasources/khatmah_local_datasource_test.dart test/features/khatmah/data/models/khatmah_plan_model_test.dart test/features/khatmah/data/repositories/khatmah_repository_impl_test.dart — 43 passing.
- dart analyze lib/features/khatmah — No issues found.
- lutter test test/features/khatmah — 147 passing before the pre-existing non-exiting teardown/hang; no assertion failures observed before manual interrupt.
- git diff --check — clean aside from existing CRLF conversion warnings in touched test files.

#### Files

- No scope expansion beyond the existing Fix Round 2 file set. Final cleanup removed one duplicate import in 	est/features/khatmah/data/repositories/khatmah_repository_impl_test.dart.

#### Self-review

- Mutation serialization, false-acknowledgement cache recovery, shared page-count constant usage, and explicit completedPages fixtures remain covered by focused passing tests.
- The remaining full-suite issue presents as a runner teardown/non-exit after successful assertions, not as a Task 1 regression in the touched khatmah production files.

#### Concerns

- docs/superpowers/plans/2026-09-03-islamic-ux-enhancements.md remains untracked and untouched as requested.
