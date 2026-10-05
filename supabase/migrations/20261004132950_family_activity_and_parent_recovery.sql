-- Additive family read model. Existing account-wide aggregates are untouched.
-- Serialize gift transitions and tolerate a successful network retry.
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
  IF v_reward.status IN ('unlocked', 'claimed') THEN RETURN NEXT v_reward; RETURN; END IF;
  IF v_reward.status <> 'locked' THEN RAISE EXCEPTION 'Invalid reward transition'; END IF;
  RETURN QUERY UPDATE public.parent_rewards r SET status = 'unlocked', unlocked_at = NOW()
    WHERE r.id = p_reward_id RETURNING r.*;
END $$;
CREATE OR REPLACE FUNCTION public.claim_parent_reward(p_reward_id BIGINT)
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
  IF v_reward.status = 'claimed' THEN RETURN NEXT v_reward; RETURN; END IF;
  IF v_reward.status <> 'unlocked' THEN RAISE EXCEPTION 'Invalid reward transition'; END IF;
  RETURN QUERY UPDATE public.parent_rewards r SET status = 'claimed', claimed_at = NOW()
    WHERE r.id = p_reward_id RETURNING r.*;
END $$;
REVOKE ALL ON FUNCTION public.unlock_parent_reward(BIGINT), public.claim_parent_reward(BIGINT)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.unlock_parent_reward(BIGINT), public.claim_parent_reward(BIGINT)
TO authenticated;

CREATE TABLE public.family_child_activity_snapshots (
  child_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id UUID NOT NULL,
  revision BIGINT NOT NULL CHECK (revision >= 0),
  snapshot JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (child_user_id, device_id)
);
ALTER TABLE public.family_child_activity_snapshots ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.family_child_activity_snapshots FROM anon, authenticated;
GRANT SELECT ON public.family_child_activity_snapshots TO authenticated;
CREATE POLICY family_activity_read ON public.family_child_activity_snapshots
FOR SELECT TO authenticated USING (
  child_user_id = (SELECT auth.uid()) OR EXISTS (
    SELECT 1 FROM public.parent_child_links pcl
    WHERE pcl.parent_user_id = (SELECT auth.uid())
      AND pcl.child_user_id = family_child_activity_snapshots.child_user_id
      AND pcl.status = 'active'
  )
);

CREATE FUNCTION public.publish_child_family_activity(
  p_device_id UUID, p_revision BIGINT, p_snapshot JSONB
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_key TEXT;
  v_event JSONB;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.profiles p
      WHERE p.id = v_uid AND p.selected_path = 'child') THEN
    RAISE EXCEPTION 'Child account required';
  END IF;
  IF p_device_id IS NULL OR p_revision IS NULL OR p_revision < 0
      OR p_snapshot IS NULL OR jsonb_typeof(p_snapshot) <> 'object'
      OR octet_length(p_snapshot::TEXT) > 131072 THEN
    RAISE EXCEPTION 'Invalid family activity';
  END IF;
  FOREACH v_key IN ARRAY ARRAY['read_pages_count', 'total_xp',
      'current_streak', 'longest_streak', 'active_days_last_30',
      'today_activity_count', 'today_read_pages_count'] LOOP
    IF NOT p_snapshot ? v_key OR jsonb_typeof(p_snapshot -> v_key) <> 'number'
        OR (p_snapshot ->> v_key) !~ '^[0-9]{1,10}$' THEN
      RAISE EXCEPTION 'Invalid family activity';
    END IF;
  END LOOP;
  IF (p_snapshot ->> 'read_pages_count')::BIGINT > 604
      OR (p_snapshot ->> 'today_read_pages_count')::BIGINT > 604
      OR (p_snapshot ->> 'active_days_last_30')::BIGINT > 30
      OR COALESCE(p_snapshot ->> 'day_key', '') !~ '^\d{4}-\d{2}-\d{2}$'
      OR COALESCE(jsonb_typeof(p_snapshot -> 'activities'), '') <> 'array' THEN
    RAISE EXCEPTION 'Invalid family activity';
  END IF;
  IF jsonb_array_length(p_snapshot -> 'activities') > 100 THEN
    RAISE EXCEPTION 'Invalid family activity';
  END IF;
  FOR v_event IN SELECT value FROM jsonb_array_elements(p_snapshot -> 'activities') LOOP
    IF jsonb_typeof(v_event) <> 'object'
        OR COALESCE(jsonb_typeof(v_event->'at'), '') <> 'string'
        OR COALESCE(v_event->>'at', '') !~ '^\d{4}-\d{2}-\d{2}T'
        OR COALESCE(v_event->>'kind', '') NOT IN ('reading','memorize','review','khatmah')
        OR COALESCE(jsonb_typeof(v_event->'key'), '') <> 'string' THEN
      RAISE EXCEPTION 'Invalid family activity';
    END IF;
    BEGIN
      PERFORM (v_event->>'at')::TIMESTAMPTZ;
    EXCEPTION WHEN OTHERS THEN RAISE EXCEPTION 'Invalid family activity';
    END;
    FOREACH v_key IN ARRAY ARRAY['surah','start','end','page'] LOOP
      IF v_event ? v_key AND v_event->v_key <> 'null'::JSONB
          AND (jsonb_typeof(v_event->v_key) <> 'number'
            OR (v_event->>v_key) !~ '^[0-9]{1,10}$') THEN
        RAISE EXCEPTION 'Invalid family activity';
      END IF;
    END LOOP;
  END LOOP;
  IF p_snapshot ? 'certificates' THEN
    IF jsonb_typeof(p_snapshot->'certificates') <> 'array' THEN
      RAISE EXCEPTION 'Invalid family activity';
    END IF;
    IF jsonb_array_length(p_snapshot->'certificates') > 100 THEN
      RAISE EXCEPTION 'Invalid family activity';
    END IF;
    FOR v_event IN SELECT value FROM jsonb_array_elements(p_snapshot->'certificates') LOOP
      IF jsonb_typeof(v_event) <> 'object'
          OR COALESCE(jsonb_typeof(v_event->'cert_id'), '') <> 'string'
          OR COALESCE(jsonb_typeof(v_event->'title_ar'), '') <> 'string'
          OR COALESCE(jsonb_typeof(v_event->'cert_type'), '') <> 'string'
          OR COALESCE(jsonb_typeof(v_event->'earned_at'), '') <> 'string' THEN
        RAISE EXCEPTION 'Invalid family activity';
      END IF;
      BEGIN
        PERFORM (v_event->>'earned_at')::TIMESTAMPTZ;
      EXCEPTION WHEN OTHERS THEN RAISE EXCEPTION 'Invalid family activity';
      END;
    END LOOP;
  END IF;
  INSERT INTO public.family_child_activity_snapshots AS current
    (child_user_id, device_id, revision, snapshot)
  VALUES (v_uid, p_device_id, p_revision, p_snapshot)
  ON CONFLICT (child_user_id, device_id) DO UPDATE
  SET revision = EXCLUDED.revision, snapshot = EXCLUDED.snapshot,
      updated_at = NOW()
  WHERE EXCLUDED.revision > current.revision;
END;
$$;
REVOKE ALL ON FUNCTION public.publish_child_family_activity(UUID,BIGINT,JSONB)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.publish_child_family_activity(UUID,BIGINT,JSONB)
TO authenticated;

-- A guardian approves exactly one requesting child device, never its password.
CREATE TABLE public.parent_pin_recovery_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id UUID NOT NULL,
  approved_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  code_hash BYTEA,
  attempts INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '10 minutes',
  consumed_at TIMESTAMPTZ,
  UNIQUE (child_user_id, device_id)
);
ALTER TABLE public.parent_pin_recovery_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.parent_pin_recovery_requests FROM PUBLIC, anon, authenticated;

CREATE FUNCTION public.request_parent_pin_recovery(p_device_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_request public.parent_pin_recovery_requests;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_device_id IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.profiles p WHERE p.id = v_uid
        AND p.selected_path = 'child') THEN
    RAISE EXCEPTION 'Child account required';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.parent_child_links pcl
      WHERE pcl.child_user_id = v_uid AND pcl.status = 'active') THEN
    RAISE EXCEPTION 'No active guardian link';
  END IF;
  INSERT INTO public.parent_pin_recovery_requests AS current
    (child_user_id, device_id) VALUES (v_uid, p_device_id)
  ON CONFLICT (child_user_id, device_id) DO UPDATE
    SET id = gen_random_uuid(), approved_by = NULL, code_hash = NULL,
      attempts = 0, created_at = NOW(),
      expires_at = NOW() + INTERVAL '10 minutes', consumed_at = NULL
    WHERE current.expires_at <= NOW() OR current.consumed_at IS NOT NULL;
  SELECT * INTO v_request FROM public.parent_pin_recovery_requests r
    WHERE r.child_user_id = v_uid AND r.device_id = p_device_id;
  RETURN jsonb_build_object('challenge_id', v_request.id,
    'expires_at', v_request.expires_at);
END;
$$;

CREATE FUNCTION public.get_child_pin_recovery_requests(p_child_user_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.parent_child_links pcl
      JOIN public.profiles p ON p.id = pcl.parent_user_id
      WHERE pcl.parent_user_id = v_uid AND pcl.child_user_id = p_child_user_id
        AND pcl.status = 'active' AND p.selected_path = 'adult') THEN
    RAISE EXCEPTION 'No active guardian link';
  END IF;
  RETURN COALESCE((SELECT jsonb_agg(jsonb_build_object(
      'challenge_id', r.id, 'created_at', r.created_at,
      'expires_at', r.expires_at)) FROM public.parent_pin_recovery_requests r
    WHERE r.child_user_id = p_child_user_id AND r.expires_at > NOW()
      AND r.consumed_at IS NULL AND r.attempts < 5), '[]'::JSONB);
END;
$$;

CREATE FUNCTION public.approve_parent_pin_recovery(p_challenge_id UUID)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_request public.parent_pin_recovery_requests;
  v_code TEXT;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT * INTO v_request FROM public.parent_pin_recovery_requests r
    WHERE r.id = p_challenge_id FOR UPDATE;
  IF NOT FOUND OR v_request.consumed_at IS NOT NULL
      OR v_request.expires_at <= NOW() OR v_request.attempts >= 5 THEN
    RAISE EXCEPTION 'Recovery request unavailable';
  END IF;
  PERFORM 1 FROM public.parent_child_links pcl
    JOIN public.profiles p ON p.id = pcl.parent_user_id
    WHERE pcl.parent_user_id = v_uid
      AND pcl.child_user_id = v_request.child_user_id
      AND pcl.status = 'active' AND p.selected_path = 'adult'
    FOR UPDATE OF pcl;
  IF NOT FOUND THEN RAISE EXCEPTION 'No active guardian link'; END IF;
  v_code := upper(encode(extensions.gen_random_bytes(6), 'hex'));
  UPDATE public.parent_pin_recovery_requests r
    SET approved_by = v_uid,
        code_hash = extensions.digest(v_code, 'sha256'), attempts = 0
    WHERE r.id = v_request.id;
  RETURN v_code;
END;
$$;

CREATE FUNCTION public.consume_parent_pin_recovery(
  p_challenge_id UUID, p_device_id UUID, p_code TEXT
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_request public.parent_pin_recovery_requests;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT * INTO v_request FROM public.parent_pin_recovery_requests r
    WHERE r.id = p_challenge_id AND r.child_user_id = v_uid
      AND r.device_id = p_device_id FOR UPDATE;
  IF NOT FOUND OR v_request.consumed_at IS NOT NULL
      OR v_request.expires_at <= NOW() OR v_request.attempts >= 5
      OR v_request.approved_by IS NULL OR v_request.code_hash IS NULL THEN
    RETURN FALSE;
  END IF;
  PERFORM 1 FROM public.parent_child_links pcl
    WHERE pcl.parent_user_id = v_request.approved_by
      AND pcl.child_user_id = v_uid AND pcl.status = 'active'
    FOR UPDATE;
  IF NOT FOUND THEN RETURN FALSE; END IF;
  IF v_request.code_hash <> extensions.digest(upper(trim(p_code)), 'sha256')
      OR p_code IS NULL THEN
    UPDATE public.parent_pin_recovery_requests r
      SET attempts = attempts + 1 WHERE r.id = v_request.id;
    RETURN FALSE;
  END IF;
  UPDATE public.parent_pin_recovery_requests r
    SET consumed_at = NOW(), code_hash = NULL WHERE r.id = v_request.id;
  RETURN TRUE;
END;
$$;
REVOKE ALL ON FUNCTION public.request_parent_pin_recovery(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_child_pin_recovery_requests(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.approve_parent_pin_recovery(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.consume_parent_pin_recovery(UUID,UUID,TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.request_parent_pin_recovery(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_child_pin_recovery_requests(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.approve_parent_pin_recovery(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.consume_parent_pin_recovery(UUID,UUID,TEXT) TO authenticated;

-- Replace only the read-side RPC; retain its signature for existing clients.
CREATE OR REPLACE FUNCTION public.get_remote_children_dashboard()
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_result JSONB := '[]'::JSONB;
  v_child RECORD;
  v_day_start TIMESTAMPTZ := date_trunc('day', NOW() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC';
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  FOR v_child IN
    SELECT pcl.child_user_id, p.display_name, p.child_nickname, p.age
    FROM public.parent_child_links pcl JOIN public.profiles p ON p.id = pcl.child_user_id
    WHERE pcl.parent_user_id = v_uid AND pcl.status = 'active'
  LOOP
    v_result := v_result || jsonb_build_array(jsonb_build_object(
      'child_user_id', v_child.child_user_id,
      'display_name', COALESCE(v_child.child_nickname, v_child.display_name, 'طفل تالية'),
      'child_nickname', v_child.child_nickname, 'age', v_child.age,
      'progress', (SELECT to_jsonb(kpc) FROM public.kids_progress_cloud kpc
        WHERE kpc.child_user_id = v_child.child_user_id),
      'today_points', (SELECT COALESCE(SUM(l.points_earned), 0) FROM public.kids_session_logs l
        WHERE l.child_user_id = v_child.child_user_id AND l.completed_at >= v_day_start
          AND l.completed_at < v_day_start + INTERVAL '1 day'),
      'today_sessions', (SELECT COUNT(*) FROM public.kids_session_logs l
        WHERE l.child_user_id = v_child.child_user_id AND l.completed_at >= v_day_start
          AND l.completed_at < v_day_start + INTERVAL '1 day'),
      'logs', COALESCE((SELECT jsonb_agg(to_jsonb(l)) FROM (
        SELECT local_id, surah_id, ayah_number, repeats_completed, points_earned, completed_at
        FROM public.kids_session_logs WHERE child_user_id = v_child.child_user_id
        ORDER BY completed_at DESC LIMIT 30) l), '[]'::JSONB),
      'rewards', COALESCE((SELECT jsonb_agg(to_jsonb(r)) FROM (
        SELECT id, title, status, created_at, unlocked_at, claimed_at
        FROM public.parent_rewards WHERE child_user_id = v_child.child_user_id
        ORDER BY created_at DESC LIMIT 50) r), '[]'::JSONB),
      'review_summary', (SELECT jsonb_build_object(
        'review_count', COALESCE(SUM(rr.total_reviews), 0),
        'tracked_count', COUNT(*),
        'memorized_count', COUNT(*) FILTER (WHERE rr.strength_level >= 6),
        'overdue_count', COUNT(*) FILTER (WHERE rr.next_review_date <= NOW() AND rr.strength_level > 0),
        'latest_review_at', MAX(rr.updated_at),
        'next_review_at', MIN(rr.next_review_date) FILTER (WHERE rr.next_review_date > NOW()),
        'last_surah_id', (SELECT r.surah_id FROM public.ayah_review_records_cloud r
          WHERE r.user_id = v_child.child_user_id AND r.audience = 'kids'
          ORDER BY r.last_reviewed_at DESC NULLS LAST LIMIT 1),
        'last_ayah_number', (SELECT r.ayah_number FROM public.ayah_review_records_cloud r
          WHERE r.user_id = v_child.child_user_id AND r.audience = 'kids'
          ORDER BY r.last_reviewed_at DESC NULLS LAST LIMIT 1))
        FROM public.ayah_review_records_cloud rr
        WHERE rr.user_id = v_child.child_user_id AND rr.audience = 'kids'),
      'daily_plan', NULL,
      'certificates', COALESCE((SELECT s.snapshot -> 'certificates'
        FROM public.family_child_activity_snapshots s
        WHERE s.child_user_id = v_child.child_user_id
        ORDER BY s.updated_at DESC, s.device_id LIMIT 1), '[]'::JSONB),
      'streak', NULL, 'activities', '[]'::JSONB,
      'activity_snapshot', (SELECT jsonb_build_object('device_id', s.device_id,
          'updated_at', s.updated_at, 'revision', s.revision, 'snapshot', s.snapshot)
        FROM public.family_child_activity_snapshots s
        WHERE s.child_user_id = v_child.child_user_id
        ORDER BY s.updated_at DESC, s.device_id LIMIT 1)
    ));
  END LOOP;
  RETURN v_result;
END;
$$;
REVOKE ALL ON FUNCTION public.get_remote_children_dashboard() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_remote_children_dashboard() TO authenticated;
