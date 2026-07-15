-- Account deletion RPC (separate contract).
-- Source: docs/backend/delete_current_user_rpc.sql

CREATE OR REPLACE FUNCTION public.delete_current_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  DELETE FROM auth.users
  WHERE id = v_uid;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_current_user() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_current_user() TO authenticated;
