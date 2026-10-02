-- Kids Adventure Plan 3: guardian-written home missions and per-child policies.
--
-- 1. `kids_home_missions`: a guardian writes a short real-world mission for a
--    linked child (1-120 chars). Lifecycle: assigned -> reported -> acknowledged.
--    Only the child reports; only the guardian acknowledges ("seen", never
--    "verified").
-- 2. `kids_child_policies`: one row per child with the guardian-controlled
--    limits. Written through a compare-and-swap RPC (optimistic `version`).
--
-- The guardian PIN never leaves the device. Every remote call authorizes
-- through auth.uid() and an ACTIVE row in public.parent_child_links. Direct
-- INSERT/UPDATE/DELETE is revoked; all writes go through the RPCs below.

-- -- 1. Tables ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.kids_home_missions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  parent_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  child_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (char_length(title) BETWEEN 1 AND 120),
  status TEXT NOT NULL DEFAULT 'assigned'
    CHECK (status IN ('assigned', 'reported', 'acknowledged')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reported_at TIMESTAMPTZ,
  acknowledged_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_kids_home_missions_child
  ON public.kids_home_missions (child_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_kids_home_missions_parent
  ON public.kids_home_missions (parent_user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.kids_child_policies (
  child_user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  reduce_motion BOOLEAN NOT NULL DEFAULT FALSE,
  max_daily_suggestions SMALLINT NOT NULL DEFAULT 3
    CHECK (max_daily_suggestions BETWEEN 1 AND 3),
  home_missions_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  session_goal_minutes SMALLINT
    CHECK (session_goal_minutes BETWEEN 1 AND 60),
  version BIGINT NOT NULL DEFAULT 0,
  updated_by UUID,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -- 2. RLS and grants -------------------------------------------------------

ALTER TABLE public.kids_home_missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kids_child_policies ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.kids_home_missions FROM anon;
REVOKE ALL ON public.kids_child_policies FROM anon;
GRANT SELECT ON public.kids_home_missions TO authenticated;
GRANT SELECT ON public.kids_child_policies TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.kids_home_missions FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.kids_child_policies FROM authenticated;

DROP POLICY IF EXISTS kids_home_missions_read ON public.kids_home_missions;
CREATE POLICY kids_home_missions_read ON public.kids_home_missions FOR SELECT TO authenticated USING (
  child_user_id = (SELECT auth.uid())
  OR EXISTS (
    SELECT 1 FROM public.parent_child_links pcl
    WHERE pcl.child_user_id = kids_home_missions.child_user_id
      AND pcl.parent_user_id = (SELECT auth.uid())
      AND pcl.status = 'active'
  )
);

DROP POLICY IF EXISTS kids_child_policies_read ON public.kids_child_policies;
CREATE POLICY kids_child_policies_read ON public.kids_child_policies FOR SELECT TO authenticated USING (
  child_user_id = (SELECT auth.uid())
  OR EXISTS (
    SELECT 1 FROM public.parent_child_links pcl
    WHERE pcl.child_user_id = kids_child_policies.child_user_id
      AND pcl.parent_user_id = (SELECT auth.uid())
      AND pcl.status = 'active'
  )
);

-- -- 3. create_kids_home_mission ---------------------------------------------

CREATE OR REPLACE FUNCTION public.create_kids_home_mission(
  p_child_user_id UUID,
  p_title TEXT
)
RETURNS SETOF public.kids_home_missions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_title TEXT := pg_catalog.btrim(COALESCE(p_title, ''));
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Hold the link row so a concurrent revocation cannot commit between
  -- authorization and the insert.
  PERFORM 1
  FROM public.parent_child_links pcl
  WHERE pcl.parent_user_id = v_caller
    AND pcl.child_user_id = p_child_user_id
    AND pcl.status = 'active'
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No active guardian link for this child';
  END IF;

  IF pg_catalog.char_length(v_title) NOT BETWEEN 1 AND 120 THEN
    RAISE EXCEPTION 'Invalid mission title';
  END IF;

  RETURN QUERY
  INSERT INTO public.kids_home_missions (parent_user_id, child_user_id, title)
  VALUES (v_caller, p_child_user_id, v_title)
  RETURNING *;
END;
$$;

REVOKE ALL ON FUNCTION public.create_kids_home_mission(UUID, TEXT)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.create_kids_home_mission(UUID, TEXT)
  TO authenticated;

-- -- 4. report_kids_home_mission ----------------------------------------------

CREATE OR REPLACE FUNCTION public.report_kids_home_mission(p_mission_id BIGINT)
RETURNS SETOF public.kids_home_missions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_mission public.kids_home_missions;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_mission
  FROM public.kids_home_missions m
  WHERE m.id = p_mission_id
  FOR UPDATE;
  -- Same message for "missing" and "someone else's" so ids are not probeable.
  IF NOT FOUND OR v_mission.child_user_id <> v_caller THEN
    RAISE EXCEPTION 'Mission not found';
  END IF;

  PERFORM 1
  FROM public.parent_child_links pcl
  WHERE pcl.parent_user_id = v_mission.parent_user_id
    AND pcl.child_user_id = v_caller
    AND pcl.status = 'active'
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Child link is not active';
  END IF;

  IF v_mission.status = 'assigned' THEN
    RETURN QUERY
    UPDATE public.kids_home_missions m
    SET status = 'reported', reported_at = NOW()
    WHERE m.id = p_mission_id
    RETURNING *;
  ELSIF v_mission.status IN ('reported', 'acknowledged') THEN
    -- Idempotent: a retried report changes nothing.
    RETURN NEXT v_mission;
  ELSE
    RAISE EXCEPTION 'Invalid mission transition';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.report_kids_home_mission(BIGINT)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.report_kids_home_mission(BIGINT)
  TO authenticated;

-- -- 5. acknowledge_kids_home_mission -----------------------------------------

CREATE OR REPLACE FUNCTION public.acknowledge_kids_home_mission(
  p_mission_id BIGINT
)
RETURNS SETOF public.kids_home_missions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_mission public.kids_home_missions;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_mission
  FROM public.kids_home_missions m
  WHERE m.id = p_mission_id
  FOR UPDATE;
  IF NOT FOUND OR v_mission.parent_user_id <> v_caller THEN
    RAISE EXCEPTION 'Mission not found';
  END IF;

  PERFORM 1
  FROM public.parent_child_links pcl
  WHERE pcl.parent_user_id = v_caller
    AND pcl.child_user_id = v_mission.child_user_id
    AND pcl.status = 'active'
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Child link is not active';
  END IF;

  IF v_mission.status <> 'reported' THEN
    RAISE EXCEPTION 'Invalid mission transition';
  END IF;

  RETURN QUERY
  UPDATE public.kids_home_missions m
  SET status = 'acknowledged', acknowledged_at = NOW()
  WHERE m.id = p_mission_id
  RETURNING *;
END;
$$;

REVOKE ALL ON FUNCTION public.acknowledge_kids_home_mission(BIGINT)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.acknowledge_kids_home_mission(BIGINT)
  TO authenticated;

-- -- 6. compare_and_swap_child_policy -----------------------------------------
-- Returns {"applied": bool, "version": bigint, "policy": row-json}. When not
-- applied, version/policy are the CURRENT server values (no exception), so the
-- client can show the conflict and retry from the fresh row.

CREATE OR REPLACE FUNCTION public.compare_and_swap_child_policy(
  p_child_user_id UUID,
  p_expected_version BIGINT,
  p_reduce_motion BOOLEAN,
  p_max_daily_suggestions INTEGER,
  p_home_missions_enabled BOOLEAN,
  p_session_goal_minutes INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_row public.kids_child_policies;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF v_caller = p_child_user_id THEN
    NULL;
  ELSE
    PERFORM 1
    FROM public.parent_child_links pcl
    WHERE pcl.parent_user_id = v_caller
      AND pcl.child_user_id = p_child_user_id
      AND pcl.status = 'active'
    FOR UPDATE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'No active guardian link for this child';
    END IF;
  END IF;

  IF p_expected_version IS NULL OR p_expected_version < 0 THEN
    RAISE EXCEPTION 'Invalid expected version';
  END IF;
  IF p_reduce_motion IS NULL OR p_home_missions_enabled IS NULL THEN
    RAISE EXCEPTION 'Invalid child policy';
  END IF;
  IF p_max_daily_suggestions IS NULL
    OR p_max_daily_suggestions NOT BETWEEN 1 AND 3 THEN
    RAISE EXCEPTION 'Invalid max daily suggestions';
  END IF;
  IF p_session_goal_minutes IS NOT NULL
    AND p_session_goal_minutes NOT BETWEEN 1 AND 60 THEN
    RAISE EXCEPTION 'Invalid session goal minutes';
  END IF;

  IF p_expected_version = 0 THEN
    INSERT INTO public.kids_child_policies AS p (
      child_user_id, reduce_motion, max_daily_suggestions,
      home_missions_enabled, session_goal_minutes, version,
      updated_by, updated_at
    )
    VALUES (
      p_child_user_id, p_reduce_motion, p_max_daily_suggestions::SMALLINT,
      p_home_missions_enabled, p_session_goal_minutes::SMALLINT, 1,
      v_caller, NOW()
    )
    ON CONFLICT (child_user_id) DO NOTHING
    RETURNING p.* INTO v_row;
  ELSE
    UPDATE public.kids_child_policies p
    SET reduce_motion = p_reduce_motion,
        max_daily_suggestions = p_max_daily_suggestions::SMALLINT,
        home_missions_enabled = p_home_missions_enabled,
        session_goal_minutes = p_session_goal_minutes::SMALLINT,
        version = p.version + 1,
        updated_by = v_caller,
        updated_at = NOW()
    WHERE p.child_user_id = p_child_user_id
      AND p.version = p_expected_version
    RETURNING p.* INTO v_row;
  END IF;

  IF v_row.child_user_id IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object(
      'applied', TRUE,
      'version', v_row.version,
      'policy', pg_catalog.to_jsonb(v_row)
    );
  END IF;

  SELECT * INTO v_row
  FROM public.kids_child_policies p
  WHERE p.child_user_id = p_child_user_id;
  RETURN pg_catalog.jsonb_build_object(
    'applied', FALSE,
    'version', COALESCE(v_row.version, 0),
    'policy', CASE
      WHEN v_row.child_user_id IS NULL THEN NULL
      ELSE pg_catalog.to_jsonb(v_row)
    END
  );
END;
$$;

REVOKE ALL ON FUNCTION public.compare_and_swap_child_policy(UUID, BIGINT, BOOLEAN, INTEGER, BOOLEAN, INTEGER)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.compare_and_swap_child_policy(UUID, BIGINT, BOOLEAN, INTEGER, BOOLEAN, INTEGER)
  TO authenticated;
