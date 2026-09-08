-- Correct the append RPC shipped in ayah_review_events_v1.
--
-- PostgreSQL resolves unqualified names in RETURNING against both the inserted
-- row and PL/pgSQL output parameters. Qualifying server_sequence with the
-- INSERT alias prevents the output parameter of the same name from making a
-- valid append fail and get reported as rejected by the per-item exception
-- boundary.
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
  v_existing_same BOOLEAN;
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
  IF pg_column_size(p_events) > 262144 THEN
    RAISE EXCEPTION 'Batch payload too large (max 256 KiB)';
  END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_events)
  LOOP
    event_id := COALESCE(NULLIF(v_item->>'event_id', ''), 'invalid');
    result := 'rejected';
    server_sequence := NULL;
    v_sequence := NULL;
    v_existing_same := FALSE;
    BEGIN
      IF jsonb_typeof(v_item) <> 'object' THEN
        RETURN NEXT;
        CONTINUE;
      END IF;
      IF EXISTS (
        SELECT 1
        FROM jsonb_object_keys(v_item) AS supplied(key)
        WHERE supplied.key <> ALL (ARRAY[
          'event_id', 'audience', 'session_id', 'task_id', 'surah_id',
          'ayah_number', 'event_type', 'assessment', 'outcome', 'rating',
          'similarity_score', 'attempt_count', 'failure_count', 'hint_level',
          'occurred_at', 'study_day_key'
        ])
      ) THEN
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

      INSERT INTO public.ayah_review_events AS inserted (
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
      ON CONFLICT DO NOTHING
      RETURNING inserted.server_sequence INTO v_sequence;

      event_id := v_event_id;
      IF v_sequence IS NULL THEN
        SELECT
          e.server_sequence,
          e.audience = v_audience
            AND e.session_id = v_session_id
            AND e.task_id = v_task_id
            AND e.surah_id = v_surah_id
            AND e.ayah_number = v_ayah_number
            AND e.event_type = v_event_type
            AND e.assessment = v_assessment
            AND e.outcome = v_outcome
            AND e.rating IS NOT DISTINCT FROM v_rating
            AND e.similarity_score IS NOT DISTINCT FROM v_similarity
            AND e.attempt_count = v_attempt_count
            AND e.failure_count = v_failure_count
            AND e.hint_level = v_hint_level
            AND e.occurred_at = v_occurred_at
            AND e.study_day_key = v_study_day_key
        INTO v_sequence, v_existing_same
        FROM public.ayah_review_events e
        WHERE e.user_id = v_uid
          AND (
            e.event_id = v_event_id
            OR (
              e.session_id = v_session_id
              AND e.task_id = v_task_id
              AND e.event_type = v_event_type
              AND e.attempt_count = v_attempt_count
            )
          )
        ORDER BY (e.event_id = v_event_id) DESC
        LIMIT 1;
        IF v_existing_same THEN
          result := 'alreadyApplied';
          server_sequence := v_sequence;
        ELSE
          result := 'rejected';
          server_sequence := NULL;
        END IF;
      ELSE
        result := 'applied';
        server_sequence := v_sequence;
      END IF;
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
