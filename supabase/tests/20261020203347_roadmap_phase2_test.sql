-- Disposable fresh/upgrade database only. All fixture changes roll back.
-- Concurrent quota/link-revocation guarantees additionally need multi-session QA.
BEGIN;
CREATE FUNCTION pg_temp.phase2_assert(p_ok BOOLEAN, p_label TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  IF p_ok IS DISTINCT FROM TRUE THEN RAISE EXCEPTION 'phase2: %', p_label; END IF;
END;
$$;
CREATE FUNCTION pg_temp.phase2_error(p_sql TEXT, p_message TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = p_message THEN RETURN; END IF;
    RAISE EXCEPTION 'phase2 wrong error: expected %, got %', p_message, SQLERRM;
  END;
  RAISE EXCEPTION 'phase2 expected rejection: %', p_message;
END;
$$;

INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) SELECT '00000000-0000-0000-0000-000000000000'::UUID, id,
  'authenticated', 'authenticated', email, '', NOW(), '{}'::JSONB,
  '{}'::JSONB, NOW(), NOW()
FROM (VALUES
  ('31000000-0000-0000-0000-000000000001'::UUID, 'phase2-parent@example.test'),
  ('31000000-0000-0000-0000-000000000002'::UUID, 'phase2-other@example.test'),
  ('32000000-0000-0000-0000-000000000001'::UUID, 'phase2-child@example.test')
) fixtures(id, email);
UPDATE public.profiles SET selected_path = 'adult'
  WHERE id IN ('31000000-0000-0000-0000-000000000001', '31000000-0000-0000-0000-000000000002');
UPDATE public.profiles SET selected_path = 'child', age = 8
  WHERE id = '32000000-0000-0000-0000-000000000001';
INSERT INTO public.parent_child_links(parent_user_id, child_user_id) VALUES
  ('31000000-0000-0000-0000-000000000001', '32000000-0000-0000-0000-000000000001');

DO $$
DECLARE
  v_parent UUID := '31000000-0000-0000-0000-000000000001';
  v_child UUID := '32000000-0000-0000-0000-000000000001';
  v_policy JSONB;
  v_reward public.parent_rewards;
  v_ordinary public.parent_rewards;
  v_message public.kids_encouragements;
  v_retry public.kids_encouragements;
  v_ids BIGINT[] := '{}';
  v_request UUID := '33000000-0000-0000-0000-000000000001';
  v_time TIMESTAMPTZ;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_parent::TEXT, TRUE);
  v_policy := public.compare_and_swap_child_policy_v2(v_child, 0, FALSE, 3, TRUE, NULL, 114, 10, 127);
  PERFORM pg_temp.phase2_assert((v_policy->>'applied')::BOOLEAN, 'v2 create');
  PERFORM pg_temp.phase2_assert((v_policy->>'version')::BIGINT = 1, 'shared initial version');
  v_policy := public.compare_and_swap_child_policy(v_child, 1, TRUE, 2, FALSE, 15);
  PERFORM pg_temp.phase2_assert((v_policy->>'applied')::BOOLEAN
    AND (v_policy->'policy'->>'next_surah_id')::INTEGER = 114
    AND (v_policy->'policy'->>'ayahs_per_session')::INTEGER = 10
    AND (v_policy->'policy'->>'practice_days')::INTEGER = 127, 'v1 preserves v2 fields');
  v_policy := public.compare_and_swap_child_policy_v2(v_child, 1, FALSE, 1, TRUE, NULL, NULL, NULL, NULL);
  PERFORM pg_temp.phase2_assert(NOT (v_policy->>'applied')::BOOLEAN
    AND (v_policy->>'version')::BIGINT = 2, 'stale v2 returns latest version');
  PERFORM pg_temp.phase2_error(
    format('SELECT public.compare_and_swap_child_policy_v2(%L,2,false,3,true,null,115,1,0)', v_child),
    'Invalid child policy');
  PERFORM pg_temp.phase2_error(
    format('SELECT public.compare_and_swap_child_policy_v2(%L,2,false,3,true,null,1,11,0)', v_child),
    'Invalid child policy');
  PERFORM pg_temp.phase2_error(
    format('SELECT public.compare_and_swap_child_policy_v2(%L,2,false,3,true,null,1,1,128)', v_child),
    'Invalid child policy');
  v_policy := public.compare_and_swap_child_policy_v2(v_child, 2, FALSE, 1, TRUE, NULL, NULL, NULL, 0);
  PERFORM pg_temp.phase2_assert((v_policy->'policy'->>'next_surah_id') IS NULL
    AND (v_policy->'policy'->>'practice_days')::INTEGER = 0, 'clear hints and disable reminders');

  SELECT * INTO v_reward FROM public.create_parent_reward_v2(v_child, 'A gift', 114);
  SELECT * INTO v_ordinary FROM public.create_parent_reward(v_child, 'Ordinary gift');
  PERFORM pg_temp.phase2_assert(v_ordinary.milestone_surah_id IS NULL, 'v1 reward remains ordinary');
  PERFORM pg_temp.phase2_error(
    format('SELECT public.unlock_parent_reward_by_milestone(%s)', v_reward.id),
    'Not authorized for reward');

  SELECT * INTO v_message FROM public.send_kids_encouragement(v_child, 'proud', 'star_reward', v_request);
  v_ids := array_append(v_ids, v_message.id);
  SELECT * INTO v_retry FROM public.send_kids_encouragement(v_child, 'proud', 'star_reward', v_request);
  PERFORM pg_temp.phase2_assert(v_message.id = v_retry.id
    AND v_message.created_at = v_retry.created_at, 'retry returns original receipt');
  PERFORM pg_temp.phase2_error(format(
    'SELECT public.send_kids_encouragement(%L,%L,%L,%L)', v_child, 'well_done', 'star_reward', v_request),
    'Encouragement request mismatch');
  FOR i IN 2..10 LOOP
    SELECT * INTO v_message FROM public.send_kids_encouragement(v_child, 'well_done',
      'talia_encourage', pg_catalog.gen_random_uuid());
    v_ids := array_append(v_ids, v_message.id);
  END LOOP;
  PERFORM pg_temp.phase2_error(format(
    'SELECT public.send_kids_encouragement(%L,%L,%L,%L)', v_child, 'proud', 'star_reward', pg_catalog.gen_random_uuid()),
    'Encouragement daily limit reached');
  SELECT * INTO v_retry FROM public.send_kids_encouragement(v_child, 'proud', 'star_reward', v_request);
  PERFORM pg_temp.phase2_assert(v_retry.id = v_ids[1], 'retry after limit is free');
  PERFORM pg_temp.phase2_assert(public.mark_kids_encouragements_seen(v_ids) = 0, 'parent cannot mark child seen');

  PERFORM set_config('request.jwt.claim.sub', v_child::TEXT, TRUE);
  PERFORM pg_temp.phase2_error(format(
    'SELECT public.compare_and_swap_child_policy_v2(%L,3,false,3,true,null,1,1,1)', v_child),
    'Guardian authorization required');
  v_policy := public.compare_and_swap_child_policy(v_child, 3, TRUE, 3, TRUE, NULL);
  PERFORM pg_temp.phase2_assert((v_policy->>'applied')::BOOLEAN, 'child v1 still works');
  SELECT * INTO v_reward FROM public.unlock_parent_reward_by_milestone(v_reward.id);
  v_time := v_reward.unlocked_at;
  SELECT * INTO v_reward FROM public.unlock_parent_reward_by_milestone(v_reward.id);
  PERFORM pg_temp.phase2_assert(v_reward.status = 'unlocked' AND v_reward.unlocked_at = v_time,
    'milestone unlock is idempotent');
  PERFORM pg_temp.phase2_error(format(
    'SELECT public.unlock_parent_reward_by_milestone(%s)', v_ordinary.id), 'Reward has no milestone');
  SELECT * INTO v_reward FROM public.request_parent_reward(v_reward.id);
  SELECT * INTO v_reward FROM public.unlock_parent_reward_by_milestone(v_reward.id);
  PERFORM pg_temp.phase2_assert(v_reward.status = 'requested', 'unlock cannot bypass hand-over approval');
  PERFORM pg_temp.phase2_assert(public.mark_kids_encouragements_seen(v_ids) = 10, 'child acknowledges batch');
  PERFORM pg_temp.phase2_assert(public.mark_kids_encouragements_seen(v_ids) = 0, 'seen retry changes nothing');
  PERFORM pg_temp.phase2_error('SELECT public.mark_kids_encouragements_seen(ARRAY[NULL]::BIGINT[])',
    'Invalid encouragement ids');
  PERFORM pg_temp.phase2_assert((SELECT count(DISTINCT seen_at) = 1
    FROM public.kids_encouragements WHERE id = ANY(v_ids)), 'one batch timestamp');

  PERFORM set_config('request.jwt.claim.sub', '31000000-0000-0000-0000-000000000002', TRUE);
  PERFORM pg_temp.phase2_error(format(
    'SELECT public.send_kids_encouragement(%L,%L,%L,%L)', v_child, 'proud', 'star_reward', v_request),
    'Child link is not active');
END;
$$;

-- Exercise actual read/write role permissions rather than owner-bypassed RLS.
SELECT set_config('request.jwt.claim.sub', '31000000-0000-0000-0000-000000000002', TRUE);
SET LOCAL ROLE authenticated;
SELECT pg_temp.phase2_assert((SELECT count(*) = 0 FROM public.kids_encouragements),
  'unrelated authenticated caller sees no encouragements');
RESET ROLE;
SELECT set_config('request.jwt.claim.sub', '32000000-0000-0000-0000-000000000001', TRUE);
SET LOCAL ROLE authenticated;
SELECT pg_temp.phase2_assert((SELECT count(*) = 10 FROM public.kids_encouragements),
  'linked child reads own originating messages');
RESET ROLE;
UPDATE public.parent_child_links SET status = 'revoked', revoked_at = NOW()
  WHERE child_user_id = '32000000-0000-0000-0000-000000000001';
SET LOCAL ROLE authenticated;
SELECT pg_temp.phase2_assert((SELECT count(*) = 0 FROM public.kids_encouragements),
  'revocation hides prior originating messages');
RESET ROLE;
INSERT INTO public.parent_child_links(parent_user_id, child_user_id) VALUES
  ('31000000-0000-0000-0000-000000000002', '32000000-0000-0000-0000-000000000001');
SELECT set_config('request.jwt.claim.sub', '31000000-0000-0000-0000-000000000002', TRUE);
SELECT pg_temp.phase2_error(
  $$SELECT public.send_kids_encouragement('32000000-0000-0000-0000-000000000001',
    'proud', 'star_reward', '33000000-0000-0000-0000-000000000099')$$,
  'Encouragement daily limit reached');
SELECT set_config('request.jwt.claim.sub', '', TRUE);
SELECT pg_temp.phase2_error(
  $$SELECT public.send_kids_encouragement('32000000-0000-0000-0000-000000000001',
    'proud', 'star_reward', '33000000-0000-0000-0000-000000000099')$$,
  'Not authenticated');
ROLLBACK;
