-- Talia Quran — Migration 0009: acknowledged review pushes and composite pulls
-- Keeps existing RPC signatures available for older clients while new clients
-- only clear dirty rows returned by the v2 RPC.

CREATE INDEX IF NOT EXISTS idx_ayah_review_records_cloud_user_updated
  ON public.ayah_review_records_cloud (user_id, updated_at, id);

CREATE OR REPLACE FUNCTION public.upsert_ayah_review_records_v2(
  p_data JSONB
)
RETURNS TABLE (
  surah_id INTEGER,
  ayah_number INTEGER,
  audience TEXT
) AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF jsonb_array_length(p_data) > 6236 THEN
    RAISE EXCEPTION 'Batch too large (max 6236 ayahs)';
  END IF;

  RETURN QUERY
  WITH input_rows AS (
    SELECT
      (item->>'surah_id')::INTEGER AS surah_id,
      (item->>'ayah_number')::INTEGER AS ayah_number,
      (item->>'strength_level')::INTEGER AS strength_level,
      (item->>'interval_days')::INTEGER AS interval_days,
      (item->>'last_reviewed_at')::TIMESTAMPTZ AS last_reviewed_at,
      (item->>'next_review_date')::TIMESTAMPTZ AS next_review_date,
      (item->>'total_reviews')::INTEGER AS total_reviews,
      item->>'last_rating' AS last_rating,
      (item->>'ease_factor')::DOUBLE PRECISION AS ease_factor,
      (item->>'lapses')::INTEGER AS lapses,
      item->>'review_state' AS review_state,
      item->>'created_by_mode' AS created_by_mode,
      COALESCE(
        (item->>'sync_version')::BIGINT,
        (EXTRACT(EPOCH FROM (item->>'last_reviewed_at')::TIMESTAMPTZ) * 1000)::BIGINT
      ) AS sync_version,
      COALESCE((item->>'difficulty')::DOUBLE PRECISION, 5.0) AS difficulty,
      COALESCE((item->>'stability')::DOUBLE PRECISION, 0.0) AS stability
    FROM jsonb_array_elements(p_data) AS item
  ),
  applied_rows AS (
    INSERT INTO public.ayah_review_records_cloud (
      user_id, surah_id, ayah_number, strength_level, interval_days,
      last_reviewed_at, next_review_date, total_reviews, last_rating,
      ease_factor, lapses, review_state, created_by_mode, sync_version,
      difficulty, stability
    )
    SELECT
      v_uid, surah_id, ayah_number, strength_level, interval_days,
      last_reviewed_at, next_review_date, total_reviews, last_rating,
      ease_factor, lapses, review_state, created_by_mode, sync_version,
      difficulty, stability
    FROM input_rows
    ON CONFLICT ON CONSTRAINT unique_user_audience_ayah_review
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
       )
    RETURNING
      ayah_review_records_cloud.surah_id,
      ayah_review_records_cloud.ayah_number,
      ayah_review_records_cloud.audience
  )
  SELECT
    applied_rows.surah_id,
    applied_rows.ayah_number,
    applied_rows.audience
  FROM applied_rows;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.upsert_ayah_review_records_v2(JSONB)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.upsert_ayah_review_records_v2(JSONB)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.pull_ayah_review_records_since(
  p_cursor_updated_at TIMESTAMPTZ DEFAULT 'epoch'::TIMESTAMPTZ,
  p_cursor_id BIGINT DEFAULT 0,
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
    AND (
      updated_at > COALESCE(p_cursor_updated_at, 'epoch'::TIMESTAMPTZ)
      OR (
        updated_at = COALESCE(p_cursor_updated_at, 'epoch'::TIMESTAMPTZ)
        AND id > COALESCE(p_cursor_id, 0)
      )
    )
  ORDER BY updated_at ASC, id ASC
  LIMIT v_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.pull_ayah_review_records_since(
  TIMESTAMPTZ, BIGINT, INTEGER
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pull_ayah_review_records_since(
  TIMESTAMPTZ, BIGINT, INTEGER
) TO authenticated;
