-- Talia Quran account deletion RPC contract.
--
-- Deploy this SQL in the Supabase project before claiming in-app account
-- deletion is live. The Flutter app calls public.delete_current_user().
--
-- Expected behavior:
-- - Only authenticated users can execute it.
-- - It deletes only auth.uid() from auth.users.
-- - Existing ON DELETE CASCADE constraints remove related cloud rows.
-- - Local on-device app progress is not affected by this RPC.

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
