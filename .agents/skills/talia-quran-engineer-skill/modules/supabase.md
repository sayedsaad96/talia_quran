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
