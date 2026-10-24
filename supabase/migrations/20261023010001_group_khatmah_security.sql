-- All feature authority is server owned. private is not an exposed Data API schema.
CREATE OR REPLACE FUNCTION private.group_khatmah_can_read(p_group uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT auth.uid() IS NOT NULL
    AND COALESCE((auth.jwt()->>'is_anonymous')::boolean,false) = false
    AND EXISTS (SELECT 1 FROM auth.users u WHERE u.id = auth.uid())
    AND EXISTS (SELECT 1 FROM auth.sessions s
      WHERE s.id = NULLIF(auth.jwt()->>'session_id','')::uuid
        AND s.user_id = auth.uid())
    AND EXISTS (SELECT 1 FROM private.group_khatmah_eligibility e
      WHERE e.user_id = auth.uid() AND e.eligible)
    AND EXISTS (SELECT 1 FROM public.group_khatmah_member m
      WHERE m.group_id = p_group AND m.user_id = auth.uid() AND m.left_at IS NULL);
$$;
REVOKE ALL ON FUNCTION private.group_khatmah_can_read(uuid)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT EXECUTE ON FUNCTION private.group_khatmah_can_read(uuid) TO authenticated;

DROP POLICY IF EXISTS group_khatmah_member_read ON public.group_khatmah_member;
CREATE POLICY group_khatmah_member_read ON public.group_khatmah_member
  FOR SELECT TO authenticated
  USING (left_at IS NULL AND private.group_khatmah_can_read(group_id));
DROP POLICY IF EXISTS group_khatmah_group_read ON public.group_khatmah;
CREATE POLICY group_khatmah_group_read ON public.group_khatmah
  FOR SELECT TO authenticated USING (private.group_khatmah_can_read(id));
DROP POLICY IF EXISTS group_khatmah_part_read ON public.group_khatmah_part;
CREATE POLICY group_khatmah_part_read ON public.group_khatmah_part
  FOR SELECT TO authenticated USING (private.group_khatmah_can_read(group_id));

CREATE OR REPLACE FUNCTION private.group_khatmah_actor()
RETURNS uuid LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_session uuid;
BEGIN
  IF v_actor IS NULL OR COALESCE((auth.jwt()->>'is_anonymous')::boolean,false) THEN
    RAISE EXCEPTION 'group_session_required';
  END IF;
  -- Same actor lock is used by deletion and trusted eligibility provisioning.
  PERFORM pg_catalog.pg_advisory_xact_lock(7031,pg_catalog.hashtext(v_actor::text));
  v_session := NULLIF(auth.jwt()->>'session_id','')::uuid;
  IF v_session IS NULL OR NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE u.id = v_actor
  ) OR NOT EXISTS (
    SELECT 1 FROM auth.sessions s WHERE s.id = v_session AND s.user_id = v_actor
  ) THEN
    RAISE EXCEPTION 'group_session_required';
  END IF;
  RETURN v_actor;
END;
$$;
REVOKE ALL ON FUNCTION private.group_khatmah_actor()
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.group_khatmah_actor() TO authenticated;

CREATE OR REPLACE FUNCTION private.group_khatmah_adult(p_actor uuid)
RETURNS boolean LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_allowed boolean;
BEGIN
  SELECT e.eligible INTO v_allowed FROM private.group_khatmah_eligibility e
    WHERE e.user_id = p_actor FOR UPDATE;
  RETURN COALESCE(v_allowed,false);
END;
$$;
REVOKE ALL ON FUNCTION private.group_khatmah_adult(uuid)
  FROM PUBLIC, anon, authenticated, service_role;
-- Deliberately no client grant: called by controlled privileged implementations.

-- Privileged provisioning is a database-admin operation, never a client RPC.
-- Revocation takes the actor lock, so in-flight writes serialize before denial.
CREATE OR REPLACE FUNCTION private.group_khatmah_provision(
  p_user uuid,p_eligible boolean,p_policy_version integer)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF p_user IS NULL OR p_eligible IS NULL OR p_policy_version IS NULL
    OR p_policy_version <= 0 THEN RAISE EXCEPTION 'invalid_eligibility'; END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(7031,pg_catalog.hashtext(p_user::text));
  INSERT INTO private.group_khatmah_eligibility(user_id,eligible,policy_version)
    VALUES (p_user,p_eligible,p_policy_version)
  ON CONFLICT (user_id) DO UPDATE SET eligible = EXCLUDED.eligible,
    policy_version = EXCLUDED.policy_version,updated_at = now();
END;
$$;
REVOKE ALL ON FUNCTION private.group_khatmah_provision(uuid,boolean,integer)
  FROM PUBLIC, anon, authenticated, service_role;

-- Only expected denials return JSON; the counter itself commits with the RPC.
CREATE OR REPLACE FUNCTION private.group_khatmah_throttle(p_actor uuid)
RETURNS boolean LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_row private.group_khatmah_join_throttle;
DECLARE v_now timestamptz := pg_catalog.clock_timestamp();
BEGIN
  SELECT * INTO v_row FROM private.group_khatmah_join_throttle
    WHERE user_id = p_actor FOR UPDATE;
  IF NOT FOUND THEN
    INSERT INTO private.group_khatmah_join_throttle
      (user_id,minute_start,minute_count,day_start,day_count)
      VALUES (p_actor,v_now,1,v_now,1);
    RETURN true;
  END IF;
  UPDATE private.group_khatmah_join_throttle SET
    minute_start = CASE WHEN v_now - v_row.minute_start >= interval '1 minute'
      THEN v_now ELSE v_row.minute_start END,
    minute_count = CASE WHEN v_now - v_row.minute_start >= interval '1 minute'
      THEN 1 ELSE v_row.minute_count + 1 END,
    day_start = CASE WHEN v_now - v_row.day_start >= interval '1 day'
      THEN v_now ELSE v_row.day_start END,
    day_count = CASE WHEN v_now - v_row.day_start >= interval '1 day'
      THEN 1 ELSE v_row.day_count + 1 END WHERE user_id = p_actor;
  RETURN (v_now - v_row.minute_start >= interval '1 minute' OR v_row.minute_count < 5)
    AND (v_now - v_row.day_start >= interval '1 day' OR v_row.day_count < 30);
END;
$$;
REVOKE ALL ON FUNCTION private.group_khatmah_throttle(uuid)
  FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.group_khatmah_valid_label(
  p_value text,p_min integer,p_max integer)
RETURNS boolean LANGUAGE sql IMMUTABLE SECURITY INVOKER SET search_path = '' AS $$
  SELECT p_value IS NOT NULL AND p_value = pg_catalog.btrim(p_value)
    AND pg_catalog.char_length(p_value) BETWEEN p_min AND p_max
    AND p_value !~ '[[:cntrl:]]'
    AND pg_catalog.translate(p_value,U&'\202A\202B\202C\202D\202E\2066\2067\2068\2069','') = p_value;
$$;
REVOKE ALL ON FUNCTION private.group_khatmah_valid_label(text,integer,integer)
  FROM PUBLIC, anon, authenticated, service_role;

-- Replay is evaluated after actor/adult guard. A gone receipt wins over payload.
CREATE OR REPLACE FUNCTION private.group_khatmah_replay(
  p_actor uuid,p_kind text,p_operation uuid,p_fingerprint text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_receipt private.group_khatmah_receipt;
DECLARE v_group public.group_khatmah;
DECLARE v_member public.group_khatmah_member;
BEGIN
  SELECT * INTO v_receipt FROM private.group_khatmah_receipt r
    WHERE r.actor_id = p_actor AND r.operation_id = p_operation;
  IF NOT FOUND THEN RETURN NULL; END IF;
  IF v_receipt.gone THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','gone','operation_id',p_operation);
  END IF;
  IF v_receipt.kind <> p_kind OR v_receipt.fingerprint <> p_fingerprint THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','invalid_operation','operation_id',p_operation);
  END IF;
  SELECT * INTO v_group FROM public.group_khatmah g
    WHERE g.id = v_receipt.group_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','gone','operation_id',p_operation);
  END IF;
  SELECT * INTO v_member FROM public.group_khatmah_member m
    WHERE m.group_id = v_group.id AND m.user_id = p_actor AND m.left_at IS NULL;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','not_member','operation_id',p_operation);
  END IF;
  IF v_member.membership_epoch <> v_receipt.membership_epoch THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','stale_operation','operation_id',p_operation);
  END IF;
  IF p_kind = 'create' AND v_group.owner_id <> p_actor THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','not_member','operation_id',p_operation);
  END IF;
  RETURN v_receipt.result || pg_catalog.jsonb_build_object(
    'membership_epoch',v_member.membership_epoch,
    'invite_code',CASE WHEN p_kind = 'create' THEN v_group.code ELSE NULL END);
END;
$$;
REVOKE ALL ON FUNCTION private.group_khatmah_replay(uuid,text,uuid,text)
  FROM PUBLIC, anon, authenticated, service_role;
