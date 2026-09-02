# Khatmah Integrity and Production Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Khatmah progress truthful, completion reliable, account data isolated, and the user journey production-safe.

**Architecture:** Store explicit completed-page coverage and route every Khatmah write through one domain command owned by `KhatmahCubit`. Preserve backward compatibility by deriving coverage from legacy `currentPage`, then make completion/history idempotent and keep the Quran page cubit independent of Khatmah persistence.

**Tech Stack:** Flutter, Dart, flutter_bloc, Equatable, SharedPreferences, GoRouter, flutter_test, mocktail.

**Spec:** `docs/superpowers/specs/2026-09-02-khatmah-remediation-design.md`

## Global Constraints

- Full completion requires explicit coverage of every page from 1 through 604.
- Digital reading records one confirmed page; physical logging records only a user-confirmed contiguous range.
- Existing cursor-only plans migrate as pages `startPage..currentPage` to avoid destructive progress loss.
- Paused plans never accept progress.
- Khatmah completion and history insertion are idempotent by plan id.
- No cloud-sync promise is shown or persisted until owner-scoped cloud synchronization exists.
- All behavior changes follow Red-Green-Refactor and retain the existing clean feature boundaries.
- No religious wording is presented as prescribed, Prophetic, or unanimously accepted without governed approval.

---

### Task 1: Explicit Page Coverage and Idempotent Completion Domain

**Files:**
- Modify: `lib/features/khatmah/domain/entities/khatmah_plan.dart`
- Modify: `lib/features/khatmah/data/models/khatmah_plan_model.dart`
- Create: `lib/features/khatmah/domain/entities/khatmah_reading_result.dart`
- Create: `lib/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart`
- Modify: `lib/features/khatmah/domain/repositories/khatmah_repository.dart`
- Modify: `lib/features/khatmah/data/datasources/khatmah_local_datasource.dart`
- Modify: `lib/features/khatmah/data/repositories/khatmah_repository_impl.dart`
- Test: `test/features/khatmah/domain/entities/khatmah_plan_test.dart`
- Test: `test/features/khatmah/domain/usecases/record_khatmah_reading_usecase_test.dart`
- Test: `test/features/khatmah/data/models/khatmah_plan_model_test.dart`
- Test: `test/features/khatmah/data/repositories/khatmah_repository_impl_test.dart`

**Interfaces:**
- Produces: `KhatmahPlan.completedPages`, `nextUnreadPage`, `isComplete`, `recordPage(int)`, `recordThroughPage(int)`.
- Produces: `enum KhatmahReadingSource { digital, physical }`.
- Produces: `KhatmahReadingResult { KhatmahPlan plan; KhatmahHistoryEntry? historyEntry; Set<int> newlyCompletedPages; bool get completed; }`.
- Produces: `Future<KhatmahReadingResult> RecordKhatmahReadingUsecase.call(KhatmahPlan plan, int pageNumber, {required KhatmahReadingSource source, DateTime? readAt})`.
- Changes: `KhatmahRepository.completePlan` returns the persisted `KhatmahHistoryEntry`.

- [ ] Write failing entity tests proving a jump to page 100 records only page 100, page 2 remains next unread after pages 1 and 100, rereads are idempotent, backward reads do not erase progress, and only full coverage is complete.
- [ ] Run `flutter test test/features/khatmah/domain/entities/khatmah_plan_test.dart` and confirm the new tests fail because the coverage API is missing.
- [ ] Add immutable normalized `completedPages` coverage and the derived getters/methods to `KhatmahPlan`; keep `currentPage` as the highest contiguous prefix projection.
- [ ] Run the entity tests and confirm they pass.
- [ ] Write failing model tests proving JSON round-trip and legacy migration from `currentPage: 10` to pages `1..10`.
- [ ] Run the model test and confirm RED.
- [ ] Add `completedPages` JSON serialization and legacy migration.
- [ ] Run the model tests and confirm GREEN.
- [ ] Write failing use-case tests for digital single-page recording, physical inclusive-range recording, paused rejection, page bounds, incomplete persistence, and exactly-once completion.
- [ ] Run the new use-case test and confirm RED.
- [ ] Implement `RecordKhatmahReadingUsecase` and result/source types with typed `KhatmahProgressException` errors.
- [ ] Make history insertion idempotent by plan id and return the persisted entry from repository completion.
- [ ] Run domain/data Khatmah tests and confirm GREEN.
- [ ] Commit with `fix(khatmah): enforce explicit page coverage`.

### Task 2: Single Reader-to-Completion Flow

**Files:**
- Modify: `lib/features/khatmah/presentation/cubits/khatmah_cubit.dart`
- Modify: `lib/features/quran/presentation/cubits/quran_page_cubit.dart`
- Modify: `lib/features/quran/presentation/pages/quran_reader_page.dart`
- Modify: `lib/features/khatmah/presentation/widgets/khatmah_reader_session_bar.dart`
- Modify: `lib/core/di/injection.dart`
- Modify: `lib/core/router/app_router.dart`
- Test: `test/features/khatmah/presentation/cubits/khatmah_cubit_test.dart`
- Test: `test/features/quran/presentation/cubits/quran_page_cubit_khatmah_test.dart`
- Test: `test/features/quran/presentation/pages/quran_reader_page_mode_test.dart`
- Test: `test/features/khatmah/integration/khatmah_e2e_flow_test.dart`

**Interfaces:**
- Consumes: `RecordKhatmahReadingUsecase` from Task 1.
- Produces: `KhatmahCubit.recordDigitalPage(int)` and `recordPhysicalThroughPage(int)`.
- Produces: `KhatmahPaused`, `KhatmahProgressFailure`, and `KhatmahCompleted` carrying the persisted history entry.
- Changes: `QuranPageCubit.confirmRead` returns `Future<bool>` and has no Khatmah dependencies.

- [ ] Write failing Cubit tests proving paused plans load as `KhatmahPaused`, digital page 604 alone does not complete, complete coverage archives and emits `KhatmahCompleted`, and storage errors emit a retryable failure.
- [ ] Run the Cubit test and confirm RED.
- [ ] Refactor `KhatmahCubit` to own the single reading command and completion states.
- [ ] Run the Cubit test and confirm GREEN.
- [ ] Write failing Quran cubit tests proving generic confirmation returns success/failure and never touches Khatmah storage.
- [ ] Run the Quran cubit test and confirm RED.
- [ ] Remove Khatmah use cases from `QuranPageCubit`, return confirmation success, and update DI.
- [ ] Run the Quran cubit tests and confirm GREEN.
- [ ] Write failing reader/widget tests proving confirmed pages call the Khatmah cubit, failures are shown, and a completed result navigates once with persisted completion data.
- [ ] Run the reader tests and confirm RED.
- [ ] Wire `QuranReaderPage` to `KhatmahCubit`, add completion/error listeners, and make the session bar show progress failure with retry.
- [ ] Replace the E2E 1-to-604 jump with explicit coverage behavior and verify completion cannot be fabricated.
- [ ] Run all Task 2 tests and confirm GREEN.
- [ ] Commit with `fix(khatmah): unify reader progress and completion`.

### Task 3: Account Safety, Paused Plans, and Replacement Guard

**Files:**
- Modify: `lib/core/identity/account_data_reset.dart`
- Modify: `lib/features/khatmah/domain/usecases/create_khatmah_usecase.dart`
- Modify: `lib/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart`
- Modify: `lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart`
- Modify: `lib/features/home/presentation/cubits/home_cubit.dart`
- Modify: `lib/features/khatmah/presentation/widgets/khatmah_hero_card.dart`
- Test: `test/core/identity/account_data_reset_test.dart`
- Test: `test/features/khatmah/domain/usecases/khatmah_usecases_test.dart`
- Test: `test/features/khatmah/presentation/cubits/khatmah_setup_cubit_test.dart`
- Test: `test/features/home/presentation/cubits/home_cubit_khatmah_test.dart`

**Interfaces:**
- Produces: `KhatmahPlanAlreadyExistsException` from `CreateKhatmahUsecase` when active or paused data exists.
- Consumes: the distinct paused state from Task 2.

- [ ] Write a failing account-reset test with all three Khatmah keys populated and assert they are removed while device settings remain.
- [ ] Run the account-reset test and confirm RED.
- [ ] Add `khatmah_active_plan`, `khatmah_history`, and the legacy `khatmah_cloud_dirty` key to account-owned reset inventory.
- [ ] Run the account-reset test and confirm GREEN.
- [ ] Write failing use-case/setup tests proving an existing active or paused plan cannot be overwritten.
- [ ] Run tests and confirm RED.
- [ ] Add the create guard and localized user-facing conflict state.
- [ ] Run tests and confirm GREEN.
- [ ] Write failing home/dashboard tests proving paused plans show Resume rather than opening the reader, and no-plan state exposes Start Khatmah.
- [ ] Implement the entry/resume UI and explicit abandon-before-replace behavior.
- [ ] Run Task 3 tests and confirm GREEN.
- [ ] Commit with `fix(khatmah): isolate account data and guard paused plans`.

### Task 4: Date-Aware Daily Scheduling and Accurate Metrics

**Files:**
- Modify: `lib/features/khatmah/domain/entities/khatmah_scheduling_engine.dart`
- Modify: `lib/features/khatmah/domain/entities/khatmah_plan.dart`
- Modify: `lib/features/khatmah/presentation/cubits/khatmah_cubit.dart`
- Modify: `lib/features/khatmah/presentation/pages/khatmah_completion_page.dart`
- Modify: `lib/features/khatmah/presentation/pages/khatmah_setup_page.dart`
- Test: `test/features/khatmah/domain/entities/khatmah_scheduling_engine_test.dart`
- Test: `test/features/khatmah/presentation/pages/khatmah_completion_page_test.dart`

**Interfaces:**
- Produces: inclusive `calculateEndDate`, stable daily target for a supplied local date, `actualElapsedDays(DateTime completedAt)`.

- [ ] Write failing scheduling tests proving a 1-day plan ends on its start date, a 31-day plan ends at start+30, and completing today’s target does not create another target on the same date.
- [ ] Run scheduling tests and confirm RED.
- [ ] Implement inclusive date calculation and date-aware target derivation using `lastReadDate` plus coverage.
- [ ] Run scheduling tests and confirm GREEN.
- [ ] Write failing completion-page tests proving actual elapsed days are displayed instead of `targetDays` and direct/null completion is rejected.
- [ ] Implement persisted completion input and accurate metrics.
- [ ] Run Task 4 tests and confirm GREEN.
- [ ] Commit with `fix(khatmah): make schedule and completion metrics accurate`.

### Task 5: Localization, Accessibility, and Governed Dua Copy

**Files:**
- Modify: `lib/core/l10n/app_ar.arb`
- Modify: `lib/core/l10n/app_en.arb`
- Modify: `lib/features/khatmah/presentation/pages/khatmah_setup_page.dart`
- Modify: `lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart`
- Modify: `lib/features/khatmah/presentation/pages/khatmah_completion_page.dart`
- Modify: `lib/features/khatmah/presentation/pages/khatm_dua_page.dart`
- Modify: `lib/features/khatmah/presentation/widgets/khatmah_hero_card.dart`
- Modify: `lib/features/khatmah/presentation/widgets/khatmah_progress_gauge.dart`
- Modify: `lib/features/khatmah/presentation/widgets/khatmah_dedication_form.dart`
- Modify: `assets/data/khatm_dua.json`
- Modify: `assets/data/content_manifest.json`
- Test: `test/features/khatmah/presentation/pages/khatm_dua_page_test.dart`
- Test: `test/features/khatmah/presentation/pages/khatmah_setup_page_test.dart`
- Test: `test/features/khatmah/presentation/pages/khatmah_completion_page_test.dart`
- Test: `test/features/home/presentation/widgets/khatmah_hero_card_test.dart`
- Test: `test/assets/corpus_integrity_test.dart`

**Interfaces:**
- Changes: dedication UI becomes optional neutral “pray for someone at completion” metadata; reward-transfer assertions are not emitted.
- Changes: Khatm Dua metadata declares a suggested general supplication and governed review fields.

- [ ] Write failing Arabic/English widget tests for every Khatmah entry surface, including the formerly English-only home text and Arabic-only completion heading.
- [ ] Add ARB keys, regenerate localization output using the project’s normal Flutter generation command, and replace hardcoded UI strings.
- [ ] Write failing large-text and semantics tests for progress gauge, physical range confirmation, and primary actions.
- [ ] Add semantic labels and flexible layouts; run widget tests and confirm GREEN.
- [ ] Write failing content-governance tests requiring Khatm Dua manifest membership and forbidding `مأثور`/reward-transfer claims in shipped Khatmah copy.
- [ ] Update the asset metadata and UI wording to “دعاء عام مقترح بعد الختم”; remove duplicated hand-written religious templates from completion UI.
- [ ] Run Task 5 tests and confirm GREEN.
- [ ] Commit with `fix(khatmah): localize and govern completion content`.

### Task 6: Final Regression and Release Gate

**Files:**
- Modify only files required by failures caused by Tasks 1-5.
- Test: all Khatmah, Quran reader, Home, identity, localization, content, and full-project suites.

- [ ] Run `dart format` on all changed Dart files.
- [ ] Run `dart analyze lib test` and require exit code 0.
- [ ] Run `flutter test test/features/khatmah test/features/quran/presentation/cubits/quran_page_cubit_khatmah_test.dart test/features/quran/presentation/pages/quran_reader_page_mode_test.dart test/features/home/presentation/cubits/home_cubit_khatmah_test.dart test/features/home/presentation/widgets/khatmah_hero_card_test.dart test/core/identity/account_data_reset_test.dart test/assets/corpus_integrity_test.dart` and require zero failures.
- [ ] Run `flutter test`; record any unrelated pre-existing failure separately and fix every failure caused by this plan.
- [ ] Review `git diff --check`, `git status --short`, and the complete branch diff.
- [ ] Commit verified cleanup with `test(khatmah): close remediation release gates` only if cleanup changes are required.

