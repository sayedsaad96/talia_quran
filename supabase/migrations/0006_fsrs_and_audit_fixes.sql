-- Talia Quran — Migration 0006: FSRS Spaced Repetition Metrics & Retention Pruning
-- Safe & Idempotent migration to add difficulty/stability to ayah_review_records_cloud
-- and update upsert RPC to prevent FSRS algorithm state loss on restore.

-- 1. Add difficulty and stability columns to ayah_review_records_cloud
ALTER TABLE public.ayah_review_records_cloud
  ADD COLUMN IF NOT EXISTS difficulty DOUBLE PRECISION NOT NULL DEFAULT 5.0,
  ADD COLUMN IF NOT EXISTS stability DOUBLE PRECISION NOT NULL DEFAULT 0.0;

-- 2. Update upsert_ayah_review_records RPC to handle difficulty and stability
CREATE OR REPLACE FUNCTION public.upsert_ayah_review_records(
  p_data JSONB
)
RETURNS VOID AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF jsonb_array_length(p_data) > 6236 THEN
    RAISE EXCEPTION 'Batch too large (max 6236 ayahs)';
  END IF;

  INSERT INTO public.ayah_review_records_cloud (
    user_id, surah_id, ayah_number, strength_level, interval_days,
    last_reviewed_at, next_review_date, total_reviews, last_rating,
    ease_factor, lapses, review_state, created_by_mode, sync_version,
    difficulty, stability
  )
  SELECT
    v_uid,
    (item->>'surah_id')::INTEGER,
    (item->>'ayah_number')::INTEGER,
    (item->>'strength_level')::INTEGER,
    (item->>'interval_days')::INTEGER,
    (item->>'last_reviewed_at')::TIMESTAMPTZ,
    (item->>'next_review_date')::TIMESTAMPTZ,
    (item->>'total_reviews')::INTEGER,
    item->>'last_rating',
    (item->>'ease_factor')::DOUBLE PRECISION,
    (item->>'lapses')::INTEGER,
    item->>'review_state',
    item->>'created_by_mode',
    COALESCE(
      (item->>'sync_version')::BIGINT,
      (EXTRACT(EPOCH FROM (item->>'last_reviewed_at')::TIMESTAMPTZ) * 1000)::BIGINT
    ),
    COALESCE((item->>'difficulty')::DOUBLE PRECISION, 5.0),
    COALESCE((item->>'stability')::DOUBLE PRECISION, 0.0)
  FROM jsonb_array_elements(p_data) AS item
  ON CONFLICT (user_id, surah_id, ayah_number)
  DO UPDATE SET
    strength_level = EXCLUDED.strength_level,
    interval_days = EXCLUDED.interval_days,
    total_reviews = EXCLUDED.total_reviews,
    lapses = EXCLUDED.lapses,
    ease_factor = EXCLUDED.ease_factor,
    last_reviewed_at = EXCLUDED.last_reviewed_at,
    next_review_date = EXCLUDED.next_review_date,
    last_rating = EXCLUDED.last_rating,
    review_state = EXCLUDED.review_state,
    created_by_mode = EXCLUDED.created_by_mode,
    sync_version = EXCLUDED.sync_version,
    difficulty = EXCLUDED.difficulty,
    stability = EXCLUDED.stability,
    updated_at = NOW()
  WHERE EXCLUDED.sync_version > ayah_review_records_cloud.sync_version
     OR (
       EXCLUDED.sync_version = ayah_review_records_cloud.sync_version
       AND EXCLUDED.last_reviewed_at > ayah_review_records_cloud.last_reviewed_at
     );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.upsert_ayah_review_records(JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.upsert_ayah_review_records(JSONB) TO authenticated;

-- 3. Update get_remote_children_dashboard RPC to include FSRS metrics in review summaries
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
          LIMIT 50
        ) r
      ), '[]'::JSONB),
      'review_summary', (
        SELECT jsonb_build_object(
          'review_count', COUNT(*)::INTEGER,
          'memorized_count', COUNT(*) FILTER (
            WHERE rr.strength_level >= 6
          )::INTEGER,
          'overdue_count', COUNT(*) FILTER (
            WHERE rr.next_review_date <= NOW()
              AND rr.strength_level > 0
          )::INTEGER,
          'latest_review_at', MAX(rr.updated_at),
          'next_review_at', MIN(rr.next_review_date) FILTER (
            WHERE rr.next_review_date > NOW()
          ),
          'last_surah_id', (
            SELECT surah_id FROM public.ayah_review_records_cloud
            WHERE user_id = v_child.child_user_id
            ORDER BY last_reviewed_at DESC NULLS LAST
            LIMIT 1
          ),
          'last_ayah_number', (
            SELECT ayah_number FROM public.ayah_review_records_cloud
            WHERE user_id = v_child.child_user_id
            ORDER BY last_reviewed_at DESC NULLS LAST
            LIMIT 1
          )
        )
        FROM public.ayah_review_records_cloud rr
        WHERE rr.user_id = v_child.child_user_id
      ),
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
          LIMIT 20
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

-- 4. Retention pruning helper for audit logs
CREATE OR REPLACE FUNCTION public.prune_audit_logs()
RETURNS VOID AS $$
BEGIN
  DELETE FROM public.xp_history
  WHERE created_at < NOW() - INTERVAL '90 days';

  DELETE FROM public.kids_session_logs
  WHERE created_at < NOW() - INTERVAL '180 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.prune_audit_logs() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.prune_audit_logs() TO authenticated;
