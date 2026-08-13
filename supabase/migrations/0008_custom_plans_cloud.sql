-- Talia Quran — Migration 0008: Custom plan cloud mirror (IS-4)
-- One row per authenticated user. Soft-delete via deleted_at so a fresh login
-- can clear a locally restored plan that the user deleted on another device.
-- Safe & idempotent.

CREATE TABLE IF NOT EXISTS public.custom_plans_cloud (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  payload JSONB NOT NULL DEFAULT '{}'::JSONB
    CHECK (pg_column_size(payload) <= 20000),
  deleted_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.custom_plans_cloud ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.custom_plans_cloud FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.custom_plans_cloud TO authenticated;

DROP POLICY IF EXISTS "custom_plans_cloud_owner_all" ON public.custom_plans_cloud;
CREATE POLICY "custom_plans_cloud_owner_all"
  ON public.custom_plans_cloud FOR ALL TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "custom_plans_cloud_parent_read" ON public.custom_plans_cloud;
CREATE POLICY "custom_plans_cloud_parent_read"
  ON public.custom_plans_cloud FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.parent_child_links pcl
      WHERE pcl.child_user_id = custom_plans_cloud.user_id
        AND pcl.parent_user_id = (SELECT auth.uid())
        AND pcl.status = 'active'
    )
  );