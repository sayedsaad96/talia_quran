-- Talia Quran — Audit patches (batches 2–4)
-- Apply AFTER baseline schema on staging, then production.
-- Idempotent: safe to re-run.

-- ── Index: parent dashboard link lookup ──
CREATE INDEX IF NOT EXISTS idx_parent_child_links_parent
  ON public.parent_child_links(parent_user_id, status)
  WHERE status = 'active';

-- ── Kids session logs batch insert ──
CREATE OR REPLACE FUNCTION public.insert_kids_session_logs_batch(
  p_data JSONB
)
RETURNS VOID AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF jsonb_array_length(p_data) > 500 THEN
    RAISE EXCEPTION 'Batch too large (max 500 logs)';
  END IF;

  INSERT INTO public.kids_session_logs (
    child_user_id, local_id, surah_id, ayah_number,
    repeats_completed, points_earned, completed_at
  )
  SELECT
    v_uid,
    item->>'local_id',
    (item->>'surah_id')::INTEGER,
    (item->>'ayah_number')::INTEGER,
    (item->>'repeats_completed')::INTEGER,
    (item->>'points_earned')::INTEGER,
    (item->>'completed_at')::TIMESTAMPTZ
  FROM jsonb_array_elements(p_data) AS item
  ON CONFLICT (child_user_id, local_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.insert_kids_session_logs_batch(JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.insert_kids_session_logs_batch(JSONB) TO authenticated;

-- ── Parent dashboard: single RPC (replaces N+1 per child) ──
CREATE OR REPLACE FUNCTION public.get_remote_children_dashboard()
RETURNS JSONB AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_result JSONB := '[]'::JSONB;
  v_child RECORD;
  v_child_json JSONB;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  FOR v_child IN
    SELECT pcl.child_user_id, p.display_name
    FROM public.parent_child_links pcl
    JOIN public.profiles p ON p.id = pcl.child_user_id
    WHERE pcl.parent_user_id = v_uid
      AND pcl.status = 'active'
  LOOP
    v_child_json := jsonb_build_object(
      'child_user_id', v_child.child_user_id,
      'display_name', COALESCE(v_child.display_name, 'طفل تالية'),
      'progress', (
        SELECT to_jsonb(kpc)
        FROM public.kids_progress_cloud kpc
        WHERE kpc.child_user_id = v_child.child_user_id
      ),
      'logs', COALESCE((
        SELECT jsonb_agg(to_jsonb(l))
        FROM (
          SELECT local_id, surah_id, ayah_number, repeats_completed,
                 points_earned, completed_at
          FROM public.kids_session_logs
          WHERE child_user_id = v_child.child_user_id
          ORDER BY completed_at DESC
          LIMIT 30
        ) l
      ), '[]'::JSONB),
      'rewards', COALESCE((
        SELECT jsonb_agg(to_jsonb(r))
        FROM (
          SELECT id, title, status, created_at, unlocked_at, claimed_at
          FROM public.parent_rewards
          WHERE child_user_id = v_child.child_user_id
          ORDER BY created_at DESC
        ) r
      ), '[]'::JSONB),
      'review_rows', COALESCE((
        SELECT jsonb_agg(to_jsonb(rr))
        FROM public.ayah_review_records_cloud rr
        WHERE rr.user_id = v_child.child_user_id
      ), '[]'::JSONB),
      'daily_plan', (
        SELECT to_jsonb(dp)
        FROM public.daily_plans_cloud dp
        WHERE dp.user_id = v_child.child_user_id
      ),
      'certificates', COALESCE((
        SELECT jsonb_agg(to_jsonb(c))
        FROM (
          SELECT cert_id, title_ar, cert_type, earned_at
          FROM public.certificate_awards_cloud
          WHERE user_id = v_child.child_user_id
          ORDER BY earned_at DESC
        ) c
      ), '[]'::JSONB),
      'streak', (
        SELECT to_jsonb(s)
        FROM public.streaks s
        WHERE s.user_id = v_child.child_user_id
      ),
      'activities', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'day_key', da.day_key,
            'activity_count', da.activity_count
          )
        )
        FROM (
          SELECT day_key, activity_count
          FROM public.daily_activities
          WHERE user_id = v_child.child_user_id
          ORDER BY day_key DESC
          LIMIT 31
        ) da
      ), '[]'::JSONB)
    );

    v_result := v_result || jsonb_build_array(v_child_json);
  END LOOP;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.get_remote_children_dashboard() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_remote_children_dashboard() TO authenticated;

-- ── Legacy tables: read-only via PostgREST (app uses Isar / certificate_awards_cloud) ──
REVOKE INSERT, UPDATE, DELETE ON public.ayah_progress FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.bookmarks FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.certificates FROM authenticated;
GRANT SELECT ON public.ayah_progress TO authenticated;
GRANT SELECT ON public.bookmarks TO authenticated;
GRANT SELECT ON public.certificates TO authenticated;

DROP POLICY IF EXISTS "ayah_progress_all_own" ON public.ayah_progress;
DROP POLICY IF EXISTS "bookmarks_all_own" ON public.bookmarks;
DROP POLICY IF EXISTS "certificates_all_own" ON public.certificates;

CREATE POLICY "ayah_progress_select_own"
  ON public.ayah_progress FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) IS NOT NULL AND (SELECT auth.uid()) = user_id);

CREATE POLICY "bookmarks_select_own"
  ON public.bookmarks FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) IS NOT NULL AND (SELECT auth.uid()) = user_id);

CREATE POLICY "certificates_select_own"
  ON public.certificates FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) IS NOT NULL AND (SELECT auth.uid()) = user_id);
