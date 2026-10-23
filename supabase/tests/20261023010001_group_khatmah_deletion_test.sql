-- Privacy cleanup and live authorization contract on a disposable database.
BEGIN;
CREATE FUNCTION pg_temp.gk_assert(p_ok boolean,p_label text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p_ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'group khatmah deletion: %',p_label; END IF;
END; $$;

INSERT INTO auth.users(instance_id,id,aud,role,email,encrypted_password,
  email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
SELECT '00000000-0000-0000-0000-000000000000'::uuid,id,
  'authenticated','authenticated',email,'',now(),'{}'::jsonb,'{}'::jsonb,now(),now()
FROM (VALUES
 ('51000000-0000-0000-0000-000000000001'::uuid,'gk-deletion-owner@example.test'),
 ('51000000-0000-0000-0000-000000000002'::uuid,'gk-deletion-member@example.test'),
 ('51000000-0000-0000-0000-000000000003'::uuid,'gk-deletion-other@example.test')
) AS fixture(id,email);
INSERT INTO auth.sessions(id,user_id,created_at,updated_at)
VALUES
 ('52000000-0000-0000-0000-000000000001','51000000-0000-0000-0000-000000000001',now(),now()),
 ('52000000-0000-0000-0000-000000000002','51000000-0000-0000-0000-000000000002',now(),now()),
 ('52000000-0000-0000-0000-000000000003','51000000-0000-0000-0000-000000000003',now(),now());
SELECT private.group_khatmah_provision('51000000-0000-0000-0000-000000000001',true,1);
SELECT private.group_khatmah_provision('51000000-0000-0000-0000-000000000002',true,1);
SELECT private.group_khatmah_provision('51000000-0000-0000-0000-000000000003',true,1);
CREATE TEMP TABLE gk_deletion_state(group_id uuid,code text,owner_epoch uuid,
  member_epoch uuid,other_epoch uuid,other_old_epoch uuid);
GRANT SELECT,INSERT,UPDATE ON gk_deletion_state TO authenticated;

SELECT set_config('request.jwt.claims',
  '{"sub":"51000000-0000-0000-0000-000000000001","session_id":"52000000-0000-0000-0000-000000000001"}',true);
SET LOCAL ROLE authenticated;
WITH created AS (SELECT public.create_group_khatmah('Shared','Owner',
  '53000000-0000-0000-0000-000000000001') AS r)
INSERT INTO gk_deletion_state(group_id,code,owner_epoch)
SELECT (r->>'group_id')::uuid,r->>'invite_code',(r->>'membership_epoch')::uuid FROM created;
RESET ROLE;

SELECT set_config('request.jwt.claims',
  '{"sub":"51000000-0000-0000-0000-000000000002","session_id":"52000000-0000-0000-0000-000000000002"}',true);
SET LOCAL ROLE authenticated;
UPDATE gk_deletion_state SET member_epoch=(public.join_group_khatmah(
  (SELECT code FROM gk_deletion_state),'Member',
  '53000000-0000-0000-0000-000000000002')->>'membership_epoch')::uuid;
SELECT pg_temp.gk_assert((public.claim_group_part((SELECT group_id FROM gk_deletion_state),
  1::smallint,1::bigint,(SELECT member_epoch FROM gk_deletion_state),
  '53000000-0000-0000-0000-000000000003')->>'code')='claimed',
  'first claim');
SELECT pg_temp.gk_assert((public.complete_group_part((SELECT group_id FROM gk_deletion_state),
  1::smallint,2::bigint,(SELECT member_epoch FROM gk_deletion_state),
  '53000000-0000-0000-0000-000000000004')->>'code')='completed',
  'first completion');
SELECT pg_temp.gk_assert((public.claim_group_part((SELECT group_id FROM gk_deletion_state),
  2::smallint,1::bigint,(SELECT member_epoch FROM gk_deletion_state),
  '53000000-0000-0000-0000-000000000005')->>'code')='claimed',
  'second claim');
RESET ROLE;

-- A claimless member still cannot be removed directly through Auth admin.
SELECT set_config('request.jwt.claims',
  '{"sub":"51000000-0000-0000-0000-000000000003","session_id":"52000000-0000-0000-0000-000000000003"}',true);
SET LOCAL ROLE authenticated;
UPDATE gk_deletion_state SET other_epoch=(public.join_group_khatmah(
  (SELECT code FROM gk_deletion_state),'Other',
  '53000000-0000-0000-0000-000000000006')->>'membership_epoch')::uuid;
UPDATE gk_deletion_state SET other_old_epoch=other_epoch;
SELECT pg_temp.gk_assert((public.claim_group_part((SELECT group_id FROM gk_deletion_state),
  3::smallint,1::bigint,(SELECT other_epoch FROM gk_deletion_state),
  '53000000-0000-0000-0000-000000000010')->>'code')='claimed',
  'other member claims before leave');
RESET ROLE;
DO $$ BEGIN
  BEGIN
    DELETE FROM auth.users WHERE id='51000000-0000-0000-0000-000000000003';
    RAISE EXCEPTION 'direct Auth-admin deletion unexpectedly succeeded';
  EXCEPTION WHEN foreign_key_violation OR restrict_violation THEN NULL;
  END;
END $$;

-- Old join/part receipts cannot return an obsolete epoch after leave/rejoin.
SELECT set_config('request.jwt.claims',
  '{"sub":"51000000-0000-0000-0000-000000000003","session_id":"52000000-0000-0000-0000-000000000003"}',true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.gk_assert((public.leave_group_khatmah((SELECT group_id FROM gk_deletion_state),
  (SELECT other_epoch FROM gk_deletion_state),
  '53000000-0000-0000-0000-000000000007')->>'code')='left',
  'other member leaves');
UPDATE gk_deletion_state SET other_epoch=(public.join_group_khatmah(
  (SELECT code FROM gk_deletion_state),'Other',
  '53000000-0000-0000-0000-000000000008')->>'membership_epoch')::uuid;
SELECT pg_temp.gk_assert((public.join_group_khatmah((SELECT code FROM gk_deletion_state),
  'Other','53000000-0000-0000-0000-000000000006')->>'code')='stale_operation',
  'old join receipt cannot restore epoch');
SELECT pg_temp.gk_assert((public.claim_group_part((SELECT group_id FROM gk_deletion_state),
  3::smallint,1::bigint,(SELECT other_old_epoch FROM gk_deletion_state),
  '53000000-0000-0000-0000-000000000010')->>'code')='stale_operation',
  'old part receipt cannot restore epoch');
RESET ROLE;

-- Revoke access before deletion; revocation is immediately reflected by RLS/RPC.
SELECT private.group_khatmah_provision('51000000-0000-0000-0000-000000000003',false,2);
SET LOCAL ROLE authenticated;
SELECT pg_temp.gk_assert((SELECT count(*)=0 FROM public.group_khatmah),
  'revoked adult cannot read group');
SELECT pg_temp.gk_assert((public.claim_group_part((SELECT group_id FROM gk_deletion_state),
  3::smallint,1::bigint,(SELECT other_epoch FROM gk_deletion_state),
  '53000000-0000-0000-0000-000000000009')->>'code')='not_eligible',
  'revoked adult cannot claim');
RESET ROLE;

-- Delete the ordinary member through the actual RPC; completed progress stays.
SELECT set_config('request.jwt.claims',
  '{"sub":"51000000-0000-0000-0000-000000000002","session_id":"52000000-0000-0000-0000-000000000002"}',true);
SET LOCAL ROLE authenticated;
SELECT public.delete_current_user();
RESET ROLE;
SELECT pg_temp.gk_assert(NOT EXISTS (SELECT 1 FROM auth.users
  WHERE id='51000000-0000-0000-0000-000000000002'),
  'member account deleted');
SELECT pg_temp.gk_assert(NOT EXISTS (SELECT 1 FROM public.group_khatmah_member
  WHERE user_id='51000000-0000-0000-0000-000000000002'),
  'member record deleted');
SELECT pg_temp.gk_assert((SELECT status='completed' AND claimed_by IS NULL
  AND version=4 FROM public.group_khatmah_part
  WHERE group_id=(SELECT group_id FROM gk_deletion_state) AND juz=1),
  'completed part remains but attribution erased');
SELECT pg_temp.gk_assert((SELECT status='open' AND claimed_by IS NULL
  AND version=3 FROM public.group_khatmah_part
  WHERE group_id=(SELECT group_id FROM gk_deletion_state) AND juz=2),
  'unfinished claim released with version bump');
SELECT pg_temp.gk_assert((SELECT version=10 FROM public.group_khatmah
  WHERE id=(SELECT group_id FROM gk_deletion_state)),
  'member cleanup advances group revision once');

-- A stale JWT cannot write after account deletion; deletion itself acknowledges
-- a lost response as an already-completed successful no-op.
SET LOCAL ROLE authenticated;
DO $$ BEGIN
  BEGIN
    PERFORM public.create_group_khatmah('Stale','Member',
      '53000000-0000-0000-0000-000000000011');
    RAISE EXCEPTION 'deleted account unexpectedly created group';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'group_session_required' THEN RAISE; END IF;
  END;
END $$;
SELECT public.delete_current_user();
RESET ROLE;

-- JWT sub and live session must name the same user; anonymous Auth sessions
-- also fail even though they use the authenticated Postgres role.
SELECT set_config('request.jwt.claims',
  '{"sub":"51000000-0000-0000-0000-000000000003","session_id":"52000000-0000-0000-0000-000000000001"}',true);
SET LOCAL ROLE authenticated;
DO $$ BEGIN
  BEGIN
    PERFORM public.create_group_khatmah('Mismatch','Other',
      '53000000-0000-0000-0000-000000000012');
    RAISE EXCEPTION 'mismatched session unexpectedly created group';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'group_session_required' THEN RAISE; END IF;
  END;
END $$;
RESET ROLE;
SELECT set_config('request.jwt.claims',
  '{"sub":"51000000-0000-0000-0000-000000000003","session_id":"52000000-0000-0000-0000-000000000003","is_anonymous":true}',true);
SET LOCAL ROLE authenticated;
DO $$ BEGIN
  BEGIN
    PERFORM public.create_group_khatmah('Anonymous','Other',
      '53000000-0000-0000-0000-000000000013');
    RAISE EXCEPTION 'anonymous session unexpectedly created group';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'group_session_required' THEN RAISE; END IF;
  END;
END $$;
RESET ROLE;

-- Owner account deletion removes its group and leaves another actor's gone receipt.
SELECT set_config('request.jwt.claims',
  '{"sub":"51000000-0000-0000-0000-000000000001","session_id":"52000000-0000-0000-0000-000000000001"}',true);
SET LOCAL ROLE authenticated;
SELECT public.delete_current_user();
RESET ROLE;
SELECT pg_temp.gk_assert(NOT EXISTS (SELECT 1 FROM public.group_khatmah
  WHERE id=(SELECT group_id FROM gk_deletion_state)),
  'owner account deletion removes owned group');
SELECT pg_temp.gk_assert((SELECT gone AND fingerprint IS NULL AND result IS NULL
  AND membership_epoch IS NULL FROM private.group_khatmah_receipt
  WHERE actor_id='51000000-0000-0000-0000-000000000003'
    AND operation_id='53000000-0000-0000-0000-000000000006'),
  'other actor receipt converted to minimal gone tombstone');
ROLLBACK;
