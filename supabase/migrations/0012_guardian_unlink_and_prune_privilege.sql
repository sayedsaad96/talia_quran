-- 0012 — V1-M6 / V1-M7 release corrections.
--
-- 1. Guardian unlink contract: define `revoke_guardian_link(uuid)` for the
--    existing client boundary while V1 keeps its UI hidden pending hosted proof.
--    Least privilege: SECURITY DEFINER is required because `authenticated`
--    holds no direct DML on parent_child_links; membership in the ACTIVE
--    link being revoked is enforced inside the function, so a user can never
--    detach two unrelated accounts.
--
-- 2. Close critical database authority: `prune_audit_logs()` performs global
--    retention deletion and must never be executable by ordinary signed-in
--    users. Migration 0006 incorrectly granted EXECUTE to `authenticated`.

-- ── 1. revoke_guardian_link ────────────────────────────────────────────────

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

-- ── 2. Revoke global audit-pruning authority from end users ────────────────

REVOKE ALL ON FUNCTION public.prune_audit_logs()
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.prune_audit_logs() TO service_role;
