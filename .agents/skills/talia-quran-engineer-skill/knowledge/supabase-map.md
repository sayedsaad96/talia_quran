---
generated_from_commit: d37da52d72f721adee09b5b9526dff03ad576b58
last_verified: 2026-10-06
confidence: medium
---

# Supabase Map

Scope: repository backend entry points and migration/test locations. Live project/schema, applied migration history, RLS permissions and RPC availability are unverified. Do not read or print `.env`/credential files to populate this map.

| Area | Client/source evidence | Contract evidence to inspect |
|---|---|---|
| Optional configured initialization | `lib/core/config/supabase_config.dart`, `lib/core/services/app_initializer.dart` | `test/core/config/supabase_config_test.dart`; preserve local/offline startup |
| Account/session/foreground sync | `lib/features/auth/`, `lib/core/identity/`, `lib/core/sync/` | `test/features/auth`, `test/integration`, `test/core/sync` |
| Review identity/evidence/acknowledgement | `lib/core/memorization/review_record_identity.dart`, `lib/features/memorization_plus/data/` | `test/core/memorization/review_record_cloud_sync_contract_test.dart`, `test/supabase/review_events_contract_test.dart` |
| Family/guardian identity, policies, missions and rewards | `lib/features/memorization_plus/` data/application owners | `test/supabase/guardian_child_identity_contract_test.dart`, `kids_home_missions_and_policies_contract_test.dart`, `parent_reward_request_approval_contract_test.dart`, `guardian_unlink_contract_test.dart` |
| Account deletion and session checks | Current auth callers and repository migration history | `test/supabase/delete_current_user_session_contract_test.dart` |
| Deployment/migration execution | `supabase/migrations/`, `supabase/tests/`, `scripts/verify_supabase_contract.ps1`, `scripts/verify_supabase_migrations.ps1` | `test/supabase/migration_history_test.dart`, `docs/backend/supabase_runtime_readiness_checklist.md` |

Migration filenames include numbered history and timestamped evolution; verify ordering through existing tooling before adding a migration. Do not rewrite applied migrations to change live behavior. Trace exact table/RPC names from current client and SQL for the task, then verify allowed/denied owner, non-owner and guardian/child cases on a disposable target. SQL-text assertions alone do not prove live access control.
