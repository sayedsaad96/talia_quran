-- Private cleanup is called only by the existing account-deletion RPC owner.
-- Direct Auth-admin deletion of a group participant is deliberately rejected by
-- owner/member RESTRICT FKs. Administrative deletion must run this cleanup and
-- auth.users deletion in one transaction with the same actor advisory lock.
CREATE OR REPLACE FUNCTION private.group_khatmah_cleanup_user(p_actor uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_group_id uuid;
DECLARE v_group public.group_khatmah;
DECLARE v_member public.group_khatmah_member;
DECLARE v_part public.group_khatmah_part;
BEGIN
  IF p_actor IS NULL OR p_actor <> auth.uid() THEN
    RAISE EXCEPTION 'group_cleanup_forbidden';
  END IF;
  -- The caller holds the subject actor lock. Groups are locked in UUID order;
  -- their members and parts are subsequently locked in deterministic order.
  FOR v_group_id IN
    SELECT id FROM (
      SELECT g.id FROM public.group_khatmah g WHERE g.owner_id=p_actor
      UNION
      SELECT m.group_id FROM public.group_khatmah_member m WHERE m.user_id=p_actor
    ) AS affected(id) ORDER BY id
  LOOP
    SELECT * INTO v_group FROM public.group_khatmah g
      WHERE g.id=v_group_id FOR UPDATE;
    IF NOT FOUND THEN CONTINUE; END IF;
    IF v_group.owner_id=p_actor THEN
      UPDATE private.group_khatmah_receipt SET gone=true,fingerprint=NULL,
        membership_epoch=NULL,result=NULL WHERE group_id=v_group_id;
      DELETE FROM public.group_khatmah WHERE id=v_group_id;
      CONTINUE;
    END IF;
    SELECT * INTO v_member FROM public.group_khatmah_member m
      WHERE m.group_id=v_group_id AND m.user_id=p_actor FOR UPDATE;
    IF NOT FOUND THEN CONTINUE; END IF;
    FOR v_part IN SELECT * FROM public.group_khatmah_part p
      WHERE p.group_id=v_group_id AND p.claimed_by=p_actor
      ORDER BY p.juz FOR UPDATE
    LOOP
      IF v_part.status='claimed' THEN
        UPDATE public.group_khatmah_part SET status='open',claimed_by=NULL,
          claim_epoch=NULL,version=version+1,updated_at=now()
          WHERE group_id=v_group_id AND juz=v_part.juz;
      ELSE
        UPDATE public.group_khatmah_part SET claimed_by=NULL,claim_epoch=NULL,
          version=version+1,updated_at=now()
          WHERE group_id=v_group_id AND juz=v_part.juz;
      END IF;
    END LOOP;
    DELETE FROM public.group_khatmah_member
      WHERE group_id=v_group_id AND user_id=p_actor;
    IF v_member.left_at IS NULL THEN
      UPDATE public.group_khatmah SET version=version+1 WHERE id=v_group_id;
    END IF;
  END LOOP;
END;
$$;
REVOKE ALL ON FUNCTION private.group_khatmah_cleanup_user(uuid)
  FROM PUBLIC, anon, authenticated, service_role;

-- Preserve the existing JWT/session and lost-acknowledgement semantics.
CREATE OR REPLACE FUNCTION public.delete_current_user()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_session_id uuid := NULLIF(auth.jwt() ->> 'session_id', '')::uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authenticated session is required';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = v_uid) THEN
    RETURN;
  END IF;
  IF v_session_id IS NULL THEN
    RAISE EXCEPTION 'Authenticated session is required';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM auth.sessions AS session
    WHERE session.id = v_session_id AND session.user_id = v_uid
  ) THEN
    RAISE EXCEPTION 'Authenticated session is no longer active';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(7031,pg_catalog.hashtext(v_uid::text));
  -- Recheck after waiting so a concurrent deletion cannot leave stale work.
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = v_uid) THEN
    RETURN;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM auth.sessions AS session
    WHERE session.id = v_session_id AND session.user_id = v_uid
  ) THEN
    RAISE EXCEPTION 'Authenticated session is no longer active';
  END IF;
  PERFORM private.group_khatmah_cleanup_user(v_uid);
  DELETE FROM auth.users WHERE id = v_uid;
END;
$$;
REVOKE ALL ON FUNCTION public.delete_current_user()
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.delete_current_user() TO authenticated;
