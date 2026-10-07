---
generated_from_commit: d37da52d72f721adee09b5b9526dff03ad576b58
last_verified: 2026-10-06
confidence: medium
---

# Repository Map

Scope: inspected source paths/configuration in a changing working tree; unrelated audit artifacts were already modified and concurrent notification/startup/audio/localization/native edits appeared later. HEAD alone is not a complete source snapshot. This map establishes ownership/navigation, not feature correctness or deployed backend state. Recheck the relevant diff when HEAD or these paths change.

| Path | Responsibility | Related evidence |
|---|---|---|
| `lib/main.dart`, `lib/app.dart` | Entrypoint, splash/full-app readiness, providers and lifecycle | `test/features/splash`, `test/widget_test.dart` |
| `lib/core/services/app_initializer.dart` | Supabase/config, DI, local migration, settings and deferred startup | `test/core/services/hifz_migration_service_test.dart` |
| `lib/core/di/injection.dart` | Manual GetIt registration | Inspect registration lifetime and caller ownership for each task |
| `lib/core/router/app_router.dart` | GoRouter route table, guards and adult/child launch inputs | `test/core/router` |
| `lib/core/storage/app_isar.dart`, `lib/core/identity/` | Complete default Isar schema and current record owner | `test/core/identity`, `test/integration/account_switch_isolation_test.dart` |
| `lib/core/memorization/`, `lib/core/progress/`, `lib/core/journey/` | Review identity/read models, V2 engine/committers/outbox, refresh and journey policy | `test/core/memorization`, `test/core/progress`, `test/core/journey` |
| `lib/core/sync/`, `lib/features/auth/application/` | Durable queue, scheduling and foreground cloud coordination | `test/core/sync`, `test/features/auth/cloud_sync_coordinator_test.dart` |
| `lib/core/services/` | Quran audio/cache/bookmarks, notifications, startup and shared services | `test/core/services` |
| `lib/core/prayer_delivery/` | Prayer event construction and Android delivery abstraction | `test/core/prayer_delivery` |
| `lib/core/theme/`, `lib/core/widgets/`, `lib/core/l10n/` | Design tokens, shared UI, localized Arabic/English | `test/core/theme`, `test/core/widgets`, `test/core/l10n`, `test/design_system` |
| `lib/core/content/`, `assets/data/` | Governed content and bundled Quran/azkar/dua data | `test/core/content`, `test/assets`, source policy in `docs/` |
| `lib/features/` | Feature UI/domain/data owners; see registry | `test/features` |
| `supabase/migrations/`, `supabase/tests/` | Repository backend history and SQL contracts | `test/supabase`; deployment is unverified |
| `scripts/verify_v1_release.ps1` | Release evidence runner | `test/scripts/v1_release_verification_contract_test.dart` |
| `scripts/verify_supabase_contract.ps1`, `scripts/verify_supabase_migrations.ps1` | SQL validation, migration execution on explicit disposable targets | `test/scripts/verify_supabase_contract_security_test.ps1` |

See [Project Playbook](../references/project-playbook.md) for invariants and symptom traces. Existing audit reports under `audit_artifacts/` are historical evidence tied to their revision, never blanket proof of current readiness.
