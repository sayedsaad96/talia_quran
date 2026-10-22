# Dot-sourced by verify_supabase_contract.ps1 after it configures psql and Check.
# All statements here are read-only catalog checks on the explicitly supplied DB.
$phase2Rpcs = @(
  @{
    Signature = 'public.compare_and_swap_child_policy_v2(uuid,bigint,boolean,integer,boolean,integer,integer,integer,integer)'
    Arguments = 'p_child_user_id uuid, p_expected_version bigint, p_reduce_motion boolean, p_max_daily_suggestions integer, p_home_missions_enabled boolean, p_session_goal_minutes integer, p_next_surah_id integer, p_ayahs_per_session integer, p_practice_days integer'
    Result = 'jsonb'
  },
  @{
    Signature = 'public.create_parent_reward_v2(uuid,text,integer)'
    Arguments = 'p_child_user_id uuid, p_title text, p_milestone_surah_id integer'
    Result = 'SETOF parent_rewards'
  },
  @{
    Signature = 'public.unlock_parent_reward_by_milestone(bigint)'
    Arguments = 'p_reward_id bigint'
    Result = 'SETOF parent_rewards'
  },
  @{
    Signature = 'public.send_kids_encouragement(uuid,text,text,uuid)'
    Arguments = 'p_child_user_id uuid, p_message_key text, p_sticker_key text, p_client_request_id uuid'
    Result = 'SETOF kids_encouragements'
  },
  @{
    Signature = 'public.mark_kids_encouragements_seen(bigint[])'
    Arguments = 'p_ids bigint[]'
    Result = 'integer'
  }
)
foreach ($rpc in $phase2Rpcs) {
  $signature = $rpc.Signature
  Check "phase2 RPC contract $signature" "SELECT pg_get_function_arguments('$signature'::regprocedure)='$($rpc.Arguments)' AND pg_get_function_result('$signature'::regprocedure)='$($rpc.Result)'"
  Check "phase2 RPC ACL $signature" "SELECT has_function_privilege('authenticated','$signature','EXECUTE') AND NOT has_function_privilege('anon','$signature','EXECUTE') AND NOT has_function_privilege('service_role','$signature','EXECUTE') AND NOT EXISTS (SELECT 1 FROM pg_proc p, LATERAL aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) a WHERE p.oid='$signature'::regprocedure AND a.grantee=0 AND a.privilege_type='EXECUTE')"
  Check "phase2 RPC security $signature" "SELECT prosecdef AND proconfig=ARRAY['search_path=' || chr(34) || chr(34)]::text[] FROM pg_proc WHERE oid='$signature'::regprocedure"
}
foreach ($table in @('kids_encouragements', 'kids_encouragement_quotas')) {
  Check "phase2 table RLS $table" "SELECT relrowsecurity FROM pg_class WHERE oid='public.$table'::regclass"
  Check "phase2 table writes revoked $table" "SELECT NOT has_table_privilege('authenticated','public.$table','INSERT,UPDATE,DELETE') AND NOT has_table_privilege('anon','public.$table','SELECT,INSERT,UPDATE,DELETE')"
}
Check 'phase2 quota private' "SELECT NOT has_table_privilege('authenticated','public.kids_encouragement_quotas','SELECT') AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='kids_encouragement_quotas')"
Check 'phase2 encouragements SELECT only' "SELECT has_table_privilege('authenticated','public.kids_encouragements','SELECT') AND (SELECT count(*)=1 AND bool_and(cmd='SELECT' AND policyname='kids_encouragements_read' AND qual LIKE '%auth.uid()%parent_child_links%') FROM pg_policies WHERE schemaname='public' AND tablename='kids_encouragements')"
Check 'phase2 encouragement sequence private' "SELECT NOT has_sequence_privilege('authenticated','public.kids_encouragements_id_seq','USAGE,SELECT,UPDATE') AND NOT has_sequence_privilege('anon','public.kids_encouragements_id_seq','USAGE,SELECT,UPDATE')"
foreach ($column in @('next_surah_id', 'ayahs_per_session', 'practice_days')) {
  Check "phase2 nullable policy smallint $column" "SELECT atttypid::regtype::text='smallint' AND NOT attnotnull FROM pg_attribute WHERE attrelid='public.kids_child_policies'::regclass AND attname='$column' AND NOT attisdropped"
  Check "phase2 policy bound $column" "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.kids_child_policies'::regclass AND contype='c' AND pg_get_constraintdef(oid) LIKE '%$column%')"
}
Check 'phase2 nullable reward milestone' "SELECT atttypid::regtype::text='smallint' AND NOT attnotnull FROM pg_attribute WHERE attrelid='public.parent_rewards'::regclass AND attname='milestone_surah_id' AND NOT attisdropped"
Check 'phase2 reward milestone bound' "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.parent_rewards'::regclass AND contype='c' AND pg_get_constraintdef(oid) LIKE '%milestone_surah_id%')"
Check 'phase2 encouragement retry uniqueness' "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.kids_encouragements'::regclass AND contype='u' AND pg_get_constraintdef(oid)='UNIQUE (parent_user_id, client_request_id)')"
Check 'phase2 child global quota key' "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.kids_encouragement_quotas'::regclass AND contype='p' AND pg_get_constraintdef(oid)='PRIMARY KEY (child_user_id, utc_day)')"
