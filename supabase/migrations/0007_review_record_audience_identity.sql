-- Talia Quran — Migration 0007: Audience-aware review record identity (IS-1/D3)
-- Adds a derived audience column so an adult record and a kids record for the
-- same ayah can no longer overwrite each other, and repoints the upsert RPC's
-- conflict target at the new four-column uniqueness contract.
-- Safe & idempotent.

ALTER TABLE public.ayah_review_records_cloud
  ADD COLUMN IF NOT EXISTS audience TEXT
    GENERATED ALWAYS AS (
      CASE WHEN created_by_mode = 'kidsMode' THEN 'kids' ELSE 'adult' END
    ) STORED;

ALTER TABLE public.ayah_review_records_cloud
  DROP CONSTRAINT IF EXISTS unique_user_ayah_review;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'unique_user_audience_ayah_review'
      AND conrelid = 'public.ayah_review_records_cloud'::regclass
  ) THEN
    ALTER TABLE public.ayah_review_records_cloud
      ADD CONSTRAINT unique_user_audience_ayah_review
      UNIQUE (user_id, audience, surah_id, ayah_number);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_ayah_review_records_cloud_user_audience
  ON public.ayah_review_records_cloud(user_id, audience);

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
     );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.upsert_ayah_review_records(JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.upsert_ayah_review_records(JSONB) TO authenticated;
