-- Talia Quran — Cost / sync / security audit fixes
-- Apply AFTER 0002 and 0003 on staging, then production.
-- Idempotent: safe to re-run.

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1–2. Atomic guardian token consume + one active guardian per child
-- ═══════════════════════════════════════════════════════════════════════════════

-- Revoke duplicate active guardians (keep earliest link) before unique index.
UPDATE public.parent_child_links pcl
SET status = 'revoked', revoked_at = NOW()
WHERE pcl.status = 'active'
  AND pcl.ctid NOT IN (
    SELECT DISTINCT ON (child_user_id) ctid
    FROM public.parent_child_links
    WHERE status = 'active'
    ORDER BY child_user_id, linked_at ASC NULLS LAST
  );

CREATE UNIQUE INDEX IF NOT EXISTS one_active_guardian_per_child
  ON public.parent_child_links (child_user_id)
  WHERE status = 'active';

CREATE OR REPLACE FUNCTION public.accept_child_link_token_with_hash(p_token_hash TEXT)
RETURNS VOID AS $$
DECLARE
  v_parent UUID := auth.uid();
  v_child UUID;
BEGIN
  IF v_parent IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Atomically consume the token (race-safe).
  UPDATE public.child_link_requests
  SET used_at = NOW()
  WHERE token_hash = p_token_hash
    AND used_at IS NULL
    AND expires_at > NOW()
  RETURNING child_user_id INTO v_child;

  IF v_child IS NULL THEN
    RAISE EXCEPTION 'Invalid or expired link token';
  END IF;
  IF v_child = v_parent THEN
    RAISE EXCEPTION 'Parent and child accounts must be different';
  END IF;

  -- Reject if another parent already has an active link.
  IF EXISTS (
    SELECT 1 FROM public.parent_child_links
    WHERE child_user_id = v_child
      AND status = 'active'
      AND parent_user_id <> v_parent
  ) THEN
    RAISE EXCEPTION 'Child already has an active guardian';
  END IF;

  INSERT INTO public.parent_child_links (parent_user_id, child_user_id, status, linked_at)
  VALUES (v_parent, v_child, 'active', NOW())
  ON CONFLICT (parent_user_id, child_user_id)
  DO UPDATE SET status = 'active', revoked_at = NULL, linked_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. sync_version + event-based SRS conflict resolution
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.ayah_review_records_cloud
  ADD COLUMN IF NOT EXISTS sync_version BIGINT NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_ayah_review_records_cloud_user_updated
  ON public.ayah_review_records_cloud (user_id, updated_at, id);

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
    ease_factor, lapses, review_state, created_by_mode, sync_version
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
    )
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3–4. Paginated delta pull for review records
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.pull_ayah_review_records_since(
  p_cursor TIMESTAMPTZ DEFAULT 'epoch'::TIMESTAMPTZ,
  p_limit INTEGER DEFAULT 500
)
RETURNS SETOF public.ayah_review_records_cloud AS $$
DECLARE
  v_limit INTEGER := LEAST(GREATEST(COALESCE(p_limit, 500), 1), 500);
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  RETURN QUERY
  SELECT *
  FROM public.ayah_review_records_cloud
  WHERE user_id = auth.uid()
    AND updated_at > COALESCE(p_cursor, 'epoch'::TIMESTAMPTZ)
  ORDER BY updated_at ASC, id ASC
  LIMIT v_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.pull_ayah_review_records_since(TIMESTAMPTZ, INTEGER)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pull_ayah_review_records_since(TIMESTAMPTZ, INTEGER)
  TO authenticated;

-- Keep legacy full pull for older clients; prefer _since going forward.
CREATE OR REPLACE FUNCTION public.pull_ayah_review_records()
RETURNS SETOF public.ayah_review_records_cloud AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  RETURN QUERY
  SELECT *
  FROM public.ayah_review_records_cloud
  WHERE user_id = auth.uid()
  ORDER BY updated_at ASC, id ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 6 / 10–11. Parent dashboard: summaries only (no full review history)
-- ═══════════════════════════════════════════════════════════════════════════════

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

-- Unused by the Flutter client. Kept historically for existing databases;
-- 0010 drops these functions so new environments do not recreate them.
-- Optional paginated detail for a single child (on-demand).
CREATE OR REPLACE FUNCTION public.pull_child_review_records_page(
  p_child_user_id UUID,
  p_cursor TIMESTAMPTZ DEFAULT 'epoch'::TIMESTAMPTZ,
  p_limit INTEGER DEFAULT 100
)
RETURNS SETOF public.ayah_review_records_cloud AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_limit INTEGER := LEAST(GREATEST(COALESCE(p_limit, 100), 1), 200);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.parent_child_links
    WHERE parent_user_id = v_uid
      AND child_user_id = p_child_user_id
      AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Not authorized for this child';
  END IF;

  RETURN QUERY
  SELECT *
  FROM public.ayah_review_records_cloud
  WHERE user_id = p_child_user_id
    AND updated_at > COALESCE(p_cursor, 'epoch'::TIMESTAMPTZ)
  ORDER BY updated_at ASC, id ASC
  LIMIT v_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.pull_child_review_records_page(UUID, TIMESTAMPTZ, INTEGER)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pull_child_review_records_page(UUID, TIMESTAMPTZ, INTEGER)
  TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 12. Session log retention helper (aggregate older than 90 days)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.prune_kids_session_logs(
  p_retain_days INTEGER DEFAULT 90
)
RETURNS INTEGER AS $$
DECLARE
  v_deleted INTEGER;
BEGIN
  DELETE FROM public.kids_session_logs
  WHERE completed_at < NOW() - make_interval(days => GREATEST(p_retain_days, 30));
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.prune_kids_session_logs(INTEGER) FROM PUBLIC, anon;
-- Intentionally not granted to authenticated; run via cron / service role.

-- ═══════════════════════════════════════════════════════════════════════════════
-- 15. Harden older SECURITY DEFINER functions with fixed search_path
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER FUNCTION public.upsert_ayah_progress(JSONB) SET search_path = public;
ALTER FUNCTION public.upsert_streak(INTEGER, INTEGER, DATE, INTEGER) SET search_path = public;
ALTER FUNCTION public.upsert_xp(INTEGER) SET search_path = public;
