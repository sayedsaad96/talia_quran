# Dot-sourced by verify_supabase_contract.ps1. Catalog SELECTs only; no deployment.
# Check and the connection are supplied by the parent verifier.
$groupKhatmahRpcs = @(
  'public.create_group_khatmah(text,text,uuid)',
  'public.join_group_khatmah(text,text,uuid)',
  'public.claim_group_part(uuid,smallint,bigint,uuid,uuid)',
  'public.complete_group_part(uuid,smallint,bigint,uuid,uuid)',
  'public.release_group_part(uuid,smallint,bigint,uuid,uuid)',
  'public.leave_group_khatmah(uuid,uuid,uuid)',
  'public.request_group_khatmah_eligibility()'
)
foreach ($signature in $groupKhatmahRpcs) {
  Check "group khatmah RPC shape $signature" "SELECT NOT prosecdef AND pg_get_function_result(oid)='jsonb' AND proconfig=ARRAY['search_path=' || chr(34) || chr(34)]::text[] FROM pg_proc WHERE oid='$signature'::regprocedure"
  Check "group khatmah RPC ACL $signature" "SELECT has_function_privilege('authenticated','$signature','EXECUTE') AND NOT has_function_privilege('anon','$signature','EXECUTE') AND NOT has_function_privilege('service_role','$signature','EXECUTE') AND NOT EXISTS (SELECT 1 FROM pg_proc p, LATERAL aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) a WHERE p.oid='$signature'::regprocedure AND a.grantee=0 AND a.privilege_type='EXECUTE')"
}

foreach ($table in @('group_khatmah', 'group_khatmah_member', 'group_khatmah_part')) {
  Check "group khatmah RLS $table" "SELECT relrowsecurity FROM pg_class WHERE oid='public.$table'::regclass"
  Check "group khatmah table ACL $table" "SELECT has_any_column_privilege('authenticated','public.$table','SELECT') AND NOT has_table_privilege('authenticated','public.$table','INSERT,UPDATE,DELETE,TRUNCATE') AND NOT has_table_privilege('anon','public.$table','SELECT,INSERT,UPDATE,DELETE,TRUNCATE') AND NOT has_table_privilege('service_role','public.$table','SELECT,INSERT,UPDATE,DELETE,TRUNCATE')"
  Check "group khatmah SELECT policy $table" "SELECT count(*)=1 AND bool_and(cmd='SELECT' AND qual LIKE '%group_khatmah_can_read%') FROM pg_policies WHERE schemaname='public' AND tablename='$table'"
}

foreach ($table in @('group_khatmah_eligibility', 'group_khatmah_join_throttle', 'group_khatmah_receipt')) {
  Check "group khatmah private RLS $table" "SELECT relrowsecurity FROM pg_class WHERE oid='private.$table'::regclass"
  Check "group khatmah private ACL $table" "SELECT NOT has_table_privilege('authenticated','private.$table','SELECT,INSERT,UPDATE,DELETE,TRUNCATE') AND NOT has_table_privilege('anon','private.$table','SELECT,INSERT,UPDATE,DELETE,TRUNCATE') AND NOT has_table_privilege('service_role','private.$table','SELECT,INSERT,UPDATE,DELETE,TRUNCATE')"
}

Check 'group khatmah definer boundaries' "SELECT count(*)>=6 AND bool_and(p.proconfig=ARRAY['search_path=' || chr(34) || chr(34)]::text[] AND NOT has_function_privilege('anon',p.oid,'EXECUTE') AND NOT has_function_privilege('service_role',p.oid,'EXECUTE') AND NOT EXISTS (SELECT 1 FROM aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) a WHERE a.grantee=0 AND a.privilege_type='EXECUTE')) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='private' AND p.proname LIKE 'group_khatmah_%'"
Check 'group khatmah cleanup restricted' "SELECT NOT has_function_privilege('authenticated','private.group_khatmah_cleanup_user(uuid)','EXECUTE') AND NOT has_function_privilege('anon','private.group_khatmah_cleanup_user(uuid)','EXECUTE')"
Check 'group khatmah privileged implementations' "SELECT count(*)>=6 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='private' AND p.proname LIKE 'group_khatmah_%' AND p.prosecdef"
Check 'group khatmah controlled definer owner' "SELECT count(*)>=6 AND bool_and(NOT pg_has_role('authenticated',p.proowner,'MEMBER') AND NOT pg_has_role('anon',p.proowner,'MEMBER') AND (r.rolsuper OR r.rolbypassrls OR NOT EXISTS (SELECT 1 FROM pg_class c WHERE c.oid IN ('public.group_khatmah'::regclass,'public.group_khatmah_member'::regclass,'public.group_khatmah_part'::regclass) AND (c.relowner<>p.proowner OR c.relforcerowsecurity)))) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_roles r ON r.oid=p.proowner WHERE n.nspname='private' AND p.proname LIKE 'group_khatmah_%' AND p.prosecdef"
Check 'group khatmah membership FK restricts bypass' "SELECT count(*)=1 AND bool_and(confdeltype='r' AND NOT condeferrable) FROM pg_constraint WHERE contype='f' AND conrelid='public.group_khatmah_member'::regclass AND confrelid='auth.users'::regclass"
Check 'group khatmah owner FK restricts bypass' "SELECT count(*)=1 AND bool_and(confdeltype='r' AND NOT condeferrable) FROM pg_constraint WHERE contype='f' AND conrelid='public.group_khatmah'::regclass AND confrelid='auth.users'::regclass"
Check 'group khatmah deletion hook preserves session authority' "SELECT pg_get_functiondef(oid) LIKE '%group_khatmah_cleanup_user%' AND pg_get_functiondef(oid) LIKE '%session_id%' AND pg_get_functiondef(oid) LIKE '%auth.sessions%' FROM pg_proc WHERE oid='public.delete_current_user()'::regprocedure"
