# Talia project playbook

Repository-relative paths below were inspected on 2026-10-06 with HEAD at `d37da52d72f721adee09b5b9526dff03ad576b58`. Concurrent working-tree edits appeared in notification/startup/audio/localization/native delivery files during the refresh; HEAD does not fully identify that source snapshot. This is a navigation and engineering baseline, not runtime or release certification. Recheck affected code and the working diff before relying on it.

## Architecture and local conventions

- Feature-first Clean Architecture, Cubit state, repositories/use cases, manual GetIt wiring in `lib/core/di/injection.dart`; route ownership is in `lib/core/router/app_router.dart`. Add registrations/providers/routes consistently with nearby working flows; do not introduce BLoC events or another state framework for ordinary work.
- `lib/main.dart` starts the app; `lib/app.dart` initially uses the splash router. Heavy initialization belongs in `lib/core/services/app_initializer.dart`, reached through splash. Preserve the initialization barrier before accessing Isar, registered services, or the full router; inspect asynchronous warmups separately from readiness.
- Existing cross-feature services and some oversized files are implementation reality, not permission to grow them. Apply `.codex/AGENTS.md` limits (widget 300 lines, method 50, file 500) to new work; split only the part needed by the task. Do not clean up unrelated legacy files.
- Arabic-first Material 3 uses `lib/core/theme/talia_tokens.dart`, `app_theme.dart`, `app_colors.dart`, and `app_typography.dart`. Reuse tokens and shared widgets. Check Arabic RTL/English LTR, narrow screens, enlarged text, light/dark/OLED where applicable, focus/semantics, back and error states.
- UI strings belong in `lib/core/l10n/app_ar.arb` and `app_en.arb` through `AppLocalizations`. `l10n.yaml` sets Arabic as the template; use `flutter gen-l10n`, never hand-edit generated localization output. Number/time helpers live in `lib/core/utils/` and `lib/core/l10n/`.

## Critical invariants

| Boundary | Existing owner and required check |
|---|---|
| Default local database | `lib/core/storage/app_isar.dart`: every isolate opening the default database must use the complete `appIsarSchemas`/`openAppIsar` contract. Opening with a subset can remove user collections. Preserve names/IDs and verify upgrades on existing state. |
| Account and audience | `lib/core/identity/record_owner_provider.dart`, `lib/core/memorization/review_record_identity.dart`, `review_record_audience_scope.dart`: preserve account + adult/child scope and child identity in reads, keys, writes, cache, queue and merge. UI selection alone is not authorization. |
| Durable review outcome | `lib/core/memorization/v2/review_outcome_committer.dart`: adult evidence/projection/checkpoint/outbox share an Isar transaction. `kids_review_outcome_committer.dart` writes evidence/projection/checkpoint without adult outbox rows; child rewards/plan effects belong to `awardKidsPoints` in `lib/features/memorization_plus/data/repositories/collaborators/memorization_kids_local_service.dart`. Preserve each path's stable logical session/task/event identity on retry; never replace either durability boundary with UI flags or inline Cubit effects. |
| Progress read side | `lib/core/memorization/memorization_progress_reader.dart`, `lib/core/progress/progress_events_bus.dart`: trace persisted evidence/projections and refresh signals before changing badges or totals in presentation. Do not restore retired `hifz` write paths. |
| Quran display and search | `assets/data/quran.json`, `surahs.json`, `lib/features/quran/data/datasources/quran_local_datasource.dart`: preserve exact display text and mappings. Normalization is for a derived search/evaluation representation, never the source/display corpus. QCF has a separate font/page rendering contract. |
| Audio lifecycle | `lib/core/services/audio_lifecycle_manager.dart` can exempt registered players via `shouldPause`; inspect `quran_continuous_player_service.dart`, `quran_background_audio_handler.dart`, `audio_resume_store.dart` and `QuranAudioPlayerCubit` before changing pause/resume policy. Preserve background Quran policy without extending it to practice or azkar players accidentally. |
| Cloud ownership and acknowledgement | `lib/features/auth/application/cloud_sync_coordinator.dart`, `lib/core/sync/cloud_sync_queue.dart`, `lib/features/memorization_plus/data/repositories/collaborators/memorization_kids_cloud_sync_service.dart`: inspect owner changes, offline retries, merge and acknowledgement before altering sync. A local SQL contract test does not prove deployed RLS/RPC behavior. |
| Religious output | `docs/TALIA_ISLAMIC_CONTENT_SOURCES_POLICY.md`, `assets/data/content_manifest.json`, `lib/core/content/approved_azkar_content.dart`: trace approval/provenance to every affected surface, including share/notification/offline. Never label an import as scholarly approval. |
| Prayer and reminders | `lib/core/prayer_delivery/`, `lib/core/services/notification_scheduler.dart`, `lib/features/prayer_companion/`: verify timezone/day boundaries, quiet hours, permission-denied state, duplicate scheduling and process/lifecycle behavior. Calculation is separate from successful device delivery. |

Android prayer delivery crosses a Dart MethodChannel in `lib/core/prayer_delivery/android_prayer_delivery_scheduler.dart`; inspect the current native channel/receiver/service wiring and manifest/build configuration when changing its contract. Host mocks prove Dart response handling, not native alarm/service execution. Keep both sides of channel methods/payloads compatible and validate actual permission-denied and fallback behavior on Android.

## Diagnose by symptom

Gather build/device, account/audience, session state, locale, network, exact reproduction and relevant error first. Use privacy-safe IDs; never dump tokens, credentials or family data.

| Symptom | Trace and focused existing evidence |
|---|---|
| Lost/duplicated review, reward or resumed task | Session engine → audience-specific committer → Isar checkpoint/evidence → adult effect outbox OR child `awardKidsPoints`/session log → read model/cloud reconciliation. Tests: `test/core/memorization/v2`, `test/features/memorization_plus/data/kids_award_points_test.dart`, `test/integration/progress_snapshot_consistency_test.dart`. |
| Another child's/account's progress or stale dashboard | Owner/audience identity → local keys/read scope → queue/cloud merge → auth refresh/UI. Tests: `test/core/memorization/audience_isolation_test.dart`, `test/integration/account_switch_isolation_test.dart`, `test/core/sync/cloud_sync_queue_owner_test.dart`. |
| Wrong ayah, bookmark, highlight or basmalah | Canonical corpus/global index → surah/page/QCF boundary → stored location or audio queue → exact display. Tests: `test/assets/corpus_integrity_test.dart`, `test/features/quran/quran_reader_sacred_text_test.dart`, `test/core/utils/quran_ayah_display_text_test.dart`, `test/core/widgets/social_share_quran_exactness_test.dart`. Do not run corpus rewriting scripts to hide a mismatch. |
| Navigation stuck or opens wrong session | Initialization/auth readiness → route redirect/guard → launch arguments → adult/child navigation context. Tests: `test/core/router`, `test/features/memorization_plus/presentation/navigation`. |
| Audio continues/stops incorrectly | Player ownership → lifecycle registration/exemption → background handler → subscription close/dispose → persisted resume. Tests: `test/core/architecture/background_audio_scope_test.dart`, `test/core/services/audio_lifecycle_manager_test.dart`, `test/features/quran/quran_audio_player_cubit_test.dart`; validate lock/background on device. |
| Offline update never reaches cloud | Local durable write → dirty/outbox/queue → signed-in owner readiness → RPC contract → acknowledgement/cursor → merge/refresh. Tests: `test/integration/offline_plan_sync_gate_test.dart`, `test/core/sync`, `test/supabase`. |
| Incorrect khatmah total, completion or certificate | Reader confirmation gate → khatmah recording use case/repository → retained dashboard → completion/award. Tests: `test/features/khatmah`, `test/features/quran/quran_read_confirmation_gate_test.dart`. |
| Notification missing or duplicated | Preferences/permission → timezone/context → scheduler/planner → Android delivery → payload guard. Tests: `test/core/prayer_delivery`, `test/core/services/notification_scheduler_prayer_delivery_test.dart`, `test/core/router/notification_payload_route_guard_test.dart`; SQL/widget tests cannot prove OS delivery. |

## Verification commands and boundaries

Run from the repository root. Capture command, exit code, and relevant output; do not report success from the last command alone. Commands below are choices, not a mandatory full suite for every edit.

- Changed Dart: `dart format --output=none --set-exit-if-changed <changed-files>` and `flutter analyze <affected-paths>`; use project-wide `flutter analyze` for wider changes.
- New feature: unit and widget tests per project instructions; critical flows also need integration coverage. Bug fix: regression at the failing boundary, then relevant neighboring tests. `flutter test <existing-test-path>` runs targeted coverage; `flutter test` runs the full suite when warranted.
- Islamic data/rendering: choose relevant tests in `test/assets`, `test/core/content`, `test/core/utils`, reader and share tests. Passing local consistency tests does not establish authoritative provenance, license or scholarly approval.
- `test/integration/` and feature integration folders exist; the baseline has no root `integration_test/`. Never present host integration tests as Android end-to-end proof. Record real device/emulator, build revision and executed scenarios separately.
- `scripts/verify_v1_release.ps1` writes evidence and orchestrates broader gates; inspect it before use. `-BuildAndroidRelease` opts into its Android build. It is not a substitute for flow coverage or an automatically invoked step during an ordinary fix.
- `scripts/verify_supabase_contract.ps1` needs `psql` and a known disposable database. It executes SQL; `-FreshDatabase` applies migrations. `scripts/verify_supabase_migrations.ps1` uses `TALIA_SUPABASE_FRESH_DB_URL` for an empty local/staging Supabase database with the auth schema. Never run either against an inferred/unknown or production target. Supply credentials through the environment without printing them.
- Regenerate `.g.dart` only when model changes require it and after inspecting generator constraints; scope the generated diff. Do not hand-edit generated Isar/Mockito files or silently change collection IDs.
- Tool unavailable, permissions/network blocked, native library absent, timeout, failure or source drift: record the limitation and keep the corresponding verification unverified. Use an evidenced installed SDK path if normal wrappers fail; never fabricate an equivalent result or install tools outside scope.

## Maintain the reference

Refresh only affected `knowledge/` entries after verified changes. Include repository revision, verification date, source paths, whether a dirty working tree was inspected, and uncertainty. Separate policy, observed code, intended future product, and measured runtime behavior. Do not import old audit findings as current defects without rechecking their source revision and reproduction.
