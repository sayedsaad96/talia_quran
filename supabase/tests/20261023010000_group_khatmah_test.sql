-- Disposable PostgreSQL/Supabase fixture. Entire test rolls back.
BEGIN;
CREATE FUNCTION pg_temp.gk_assert(p_ok boolean,p_label text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'group khatmah: %',p_label; END IF;
END; $$;

INSERT INTO auth.users(instance_id,id,aud,role,email,encrypted_password,
  email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
SELECT '00000000-0000-0000-0000-000000000000'::uuid,id,
  'authenticated','authenticated',email,'',now(),'{}'::jsonb,'{}'::jsonb,now(),now()
FROM (VALUES
 ('41000000-0000-0000-0000-000000000001'::uuid,'gk-owner@example.test'),
 ('41000000-0000-0000-0000-000000000002'::uuid,'gk-member@example.test'),
 ('41000000-0000-0000-0000-000000000003'::uuid,'gk-outsider@example.test'),
 ('41000000-0000-0000-0000-000000000004'::uuid,'gk-unknown@example.test')
) AS fixture(id,email);
INSERT INTO auth.sessions(id,user_id,created_at,updated_at)
VALUES
 ('42000000-0000-0000-0000-000000000001','41000000-0000-0000-0000-000000000001',now(),now()),
 ('42000000-0000-0000-0000-000000000002','41000000-0000-0000-0000-000000000002',now(),now()),
 ('42000000-0000-0000-0000-000000000003','41000000-0000-0000-0000-000000000003',now(),now()),
 ('42000000-0000-0000-0000-000000000004','41000000-0000-0000-0000-000000000004',now(),now());
SELECT private.group_khatmah_provision('41000000-0000-0000-0000-000000000001',true,1);
SELECT private.group_khatmah_provision('41000000-0000-0000-0000-000000000002',true,1);
SELECT private.group_khatmah_provision('41000000-0000-0000-0000-000000000003',true,1);

SELECT set_config('request.jwt.claims',
  '{"sub":"41000000-0000-0000-0000-000000000004","session_id":"42000000-0000-0000-0000-000000000004"}',true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.gk_assert((public.create_group_khatmah('Unknown','Unknown',
  '43000000-0000-0000-0000-000000000001')->>'code')='not_eligible',
  'unknown account cannot create');
RESET ROLE;

SELECT set_config('request.jwt.claims',
  '{"sub":"41000000-0000-0000-0000-000000000001","session_id":"42000000-0000-0000-0000-000000000001"}',true);
CREATE TEMP TABLE gk_test_state(group_id uuid,code text,owner_epoch uuid,member_epoch uuid);
GRANT SELECT,INSERT,UPDATE ON gk_test_state TO authenticated;
SET LOCAL ROLE authenticated;
WITH created AS (SELECT public.create_group_khatmah('Shared Quran','Owner',
  '43000000-0000-0000-0000-000000000002') AS r)
INSERT INTO gk_test_state(group_id,code,owner_epoch)
SELECT (r->>'group_id')::uuid,r->>'invite_code',(r->>'membership_epoch')::uuid FROM created;
SELECT pg_temp.gk_assert((SELECT count(*)=30 FROM public.group_khatmah_part),
  'create makes exactly thirty parts');
SELECT pg_temp.gk_assert((SELECT count(*)=1 FROM public.group_khatmah_member),
  'owner sees own membership');
SELECT pg_temp.gk_assert((public.create_group_khatmah('Shared Quran','Owner',
  '43000000-0000-0000-0000-000000000002')->>'group_id')=(SELECT group_id::text FROM gk_test_state),
  'create receipt replays same group');
SELECT pg_temp.gk_assert((SELECT count(*)=1 FROM public.group_khatmah),
  'create replay did not create a second group');
SELECT pg_temp.gk_assert((public.create_group_khatmah('Changed','Owner',
  '43000000-0000-0000-0000-000000000002')->>'code')='invalid_operation',
  'changed payload cannot reuse operation id');
RESET ROLE;

SELECT set_config('request.jwt.claims',
  '{"sub":"41000000-0000-0000-0000-000000000003","session_id":"42000000-0000-0000-0000-000000000003"}',true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.gk_assert((SELECT count(*)=0 FROM public.group_khatmah),
  'outsider cannot read group');
SELECT pg_temp.gk_assert((SELECT count(*)=0 FROM public.group_khatmah_member),
  'outsider cannot read roster');
SELECT pg_temp.gk_assert((SELECT count(*)=0 FROM public.group_khatmah_part),
  'outsider cannot read parts');
SELECT pg_temp.gk_assert((public.join_group_khatmah('BAD!','Outsider',
  '43000000-0000-0000-0000-000000000003')->>'code')='invalid_invite',
  'invalid code denied');
RESET ROLE;
SET LOCAL ROLE anon;
DO $$ BEGIN
  BEGIN
    PERFORM public.create_group_khatmah('Denied','Anonymous',
      '43000000-0000-0000-0000-000000000015');
    RAISE EXCEPTION 'anon RPC unexpectedly executable';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM count(*) FROM public.group_khatmah;
    RAISE EXCEPTION 'anon table unexpectedly readable';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $$;
RESET ROLE;

SELECT set_config('request.jwt.claims',
  '{"sub":"41000000-0000-0000-0000-000000000002","session_id":"42000000-0000-0000-0000-000000000002"}',true);
SET LOCAL ROLE authenticated;
UPDATE gk_test_state SET member_epoch=(public.join_group_khatmah(
  (SELECT code FROM gk_test_state),'Member',
  '43000000-0000-0000-0000-000000000004')->>'membership_epoch')::uuid;
SELECT pg_temp.gk_assert((SELECT count(*)=1 FROM public.group_khatmah),
  'member can read group without recursive policy');
SELECT pg_temp.gk_assert((SELECT count(*)=2 FROM public.group_khatmah_member),
  'member can read roster');
SELECT pg_temp.gk_assert((SELECT version=2 FROM public.group_khatmah),
  'join increments group revision once');
SELECT pg_temp.gk_assert((public.join_group_khatmah((SELECT code FROM gk_test_state),
  'Member','43000000-0000-0000-0000-000000000004')->>'code')='joined',
  'join receipt replays');
SELECT pg_temp.gk_assert((SELECT version=2 FROM public.group_khatmah),
  'join replay leaves revision alone');
RESET ROLE;

SELECT set_config('request.jwt.claims',
  '{"sub":"41000000-0000-0000-0000-000000000001","session_id":"42000000-0000-0000-0000-000000000001"}',true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.gk_assert((private.group_khatmah_change_part(NULL,
  (SELECT group_id FROM gk_test_state),1::smallint,1::bigint,
  (SELECT owner_epoch FROM gk_test_state),
  '43000000-0000-0000-0000-000000000012')->>'code')='invalid_operation',
  'null private action is rejected without mutation');
SELECT pg_temp.gk_assert((public.claim_group_part((SELECT group_id FROM gk_test_state),
  1::smallint,1::bigint,(SELECT owner_epoch FROM gk_test_state),
  '43000000-0000-0000-0000-000000000005')->>'applied')='true',
  'owner claim succeeds');
SELECT pg_temp.gk_assert((SELECT version=3 FROM public.group_khatmah),
  'claim advances group revision');
RESET ROLE;

SELECT set_config('request.jwt.claims',
  '{"sub":"41000000-0000-0000-0000-000000000002","session_id":"42000000-0000-0000-0000-000000000002"}',true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.gk_assert((public.claim_group_part((SELECT group_id FROM gk_test_state),
  1::smallint,1::bigint,(SELECT member_epoch FROM gk_test_state),
  '43000000-0000-0000-0000-000000000006')->>'code')='conflict',
  'second claim loses CAS');
SELECT pg_temp.gk_assert((public.complete_group_part((SELECT group_id FROM gk_test_state),
  1::smallint,2::bigint,(SELECT member_epoch FROM gk_test_state),
  '43000000-0000-0000-0000-000000000007')->>'code')='conflict',
  'another member cannot complete claim');
SELECT pg_temp.gk_assert((SELECT version=3 FROM public.group_khatmah),
  'conflicts do not increment revision');
RESET ROLE;

SELECT set_config('request.jwt.claims',
  '{"sub":"41000000-0000-0000-0000-000000000001","session_id":"42000000-0000-0000-0000-000000000001"}',true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.gk_assert((public.complete_group_part((SELECT group_id FROM gk_test_state),
  1::smallint,2::bigint,(SELECT owner_epoch FROM gk_test_state),
  '43000000-0000-0000-0000-000000000008')->>'code')='completed',
  'claim owner completes with stable code');
SELECT pg_temp.gk_assert((SELECT version=4 FROM public.group_khatmah),
  'complete advances group revision');
SELECT pg_temp.gk_assert((public.claim_group_part((SELECT group_id FROM gk_test_state),
  2::smallint,1::bigint,(SELECT owner_epoch FROM gk_test_state),
  '43000000-0000-0000-0000-000000000013')->>'code')='claimed',
  'second part claimed');
SELECT pg_temp.gk_assert((public.release_group_part((SELECT group_id FROM gk_test_state),
  2::smallint,2::bigint,(SELECT owner_epoch FROM gk_test_state),
  '43000000-0000-0000-0000-000000000014')->>'code')='released',
  'own unfinished claim released');
SELECT pg_temp.gk_assert((public.release_group_part((SELECT group_id FROM gk_test_state),
  2::smallint,2::bigint,(SELECT owner_epoch FROM gk_test_state),
  '43000000-0000-0000-0000-000000000014')->>'code')='released',
  'release receipt replays');
SELECT pg_temp.gk_assert((SELECT version=6 FROM public.group_khatmah),
  'release replay does not advance group revision');
SELECT pg_temp.gk_assert((SELECT version=3 AND status='open'
  FROM public.group_khatmah_part WHERE juz=2),
  'release replay does not advance part revision');
RESET ROLE;

SELECT set_config('request.jwt.claims',
  '{"sub":"41000000-0000-0000-0000-000000000002","session_id":"42000000-0000-0000-0000-000000000002"}',true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.gk_assert((public.leave_group_khatmah((SELECT group_id FROM gk_test_state),
  (SELECT member_epoch FROM gk_test_state),
  '43000000-0000-0000-0000-000000000009')->>'code')='left',
  'member leaves');
SELECT pg_temp.gk_assert((SELECT count(*)=0 FROM public.group_khatmah_member),
  'departed member loses roster access');
SELECT pg_temp.gk_assert((public.complete_group_part((SELECT group_id FROM gk_test_state),
  1::smallint,2::bigint,(SELECT member_epoch FROM gk_test_state),
  '43000000-0000-0000-0000-000000000010')->>'code')='not_member',
  'completion after leave denied');
RESET ROLE;

SELECT set_config('request.jwt.claims',
  '{"sub":"41000000-0000-0000-0000-000000000001","session_id":"42000000-0000-0000-0000-000000000001"}',true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.gk_assert((public.leave_group_khatmah((SELECT group_id FROM gk_test_state),
  (SELECT owner_epoch FROM gk_test_state),
  '43000000-0000-0000-0000-000000000011')->>'code')='group_deleted',
  'sole owner deletes group');
SELECT pg_temp.gk_assert((public.create_group_khatmah('Changed','Owner',
  '43000000-0000-0000-0000-000000000002')->>'code')='gone',
  'gone create receipt cannot recreate group');
RESET ROLE;
ROLLBACK;
