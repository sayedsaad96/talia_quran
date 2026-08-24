param(
  [string] $DatabaseUrl = $env:SUPABASE_DB_URL,
  [switch] $FreshDatabase
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) { throw 'SUPABASE_DB_URL (or -DatabaseUrl) is required.' }
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) { throw 'psql is required. Install PostgreSQL client tools or run this in the Supabase CLI container.' }

$root = Join-Path $PSScriptRoot '..'
$migrations = Get-ChildItem (Join-Path $root 'supabase\migrations') -Filter '*.sql' -File | Sort-Object Name
if ($migrations.Count -eq 0) { throw 'No migrations found.' }
if ($FreshDatabase) {
  foreach ($migration in $migrations) {
    & psql "--dbname=$DatabaseUrl" --set ON_ERROR_STOP=1 --file $migration.FullName | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Migration failed: $($migration.Name)" }
  }
  Write-Host "PASS: fresh database applied $($migrations.Count) migrations"
}

$anyFailed = $false
function Check([string] $label, [string] $query) {
  $value = (& psql "--dbname=$DatabaseUrl" --tuples-only --no-align --quiet --command $query).Trim()
  if ($LASTEXITCODE -ne 0 -or $value -ne 't') { Write-Host "FAIL: $label"; $script:anyFailed = $true } else { Write-Host "PASS: $label" }
}

@('profiles','parent_child_links','kids_progress_cloud','kids_session_logs','parent_rewards','streaks','xp','daily_activities','ayah_review_records_cloud','daily_plans_cloud','custom_plans_cloud','certificate_awards_cloud','reading_progress_cloud','quran_bookmarks_cloud') | ForEach-Object {
  Check "table public.$_" "SELECT to_regclass('public.$_') IS NOT NULL"
  Check "RLS public.$_" "SELECT relrowsecurity FROM pg_class WHERE oid='public.$_'::regclass"
}
@{
  'daily_plans_cloud.revision' = "SELECT atttypid::regtype::text='bigint' FROM pg_attribute WHERE attrelid='public.daily_plans_cloud'::regclass AND attname='revision' AND NOT attisdropped"
  'custom_plans_cloud.revision' = "SELECT atttypid::regtype::text='bigint' FROM pg_attribute WHERE attrelid='public.custom_plans_cloud'::regclass AND attname='revision' AND NOT attisdropped"
  'quran_bookmarks_cloud.revision' = "SELECT atttypid::regtype::text='bigint' FROM pg_attribute WHERE attrelid='public.quran_bookmarks_cloud'::regclass AND attname='revision' AND NOT attisdropped"
  'quran_bookmarks_cloud.is_deleted' = "SELECT atttypid::regtype::text='boolean' FROM pg_attribute WHERE attrelid='public.quran_bookmarks_cloud'::regclass AND attname='is_deleted' AND NOT attisdropped"
}.GetEnumerator() | ForEach-Object { Check "column $($_.Key)" $_.Value }

@{
  'delete_current_user' = "SELECT pg_get_function_result('public.delete_current_user()'::regprocedure)='void' AND has_function_privilege('authenticated','public.delete_current_user()','EXECUTE')"
  'pull_quran_bookmarks' = "SELECT pg_get_function_result('public.pull_quran_bookmarks()'::regprocedure)='SETOF public.quran_bookmarks_cloud' AND has_function_privilege('authenticated','public.pull_quran_bookmarks()','EXECUTE')"
  'upsert_quran_bookmark' = "SELECT pg_get_function_result('public.upsert_quran_bookmark(integer,integer,jsonb,bigint,boolean)'::regprocedure) LIKE 'TABLE(surah_id integer, ayah_number integer, revision bigint)' AND has_function_privilege('authenticated','public.upsert_quran_bookmark(integer,integer,jsonb,bigint,boolean)','EXECUTE')"
  'compare_and_swap_daily_plan' = "SELECT pg_get_function_result('public.compare_and_swap_daily_plan(bigint,integer,timestamp with time zone,integer,integer,jsonb)'::regprocedure)='jsonb' AND has_function_privilege('authenticated','public.compare_and_swap_daily_plan(bigint,integer,timestamp with time zone,integer,integer,jsonb)','EXECUTE')"
  'compare_and_swap_custom_plan' = "SELECT pg_get_function_result('public.compare_and_swap_custom_plan(bigint,jsonb,boolean)'::regprocedure)='jsonb' AND has_function_privilege('authenticated','public.compare_and_swap_custom_plan(bigint,jsonb,boolean)','EXECUTE')"
  'create_parent_reward' = "SELECT pg_get_function_result('public.create_parent_reward(uuid,text)'::regprocedure)='SETOF public.parent_rewards' AND has_function_privilege('authenticated','public.create_parent_reward(uuid,text)','EXECUTE')"
  'unlock_parent_reward' = "SELECT pg_get_function_result('public.unlock_parent_reward(bigint)'::regprocedure)='SETOF public.parent_rewards' AND has_function_privilege('authenticated','public.unlock_parent_reward(bigint)','EXECUTE')"
  'claim_parent_reward' = "SELECT pg_get_function_result('public.claim_parent_reward(bigint)'::regprocedure)='SETOF public.parent_rewards' AND has_function_privilege('authenticated','public.claim_parent_reward(bigint)','EXECUTE')"
  'insert_kids_session_logs_batch' = "SELECT pg_get_function_result('public.insert_kids_session_logs_batch(jsonb)'::regprocedure) LIKE 'TABLE(local_id text, surah_id integer, ayah_number integer)' AND has_function_privilege('authenticated','public.insert_kids_session_logs_batch(jsonb)','EXECUTE')"
  'revoke_guardian_link' = "SELECT pg_get_function_result('public.revoke_guardian_link(uuid)'::regprocedure)='void' AND has_function_privilege('authenticated','public.revoke_guardian_link(uuid)','EXECUTE')"
}.GetEnumerator() | ForEach-Object { Check "RPC $($_.Key)" $_.Value }

Check 'prune_audit_logs denied to authenticated' "SELECT NOT has_function_privilege('authenticated','public.prune_audit_logs()','EXECUTE')"

Check 'parent_rewards direct DML revoked' "SELECT NOT has_table_privilege('authenticated','public.parent_rewards','INSERT,UPDATE,DELETE')"
Check 'daily plans direct DML revoked' "SELECT NOT has_table_privilege('authenticated','public.daily_plans_cloud','INSERT,UPDATE,DELETE')"
Check 'custom plans direct DML revoked' "SELECT NOT has_table_privilege('authenticated','public.custom_plans_cloud','INSERT,UPDATE,DELETE')"
Check 'bookmark direct DML revoked' "SELECT NOT has_table_privilege('authenticated','public.quran_bookmarks_cloud','INSERT,UPDATE,DELETE')"
Check 'parent rewards child read policy' "SELECT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='parent_rewards' AND policyname='parent_rewards_child_read')"
Check 'bookmark owner read policy' "SELECT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='quran_bookmarks_cloud' AND policyname='quran_bookmarks_cloud_owner_read')"
if ($anyFailed) { exit 1 }
Write-Host 'PASS: Supabase contract verified'
