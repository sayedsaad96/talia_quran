# Supabase migrations

The checked-in `migrations/` directory is the complete database source of
truth. Apply every file in lexical order to a fresh Supabase database; do not
depend on a root schema dump or a deployed database.

For a real reconstruction and contract check, run:

```powershell
$env:TALIA_SUPABASE_FRESH_DB_URL = '<empty local/staging Supabase database URL>'
./scripts/verify_supabase_migrations.ps1
```

For an already migrated target, run `verify_supabase_contract.ps1` with
`SUPABASE_DB_URL`. Both scripts fail non-zero for incompatible tables, columns,
RLS, grants, policies, or critical RPC signatures.
