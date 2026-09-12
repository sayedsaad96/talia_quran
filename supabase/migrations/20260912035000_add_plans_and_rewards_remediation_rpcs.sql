-- Remediation migration to ensure revision columns, CAS plan functions,
-- parent rewards functions, and batch kids session log table returns are live.

-- Add revision columns
ALTER TABLE public.daily_plans_cloud
  ADD COLUMN IF NOT EXISTS revision BIGINT NOT NULL DEFAULT 0 CHECK (revision >= 0);
ALTER TABLE public.custom_plans_cloud
  ADD COLUMN IF NOT EXISTS revision BIGINT NOT NULL DEFAULT 0 CHECK (revision >= 0);

REVOKE INSERT, UPDATE, DELETE ON public.daily_plans_cloud, public.custom_plans_cloud
  FROM authenticated;

-- compare_and_swap_daily_plan
CREATE OR REPLACE FUNCTION public.compare_and_swap_daily_plan(
  p_expected_revision BIGINT,
  p_surah_id INTEGER,
  p_generated_at TIMESTAMPTZ,
  p_total_items INTEGER,
  p_completed_count INTEGER,
  p_payload JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
#variable_conflict use_column
DECLARE
  v_uid UUID := auth.uid();
  v_row public.daily_plans_cloud;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_expected_revision < 0 OR p_surah_id NOT BETWEEN 1 AND 114
    OR p_total_items < 0 OR p_completed_count < 0
    OR pg_column_size(COALESCE(p_payload, '{}'::JSONB)) > 20000 THEN
    RAISE EXCEPTION 'Invalid daily plan mutation';
  END IF;

  IF p_expected_revision <> 0 AND NOT EXISTS (
    SELECT 1 FROM public.daily_plans_cloud WHERE user_id = v_uid
  ) THEN
    RETURN jsonb_build_object('status', 'conflict', 'row', NULL);
  END IF;

  INSERT INTO public.daily_plans_cloud (
    user_id, surah_id, generated_at, total_items, completed_count, payload, revision, updated_at
  ) VALUES (
    v_uid, p_surah_id, p_generated_at, p_total_items, p_completed_count,
    COALESCE(p_payload, '{}'::JSONB), p_expected_revision + 1, NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    surah_id = EXCLUDED.surah_id,
    generated_at = EXCLUDED.generated_at,
    total_items = EXCLUDED.total_items,
    completed_count = EXCLUDED.completed_count,
    payload = EXCLUDED.payload,
    revision = EXCLUDED.revision,
    updated_at = NOW()
  WHERE daily_plans_cloud.revision = p_expected_revision
  RETURNING * INTO v_row;
  IF NOT FOUND THEN
    SELECT * INTO v_row FROM public.daily_plans_cloud WHERE user_id = v_uid;
    RETURN jsonb_build_object('status', 'conflict', 'row', to_jsonb(v_row));
  END IF;
  RETURN jsonb_build_object('status', 'acknowledged', 'row', to_jsonb(v_row));
END;
$fn$;

-- compare_and_swap_custom_plan
CREATE OR REPLACE FUNCTION public.compare_and_swap_custom_plan(
  p_expected_revision BIGINT,
  p_payload JSONB,
  p_is_deleted BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
#variable_conflict use_column
DECLARE
  v_uid UUID := auth.uid();
  v_row public.custom_plans_cloud;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_expected_revision < 0 OR pg_column_size(COALESCE(p_payload, '{}'::JSONB)) > 20000 THEN
    RAISE EXCEPTION 'Invalid custom plan mutation';
  END IF;

  IF p_expected_revision <> 0 AND NOT EXISTS (
    SELECT 1 FROM public.custom_plans_cloud WHERE user_id = v_uid
  ) THEN
    RETURN jsonb_build_object('status', 'conflict', 'row', NULL);
  END IF;

  INSERT INTO public.custom_plans_cloud (user_id, payload, deleted_at, revision, updated_at)
  VALUES (
    v_uid, COALESCE(p_payload, '{}'::JSONB),
    CASE WHEN p_is_deleted THEN NOW() ELSE NULL END, p_expected_revision + 1, NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    payload = EXCLUDED.payload,
    deleted_at = EXCLUDED.deleted_at,
    revision = EXCLUDED.revision,
    updated_at = NOW()
  WHERE custom_plans_cloud.revision = p_expected_revision
  RETURNING * INTO v_row;
  IF NOT FOUND THEN
    SELECT * INTO v_row FROM public.custom_plans_cloud WHERE user_id = v_uid;
    RETURN jsonb_build_object('status', 'conflict', 'row', to_jsonb(v_row));
  END IF;
  RETURN jsonb_build_object('status', 'acknowledged', 'row', to_jsonb(v_row));
END;
$fn$;

REVOKE ALL ON FUNCTION public.compare_and_swap_daily_plan(BIGINT, INTEGER, TIMESTAMPTZ, INTEGER, INTEGER, JSONB),
  public.compare_and_swap_custom_plan(BIGINT, JSONB, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.compare_and_swap_daily_plan(BIGINT, INTEGER, TIMESTAMPTZ, INTEGER, INTEGER, JSONB),
  public.compare_and_swap_custom_plan(BIGINT, JSONB, BOOLEAN) TO authenticated;

-- parent rewards permissions & RPCs
REVOKE INSERT, UPDATE, DELETE ON public.parent_rewards FROM authenticated;

CREATE OR REPLACE FUNCTION public.create_parent_reward(
  p_child_user_id UUID,
  p_title TEXT
)
RETURNS SETOF public.parent_rewards
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
#variable_conflict use_column
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF char_length(trim(COALESCE(p_title, ''))) NOT BETWEEN 1 AND 120 THEN
    RAISE EXCEPTION 'Invalid reward title';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.parent_child_links
    WHERE parent_user_id = v_uid AND child_user_id = p_child_user_id AND status = 'active'
  ) THEN RAISE EXCEPTION 'Child is not linked to parent'; END IF;

  RETURN QUERY INSERT INTO public.parent_rewards (parent_user_id, child_user_id, title)
    VALUES (v_uid, p_child_user_id, trim(p_title)) RETURNING *;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.unlock_parent_reward(p_reward_id BIGINT)
RETURNS SETOF public.parent_rewards
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
#variable_conflict use_column
DECLARE
  v_uid UUID := auth.uid();
  v_reward public.parent_rewards;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT * INTO v_reward FROM public.parent_rewards WHERE id = p_reward_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Reward not found'; END IF;
  IF v_reward.parent_user_id <> v_uid THEN RAISE EXCEPTION 'Not authorized for reward'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.parent_child_links
    WHERE parent_user_id = v_uid AND child_user_id = v_reward.child_user_id AND status = 'active'
  ) THEN RAISE EXCEPTION 'Child link is not active'; END IF;
  IF v_reward.status <> 'locked' THEN RAISE EXCEPTION 'Invalid reward transition'; END IF;
  RETURN QUERY
  UPDATE public.parent_rewards
  SET status = 'unlocked', unlocked_at = NOW()
  WHERE id = p_reward_id
  RETURNING *;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.claim_parent_reward(p_reward_id BIGINT)
RETURNS SETOF public.parent_rewards
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
#variable_conflict use_column
DECLARE
  v_uid UUID := auth.uid();
  v_reward public.parent_rewards;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT * INTO v_reward FROM public.parent_rewards WHERE id = p_reward_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Reward not found'; END IF;
  IF v_reward.child_user_id <> v_uid THEN RAISE EXCEPTION 'Not authorized for reward'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.parent_child_links
    WHERE parent_user_id = v_reward.parent_user_id AND child_user_id = v_uid AND status = 'active'
  ) THEN RAISE EXCEPTION 'Child link is not active'; END IF;
  IF v_reward.status <> 'unlocked' THEN RAISE EXCEPTION 'Invalid reward transition'; END IF;
  RETURN QUERY
  UPDATE public.parent_rewards
  SET status = 'claimed', claimed_at = NOW()
  WHERE id = p_reward_id
  RETURNING *;
END;
$fn$;

REVOKE ALL ON FUNCTION public.create_parent_reward(UUID, TEXT),
  public.unlock_parent_reward(BIGINT), public.claim_parent_reward(BIGINT)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_parent_reward(UUID, TEXT),
  public.unlock_parent_reward(BIGINT), public.claim_parent_reward(BIGINT)
  TO authenticated;

-- insert_kids_session_logs_batch returning table
DROP FUNCTION IF EXISTS public.insert_kids_session_logs_batch(JSONB);
CREATE FUNCTION public.insert_kids_session_logs_batch(p_data JSONB)
RETURNS TABLE (local_id TEXT, surah_id INTEGER, ayah_number INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
#variable_conflict use_column
DECLARE v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF jsonb_typeof(p_data) <> 'array' OR jsonb_array_length(p_data) > 500 THEN
    RAISE EXCEPTION 'Invalid log batch';
  END IF;

  RETURN QUERY
  WITH input_rows AS (
    SELECT item->>'local_id' AS local_id,
      (item->>'surah_id')::INTEGER AS surah_id,
      (item->>'ayah_number')::INTEGER AS ayah_number,
      (item->>'repeats_completed')::INTEGER AS repeats_completed,
      (item->>'points_earned')::INTEGER AS points_earned,
      (item->>'completed_at')::TIMESTAMPTZ AS completed_at
    FROM jsonb_array_elements(p_data) item
  ), inserted AS (
    INSERT INTO public.kids_session_logs (
      child_user_id, local_id, surah_id, ayah_number, repeats_completed, points_earned, completed_at
    )
    SELECT v_uid, input_rows.local_id, input_rows.surah_id, input_rows.ayah_number, input_rows.repeats_completed, input_rows.points_earned, input_rows.completed_at
    FROM input_rows
    ON CONFLICT (child_user_id, surah_id, ayah_number) DO NOTHING
    RETURNING kids_session_logs.local_id, kids_session_logs.surah_id, kids_session_logs.ayah_number
  )
  SELECT * FROM inserted
  UNION
  SELECT logs.local_id, logs.surah_id, logs.ayah_number
  FROM public.kids_session_logs logs
  JOIN input_rows input USING (local_id, surah_id, ayah_number)
  WHERE logs.child_user_id = v_uid;
END;
$fn$;
REVOKE ALL ON FUNCTION public.insert_kids_session_logs_batch(JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.insert_kids_session_logs_batch(JSONB) TO authenticated;
