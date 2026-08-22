-- Production data-layer remediation.
-- This migration is intentionally imperative: numbered migrations are the
-- only deploy history for Supabase.

-- xp_history is retained: deleting an audit table is neither required for the
-- client contract nor safe in a production reconciliation migration.

-- The identity RPC was referenced by the client but was never deployed.
-- Keep the historical p_updated_at argument for client compatibility, but
-- ignore it: updated_at is exclusively server-managed.
CREATE OR REPLACE FUNCTION public.upsert_memorization_identity(
  p_selected_path TEXT,
  p_guardian_onboarding_status TEXT,
  p_is_parent_guardian BOOLEAN,
  p_child_age INTEGER DEFAULT NULL,
  p_updated_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF p_selected_path NOT IN ('adult', 'child') THEN
    RAISE EXCEPTION 'Invalid selected path';
  END IF;
  IF p_guardian_onboarding_status NOT IN ('required', 'skipped', 'completed') THEN
    RAISE EXCEPTION 'Invalid guardian onboarding status';
  END IF;
  IF p_child_age IS NOT NULL AND (p_child_age < 1 OR p_child_age > 150) THEN
    RAISE EXCEPTION 'Invalid child age';
  END IF;
  IF p_selected_path = 'adult' AND p_child_age IS NOT NULL THEN
    RAISE EXCEPTION 'Adult identity cannot contain child age';
  END IF;

  INSERT INTO public.profiles (
    id, selected_path, guardian_onboarding_status, is_parent_guardian, age, updated_at
  )
  VALUES (
    v_uid, p_selected_path, p_guardian_onboarding_status,
    p_is_parent_guardian, p_child_age, NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    selected_path = EXCLUDED.selected_path,
    guardian_onboarding_status = EXCLUDED.guardian_onboarding_status,
    is_parent_guardian = EXCLUDED.is_parent_guardian,
    age = EXCLUDED.age,
    updated_at = NOW();
END;
$fn$;

REVOKE ALL ON FUNCTION public.upsert_memorization_identity(TEXT, TEXT, BOOLEAN, INTEGER, TIMESTAMPTZ)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.upsert_memorization_identity(TEXT, TEXT, BOOLEAN, INTEGER, TIMESTAMPTZ)
  TO authenticated;

-- Bookmarks are account data. Tombstones make deletes durable across devices.
CREATE TABLE IF NOT EXISTS public.quran_bookmarks_cloud (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  surah_id INTEGER NOT NULL CHECK (surah_id BETWEEN 1 AND 114),
  ayah_number INTEGER NOT NULL CHECK (ayah_number BETWEEN 1 AND 286),
  payload JSONB NOT NULL DEFAULT '{}'::JSONB CHECK (pg_column_size(payload) <= 12000),
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  revision BIGINT NOT NULL DEFAULT 0 CHECK (revision >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, surah_id, ayah_number)
);

CREATE INDEX IF NOT EXISTS idx_quran_bookmarks_cloud_user_updated
  ON public.quran_bookmarks_cloud (user_id, updated_at DESC);

ALTER TABLE public.quran_bookmarks_cloud ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.quran_bookmarks_cloud FROM anon, authenticated;
GRANT SELECT ON public.quran_bookmarks_cloud TO authenticated;

DROP POLICY IF EXISTS quran_bookmarks_cloud_owner_read ON public.quran_bookmarks_cloud;
CREATE POLICY quran_bookmarks_cloud_owner_read
  ON public.quran_bookmarks_cloud FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE OR REPLACE FUNCTION public.upsert_quran_bookmark(
  p_surah_id INTEGER,
  p_ayah_number INTEGER,
  p_payload JSONB,
  p_revision BIGINT,
  p_is_deleted BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (surah_id INTEGER, ayah_number INTEGER, revision BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_surah_id NOT BETWEEN 1 AND 114 OR p_ayah_number NOT BETWEEN 1 AND 286 THEN
    RAISE EXCEPTION 'Invalid verse identity';
  END IF;
  IF p_revision < 1 OR pg_column_size(COALESCE(p_payload, '{}'::JSONB)) > 12000 THEN
    RAISE EXCEPTION 'Invalid bookmark mutation';
  END IF;

  RETURN QUERY
  INSERT INTO public.quran_bookmarks_cloud (
    user_id, surah_id, ayah_number, payload, is_deleted, revision, updated_at, deleted_at
  ) VALUES (
    v_uid, p_surah_id, p_ayah_number, COALESCE(p_payload, '{}'::JSONB),
    p_is_deleted, p_revision, NOW(), CASE WHEN p_is_deleted THEN NOW() ELSE NULL END
  )
  ON CONFLICT (user_id, surah_id, ayah_number) DO UPDATE SET
    payload = EXCLUDED.payload,
    is_deleted = EXCLUDED.is_deleted,
    revision = EXCLUDED.revision,
    updated_at = NOW(),
    deleted_at = CASE WHEN EXCLUDED.is_deleted THEN NOW() ELSE NULL END
  WHERE EXCLUDED.revision > quran_bookmarks_cloud.revision
  RETURNING quran_bookmarks_cloud.surah_id, quran_bookmarks_cloud.ayah_number,
    quran_bookmarks_cloud.revision;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.pull_quran_bookmarks()
RETURNS SETOF public.quran_bookmarks_cloud
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $fn$
  SELECT * FROM public.quran_bookmarks_cloud
  WHERE user_id = auth.uid()
  ORDER BY updated_at ASC, surah_id ASC, ayah_number ASC;
$fn$;

REVOKE ALL ON FUNCTION public.upsert_quran_bookmark(INTEGER, INTEGER, JSONB, BIGINT, BOOLEAN)
  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.pull_quran_bookmarks() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.upsert_quran_bookmark(INTEGER, INTEGER, JSONB, BIGINT, BOOLEAN)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.pull_quran_bookmarks() TO authenticated;

-- Parent rewards are conditional state transitions, never direct client writes.
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

-- Exact batch acknowledgement: a retry acknowledges only the same local ID,
-- never a competing device's row for the same ayah.
DROP FUNCTION IF EXISTS public.insert_kids_session_logs_batch(JSONB);
CREATE FUNCTION public.insert_kids_session_logs_batch(p_data JSONB)
RETURNS TABLE (local_id TEXT, surah_id INTEGER, ayah_number INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
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
    SELECT v_uid, local_id, surah_id, ayah_number, repeats_completed, points_earned, completed_at
    FROM input_rows
    ON CONFLICT (child_user_id, surah_id, ayah_number) DO NOTHING
    RETURNING local_id, surah_id, ayah_number
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

-- Plans use compare-and-swap revisions. A concurrent device update returns the
-- authoritative cloud copy; it never silently overwrites the local draft.
ALTER TABLE public.daily_plans_cloud
  ADD COLUMN IF NOT EXISTS revision BIGINT NOT NULL DEFAULT 0 CHECK (revision >= 0);
ALTER TABLE public.custom_plans_cloud
  ADD COLUMN IF NOT EXISTS revision BIGINT NOT NULL DEFAULT 0 CHECK (revision >= 0);

REVOKE INSERT, UPDATE, DELETE ON public.daily_plans_cloud, public.custom_plans_cloud
  FROM authenticated;

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
