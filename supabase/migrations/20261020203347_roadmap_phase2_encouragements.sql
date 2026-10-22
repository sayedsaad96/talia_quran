CREATE TABLE IF NOT EXISTS public.kids_encouragements (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  parent_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  child_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_request_id UUID NOT NULL,
  message_key TEXT NOT NULL CHECK (message_key IN
    ('proud', 'well_done', 'keep_going', 'great_effort', 'see_you_tomorrow')),
  sticker_key TEXT NOT NULL CHECK (sticker_key IN ('star_reward', 'talia_encourage')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  seen_at TIMESTAMPTZ,
  CONSTRAINT kids_encouragements_request_unique UNIQUE (parent_user_id, client_request_id),
  CONSTRAINT kids_encouragements_distinct_users CHECK (parent_user_id <> child_user_id)
);
CREATE INDEX IF NOT EXISTS kids_encouragements_child_created ON public.kids_encouragements
  (child_user_id, created_at, id);
CREATE INDEX IF NOT EXISTS kids_encouragements_parent_child_created ON public.kids_encouragements
  (parent_user_id, child_user_id, created_at);

-- Global per-child quota survives message deletion and guardian replacement.
-- Neither clients nor their RPC arguments can choose the quota day/count.
CREATE TABLE IF NOT EXISTS public.kids_encouragement_quotas (
  child_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  utc_day DATE NOT NULL,
  used SMALLINT NOT NULL CHECK (used BETWEEN 1 AND 10),
  PRIMARY KEY (child_user_id, utc_day)
);
ALTER TABLE public.kids_encouragements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kids_encouragement_quotas ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kids_encouragements, public.kids_encouragement_quotas
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON SEQUENCE public.kids_encouragements_id_seq
  FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON public.kids_encouragements TO authenticated;

DROP POLICY IF EXISTS kids_encouragements_read ON public.kids_encouragements;
CREATE POLICY kids_encouragements_read ON public.kids_encouragements
FOR SELECT TO authenticated USING (
  ((SELECT auth.uid()) = parent_user_id OR (SELECT auth.uid()) = child_user_id)
  AND EXISTS (SELECT 1 FROM public.parent_child_links l
    WHERE l.parent_user_id = kids_encouragements.parent_user_id
      AND l.child_user_id = kids_encouragements.child_user_id AND l.status = 'active')
);

CREATE OR REPLACE FUNCTION public.send_kids_encouragement(
  p_child_user_id UUID, p_message_key TEXT, p_sticker_key TEXT, p_client_request_id UUID
)
RETURNS SETOF public.kids_encouragements LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_existing public.kids_encouragements;
  v_now TIMESTAMPTZ;
  v_used SMALLINT;
BEGIN
  IF v_caller IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_child_user_id IS NULL OR v_caller = p_child_user_id
    OR p_client_request_id IS NULL OR p_message_key IS NULL OR p_sticker_key IS NULL
    OR p_message_key NOT IN ('proud', 'well_done', 'keep_going', 'great_effort', 'see_you_tomorrow')
    OR p_sticker_key NOT IN ('star_reward', 'talia_encourage') THEN
    RAISE EXCEPTION 'Invalid encouragement';
  END IF;
  PERFORM 1 FROM public.parent_child_links l WHERE l.parent_user_id = v_caller
    AND l.child_user_id = p_child_user_id AND l.status = 'active' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Child link is not active'; END IF;
  SELECT * INTO v_existing FROM public.kids_encouragements e
    WHERE e.parent_user_id = v_caller AND e.client_request_id = p_client_request_id;
  IF FOUND THEN
    IF v_existing.child_user_id <> p_child_user_id
      OR v_existing.message_key <> p_message_key OR v_existing.sticker_key <> p_sticker_key THEN
      RAISE EXCEPTION 'Encouragement request mismatch';
    END IF;
    RETURN NEXT v_existing; RETURN;
  END IF;
  v_now := pg_catalog.clock_timestamp();
  INSERT INTO public.kids_encouragement_quotas AS q (child_user_id, utc_day, used)
    VALUES (p_child_user_id, (v_now AT TIME ZONE 'UTC')::DATE, 1)
    ON CONFLICT (child_user_id, utc_day) DO UPDATE SET used = q.used + 1
      WHERE q.used < 10 RETURNING used INTO v_used;
  IF NOT FOUND THEN RAISE EXCEPTION 'Encouragement daily limit reached'; END IF;
  RETURN QUERY INSERT INTO public.kids_encouragements (
    parent_user_id, child_user_id, client_request_id, message_key, sticker_key, created_at
  ) VALUES (v_caller, p_child_user_id, p_client_request_id,
    p_message_key, p_sticker_key, v_now) RETURNING *;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_kids_encouragements_seen(p_ids BIGINT[])
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_count INTEGER;
  v_now TIMESTAMPTZ;
BEGIN
  IF v_caller IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_ids IS NULL OR pg_catalog.cardinality(p_ids) > 100
    OR pg_catalog.array_position(p_ids, NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'Invalid encouragement ids';
  END IF;
  -- Match sender lock order (link before message), including stable order when
  -- a child acknowledges messages from several historical guardians.
  PERFORM 1 FROM public.parent_child_links l
    WHERE l.child_user_id = v_caller AND l.status = 'active'
      AND EXISTS (SELECT 1 FROM public.kids_encouragements e
        WHERE e.id = ANY(p_ids) AND e.child_user_id = v_caller
          AND e.parent_user_id = l.parent_user_id)
    ORDER BY l.parent_user_id, l.child_user_id FOR UPDATE;
  v_now := pg_catalog.clock_timestamp();
  UPDATE public.kids_encouragements e SET seen_at = v_now
    WHERE e.id = ANY(p_ids) AND e.child_user_id = v_caller AND e.seen_at IS NULL
      AND EXISTS (SELECT 1 FROM public.parent_child_links l
        WHERE l.parent_user_id = e.parent_user_id AND l.child_user_id = v_caller
          AND l.status = 'active');
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;
REVOKE ALL ON FUNCTION public.send_kids_encouragement(UUID, TEXT, TEXT, UUID),
  public.mark_kids_encouragements_seen(BIGINT[])
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.send_kids_encouragement(UUID, TEXT, TEXT, UUID),
  public.mark_kids_encouragements_seen(BIGINT[]) TO authenticated;
