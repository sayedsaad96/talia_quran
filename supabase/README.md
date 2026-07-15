# Supabase schema

## New project

1. Run `supabase_schema.sql` in the Supabase SQL Editor (full baseline).
2. Run migrations in order (only if not already included in baseline):
   - `migrations/0002_audit_patches.sql`
   - `migrations/0003_delete_current_user.sql`

## Existing project (production/staging)

Apply **incremental** migrations only:

| Order | File | Purpose |
|-------|------|---------|
| 1 | `migrations/0002_audit_patches.sql` | Parent dashboard RPC, kids batch insert, indexes, legacy table hardening |
| 2 | `migrations/0003_delete_current_user.sql` | In-app account deletion |

Do **not** re-run the full `supabase_schema.sql` on a live database.

## Canonical source

`supabase_schema.sql` at the repo root remains the single-file reference for the complete schema. Numbered migrations capture **delta** changes after initial deploy.
