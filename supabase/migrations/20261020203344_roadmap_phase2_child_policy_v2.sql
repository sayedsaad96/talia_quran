-- Additive guardian-owned planning hints. v1 keeps its explicit column list,
-- preserving these values while sharing the same optimistic version counter.
ALTER TABLE public.kids_child_policies
  ADD COLUMN IF NOT EXISTS next_surah_id SMALLINT CHECK (next_surah_id BETWEEN 1 AND 114),
  ADD COLUMN IF NOT EXISTS ayahs_per_session SMALLINT CHECK (ayahs_per_session BETWEEN 1 AND 10),
  ADD COLUMN IF NOT EXISTS practice_days SMALLINT CHECK (practice_days BETWEEN 0 AND 127);
-- practice_days bits 0..6 are Monday..Sunday; NULL means no remote override.

CREATE OR REPLACE FUNCTION public.compare_and_swap_child_policy_v2(
  p_child_user_id UUID,
  p_expected_version BIGINT,
  p_reduce_motion BOOLEAN,
  p_max_daily_suggestions INTEGER,
  p_home_missions_enabled BOOLEAN,
  p_session_goal_minutes INTEGER,
  p_next_surah_id INTEGER,
  p_ayahs_per_session INTEGER,
  p_practice_days INTEGER
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_row public.kids_child_policies;
BEGIN
  IF v_caller IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_child_user_id IS NULL OR v_caller = p_child_user_id THEN
    RAISE EXCEPTION 'Guardian authorization required';
  END IF;
  PERFORM 1 FROM public.parent_child_links l
    WHERE l.parent_user_id = v_caller AND l.child_user_id = p_child_user_id
      AND l.status = 'active' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'No active guardian link for this child'; END IF;
  IF p_expected_version IS NULL OR p_expected_version < 0
    OR p_reduce_motion IS NULL OR p_home_missions_enabled IS NULL
    OR p_max_daily_suggestions IS NULL OR p_max_daily_suggestions NOT BETWEEN 1 AND 3
    OR (p_session_goal_minutes IS NOT NULL AND p_session_goal_minutes NOT BETWEEN 1 AND 60)
    OR (p_next_surah_id IS NOT NULL AND p_next_surah_id NOT BETWEEN 1 AND 114)
    OR (p_ayahs_per_session IS NOT NULL AND p_ayahs_per_session NOT BETWEEN 1 AND 10)
    OR (p_practice_days IS NOT NULL AND p_practice_days NOT BETWEEN 0 AND 127) THEN
    RAISE EXCEPTION 'Invalid child policy';
  END IF;
  IF p_expected_version = 0 THEN
    INSERT INTO public.kids_child_policies AS p (
      child_user_id, reduce_motion, max_daily_suggestions, home_missions_enabled,
      session_goal_minutes, next_surah_id, ayahs_per_session, practice_days,
      version, updated_by, updated_at
    ) VALUES (
      p_child_user_id, p_reduce_motion, p_max_daily_suggestions::SMALLINT,
      p_home_missions_enabled, p_session_goal_minutes::SMALLINT,
      p_next_surah_id::SMALLINT, p_ayahs_per_session::SMALLINT,
      p_practice_days::SMALLINT, 1, v_caller, pg_catalog.clock_timestamp()
    ) ON CONFLICT (child_user_id) DO NOTHING RETURNING p.* INTO v_row;
  ELSE
    UPDATE public.kids_child_policies p SET
      reduce_motion = p_reduce_motion,
      max_daily_suggestions = p_max_daily_suggestions::SMALLINT,
      home_missions_enabled = p_home_missions_enabled,
      session_goal_minutes = p_session_goal_minutes::SMALLINT,
      next_surah_id = p_next_surah_id::SMALLINT,
      ayahs_per_session = p_ayahs_per_session::SMALLINT,
      practice_days = p_practice_days::SMALLINT,
      version = p.version + 1, updated_by = v_caller,
      updated_at = pg_catalog.clock_timestamp()
    WHERE p.child_user_id = p_child_user_id AND p.version = p_expected_version
    RETURNING p.* INTO v_row;
  END IF;
  IF v_row.child_user_id IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('applied', TRUE, 'version', v_row.version,
      'policy', pg_catalog.to_jsonb(v_row));
  END IF;
  SELECT * INTO v_row FROM public.kids_child_policies p
    WHERE p.child_user_id = p_child_user_id;
  RETURN pg_catalog.jsonb_build_object('applied', FALSE,
    'version', COALESCE(v_row.version, 0), 'policy',
    CASE WHEN v_row.child_user_id IS NULL THEN NULL ELSE pg_catalog.to_jsonb(v_row) END);
END;
$$;
REVOKE ALL ON FUNCTION public.compare_and_swap_child_policy_v2(
  UUID, BIGINT, BOOLEAN, INTEGER, BOOLEAN, INTEGER, INTEGER, INTEGER, INTEGER
) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.compare_and_swap_child_policy_v2(
  UUID, BIGINT, BOOLEAN, INTEGER, BOOLEAN, INTEGER, INTEGER, INTEGER, INTEGER
) TO authenticated;
