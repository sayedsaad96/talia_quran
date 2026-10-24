-- Capacity, throttle, final completion, and expired-session contract.
BEGIN;
CREATE FUNCTION pg_temp.gk_assert(p_ok boolean,p_label text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'group khatmah capacity: %',p_label; END IF;
END; $$;

INSERT INTO auth.users(instance_id,id,aud,role,email,encrypted_password,
  email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
SELECT '00000000-0000-0000-0000-000000000000'::uuid,
  ('61000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,
  'authenticated','authenticated','gk-capacity-'||n||'@example.test',
  '',now(),'{}'::jsonb,'{}'::jsonb,now(),now()
FROM pg_catalog.generate_series(1,31) AS nums(n);
INSERT INTO auth.sessions(id,user_id,created_at,updated_at)
SELECT ('62000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,
  ('61000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,now(),now()
FROM pg_catalog.generate_series(1,31) AS nums(n);
DO $$
DECLARE v_i integer;
BEGIN
  FOR v_i IN 1..31 LOOP
    PERFORM private.group_khatmah_provision(
      ('61000000-0000-0000-0000-'||lpad(v_i::text,12,'0'))::uuid,true,1);
  END LOOP;
END $$;

DO $$
DECLARE v_result jsonb;
DECLARE v_group uuid;
DECLARE v_code text;
DECLARE v_epoch uuid;
DECLARE v_i integer;
BEGIN
  PERFORM set_config('request.jwt.claims',pg_catalog.jsonb_build_object(
    'sub','61000000-0000-0000-0000-000000000001',
    'session_id','62000000-0000-0000-0000-000000000001')::text,true);
  v_result := public.create_group_khatmah('Thirty Members','Owner',
    '63000000-0000-0000-0000-000000000001');
  PERFORM pg_temp.gk_assert(v_result->>'code'='created','owner creates');
  v_group := (v_result->>'group_id')::uuid;
  v_code := v_result->>'invite_code';
  v_epoch := (v_result->>'membership_epoch')::uuid;
  FOR v_i IN 2..30 LOOP
    PERFORM set_config('request.jwt.claims',pg_catalog.jsonb_build_object(
      'sub','61000000-0000-0000-0000-'||lpad(v_i::text,12,'0'),
      'session_id','62000000-0000-0000-0000-'||lpad(v_i::text,12,'0'))::text,true);
    v_result := public.join_group_khatmah(v_code,'Member '||v_i,
      ('63000000-0000-0000-0000-'||lpad(v_i::text,12,'0'))::uuid);
    PERFORM pg_temp.gk_assert(v_result->>'code'='joined','member joins');
  END LOOP;
  PERFORM pg_temp.gk_assert((SELECT count(*)=30 FROM public.group_khatmah_member
    WHERE group_id=v_group AND left_at IS NULL),'thirty active members');
  PERFORM pg_temp.gk_assert((SELECT version=30 FROM public.group_khatmah
    WHERE id=v_group),'each join increments revision once');
  PERFORM set_config('request.jwt.claims',pg_catalog.jsonb_build_object(
    'sub','61000000-0000-0000-0000-000000000031',
    'session_id','62000000-0000-0000-0000-000000000031')::text,true);
  v_result := public.join_group_khatmah(v_code,'Member 31',
    '63000000-0000-0000-0000-000000000031');
  PERFORM pg_temp.gk_assert(v_result->>'code'='group_full','31st member denied');
  FOR v_i IN 1..4 LOOP
    v_result := public.join_group_khatmah('BAD!','Member 31',
      ('64000000-0000-0000-0000-'||lpad(v_i::text,12,'0'))::uuid);
    PERFORM pg_temp.gk_assert(v_result->>'code'='invalid_invite',
      'invalid invitation denied and counted');
  END LOOP;
  v_result := public.join_group_khatmah(v_code,'Member 31',
    '64000000-0000-0000-0000-000000000005');
  PERFORM pg_temp.gk_assert(v_result->>'code'='rate_limited',
    'sixth attempt denied before lookup');
  PERFORM pg_temp.gk_assert((SELECT minute_count=6
    FROM private.group_khatmah_join_throttle
    WHERE user_id='61000000-0000-0000-0000-000000000031'),
    'denied attempts persist in throttle');

  PERFORM set_config('request.jwt.claims',pg_catalog.jsonb_build_object(
    'sub','61000000-0000-0000-0000-000000000001',
    'session_id','62000000-0000-0000-0000-000000000001')::text,true);
  FOR v_i IN 1..30 LOOP
    v_result := public.claim_group_part(v_group,v_i::smallint,1,v_epoch,
      ('65000000-0000-0000-0000-'||lpad(v_i::text,12,'0'))::uuid);
    PERFORM pg_temp.gk_assert(v_result->>'code'='claimed','part claimed');
    v_result := public.complete_group_part(v_group,v_i::smallint,2,v_epoch,
      ('66000000-0000-0000-0000-'||lpad(v_i::text,12,'0'))::uuid);
    PERFORM pg_temp.gk_assert(v_result->>'code'='completed','part completed');
  END LOOP;
  PERFORM pg_temp.gk_assert((SELECT status='completed' AND version=90
    AND completed_at IS NOT NULL FROM public.group_khatmah WHERE id=v_group),
    'final completion sets status and increments once');
  v_result := public.complete_group_part(v_group,30::smallint,2,v_epoch,
    '66000000-0000-0000-0000-000000000030');
  PERFORM pg_temp.gk_assert(v_result->>'code'='completed',
    'final completion receipt replays after group closes');
  v_result := public.claim_group_part(v_group,1::smallint,3,v_epoch,
    '67000000-0000-0000-0000-000000000001');
  PERFORM pg_temp.gk_assert(v_result->>'code'='group_completed',
    'completed group is read only');
  v_result := public.leave_group_khatmah(v_group,v_epoch,
    '67000000-0000-0000-0000-000000000002');
  PERFORM pg_temp.gk_assert(v_result->>'code'='owner_has_members',
    'owner cannot remove shared completed group');
  PERFORM pg_temp.gk_assert((SELECT version=90 FROM public.group_khatmah
    WHERE id=v_group),'denials and receipt replay do not advance revision');
END $$;

-- Create shares the join throttle (five calls per minute; this user already
-- spent one on joining), and replays are free.
DO $$
DECLARE v_result jsonb;
DECLARE v_i integer;
BEGIN
  PERFORM set_config('request.jwt.claims',pg_catalog.jsonb_build_object(
    'sub','61000000-0000-0000-0000-000000000005',
    'session_id','62000000-0000-0000-0000-000000000005')::text,true);
  FOR v_i IN 1..4 LOOP
    v_result := public.create_group_khatmah('Throttled '||v_i,'Creator',
      ('69000000-0000-0000-0000-'||lpad(v_i::text,12,'0'))::uuid);
    PERFORM pg_temp.gk_assert(v_result->>'code'='created','create within budget');
  END LOOP;
  v_result := public.create_group_khatmah('Throttled 5','Creator',
    '69000000-0000-0000-0000-000000000005');
  PERFORM pg_temp.gk_assert(v_result->>'code'='rate_limited',
    'fifth call in a minute denied');
  PERFORM pg_temp.gk_assert(NOT EXISTS (SELECT 1 FROM public.group_khatmah
    WHERE title='Throttled 5'),'rate limited create writes no group');
  v_result := public.create_group_khatmah('Throttled 1','Creator',
    '69000000-0000-0000-0000-000000000001');
  PERFORM pg_temp.gk_assert(v_result->>'code'='created'
    AND v_result->>'group_id' IS NOT NULL,'create replay is not throttled');
END $$;

DELETE FROM auth.sessions WHERE id='62000000-0000-0000-0000-000000000031';
SELECT set_config('request.jwt.claims',
  '{"sub":"61000000-0000-0000-0000-000000000031","session_id":"62000000-0000-0000-0000-000000000031"}',true);
DO $$ BEGIN
  BEGIN
    PERFORM public.create_group_khatmah('Bad Session','Member 31',
      '68000000-0000-0000-0000-000000000001');
    RAISE EXCEPTION 'expired session unexpectedly created group';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'group_session_required' THEN RAISE; END IF;
  END;
END $$;
ROLLBACK;
