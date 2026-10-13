-- Kids learning support (roadmap T7): the guardian's answer to "how does the
-- child read?", synced between the guardian's device and a linked child's
-- device.
--
-- Additive only. It is a separate table and RPC on purpose: the existing
-- `kids_child_policies` row and `compare_and_swap_child_policy` stay
-- untouched, so older clients keep working unchanged and creating this row
-- can never reset a pending child-policy edit.
--
-- reading_ability NULL means "not answered" (today's behaviour). The values
-- match the client enum names: independent, withHelp, notYetReading.

-- -- 1. Table -----------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.kids_child_reading_support (
  child_user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  reading_ability TEXT
    CHECK (reading_ability IN ('independent', 'withHelp', 'notYetReading')),
  version BIGINT NOT NULL DEFAULT 0 CHECK (version >= 0),
  updated_by UUID,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -- 2. RLS and grants -------------------------------------------------------

ALTER TABLE public.kids_child_reading_support ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.kids_child_reading_support FROM anon;
REVOKE ALL ON public.kids_child_reading_support FROM authenticated;
GRANT SELECT ON public.kids_child_reading_support TO authenticated;

DROP POLICY IF EXISTS kids_child_reading_support_read
  ON public.kids_child_reading_support;
CREATE POLICY kids_child_reading_support_read
  ON public.kids_child_reading_support FOR SELECT TO authenticated USING (
  child_user_id = (SELECT auth.uid())
  OR EXISTS (
    SELECT 1 FROM public.parent_child_links pcl
    WHERE pcl.child_user_id = kids_child_reading_support.child_user_id
      AND pcl.parent_user_id = (SELECT auth.uid())
      AND pcl.status = 'active'
  )
);

-- -- 3. compare_and_swap_child_reading_support -------------------------------
-- Same authorization and CAS contract as compare_and_swap_child_policy:
-- the child itself (with an active link) or its actively linked guardian.
-- expected 0 creates the row; otherwise the row must still be at
-- p_expected_version. Returns {applied, version, support}; on a conflict
-- `support` is the CURRENT server row so the client can show and retry.

CREATE OR REPLACE FUNCTION public.compare_and_swap_child_reading_support(
  p_child_user_id UUID,
  p_expected_version BIGINT,
  p_reading_ability TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_row public.kids_child_reading_support;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF v_caller = p_child_user_id THEN
    PERFORM 1
    FROM public.parent_child_links pcl
    WHERE pcl.child_user_id = v_caller
      AND pcl.status = 'active'
    FOR UPDATE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Child link is not active';
    END IF;
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
  IF p_reading_ability IS NOT NULL
    AND p_reading_ability NOT IN ('independent', 'withHelp', 'notYetReading')
  THEN
    RAISE EXCEPTION 'Invalid reading ability';
  END IF;

  IF p_expected_version = 0 THEN
    INSERT INTO public.kids_child_reading_support AS s (
      child_user_id, reading_ability, version, updated_by, updated_at
    )
    VALUES (p_child_user_id, p_reading_ability, 1, v_caller, NOW())
    ON CONFLICT (child_user_id) DO NOTHING
    RETURNING s.* INTO v_row;
  ELSE
    UPDATE public.kids_child_reading_support s
    SET reading_ability = p_reading_ability,
        version = s.version + 1,
        updated_by = v_caller,
        updated_at = NOW()
    WHERE s.child_user_id = p_child_user_id
      AND s.version = p_expected_version
    RETURNING s.* INTO v_row;
  END IF;

  IF v_row.child_user_id IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object(
      'applied', TRUE,
      'version', v_row.version,
      'support', pg_catalog.to_jsonb(v_row)
    );
  END IF;

  SELECT * INTO v_row
  FROM public.kids_child_reading_support s
  WHERE s.child_user_id = p_child_user_id;
  RETURN pg_catalog.jsonb_build_object(
    'applied', FALSE,
    'version', COALESCE(v_row.version, 0),
    'support', CASE
      WHEN v_row.child_user_id IS NULL THEN NULL
      ELSE pg_catalog.to_jsonb(v_row)
    END
  );
END;
$$;

REVOKE ALL ON FUNCTION public.compare_and_swap_child_reading_support(UUID, BIGINT, TEXT)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.compare_and_swap_child_reading_support(UUID, BIGINT, TEXT)
  TO authenticated;
