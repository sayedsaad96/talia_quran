-- Talia Quran — Kids session log ayah uniqueness
--
-- Two devices completing the same ayah generated different local_id values,
-- so UNIQUE (child_user_id, local_id) allowed duplicate cloud rows for one
-- ayah. Keep the latest completion per (child, surah, ayah) and reject
-- subsequent inserts of the same ayah.
--
-- Apply after the preceding numbered migrations. Production must be at this
-- migration or later before a client relies on ayah-level log deduplication.

-- Keep the latest row per ayah; drop older duplicates.
DELETE FROM public.kids_session_logs a
WHERE a.id NOT IN (
  SELECT DISTINCT ON (child_user_id, surah_id, ayah_number) id
  FROM public.kids_session_logs
  ORDER BY child_user_id, surah_id, ayah_number, completed_at DESC, id DESC
);

ALTER TABLE public.kids_session_logs
  DROP CONSTRAINT IF EXISTS unique_child_session_log_ayah;

ALTER TABLE public.kids_session_logs
  ADD CONSTRAINT unique_child_session_log_ayah
  UNIQUE (child_user_id, surah_id, ayah_number);

CREATE OR REPLACE FUNCTION public.insert_kids_session_log(
  p_local_id TEXT,
  p_surah_id INTEGER,
  p_ayah_number INTEGER,
  p_repeats_completed INTEGER,
  p_points_earned INTEGER,
  p_completed_at TIMESTAMPTZ
)
RETURNS VOID AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO public.kids_session_logs (
    child_user_id, local_id, surah_id, ayah_number,
    repeats_completed, points_earned, completed_at
  )
  VALUES (
    v_uid, p_local_id, p_surah_id, p_ayah_number,
    p_repeats_completed, p_points_earned, p_completed_at
  )
  ON CONFLICT (child_user_id, surah_id, ayah_number) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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
  ON CONFLICT (child_user_id, surah_id, ayah_number) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Unused by the Flutter client (introduced in 0004). Drop so canonical schema
-- and live databases stay aligned. prune_kids_session_logs is ops-only and is
-- also unused by the app; drop it here to avoid a second undocumented RPC.
DROP FUNCTION IF EXISTS public.pull_child_review_records_page(UUID, TIMESTAMPTZ, INTEGER);
DROP FUNCTION IF EXISTS public.prune_kids_session_logs(INTEGER);
