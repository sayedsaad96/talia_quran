ALTER TABLE public.parent_rewards ADD COLUMN IF NOT EXISTS milestone_surah_id SMALLINT
  CHECK (milestone_surah_id BETWEEN 1 AND 114);

CREATE OR REPLACE FUNCTION public.create_parent_reward_v2(
  p_child_user_id UUID, p_title TEXT, p_milestone_surah_id INTEGER
)
RETURNS SETOF public.parent_rewards LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE v_caller UUID := auth.uid();
BEGIN
  IF v_caller IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_child_user_id IS NULL OR v_caller = p_child_user_id THEN
    RAISE EXCEPTION 'Guardian authorization required';
  END IF;
  IF pg_catalog.char_length(pg_catalog.btrim(COALESCE(p_title, ''))) NOT BETWEEN 1 AND 120
    OR (p_milestone_surah_id IS NOT NULL AND p_milestone_surah_id NOT BETWEEN 1 AND 114) THEN
    RAISE EXCEPTION 'Invalid reward';
  END IF;
  PERFORM 1 FROM public.parent_child_links l WHERE l.parent_user_id = v_caller
    AND l.child_user_id = p_child_user_id AND l.status = 'active' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Child link is not active'; END IF;
  RETURN QUERY INSERT INTO public.parent_rewards (
    parent_user_id, child_user_id, title, milestone_surah_id
  ) VALUES (v_caller, p_child_user_id, pg_catalog.btrim(p_title),
    p_milestone_surah_id::SMALLINT) RETURNING *;
END;
$$;

-- A child completion signal authorizes this transition; the server does not
-- claim to verify memorization. Guardian approval of hand-over stays separate.
CREATE OR REPLACE FUNCTION public.unlock_parent_reward_by_milestone(p_reward_id BIGINT)
RETURNS SETOF public.parent_rewards LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE v_caller UUID := auth.uid(); v_reward public.parent_rewards;
BEGIN
  IF v_caller IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT * INTO v_reward FROM public.parent_rewards r
    WHERE r.id = p_reward_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Reward not found'; END IF;
  IF v_reward.child_user_id <> v_caller THEN
    RAISE EXCEPTION 'Not authorized for reward';
  END IF;
  PERFORM 1 FROM public.parent_child_links l
    WHERE l.parent_user_id = v_reward.parent_user_id AND l.child_user_id = v_caller
      AND l.status = 'active' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Child link is not active'; END IF;
  IF v_reward.milestone_surah_id IS NULL THEN
    RAISE EXCEPTION 'Reward has no milestone';
  END IF;
  IF v_reward.status IN ('unlocked', 'requested', 'claimed') THEN
    RETURN NEXT v_reward; RETURN;
  END IF;
  IF v_reward.status <> 'locked' THEN RAISE EXCEPTION 'Invalid reward transition'; END IF;
  RETURN QUERY UPDATE public.parent_rewards r SET status = 'unlocked',
    unlocked_at = pg_catalog.clock_timestamp() WHERE r.id = p_reward_id RETURNING r.*;
END;
$$;

REVOKE ALL ON FUNCTION public.create_parent_reward_v2(UUID, TEXT, INTEGER),
  public.unlock_parent_reward_by_milestone(BIGINT)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.create_parent_reward_v2(UUID, TEXT, INTEGER),
  public.unlock_parent_reward_by_milestone(BIGINT) TO authenticated;
