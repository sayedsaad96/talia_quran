-- Group khatmah self-service eligibility (phase 4 L5).
-- An authenticated, non-anonymous account with a live session whose saved
-- memorization path is adult, and which has never been a linked child, may
-- grant itself eligibility. Self-grants use policy_version 2 and are
-- re-checked live on every action and read, so a later child link or a
-- switch to the child path withdraws them. Rows written by trusted
-- provisioning (any other version) are untouched: a manual grant stays and a
-- manual denial is never overturned by this request.
-- Limit accepted by the owner: the adult path is self-declared by the
-- account; an unlinked child account cannot be told apart server-side.

CREATE OR REPLACE FUNCTION private.group_khatmah_self_policy_holds(p_user uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = p_user AND p.selected_path = 'adult')
    AND NOT EXISTS (
      SELECT 1 FROM public.parent_child_links l WHERE l.child_user_id = p_user);
$$;
REVOKE ALL ON FUNCTION private.group_khatmah_self_policy_holds(uuid)
  FROM PUBLIC, anon, authenticated, service_role;
-- No client grant: only the definer functions below call it.

-- Same body as 20261023010001 plus the live re-check of self-grants.
CREATE OR REPLACE FUNCTION private.group_khatmah_can_read(p_group uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT auth.uid() IS NOT NULL
    AND COALESCE((auth.jwt()->>'is_anonymous')::boolean,false) = false
    AND EXISTS (SELECT 1 FROM auth.users u WHERE u.id = auth.uid())
    AND EXISTS (SELECT 1 FROM auth.sessions s
      WHERE s.id = NULLIF(auth.jwt()->>'session_id','')::uuid
        AND s.user_id = auth.uid())
    AND EXISTS (SELECT 1 FROM private.group_khatmah_eligibility e
      WHERE e.user_id = auth.uid() AND e.eligible
        AND (e.policy_version <> 2
          OR private.group_khatmah_self_policy_holds(auth.uid())))
    AND EXISTS (SELECT 1 FROM public.group_khatmah_member m
      WHERE m.group_id = p_group AND m.user_id = auth.uid() AND m.left_at IS NULL);
$$;

-- Same contract as 20261023010001; self-grants must still hold right now.
CREATE OR REPLACE FUNCTION private.group_khatmah_adult(p_actor uuid)
RETURNS boolean LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_allowed boolean;
  v_version integer;
BEGIN
  SELECT e.eligible, e.policy_version INTO v_allowed, v_version
    FROM private.group_khatmah_eligibility e
    WHERE e.user_id = p_actor FOR UPDATE;
  IF NOT COALESCE(v_allowed,false) THEN RETURN false; END IF;
  IF v_version = 2 THEN
    RETURN private.group_khatmah_self_policy_holds(p_actor);
  END IF;
  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION private.group_khatmah_self_eligibility()
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_actor uuid;
  v_existing boolean;
  v_version integer;
BEGIN
  -- Raises group_session_required and takes the same actor lock as
  -- provisioning and deletion, so concurrent requests serialize.
  v_actor := private.group_khatmah_actor();
  SELECT e.eligible, e.policy_version INTO v_existing, v_version
    FROM private.group_khatmah_eligibility e
    WHERE e.user_id = v_actor FOR UPDATE;
  IF FOUND THEN
    -- A self-grant answers with its live status; any other row is final.
    IF v_version = 2 THEN
      RETURN pg_catalog.jsonb_build_object('eligible',
        v_existing AND private.group_khatmah_self_policy_holds(v_actor));
    END IF;
    RETURN pg_catalog.jsonb_build_object('eligible', v_existing);
  END IF;
  IF private.group_khatmah_self_policy_holds(v_actor) THEN
    INSERT INTO private.group_khatmah_eligibility(user_id, eligible, policy_version)
      VALUES (v_actor, true, 2);
    RETURN pg_catalog.jsonb_build_object('eligible', true);
  END IF;
  RETURN pg_catalog.jsonb_build_object('eligible', false);
END;
$$;
REVOKE ALL ON FUNCTION private.group_khatmah_self_eligibility()
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.group_khatmah_self_eligibility() TO authenticated;

-- The exposed entry point carries no privilege of its own.
CREATE OR REPLACE FUNCTION public.request_group_khatmah_eligibility()
RETURNS jsonb LANGUAGE sql VOLATILE SECURITY INVOKER SET search_path = '' AS $$
  SELECT private.group_khatmah_self_eligibility();
$$;
REVOKE ALL ON FUNCTION public.request_group_khatmah_eligibility()
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.request_group_khatmah_eligibility() TO authenticated;
