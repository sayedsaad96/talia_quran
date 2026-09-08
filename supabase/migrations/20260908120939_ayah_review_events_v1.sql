-- Append-only, privacy-safe review evidence. This ledger never stores audio,
-- speech-recognition text, or Quran text.

CREATE OR REPLACE FUNCTION public.is_valid_quran_ayah_reference(
  p_surah_id INTEGER,
  p_ayah_number INTEGER
)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $fn$
  SELECT p_surah_id BETWEEN 1 AND 114
    AND p_ayah_number BETWEEN 1 AND (ARRAY[
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52,
      99, 128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69,
      60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37,
      35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14,
      11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50,
      40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11,
      8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5,
      6
    ])[p_surah_id];
$fn$;

CREATE TABLE IF NOT EXISTS public.ayah_review_events (
  server_sequence BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_id TEXT NOT NULL CHECK (char_length(event_id) BETWEEN 1 AND 160),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  audience TEXT NOT NULL CHECK (audience IN ('adult', 'kids')),
  session_id TEXT NOT NULL CHECK (char_length(session_id) BETWEEN 1 AND 160),
  task_id TEXT NOT NULL CHECK (char_length(task_id) BETWEEN 1 AND 240),
  surah_id INTEGER NOT NULL,
  ayah_number INTEGER NOT NULL,
  event_type SMALLINT NOT NULL CHECK (event_type IN (0, 1)),
  assessment SMALLINT NOT NULL CHECK (assessment IN (0, 1)),
  outcome SMALLINT NOT NULL CHECK (outcome IN (0, 1, 2)),
  rating SMALLINT CHECK (rating IN (0, 1, 2)),
  similarity_score NUMERIC(5, 4) CHECK (
    similarity_score IS NULL OR similarity_score BETWEEN 0 AND 1
  ),
  attempt_count INTEGER NOT NULL CHECK (attempt_count BETWEEN 1 AND 1000),
  failure_count INTEGER NOT NULL CHECK (
    failure_count BETWEEN 0 AND attempt_count
  ),
  hint_level SMALLINT NOT NULL CHECK (hint_level IN (0, 1, 2)),
  occurred_at TIMESTAMPTZ NOT NULL,
  study_day_key TEXT NOT NULL CHECK (
    study_day_key ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
  ),
  committed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ayah_review_events_valid_reference CHECK (
    public.is_valid_quran_ayah_reference(surah_id, ayah_number)
  ),
  UNIQUE (user_id, event_id)
);

CREATE INDEX IF NOT EXISTS idx_ayah_review_events_user_cursor
  ON public.ayah_review_events (user_id, server_sequence, event_id);
CREATE INDEX IF NOT EXISTS idx_ayah_review_events_user_audience_ayah
  ON public.ayah_review_events (user_id, audience, surah_id, ayah_number);

ALTER TABLE public.ayah_review_events ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.ayah_review_events FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.ayah_review_events TO authenticated;

DROP POLICY IF EXISTS ayah_review_events_owner_read ON public.ayah_review_events;
CREATE POLICY ayah_review_events_owner_read
  ON public.ayah_review_events FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS ayah_review_events_linked_parent_read ON public.ayah_review_events;
CREATE POLICY ayah_review_events_linked_parent_read
  ON public.ayah_review_events FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.parent_child_links pcl
      WHERE pcl.child_user_id = ayah_review_events.user_id
        AND pcl.parent_user_id = (SELECT auth.uid())
        AND pcl.status = 'active'
    )
  );

-- The policy documents ownership even though direct INSERT remains revoked;
-- application clients add rows through the validated RPC below.
DROP POLICY IF EXISTS ayah_review_events_owner_insert ON public.ayah_review_events;
CREATE POLICY ayah_review_events_owner_insert
  ON public.ayah_review_events FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE OR REPLACE FUNCTION public.append_ayah_review_events_v1(p_events JSONB)
RETURNS TABLE (
  event_id TEXT,
  result TEXT,
  server_sequence BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE
  v_uid UUID := auth.uid();
  v_item JSONB;
  v_event_id TEXT;
  v_audience TEXT;
  v_session_id TEXT;
  v_task_id TEXT;
  v_surah_id INTEGER;
  v_ayah_number INTEGER;
  v_event_type SMALLINT;
  v_assessment SMALLINT;
  v_outcome SMALLINT;
  v_rating SMALLINT;
  v_similarity NUMERIC(5, 4);
  v_attempt_count INTEGER;
  v_failure_count INTEGER;
  v_hint_level SMALLINT;
  v_occurred_at TIMESTAMPTZ;
  v_study_day_key TEXT;
  v_sequence BIGINT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF p_events IS NULL OR jsonb_typeof(p_events) <> 'array' THEN
    RAISE EXCEPTION 'Events must be a JSON array';
  END IF;
  IF jsonb_array_length(p_events) > 100 THEN
    RAISE EXCEPTION 'Batch too large (max 100 events)';
  END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_events)
  LOOP
    event_id := COALESCE(NULLIF(v_item->>'event_id', ''), 'invalid');
    result := 'rejected';
    server_sequence := NULL;
    BEGIN
      IF jsonb_typeof(v_item) <> 'object' THEN
        RETURN NEXT;
        CONTINUE;
      END IF;

      v_event_id := NULLIF(v_item->>'event_id', '');
      v_audience := NULLIF(v_item->>'audience', '');
      v_session_id := NULLIF(v_item->>'session_id', '');
      v_task_id := NULLIF(v_item->>'task_id', '');
      v_surah_id := NULLIF(v_item->>'surah_id', '')::INTEGER;
      v_ayah_number := NULLIF(v_item->>'ayah_number', '')::INTEGER;
      v_event_type := NULLIF(v_item->>'event_type', '')::SMALLINT;
      v_assessment := NULLIF(v_item->>'assessment', '')::SMALLINT;
      v_outcome := NULLIF(v_item->>'outcome', '')::SMALLINT;
      v_rating := NULLIF(v_item->>'rating', '')::SMALLINT;
      v_similarity := NULLIF(v_item->>'similarity_score', '')::NUMERIC(5, 4);
      v_attempt_count := NULLIF(v_item->>'attempt_count', '')::INTEGER;
      v_failure_count := NULLIF(v_item->>'failure_count', '')::INTEGER;
      v_hint_level := NULLIF(v_item->>'hint_level', '')::SMALLINT;
      v_occurred_at := NULLIF(v_item->>'occurred_at', '')::TIMESTAMPTZ;
      v_study_day_key := NULLIF(v_item->>'study_day_key', '');

      IF v_event_id IS NULL OR char_length(v_event_id) > 160
        OR v_session_id IS NULL OR char_length(v_session_id) > 160
        OR v_task_id IS NULL OR char_length(v_task_id) > 240
        OR v_audience NOT IN ('adult', 'kids')
        OR NOT public.is_valid_quran_ayah_reference(v_surah_id, v_ayah_number)
        OR v_event_type NOT IN (0, 1)
        OR v_assessment NOT IN (0, 1)
        OR v_outcome NOT IN (0, 1, 2)
        OR (v_rating IS NOT NULL AND v_rating NOT IN (0, 1, 2))
        OR (v_similarity IS NOT NULL AND v_similarity NOT BETWEEN 0 AND 1)
        OR v_attempt_count NOT BETWEEN 1 AND 1000
        OR v_failure_count NOT BETWEEN 0 AND v_attempt_count
        OR v_hint_level NOT IN (0, 1, 2)
        OR v_occurred_at IS NULL
        OR v_study_day_key !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
      THEN
        RETURN NEXT;
        CONTINUE;
      END IF;

      INSERT INTO public.ayah_review_events (
        event_id, user_id, audience, session_id, task_id, surah_id,
        ayah_number, event_type, assessment, outcome, rating,
        similarity_score, attempt_count, failure_count, hint_level,
        occurred_at, study_day_key
      ) VALUES (
        v_event_id, v_uid, v_audience, v_session_id, v_task_id, v_surah_id,
        v_ayah_number, v_event_type, v_assessment, v_outcome, v_rating,
        v_similarity, v_attempt_count, v_failure_count, v_hint_level,
        v_occurred_at, v_study_day_key
      )
      ON CONFLICT (user_id, event_id) DO NOTHING
      RETURNING server_sequence INTO v_sequence;

      event_id := v_event_id;
      IF v_sequence IS NULL THEN
        SELECT e.server_sequence
        INTO v_sequence
        FROM public.ayah_review_events e
        WHERE e.user_id = v_uid AND e.event_id = v_event_id;
        result := 'alreadyApplied';
      ELSE
        result := 'applied';
      END IF;
      server_sequence := v_sequence;
      RETURN NEXT;
    EXCEPTION WHEN OTHERS THEN
      RETURN NEXT;
    END;
  END LOOP;
END;
$fn$;

REVOKE ALL ON FUNCTION public.append_ayah_review_events_v1(JSONB)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.append_ayah_review_events_v1(JSONB)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.pull_ayah_review_events_since(
  p_owner_user_id UUID DEFAULT NULL,
  p_cursor_sequence BIGINT DEFAULT 0,
  p_cursor_event_id TEXT DEFAULT '',
  p_limit INTEGER DEFAULT 500
)
RETURNS SETOF public.ayah_review_events
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE
  v_uid UUID := auth.uid();
  v_owner UUID := COALESCE(p_owner_user_id, v_uid);
  v_limit INTEGER := LEAST(GREATEST(COALESCE(p_limit, 500), 1), 500);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF v_owner <> v_uid AND NOT EXISTS (
    SELECT 1
    FROM public.parent_child_links pcl
    WHERE pcl.parent_user_id = v_uid
      AND pcl.child_user_id = v_owner
      AND pcl.status = 'active'
  ) THEN
    RAISE EXCEPTION 'Not authorized for review events';
  END IF;

  RETURN QUERY
  SELECT e.*
  FROM public.ayah_review_events e
  WHERE e.user_id = v_owner
    AND (
      e.server_sequence > COALESCE(p_cursor_sequence, 0)
      OR (
        e.server_sequence = COALESCE(p_cursor_sequence, 0)
        AND e.event_id > COALESCE(p_cursor_event_id, '')
      )
    )
  ORDER BY server_sequence ASC, event_id ASC
  LIMIT v_limit;
END;
$fn$;

REVOKE ALL ON FUNCTION public.pull_ayah_review_events_since(UUID, BIGINT, TEXT, INTEGER)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.pull_ayah_review_events_since(UUID, BIGINT, TEXT, INTEGER)
  TO authenticated;
