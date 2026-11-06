-- Run only on a freshly migrated disposable Supabase database. No data persists.
BEGIN;
CREATE FUNCTION pg_temp.sg_assert(ok boolean, label text) RETURNS void
LANGUAGE plpgsql AS $$ BEGIN
  IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'share good: %', label; END IF;
END $$;

INSERT INTO auth.users(instance_id,id,aud,role,email,encrypted_password,
  email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
SELECT '00000000-0000-0000-0000-000000000000'::uuid,id,
  'authenticated','authenticated',email,'',now(),'{}'::jsonb,'{}'::jsonb,now(),now()
FROM (VALUES
 ('61000000-0000-0000-0000-000000000001'::uuid,'sg-a@example.test'),
 ('61000000-0000-0000-0000-000000000002'::uuid,'sg-b@example.test'),
 ('61000000-0000-0000-0000-000000000003'::uuid,'sg-c@example.test'),
 ('61000000-0000-0000-0000-000000000004'::uuid,'sg-limit@example.test')
) f(id,email);
INSERT INTO auth.sessions(id,user_id,created_at,updated_at)
SELECT ('62000000-0000-0000-0000-00000000000' || n)::uuid,
       ('61000000-0000-0000-0000-00000000000' || n)::uuid,now(),now()
FROM generate_series(1,4) n;
CREATE TEMP TABLE sg_state (name text PRIMARY KEY, value text);
GRANT SELECT,INSERT,UPDATE ON sg_state TO anon,authenticated;

-- The exact local boundary must roll to tomorrow, including in a non-UTC zone.
SELECT pg_temp.sg_assert(private.share_good_expires_at_v1(
 '{"v":1,"type":"azkar_collection","category":"morning"}',
 '2026-01-01 13:29:59+00','Africa/Cairo') = '2026-01-01 13:30:00+00', 'morning before boundary');
SELECT pg_temp.sg_assert(private.share_good_expires_at_v1(
 '{"v":1,"type":"azkar_collection","category":"morning"}',
 '2026-01-01 13:30:00+00','Africa/Cairo') = '2026-01-02 13:30:00+00', 'morning at boundary');
SELECT pg_temp.sg_assert(private.share_good_expires_at_v1(
 '{"v":1,"type":"azkar_collection","category":"evening"}',
 '2026-01-01 01:59:59+00','Africa/Cairo') = '2026-01-01 02:00:00+00', 'evening before boundary');
SELECT pg_temp.sg_assert(private.share_good_expires_at_v1(
 '{"v":1,"type":"azkar_collection","category":"evening"}',
 '2026-01-01 02:00:00+00','Africa/Cairo') = '2026-01-02 02:00:00+00', 'evening at boundary');
SELECT pg_temp.sg_assert(private.share_good_expires_at_v1(
 '{"v":1,"type":"quran_page","page":42}', '2026-01-01 00:00+00','UTC') =
 '2026-01-08 00:00+00', 'page expiry');
SELECT pg_temp.sg_assert(private.share_good_expires_at_v1(
 '{"v":1,"type":"quran_wird","start_page":1,"end_page":2}', '2026-01-01 00:00+00','UTC') =
 '2026-01-04 00:00+00', 'wird expiry');

-- ACLs are tested as well as exercised under the actual database roles.
SELECT pg_temp.sg_assert(has_function_privilege('anon','public.resolve_share_good_invite_v1(text,text)','EXECUTE')
 AND has_function_privilege('anon','public.advance_share_good_participation_v1(text,text,text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.create_share_good_invite_v1(jsonb,text,text,text,text,text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.create_share_good_chain_invite_v1(text,text,jsonb,text,text,text,text,text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.disclose_share_good_completion_v1(text,text,text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.get_share_good_impact_v1()','EXECUTE'), 'anon exact wrapper grants');
SET LOCAL ROLE anon;
DO $$ BEGIN
  BEGIN
    PERFORM public.disclose_share_good_completion_v1('x','x','No');
    RAISE EXCEPTION 'anon disclosure unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.create_share_good_invite_v1('{}','before','personal','anonymous',NULL,'UTC');
    RAISE EXCEPTION 'anon creation unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;

-- A valid subject alone, or a session belonging to someone else, cannot write.
SELECT set_config('request.jwt.claims','{"sub":"61000000-0000-0000-0000-000000000001"}',true);
SET LOCAL ROLE authenticated;
DO $$ DECLARE rejected boolean := false; BEGIN
  BEGIN PERFORM public.get_share_good_impact_v1(); EXCEPTION WHEN OTHERS THEN rejected := true; END;
  PERFORM pg_temp.sg_assert(rejected,'missing session rejected');
END $$;
RESET ROLE;
SELECT set_config('request.jwt.claims','{"sub":"61000000-0000-0000-0000-000000000001","session_id":"62000000-0000-0000-0000-000000000002"}',true);
SET LOCAL ROLE authenticated;
DO $$ DECLARE rejected boolean := false; BEGIN
  BEGIN PERFORM public.get_share_good_impact_v1(); EXCEPTION WHEN OTHERS THEN rejected := true; END;
  PERFORM pg_temp.sg_assert(rejected,'mismatched session rejected');
END $$;
RESET ROLE;

-- A creates a root. B completes it, discloses, then creates a child. C
-- completes the child and creates a grandchild: the entire chain uses RPCs.
SELECT set_config('request.jwt.claims','{"sub":"61000000-0000-0000-0000-000000000001","session_id":"62000000-0000-0000-0000-000000000001"}',true);
SET LOCAL ROLE authenticated;
INSERT INTO sg_state SELECT 'a', public.create_share_good_invite_v1(
 '{"v":1,"type":"quran_page","page":42}', 'before','personal','anonymous',NULL,'UTC')->>'token';
SELECT pg_temp.sg_assert((SELECT value ~ '^[A-Za-z0-9_-]{43}$' FROM sg_state WHERE name='a'), 'root token format');
SELECT pg_temp.sg_assert(public.create_share_good_invite_v1(
 '{"v":1,"type":"quran_page","page":42.0}', 'before','personal','anonymous',NULL,'UTC')->>'error' IS NOT NULL,
 'reject fractional representation');
SELECT pg_temp.sg_assert(public.create_share_good_invite_v1(
 '{"v":1,"type":"quran_page","page":42,"text":"extra"}', 'before','personal','anonymous',NULL,'UTC')->>'error' IS NOT NULL,
 'reject unexpected target key');
RESET ROLE;
SELECT set_config('request.jwt.claims','{}',true);
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  token text := (SELECT value FROM sg_state WHERE name='a');
  participant text := repeat('Z',43);
BEGIN
  BEGIN
    PERFORM public.resolve_share_good_invite_v1(token,participant);
    RAISE EXCEPTION 'malformed authenticated resolve unexpectedly succeeded';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'share_good_session_required' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.advance_share_good_participation_v1(token,participant,'opened');
    RAISE EXCEPTION 'malformed authenticated advance unexpectedly succeeded';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'share_good_session_required' THEN RAISE; END IF;
  END;
END $$;
RESET ROLE;
SET LOCAL ROLE anon;
SELECT pg_temp.sg_assert((public.resolve_share_good_invite_v1((SELECT value FROM sg_state WHERE name='a'),'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB')->>'status')='active','anon resolve');
SELECT pg_temp.sg_assert((public.advance_share_good_participation_v1((SELECT value FROM sg_state WHERE name='a'),'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB','started')->>'status')='started','anon start');
SELECT pg_temp.sg_assert((public.advance_share_good_participation_v1((SELECT value FROM sg_state WHERE name='a'),'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB','started')->>'status')='started','repeat advance');
SELECT pg_temp.sg_assert((public.advance_share_good_participation_v1((SELECT value FROM sg_state WHERE name='a'),'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB','opened')->>'status')='started','backward advance');
SELECT pg_temp.sg_assert((public.advance_share_good_participation_v1((SELECT value FROM sg_state WHERE name='a'),'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB','completed_private')->>'status')='completed_private','anon complete');
SELECT pg_temp.sg_assert((public.advance_share_good_participation_v1((SELECT value FROM sg_state WHERE name='a'),'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB','completed_shared_identity')->>'error') IS NOT NULL,'cannot advance to disclosed');
SELECT pg_temp.sg_assert((public.advance_share_good_participation_v1((SELECT value FROM sg_state WHERE name='a'),'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB','continued_as_new_invite')->>'error') IS NOT NULL,'cannot advance to continued');
RESET ROLE;
SELECT set_config('request.jwt.claims','{"sub":"61000000-0000-0000-0000-000000000002","session_id":"62000000-0000-0000-0000-000000000002"}',true);
SET LOCAL ROLE authenticated;
-- An uncompleted participant cannot disclose a name or continue the chain.
SELECT pg_temp.sg_assert((public.disclose_share_good_completion_v1((SELECT value FROM sg_state WHERE name='a'),'EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE','B')->>'error') IS NOT NULL,'disclosure requires completion');
SELECT pg_temp.sg_assert((public.create_share_good_chain_invite_v1((SELECT value FROM sg_state WHERE name='a'),'EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE','{"v":1,"type":"quran_page","page":42}','after','personal','anonymous',NULL,'UTC')->>'error') IS NOT NULL,'chain requires completion');
SELECT pg_temp.sg_assert((public.disclose_share_good_completion_v1((SELECT value FROM sg_state WHERE name='a'),'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB','B')->>'status')='completed_shared_identity','B disclosure');
SELECT pg_temp.sg_assert(public.create_share_good_chain_invite_v1(
 (SELECT value FROM sg_state WHERE name='a'),repeat('B',43),'{"v":1,"type":"quran_page","page":43}',
 'after','personal','anonymous',NULL,'UTC')->>'error'='not_eligible','continuation preserves target');
INSERT INTO sg_state SELECT 'b',public.create_share_good_chain_invite_v1(
 (SELECT value FROM sg_state WHERE name='a'),'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB','{"v":1,"type":"quran_page","page":42}',
 'after','personal','display_name','B','UTC')->>'token';
SELECT pg_temp.sg_assert((SELECT value ~ '^[A-Za-z0-9_-]{43}$' FROM sg_state WHERE name='b'),'B child token');
RESET ROLE;
SELECT set_config('request.jwt.claims','{"sub":"61000000-0000-0000-0000-000000000003","session_id":"62000000-0000-0000-0000-000000000003"}',true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.sg_assert((public.advance_share_good_participation_v1((SELECT value FROM sg_state WHERE name='b'),'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC','completed_private')->>'status')='completed_private','C completes');
INSERT INTO sg_state SELECT 'c',public.create_share_good_chain_invite_v1(
 (SELECT value FROM sg_state WHERE name='b'),'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC','{"v":1,"type":"quran_page","page":42}',
 'after','personal','anonymous',NULL,'UTC')->>'token';
SELECT pg_temp.sg_assert((SELECT value ~ '^[A-Za-z0-9_-]{43}$' FROM sg_state WHERE name='c'),'C child token');
RESET ROLE;

SELECT set_config('request.jwt.claims','{"sub":"61000000-0000-0000-0000-000000000001","session_id":"62000000-0000-0000-0000-000000000001"}',true);
SET LOCAL ROLE authenticated;
DO $$
DECLARE impact jsonb := public.get_share_good_impact_v1();
BEGIN
  PERFORM pg_temp.sg_assert(
    impact - ARRAY['invites','responses','completions','downstream_reach','acknowledgements','fetched_at'] = '{}'::jsonb
    AND (impact->'invites'->0) - ARRAY['target','status','expires_at','opens','starts','completions'] = '{}'::jsonb
    AND impact->'acknowledgements'->0->>'visible_name' = 'B',
    'impact returns aggregates and explicitly disclosed names only'
  );
END $$;
RESET ROLE;

-- Save IDs only as privileged test evidence, never from RPC responses.
INSERT INTO sg_state SELECT name || '_id',i.id::text FROM sg_state s JOIN public.share_good_invites i
 ON i.token_hash=encode(sha256(convert_to(s.value,'UTF8')),'hex') WHERE s.name IN ('a','b','c');
SELECT set_config('request.jwt.claims','{"sub":"61000000-0000-0000-0000-000000000002","session_id":"62000000-0000-0000-0000-000000000002"}',true);
SET LOCAL ROLE authenticated;
SELECT public.delete_current_user();
RESET ROLE;
SELECT pg_temp.sg_assert(NOT EXISTS(SELECT 1 FROM auth.users WHERE id='61000000-0000-0000-0000-000000000002'),'B deleted via RPC');
SELECT pg_temp.sg_assert((SELECT creator_user_id IS NULL AND parent_invite_id=(SELECT value::uuid FROM sg_state WHERE name='a_id') AND root_invite_id=(SELECT value::uuid FROM sg_state WHERE name='a_id') FROM public.share_good_invites WHERE id=(SELECT value::uuid FROM sg_state WHERE name='b_id')),'B invite lineage survives');
SELECT pg_temp.sg_assert((SELECT parent_invite_id=(SELECT value::uuid FROM sg_state WHERE name='b_id') AND root_invite_id=(SELECT value::uuid FROM sg_state WHERE name='a_id') FROM public.share_good_invites WHERE id=(SELECT value::uuid FROM sg_state WHERE name='c_id')),'C lineage survives');
SELECT pg_temp.sg_assert(NOT EXISTS(SELECT 1 FROM public.share_good_invite_identities WHERE user_id='61000000-0000-0000-0000-000000000002') AND NOT EXISTS(SELECT 1 FROM public.share_good_completion_disclosures WHERE user_id='61000000-0000-0000-0000-000000000002'),'B names removed');
SELECT set_config('request.jwt.claims','{"sub":"61000000-0000-0000-0000-000000000001","session_id":"62000000-0000-0000-0000-000000000001"}',true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.sg_assert((public.get_share_good_impact_v1()->>'downstream_reach')::int=1,'downstream reach survives deletion');
RESET ROLE;

-- Deleted JWTs cannot authorize authenticated operations.
SELECT set_config('request.jwt.claims','{"sub":"61000000-0000-0000-0000-000000000002","session_id":"62000000-0000-0000-0000-000000000002"}',true);
SET LOCAL ROLE authenticated;
DO $$ DECLARE rejected boolean := false; BEGIN
  BEGIN PERFORM public.get_share_good_impact_v1(); EXCEPTION WHEN OTHERS THEN rejected := true; END;
  PERFORM pg_temp.sg_assert(rejected,'deleted session rejected');
END $$;
RESET ROLE;
-- Expired and revoked invitations cannot be advanced.
UPDATE public.share_good_invites
SET created_at=now()-interval '7 days', expires_at=now()-interval '1 second'
WHERE id=(SELECT value::uuid FROM sg_state WHERE name='a_id');
UPDATE public.share_good_invites SET revoked_at=now() WHERE id=(SELECT value::uuid FROM sg_state WHERE name='b_id');
SELECT set_config('request.jwt.claims','{}',true);
SET LOCAL ROLE anon;
SELECT pg_temp.sg_assert(public.advance_share_good_participation_v1((SELECT value FROM sg_state WHERE name='a'),'LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL','started')->>'error'='expired','expired advance');
SELECT pg_temp.sg_assert(public.advance_share_good_participation_v1((SELECT value FROM sg_state WHERE name='b'),'LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL','started')->>'error'='expired','revoked advance');
RESET ROLE;
SELECT set_config('request.jwt.claims','{"sub":"61000000-0000-0000-0000-000000000003","session_id":"62000000-0000-0000-0000-000000000003"}',true);
SET LOCAL ROLE authenticated;
SELECT pg_temp.sg_assert(public.create_share_good_chain_invite_v1(
 (SELECT value FROM sg_state WHERE name='a'),repeat('B',43),'{"v":1,"type":"quran_page","page":42}',
 'after','personal','anonymous',NULL,'UTC')->>'error'='expired','expired parent cannot continue');
RESET ROLE;
UPDATE public.profiles SET selected_path='child' WHERE id='61000000-0000-0000-0000-000000000003';
SET LOCAL ROLE authenticated;
DO $$ BEGIN
  BEGIN
    PERFORM public.get_share_good_impact_v1();
    RAISE EXCEPTION 'known child unexpectedly authorized';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'share_good_not_eligible' THEN RAISE; END IF;
  END;
END $$;
RESET ROLE;
SELECT set_config('request.jwt.claims','{}',true);

-- Fresh keys isolate the documented thresholds from the earlier actions.
SET LOCAL ROLE anon;
DO $$ DECLARE r jsonb; i integer; token text; BEGIN
 SELECT value INTO token FROM sg_state WHERE name='c';
 FOR i IN 1..60 LOOP
   r := public.resolve_share_good_invite_v1(token,'RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR');
   PERFORM pg_temp.sg_assert(r->>'error' IS DISTINCT FROM 'rate_limited','resolve below cap');
 END LOOP;
 PERFORM pg_temp.sg_assert(public.resolve_share_good_invite_v1(token,'RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR')->>'error'='rate_limited','resolve cap');
 FOR i IN 1..20 LOOP
   r := public.advance_share_good_participation_v1(token,'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD','opened');
   PERFORM pg_temp.sg_assert(r->>'error' IS DISTINCT FROM 'rate_limited','advance below cap');
 END LOOP;
 PERFORM pg_temp.sg_assert(public.advance_share_good_participation_v1(token,'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD','opened')->>'error'='rate_limited','advance cap');
END $$;
RESET ROLE;
SELECT set_config('request.jwt.claims','{"sub":"61000000-0000-0000-0000-000000000004","session_id":"62000000-0000-0000-0000-000000000004"}',true);
SET LOCAL ROLE authenticated;
DO $$ DECLARE r jsonb; i integer; BEGIN
 FOR i IN 1..30 LOOP
   r := public.create_share_good_invite_v1('{"v":1,"type":"quran_page","page":1}','before','personal','anonymous',NULL,'UTC');
   PERFORM pg_temp.sg_assert(r->>'token' IS NOT NULL,'creation below cap');
 END LOOP;
 r := public.create_share_good_invite_v1('{"v":1,"type":"quran_page","page":1}','before','personal','anonymous',NULL,'UTC');
 PERFORM pg_temp.sg_assert(r->>'error'='rate_limited','creation cap');
END $$;
RESET ROLE;
ROLLBACK;
