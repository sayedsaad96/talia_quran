-- The hosted `revoke_guardian_link` drifted from 0012: it ran with
-- `search_path = public` and accepted the caller as its own counterpart.
-- Re-applies 0012's definition; behaviour for valid calls is unchanged.

CREATE OR REPLACE FUNCTION public.revoke_guardian_link(p_counterpart_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_updated INTEGER;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_counterpart_user_id IS NULL OR p_counterpart_user_id = v_caller THEN
    RAISE EXCEPTION 'Invalid counterpart user';
  END IF;

  UPDATE public.parent_child_links pcl
  SET status = 'revoked',
      revoked_at = NOW()
  WHERE pcl.status = 'active'
    AND (
      (pcl.parent_user_id = v_caller AND pcl.child_user_id = p_counterpart_user_id)
      OR
      (pcl.child_user_id = v_caller AND pcl.parent_user_id = p_counterpart_user_id)
    );

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated = 0 THEN
    RAISE EXCEPTION 'No active guardian link between these users';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.revoke_guardian_link(UUID)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.revoke_guardian_link(UUID) TO authenticated;
