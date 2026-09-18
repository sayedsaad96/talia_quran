# Supabase Migration Workflow

1. Confirm environment: local/dev/staging/production.
2. Inspect current schema, migrations, Flutter client contract, auth, storage/functions, and **RLS**.
3. Classify migration as `M0`, `M1`, `M2`, or `M3`.
4. Define data preservation, old/new client **compatibility**, blast radius, and rollout order.
5. For `M2`, test transformation/backfill on representative data before production execution.
6. For `M3`, **stop for explicit approval before destructive execution**; document backup/recovery and **rollback** first.
7. Apply the migration in the controlled environment.
8. Validate both allowed and denied RLS/authorization paths.
9. Verify rollout compatibility, recovery path, and application behavior/runtime.
10. Update the verified Supabase map and risk register.
