# Supabase

Inspect the real schema, migrations, **RLS** policies, functions/RPCs, storage, auth flows, and Flutter client usage before changing backend behavior.

- Use least privilege; never place a **service-role** secret in Flutter.
- Test both **allowed** and **denied** RLS paths, including owner/non-owner and auth states relevant to the feature.
- Preserve old/new client coexistence when rollout order matters.
- Protect user progress/history during backfills and migrations.

## Migration Risk

- `M0`: additive, backward-compatible.
- `M1`: compatible contract evolution.
- `M2`: data transformation/backfill or behavior migration.
- `M3`: destructive/breaking/irreversible production change.

`M3` stops before execution until environment, blast radius, recovery/backup, rollout order, and **rollback** strategy are explicit and approved.

## Talia boundaries

Consult [Supabase Map](../knowledge/supabase-map.md) and [Project Playbook](../references/project-playbook.md). Read current client collaborators and migration SQL; infer neither deployed schema nor authorization from migration filenames. Keep account + audience + child ownership stable through local durable writes, pending queue, upload, acknowledgement, pull cursor, merge and UI refresh.

Existing SQL verification scripts execute database statements and may apply migrations. Use only an explicit disposable target after inspecting parameters and SQL; never point `-FreshDatabase` at production. Source-contract tests in `test/supabase` are not live RLS tests. Record deployed checks as unverified if no appropriate target is available. Use the available Supabase skill for actual backend changes; that does not grant deployment authorization.
