-- Self-service eligibility contract (phase 4 L5).
BEGIN;
CREATE FUNCTION pg_temp.gk_assert(p_ok boolean,p_label text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'group khatmah eligibility: %',p_label; END IF;
END; $$;

-- 1 adult, 2 linked child, 3 no profile, 4 adult manually denied,
-- 5 adult path whose child link was revoked, 6 child path without a link,
-- 7 profile without a path.
INSERT INTO auth.users(instance_id,id,aud,role,email,encrypted_password,
  email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
SELECT '00000000-0000-0000-0000-000000000000'::uuid,
  ('71000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,
  'authenticated','authenticated','gk-eligibility-'||n||'@example.test',
  '',now(),'{}'::jsonb,'{}'::jsonb,now(),now()
FROM pg_catalog.generate_series(1,7) AS nums(n);
INSERT INTO auth.sessions(id,user_id,created_at,updated_at)
SELECT ('72000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,
  ('71000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,now(),now()
FROM pg_catalog.generate_series(1,7) AS nums(n);
INSERT INTO public.profiles(id,selected_path) VALUES
  ('71000000-0000-0000-0000-000000000001','adult'),
  ('71000000-0000-0000-0000-000000000002','child'),
  ('71000000-0000-0000-0000-000000000004','adult'),
  ('71000000-0000-0000-0000-000000000005','adult'),
  ('71000000-0000-0000-0000-000000000006','child'),
  ('71000000-0000-0000-0000-000000000007',NULL);
INSERT INTO public.parent_child_links(parent_user_id,child_user_id,status) VALUES
  ('71000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000002','active'),
  ('71000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000005','revoked');
SELECT private.group_khatmah_provision('71000000-0000-0000-0000-000000000004',false,1);

CREATE FUNCTION pg_temp.as_user(p_n integer) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claims',pg_catalog.jsonb_build_object(
    'sub','71000000-0000-0000-0000-'||lpad(p_n::text,12,'0'),
    'session_id','72000000-0000-0000-0000-'||lpad(p_n::text,12,'0'))::text,true);
END; $$;

DO $$
DECLARE v_result jsonb;
BEGIN
  PERFORM pg_temp.as_user(1);
  v_result := public.request_group_khatmah_eligibility();
  PERFORM pg_temp.gk_assert(v_result = '{"eligible": true}'::jsonb,'adult is granted');
  PERFORM pg_temp.gk_assert((SELECT eligible AND policy_version = 2
    FROM private.group_khatmah_eligibility
    WHERE user_id = '71000000-0000-0000-0000-000000000001'),'self-grant is policy 2');
  v_result := public.request_group_khatmah_eligibility();
  PERFORM pg_temp.gk_assert(v_result = '{"eligible": true}'::jsonb,'repeat stays granted');
  PERFORM pg_temp.gk_assert((SELECT count(*) = 1 FROM private.group_khatmah_eligibility
    WHERE user_id = '71000000-0000-0000-0000-000000000001'),'repeat adds no row');
  v_result := public.create_group_khatmah('Family','Owner',
    '73000000-0000-0000-0000-000000000001');
  PERFORM pg_temp.gk_assert(v_result->>'code' = 'created','granted adult can create');

  PERFORM pg_temp.as_user(2);
  v_result := public.request_group_khatmah_eligibility();
  PERFORM pg_temp.gk_assert(v_result = '{"eligible": false}'::jsonb,'linked child refused');

  PERFORM pg_temp.as_user(3);
  v_result := public.request_group_khatmah_eligibility();
  PERFORM pg_temp.gk_assert(v_result = '{"eligible": false}'::jsonb,'no profile refused');

  PERFORM pg_temp.as_user(4);
  v_result := public.request_group_khatmah_eligibility();
  PERFORM pg_temp.gk_assert(v_result = '{"eligible": false}'::jsonb,'manual denial kept');

  PERFORM pg_temp.as_user(5);
  v_result := public.request_group_khatmah_eligibility();
  PERFORM pg_temp.gk_assert(v_result = '{"eligible": false}'::jsonb,
    'any link history blocks, even revoked');

  PERFORM pg_temp.as_user(6);
  v_result := public.request_group_khatmah_eligibility();
  PERFORM pg_temp.gk_assert(v_result = '{"eligible": false}'::jsonb,'child path refused');

  PERFORM pg_temp.as_user(7);
  v_result := public.request_group_khatmah_eligibility();
  PERFORM pg_temp.gk_assert(v_result = '{"eligible": false}'::jsonb,'no path refused');

  PERFORM pg_temp.gk_assert(NOT EXISTS (SELECT 1 FROM private.group_khatmah_eligibility
    WHERE user_id IN ('71000000-0000-0000-0000-000000000002',
      '71000000-0000-0000-0000-000000000003','71000000-0000-0000-0000-000000000005',
      '71000000-0000-0000-0000-000000000006','71000000-0000-0000-0000-000000000007')),
    'refusals write nothing');
END $$;

-- A self-grant is withdrawn live when the account later becomes a linked
-- child or switches to the child path; a trusted grant is not.
DO $$
DECLARE v_result jsonb;
BEGIN
  INSERT INTO public.parent_child_links(parent_user_id,child_user_id,status) VALUES
    ('71000000-0000-0000-0000-000000000004','71000000-0000-0000-0000-000000000001','active');
  PERFORM pg_temp.as_user(1);
  PERFORM pg_temp.gk_assert(NOT private.group_khatmah_adult(
    '71000000-0000-0000-0000-000000000001'),'linked later: actions refused');
  v_result := public.join_group_khatmah('ABCDEF','Child',
    '73000000-0000-0000-0000-000000000002');
  PERFORM pg_temp.gk_assert(v_result->>'code' = 'not_eligible','linked later: join refused');
  -- The runner is a superuser, so assert the RLS predicate itself.
  PERFORM pg_temp.gk_assert((SELECT NOT private.group_khatmah_can_read(g.id)
    FROM public.group_khatmah g
    WHERE g.owner_id = '71000000-0000-0000-0000-000000000001'),
    'linked later: own group no longer readable');
  v_result := public.request_group_khatmah_eligibility();
  PERFORM pg_temp.gk_assert(v_result = '{"eligible": false}'::jsonb,
    'linked later: request answers false');

  PERFORM private.group_khatmah_provision('71000000-0000-0000-0000-000000000004',true,1);
  PERFORM pg_temp.gk_assert(private.group_khatmah_adult(
    '71000000-0000-0000-0000-000000000004'),'trusted grant ignores the live check');
END $$;

DO $$
BEGIN
  PERFORM set_config('request.jwt.claims','{}',true);
  BEGIN
    PERFORM public.request_group_khatmah_eligibility();
    RAISE EXCEPTION 'group khatmah eligibility: anonymous call was allowed';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'group_session_required' THEN RAISE; END IF;
  END;
  PERFORM pg_temp.as_user(1);
  PERFORM set_config('request.jwt.claims',pg_catalog.jsonb_build_object(
    'sub','71000000-0000-0000-0000-000000000001',
    'session_id','72000000-0000-0000-0000-000000000099')::text,true);
  BEGIN
    PERFORM public.request_group_khatmah_eligibility();
    RAISE EXCEPTION 'group khatmah eligibility: a dead session was allowed';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'group_session_required' THEN RAISE; END IF;
  END;
END $$;

DO $$
BEGIN
  PERFORM pg_temp.gk_assert(NOT has_function_privilege('anon',
    'public.request_group_khatmah_eligibility()','EXECUTE'),'anon cannot execute');
  PERFORM pg_temp.gk_assert(has_function_privilege('authenticated',
    'public.request_group_khatmah_eligibility()','EXECUTE'),'authenticated can execute');
  PERFORM pg_temp.gk_assert(NOT has_function_privilege('anon',
    'private.group_khatmah_self_eligibility()','EXECUTE'),'anon cannot reach private');
  PERFORM pg_temp.gk_assert((SELECT NOT p.prosecdef FROM pg_catalog.pg_proc p
    WHERE p.oid = 'public.request_group_khatmah_eligibility()'::regprocedure),
    'entry point is security invoker');
  PERFORM pg_temp.gk_assert((SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
    FROM pg_catalog.pg_proc p
    WHERE p.oid = 'private.group_khatmah_self_eligibility()'::regprocedure),
    'private function is definer with empty search_path');
END $$;
ROLLBACK;
