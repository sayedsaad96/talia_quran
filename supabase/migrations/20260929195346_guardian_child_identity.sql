-- Guardian ↔ child identity: the child's name and age reach the guardian's
-- family dashboard, and the guardian can correct them.
--
-- 1. `profiles.child_nickname` holds the name the child was set up with.
--    `profiles.display_name` stays the account name (often typed by whoever
--    signed up), so the two are kept apart and the dashboard prefers the
--    nickname. The age already lives in `profiles.age` (see 0011).
-- 2. `set_own_child_nickname(text)`: the child device publishes its own name.
-- 3. `update_linked_child_identity(uuid, text, integer)`: a guardian corrects
--    the name and age of a child linked to them. SECURITY DEFINER is required
--    because a guardian cannot write another account's profile row; the
--    ACTIVE link is enforced inside the function.
-- 4. `get_remote_children_dashboard()` also returns `child_nickname` and
--    `age`, and its `display_name` prefers the nickname.
--
-- Rules shared with the client (ChildIdentityPolicy): the name is trimmed,
-- inner whitespace collapsed, 1–50 characters, no control characters; the
-- age is 5–12. Both writers bump `profiles.updated_at`, which the client's
-- last-writer-wins identity pull already compares.

-- ── 1. Column ───────────────────────────────────────────────────────────────

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS child_nickname TEXT;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_child_nickname_valid;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_child_nickname_valid CHECK (
    child_nickname IS NULL
    OR (
      char_length(child_nickname) BETWEEN 1 AND 50
      AND child_nickname = btrim(child_nickname)
      AND child_nickname !~ '[[:cntrl:]]'
    )
  );

-- ── Shared normalization ────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.normalize_child_nickname(p_nickname TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT CASE
    WHEN p_nickname IS NULL THEN NULL
    ELSE pg_catalog.btrim(
      pg_catalog.regexp_replace(p_nickname, '\s+', ' ', 'g')
    )
  END;
$$;

REVOKE ALL ON FUNCTION public.normalize_child_nickname(TEXT)
  FROM PUBLIC, anon, authenticated, service_role;

-- ── 2. set_own_child_nickname ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.set_own_child_nickname(p_nickname TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_name TEXT := public.normalize_child_nickname(p_nickname);
  v_updated INTEGER;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF v_name IS NULL
    OR char_length(v_name) NOT BETWEEN 1 AND 50
    OR v_name ~ '[[:cntrl:]]' THEN
    RAISE EXCEPTION 'Invalid child nickname';
  END IF;

  UPDATE public.profiles p
  SET child_nickname = v_name,
      updated_at = NOW()
  WHERE p.id = v_caller
    AND p.selected_path IS DISTINCT FROM 'adult';

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated = 0 THEN
    RAISE EXCEPTION 'Only child profiles have a nickname';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.set_own_child_nickname(TEXT)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.set_own_child_nickname(TEXT) TO authenticated;

-- ── 3. update_linked_child_identity ─────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.update_linked_child_identity(
  p_child_user_id UUID,
  p_nickname TEXT,
  p_age INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_name TEXT := public.normalize_child_nickname(p_nickname);
  v_updated INTEGER;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Hold the link row until this transaction finishes, so a concurrent
  -- revocation cannot commit between authorization and the profile update.
  PERFORM 1
  FROM public.parent_child_links pcl
  WHERE pcl.parent_user_id = v_caller
    AND pcl.child_user_id = p_child_user_id
    AND pcl.status = 'active'
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No active guardian link for this child';
  END IF;

  IF v_name IS NULL
    OR char_length(v_name) NOT BETWEEN 1 AND 50
    OR v_name ~ '[[:cntrl:]]' THEN
    RAISE EXCEPTION 'Invalid child nickname';
  END IF;

  IF p_age IS NULL OR p_age NOT BETWEEN 5 AND 12 THEN
    RAISE EXCEPTION 'Invalid child age';
  END IF;

  UPDATE public.profiles p
  SET child_nickname = v_name,
      age = p_age,
      updated_at = NOW()
  WHERE p.id = p_child_user_id
    AND p.selected_path IS DISTINCT FROM 'adult';

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated = 0 THEN
    RAISE EXCEPTION 'Only child profiles have a nickname';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.update_linked_child_identity(UUID, TEXT, INTEGER)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.update_linked_child_identity(UUID, TEXT, INTEGER)
  TO authenticated;

-- ── 4. get_remote_children_dashboard ────────────────────────────────────────
-- Same body as 0006 plus `child_nickname` and `age`; `display_name` prefers
-- the nickname so older clients show it without changes.

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
    SELECT pcl.child_user_id, p.display_name, p.child_nickname, p.age
    FROM public.parent_child_links pcl
    JOIN public.profiles p ON p.id = pcl.child_user_id
    WHERE pcl.parent_user_id = v_uid
      AND pcl.status = 'active'
  LOOP
    v_child_json := jsonb_build_object(
      'child_user_id', v_child.child_user_id,
      'display_name', COALESCE(
        v_child.child_nickname,
        v_child.display_name,
        'طفل تالية'
      ),
      'child_nickname', v_child.child_nickname,
      'age', v_child.age,
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

REVOKE ALL ON FUNCTION public.get_remote_children_dashboard() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_remote_children_dashboard() TO authenticated;
