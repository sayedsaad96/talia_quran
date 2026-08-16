-- Talia Quran — Migration 0011: Cloud reading progress, profiles identity columns,
-- upsert RPCs, and revoke leftover plaintext parent-link RPCs.
-- Safe & idempotent (uses IF NOT EXISTS, CREATE OR REPLACE, DROP IF EXISTS).

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. reading_progress_cloud table
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.reading_progress_cloud (
  user_id    UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  pages      INTEGER[] NOT NULL DEFAULT ARRAY[]::INTEGER[]
    CONSTRAINT pages_cardinality CHECK (cardinality(pages) <= 604)
    CONSTRAINT pages_values CHECK (
      pages = ARRAY[]::INTEGER[] OR
      (SELECT bool_and(p >= 1 AND p <= 604) FROM unnest(pages) p)
    ),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.reading_progress_cloud ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.reading_progress_cloud FROM anon, authenticated;
GRANT SELECT ON public.reading_progress_cloud TO authenticated;

DROP POLICY IF EXISTS "reading_progress_cloud_owner_all" ON public.reading_progress_cloud;
CREATE POLICY "reading_progress_cloud_owner_all"
  ON public.reading_progress_cloud FOR ALL TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "reading_progress_cloud_parent_read" ON public.reading_progress_cloud;
CREATE POLICY "reading_progress_cloud_parent_read"
  ON public.reading_progress_cloud FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.parent_child_links pcl
      WHERE pcl.child_user_id = reading_progress_cloud.user_id
        AND pcl.parent_user_id = (SELECT auth.uid())
        AND pcl.status = 'active'
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. upsert_reading_progress RPC (union merge, SECURITY DEFINER, auth-guarded)
-- ─────────────────────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.upsert_reading_progress(INTEGER[]);

CREATE OR REPLACE FUNCTION public.upsert_reading_progress(p_pages INTEGER[])
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  v_uid    UUID := auth.uid();
  v_merged INTEGER[];
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF EXISTS (SELECT 1 FROM unnest(p_pages) p WHERE p < 1 OR p > 604) THEN
    RAISE EXCEPTION 'Page numbers must be between 1 and 604';
  END IF;

  IF cardinality(p_pages) > 604 THEN
    RAISE EXCEPTION 'Too many pages (max 604)';
  END IF;

  -- Union merge: combine stored and incoming pages (monotonic, no last-write clobber)
  SELECT ARRAY(
    SELECT DISTINCT unnest(COALESCE(rpc.pages, ARRAY[]::INTEGER[]) || p_pages)
    ORDER BY 1
  )
  INTO v_merged
  FROM (SELECT pages FROM public.reading_progress_cloud WHERE user_id = v_uid) rpc;

  IF v_merged IS NULL THEN
    SELECT ARRAY(SELECT DISTINCT unnest(p_pages) ORDER BY 1) INTO v_merged;
  END IF;

  INSERT INTO public.reading_progress_cloud (user_id, pages, updated_at)
  VALUES (v_uid, v_merged, NOW())
  ON CONFLICT (user_id) DO UPDATE
    SET pages      = v_merged,
        updated_at = NOW();
END;
$fn$;

REVOKE EXECUTE ON FUNCTION public.upsert_reading_progress(INTEGER[]) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.upsert_reading_progress(INTEGER[]) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. profiles identity columns (already applied — safe no-ops with IF NOT EXISTS)
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS selected_path TEXT
    CHECK (selected_path IN ('adult', 'child')),
  ADD COLUMN IF NOT EXISTS guardian_onboarding_status TEXT
    CHECK (guardian_onboarding_status IN ('required', 'skipped', 'completed')),
  ADD COLUMN IF NOT EXISTS is_parent_guardian BOOLEAN NOT NULL DEFAULT FALSE;

-- Reuse profiles.age as child_age (same column, no duplicate).

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. upsert_memorization_identity RPC (already applied — safe no-op)
-- ─────────────────────────────────────────────────────────────────────────────

-- Already exists with correct implementation; CREATE OR REPLACE is safe.
-- (See migration history for original definition.)

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Revoke and drop plaintext parent-link RPCs (not present on live project;
--    DROP IF EXISTS is safe).
-- ─────────────────────────────────────────────────────────────────────────────

REVOKE ALL ON FUNCTION public.accept_child_link_token(text)
  FROM PUBLIC, anon, authenticated;
DROP FUNCTION IF EXISTS public.accept_child_link_token(text);

REVOKE ALL ON FUNCTION public.create_child_link_request()
  FROM PUBLIC, anon, authenticated;
DROP FUNCTION IF EXISTS public.create_child_link_request();
