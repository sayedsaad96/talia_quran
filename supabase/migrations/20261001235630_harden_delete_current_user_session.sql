-- Strengthen the existing account-deletion RPC.  The session identifier comes
-- from the signed JWT and is checked against auth.sessions before deleting the
-- JWT owner. A missing auth.users row is intentionally a successful no-op so a
-- client that already recorded remote confirmation never needs to retry.

CREATE OR REPLACE FUNCTION public.delete_current_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_session_id uuid := NULLIF(auth.jwt() ->> 'session_id', '')::uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authenticated session is required';
  END IF;

  -- A response can be lost after the DELETE commits. In that case the JWT may
  -- still identify the former user even though the row and its sessions are
  -- already gone; returning is safely idempotent.
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = v_uid) THEN
    RETURN;
  END IF;

  IF v_session_id IS NULL THEN
    RAISE EXCEPTION 'Authenticated session is required';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM auth.sessions AS session
    WHERE session.id = v_session_id
      AND session.user_id = v_uid
  ) THEN
    RAISE EXCEPTION 'Authenticated session is no longer active';
  END IF;

  DELETE FROM auth.users
  WHERE id = v_uid;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_current_user() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_current_user() TO authenticated;
