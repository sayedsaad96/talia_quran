-- Gift receipt needs guardian approval: the child requests an unlocked gift,
-- the guardian confirms the hand-over. locked -> unlocked -> requested -> claimed.
ALTER TABLE public.parent_rewards ADD COLUMN IF NOT EXISTS requested_at TIMESTAMPTZ;
ALTER TABLE public.parent_rewards DROP CONSTRAINT IF EXISTS parent_rewards_status_check;
ALTER TABLE public.parent_rewards ADD CONSTRAINT parent_rewards_status_check
  CHECK (status IN ('locked', 'unlocked', 'requested', 'claimed'));

-- Guardian unlock stays idempotent once the gift has moved further along.
CREATE OR REPLACE FUNCTION public.unlock_parent_reward(p_reward_id BIGINT)
RETURNS SETOF public.parent_rewards LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE v_uid UUID := auth.uid(); v_reward public.parent_rewards;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT * INTO v_reward FROM public.parent_rewards r WHERE r.id = p_reward_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Reward not found'; END IF;
  IF v_reward.parent_user_id <> v_uid THEN RAISE EXCEPTION 'Not authorized for reward'; END IF;
  PERFORM 1 FROM public.parent_child_links pcl WHERE pcl.parent_user_id = v_uid
    AND pcl.child_user_id = v_reward.child_user_id AND pcl.status = 'active' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Child link is not active'; END IF;
  IF v_reward.status IN ('unlocked', 'requested', 'claimed') THEN
    RETURN NEXT v_reward; RETURN;
  END IF;
  IF v_reward.status <> 'locked' THEN RAISE EXCEPTION 'Invalid reward transition'; END IF;
  RETURN QUERY UPDATE public.parent_rewards r SET status = 'unlocked', unlocked_at = NOW()
    WHERE r.id = p_reward_id RETURNING r.*;
END $$;

-- Child: asks to receive an unlocked gift. A retry after success is a no-op.
CREATE OR REPLACE FUNCTION public.request_parent_reward(p_reward_id BIGINT)
RETURNS SETOF public.parent_rewards LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE v_uid UUID := auth.uid(); v_reward public.parent_rewards;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT * INTO v_reward FROM public.parent_rewards r WHERE r.id = p_reward_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Reward not found'; END IF;
  IF v_reward.child_user_id <> v_uid THEN RAISE EXCEPTION 'Not authorized for reward'; END IF;
  PERFORM 1 FROM public.parent_child_links pcl WHERE pcl.parent_user_id = v_reward.parent_user_id
    AND pcl.child_user_id = v_uid AND pcl.status = 'active' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Child link is not active'; END IF;
  IF v_reward.status IN ('requested', 'claimed') THEN RETURN NEXT v_reward; RETURN; END IF;
  IF v_reward.status <> 'unlocked' THEN RAISE EXCEPTION 'Invalid reward transition'; END IF;
  RETURN QUERY UPDATE public.parent_rewards r SET status = 'requested', requested_at = NOW()
    WHERE r.id = p_reward_id RETURNING r.*;
END $$;

-- Guardian: confirms the gift was handed over. A retry after success is a no-op.
CREATE OR REPLACE FUNCTION public.approve_parent_reward(p_reward_id BIGINT)
RETURNS SETOF public.parent_rewards LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE v_uid UUID := auth.uid(); v_reward public.parent_rewards;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT * INTO v_reward FROM public.parent_rewards r WHERE r.id = p_reward_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Reward not found'; END IF;
  IF v_reward.parent_user_id <> v_uid THEN RAISE EXCEPTION 'Not authorized for reward'; END IF;
  PERFORM 1 FROM public.parent_child_links pcl WHERE pcl.parent_user_id = v_uid
    AND pcl.child_user_id = v_reward.child_user_id AND pcl.status = 'active' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Child link is not active'; END IF;
  IF v_reward.status = 'claimed' THEN RETURN NEXT v_reward; RETURN; END IF;
  IF v_reward.status <> 'requested' THEN RAISE EXCEPTION 'Invalid reward transition'; END IF;
  RETURN QUERY UPDATE public.parent_rewards r SET status = 'claimed', claimed_at = NOW()
    WHERE r.id = p_reward_id RETURNING r.*;
END $$;

-- Older clients may still call claim_parent_reward; it can no longer skip the
-- guardian and now only files the request.
CREATE OR REPLACE FUNCTION public.claim_parent_reward(p_reward_id BIGINT)
RETURNS SETOF public.parent_rewards LANGUAGE sql SECURITY DEFINER
SET search_path = '' AS $$
  SELECT * FROM public.request_parent_reward(p_reward_id);
$$;

REVOKE ALL ON FUNCTION public.unlock_parent_reward(BIGINT),
  public.request_parent_reward(BIGINT), public.approve_parent_reward(BIGINT),
  public.claim_parent_reward(BIGINT)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.unlock_parent_reward(BIGINT),
  public.request_parent_reward(BIGINT), public.approve_parent_reward(BIGINT),
  public.claim_parent_reward(BIGINT)
TO authenticated;
