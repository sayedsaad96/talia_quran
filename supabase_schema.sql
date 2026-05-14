-- ═══════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════
--  Kids Remote Parent Linking
--  Optional cloud layer for Kids Mode parent monitoring
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.child_link_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL UNIQUE CHECK (char_length(token_hash) = 64),
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_child_link_requests_child
  ON public.child_link_requests(child_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_child_link_requests_token
  ON public.child_link_requests(token_hash)
  WHERE used_at IS NULL;

CREATE TABLE IF NOT EXISTS public.parent_child_links (
  parent_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  child_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'revoked')),
  linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  PRIMARY KEY (parent_user_id, child_user_id),
  CHECK (parent_user_id <> child_user_id)
);

CREATE INDEX IF NOT EXISTS idx_parent_child_links_child
  ON public.parent_child_links(child_user_id);

CREATE TABLE IF NOT EXISTS public.kids_progress_cloud (
  child_user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  total_points INTEGER NOT NULL DEFAULT 0 CHECK (total_points >= 0),
  current_level INTEGER NOT NULL DEFAULT 1 CHECK (current_level >= 1),
  current_streak INTEGER NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
  stars_earned INTEGER NOT NULL DEFAULT 0 CHECK (stars_earned >= 0),
  ayahs_completed INTEGER NOT NULL DEFAULT 0 CHECK (ayahs_completed >= 0),
  last_session_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.kids_session_logs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  child_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  local_id TEXT NOT NULL CHECK (char_length(local_id) <= 120),
  surah_id INTEGER NOT NULL CHECK (surah_id >= 1 AND surah_id <= 114),
  ayah_number INTEGER NOT NULL CHECK (ayah_number >= 1 AND ayah_number <= 286),
  repeats_completed INTEGER NOT NULL DEFAULT 0 CHECK (repeats_completed >= 0),
  points_earned INTEGER NOT NULL DEFAULT 0 CHECK (points_earned >= 0),
  completed_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_child_session_log UNIQUE (child_user_id, local_id)
);

CREATE INDEX IF NOT EXISTS idx_kids_session_logs_child
  ON public.kids_session_logs(child_user_id, completed_at DESC);

CREATE TABLE IF NOT EXISTS public.parent_rewards (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  parent_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  child_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (char_length(title) BETWEEN 1 AND 120),
  status TEXT NOT NULL DEFAULT 'locked'
    CHECK (status IN ('locked', 'unlocked', 'claimed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unlocked_at TIMESTAMPTZ,
  claimed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_parent_rewards_child
  ON public.parent_rewards(child_user_id, created_at DESC);

ALTER TABLE public.child_link_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_child_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kids_progress_cloud ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kids_session_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_rewards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "child_link_requests_child_own"
  ON public.child_link_requests FOR SELECT
  USING (auth.uid() = child_user_id);

CREATE POLICY "parent_child_links_parent_or_child_read"
  ON public.parent_child_links FOR SELECT
  USING (auth.uid() = parent_user_id OR auth.uid() = child_user_id);

CREATE POLICY "kids_progress_child_write"
  ON public.kids_progress_cloud FOR ALL
  USING (auth.uid() = child_user_id)
  WITH CHECK (auth.uid() = child_user_id);

CREATE POLICY "kids_progress_parent_read"
  ON public.kids_progress_cloud FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.parent_child_links pcl
      WHERE pcl.child_user_id = kids_progress_cloud.child_user_id
        AND pcl.parent_user_id = auth.uid()
        AND pcl.status = 'active'
    )
  );

CREATE POLICY "kids_session_logs_child_write"
  ON public.kids_session_logs FOR ALL
  USING (auth.uid() = child_user_id)
  WITH CHECK (auth.uid() = child_user_id);

CREATE POLICY "kids_session_logs_parent_read"
  ON public.kids_session_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.parent_child_links pcl
      WHERE pcl.child_user_id = kids_session_logs.child_user_id
        AND pcl.parent_user_id = auth.uid()
        AND pcl.status = 'active'
    )
  );

CREATE POLICY "parent_rewards_parent_manage"
  ON public.parent_rewards FOR ALL
  USING (
    auth.uid() = parent_user_id
    AND EXISTS (
      SELECT 1 FROM public.parent_child_links pcl
      WHERE pcl.child_user_id = parent_rewards.child_user_id
        AND pcl.parent_user_id = auth.uid()
        AND pcl.status = 'active'
    )
  )
  WITH CHECK (
    auth.uid() = parent_user_id
    AND EXISTS (
      SELECT 1 FROM public.parent_child_links pcl
      WHERE pcl.child_user_id = parent_rewards.child_user_id
        AND pcl.parent_user_id = auth.uid()
        AND pcl.status = 'active'
    )
  );

CREATE POLICY "parent_rewards_child_read"
  ON public.parent_rewards FOR SELECT
  USING (auth.uid() = child_user_id);

CREATE POLICY "profiles_parent_read_linked_child"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.parent_child_links pcl
      WHERE pcl.child_user_id = profiles.id
        AND pcl.parent_user_id = auth.uid()
        AND pcl.status = 'active'
    )
  );

-- ─── Token creation: Flutter generates token + hash, DB just stores it ────────
-- No pgcrypto needed: Flutter generates the random token and SHA-256 hash
CREATE OR REPLACE FUNCTION public.create_child_link_request_with_hash(p_token_hash TEXT)
RETURNS VOID AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF char_length(p_token_hash) != 64 THEN
    RAISE EXCEPTION 'Invalid token hash length';
  END IF;

  -- Clean up old expired tokens for this user first
  DELETE FROM public.child_link_requests
  WHERE child_user_id = v_uid AND expires_at < NOW();

  INSERT INTO public.child_link_requests (child_user_id, token_hash, expires_at)
  VALUES (v_uid, p_token_hash, NOW() + INTERVAL '10 minutes');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ─── Token acceptance: Flutter hashes the scanned token, DB verifies hash ────
CREATE OR REPLACE FUNCTION public.accept_child_link_token_with_hash(p_token_hash TEXT)
RETURNS VOID AS $$
DECLARE
  v_parent UUID := auth.uid();
  v_child UUID;
BEGIN
  IF v_parent IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT child_user_id INTO v_child
  FROM public.child_link_requests
  WHERE token_hash = p_token_hash
    AND used_at IS NULL
    AND expires_at > NOW()
  LIMIT 1;

  IF v_child IS NULL THEN
    RAISE EXCEPTION 'Invalid or expired link token';
  END IF;
  IF v_child = v_parent THEN
    RAISE EXCEPTION 'Parent and child accounts must be different';
  END IF;

  INSERT INTO public.parent_child_links (parent_user_id, child_user_id, status, linked_at)
  VALUES (v_parent, v_child, 'active', NOW())
  ON CONFLICT (parent_user_id, child_user_id)
  DO UPDATE SET status = 'active', revoked_at = NULL, linked_at = NOW();

  UPDATE public.child_link_requests
  SET used_at = NOW()
  WHERE token_hash = p_token_hash;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.upsert_kids_progress_cloud(
  p_total_points INTEGER,
  p_current_level INTEGER,
  p_current_streak INTEGER,
  p_stars_earned INTEGER,
  p_ayahs_completed INTEGER,
  p_last_session_at TIMESTAMPTZ
)
RETURNS VOID AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO public.kids_progress_cloud (
    child_user_id, total_points, current_level, current_streak,
    stars_earned, ayahs_completed, last_session_at
  )
  VALUES (
    v_uid, p_total_points, p_current_level, p_current_streak,
    p_stars_earned, p_ayahs_completed, p_last_session_at
  )
  ON CONFLICT (child_user_id)
  DO UPDATE SET
    total_points = GREATEST(kids_progress_cloud.total_points, p_total_points),
    current_level = GREATEST(kids_progress_cloud.current_level, p_current_level),
    current_streak = GREATEST(kids_progress_cloud.current_streak, p_current_streak),
    stars_earned = GREATEST(kids_progress_cloud.stars_earned, p_stars_earned),
    ayahs_completed = GREATEST(kids_progress_cloud.ayahs_completed, p_ayahs_completed),
    last_session_at = GREATEST(kids_progress_cloud.last_session_at, p_last_session_at),
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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
  ON CONFLICT (child_user_id, local_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.create_child_link_request_with_hash(TEXT) FROM anon;
REVOKE EXECUTE ON FUNCTION public.accept_child_link_token_with_hash(TEXT) FROM anon;
REVOKE EXECUTE ON FUNCTION public.upsert_kids_progress_cloud(INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, TIMESTAMPTZ) FROM anon;
REVOKE EXECUTE ON FUNCTION public.insert_kids_session_log(TEXT, INTEGER, INTEGER, INTEGER, INTEGER, TIMESTAMPTZ) FROM anon;

GRANT EXECUTE ON FUNCTION public.create_child_link_request_with_hash(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_child_link_token_with_hash(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_kids_progress_cloud(INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.insert_kids_session_log(TEXT, INTEGER, INTEGER, INTEGER, INTEGER, TIMESTAMPTZ) TO authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════
--  Talia Quran — Supabase Schema (Security Hardened)
--  Run this SQL in your Supabase Dashboard > SQL Editor
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── 1. User Profiles ────────────────────────────────────────────────────────
-- Extends Supabase auth.users with app-specific data
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT 'مستخدم'
    CHECK (char_length(display_name) <= 100),
  avatar_url TEXT
    CHECK (avatar_url IS NULL OR char_length(avatar_url) <= 500),
  age INTEGER
    CHECK (age IS NULL OR (age >= 1 AND age <= 150)),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    LEFT(COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      'مستخدم'
    ), 100),
    LEFT(NEW.raw_user_meta_data->>'avatar_url', 500)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: fires after a new user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();


-- ─── 2. Ayah Progress (Memorization Tracking) ───────────────────────────────
-- Mirrors IsarAyahProgress — stores per-ayah memorization state
CREATE TABLE IF NOT EXISTS public.ayah_progress (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  surah_id INTEGER NOT NULL
    CHECK (surah_id >= 1 AND surah_id <= 114),
  ayah_number INTEGER NOT NULL
    CHECK (ayah_number >= 1 AND ayah_number <= 286),
  status TEXT NOT NULL DEFAULT 'notStarted'
    CHECK (status IN ('notStarted', 'learning', 'review', 'memorized')),
  repetitions INTEGER NOT NULL DEFAULT 0
    CHECK (repetitions >= 0 AND repetitions <= 10000),
  next_review_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_review_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- One record per user + surah + ayah combination
  CONSTRAINT unique_user_ayah UNIQUE (user_id, surah_id, ayah_number)
);

-- Fast lookups by user
CREATE INDEX IF NOT EXISTS idx_ayah_progress_user
  ON public.ayah_progress(user_id);

-- Fast lookups for review-due ayahs
CREATE INDEX IF NOT EXISTS idx_ayah_progress_review
  ON public.ayah_progress(user_id, next_review_date);


-- ─── 3. Streak Data ─────────────────────────────────────────────────────────
-- Mirrors StreakIsar — one row per user
CREATE TABLE IF NOT EXISTS public.streaks (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  current_streak INTEGER NOT NULL DEFAULT 0
    CHECK (current_streak >= 0 AND current_streak <= 36500),
  longest_streak INTEGER NOT NULL DEFAULT 0
    CHECK (longest_streak >= 0 AND longest_streak <= 36500),
  last_activity_date DATE,
  freezes_available INTEGER NOT NULL DEFAULT 0
    CHECK (freezes_available >= 0 AND freezes_available <= 30),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ─── 4. XP Data ─────────────────────────────────────────────────────────────
-- Mirrors XpIsar — one row per user
CREATE TABLE IF NOT EXISTS public.xp (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  total_xp INTEGER NOT NULL DEFAULT 0
    CHECK (total_xp >= 0 AND total_xp <= 100000000),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ─── 5. XP History (Audit Log) ──────────────────────────────────────────────
-- Tracks every XP gain for analytics (immutable audit log)
CREATE TABLE IF NOT EXISTS public.xp_history (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL
    CHECK (char_length(action) <= 50),
  xp_gained INTEGER NOT NULL
    CHECK (xp_gained >= 0 AND xp_gained <= 1000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_xp_history_user
  ON public.xp_history(user_id, created_at DESC);


-- ─── 6. Bookmarks ───────────────────────────────────────────────────────────
-- Cloud-synced bookmarks
CREATE TABLE IF NOT EXISTS public.bookmarks (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  surah_id INTEGER NOT NULL
    CHECK (surah_id >= 1 AND surah_id <= 114),
  surah_name TEXT NOT NULL
    CHECK (char_length(surah_name) <= 50),
  ayah_number INTEGER NOT NULL
    CHECK (ayah_number >= 1 AND ayah_number <= 286),
  ayah_text TEXT NOT NULL DEFAULT ''
    CHECK (char_length(ayah_text) <= 2000),
  saved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT unique_user_bookmark UNIQUE (user_id, surah_id, ayah_number)
);

CREATE INDEX IF NOT EXISTS idx_bookmarks_user
  ON public.bookmarks(user_id, saved_at DESC);


-- ─── 7. Certificates ────────────────────────────────────────────────────────
-- Records of completed Juz certificates
CREATE TABLE IF NOT EXISTS public.certificates (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  juz_number INTEGER NOT NULL
    CHECK (juz_number >= 1 AND juz_number <= 30),
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  certificate_url TEXT
    CHECK (certificate_url IS NULL OR char_length(certificate_url) <= 500),

  CONSTRAINT unique_user_certificate UNIQUE (user_id, juz_number)
);


-- ─── 8. Auto-update `updated_at` Trigger ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT unnest(ARRAY[
      'profiles', 'ayah_progress', 'streaks', 'xp'
    ])
  LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS set_updated_at ON public.%I; '
      'CREATE TRIGGER set_updated_at '
      'BEFORE UPDATE ON public.%I '
      'FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();',
      tbl, tbl
    );
  END LOOP;
END $$;


-- ═══════════════════════════════════════════════════════════════════════════════
--  Row Level Security (RLS)
--  Each user can ONLY read/write their own data — no exceptions
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ayah_progress   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streaks         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xp              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xp_history      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.certificates    ENABLE ROW LEVEL SECURITY;

-- ── Profiles ──
-- SELECT: own profile only
CREATE POLICY "profiles_select_own"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- UPDATE: own profile only (cannot change id)
CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- INSERT: BLOCKED — profiles are created only by the trigger
-- (No INSERT policy = denied by default when RLS is on)

-- DELETE: BLOCKED — profiles are deleted only via CASCADE from auth.users
-- (No DELETE policy = denied by default when RLS is on)

-- ── Ayah Progress ──
CREATE POLICY "ayah_progress_all_own"
  ON public.ayah_progress FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Streaks ──
CREATE POLICY "streaks_all_own"
  ON public.streaks FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── XP ──
CREATE POLICY "xp_all_own"
  ON public.xp FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── XP History (Audit Log — immutable) ──
CREATE POLICY "xp_history_select_own"
  ON public.xp_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "xp_history_insert_own"
  ON public.xp_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: BLOCKED — audit log is immutable
-- DELETE: BLOCKED — audit log is immutable

-- ── Bookmarks ──
CREATE POLICY "bookmarks_all_own"
  ON public.bookmarks FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Certificates ──
CREATE POLICY "certificates_all_own"
  ON public.certificates FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- ═══════════════════════════════════════════════════════════════════════════════
--  Upsert Functions (SECURITY DEFINER — bypasses RLS but validates auth)
--
--  SECURITY NOTE: These functions use SECURITY DEFINER because they need to
--  bypass RLS to do ON CONFLICT upserts. Each function validates auth.uid()
--  is NOT NULL before proceeding, preventing unauthenticated access.
-- ═══════════════════════════════════════════════════════════════════════════════

-- Bulk upsert ayah progress (called during sync)
CREATE OR REPLACE FUNCTION public.upsert_ayah_progress(
  p_data JSONB  -- Array of { surah_id, ayah_number, status, repetitions, next_review_date, last_review_date }
)
RETURNS VOID AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  -- SECURITY: Reject unauthenticated calls
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- SECURITY: Limit batch size to prevent abuse
  IF jsonb_array_length(p_data) > 6236 THEN
    RAISE EXCEPTION 'Batch too large (max 6236 ayahs)';
  END IF;

  INSERT INTO public.ayah_progress (
    user_id, surah_id, ayah_number, status, repetitions, next_review_date, last_review_date
  )
  SELECT
    v_uid,
    (item->>'surah_id')::INTEGER,
    (item->>'ayah_number')::INTEGER,
    item->>'status',
    (item->>'repetitions')::INTEGER,
    (item->>'next_review_date')::TIMESTAMPTZ,
    (item->>'last_review_date')::TIMESTAMPTZ
  FROM jsonb_array_elements(p_data) AS item
  ON CONFLICT (user_id, surah_id, ayah_number)
  DO UPDATE SET
    status = EXCLUDED.status,
    repetitions = EXCLUDED.repetitions,
    next_review_date = EXCLUDED.next_review_date,
    last_review_date = EXCLUDED.last_review_date,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Upsert streak data (called during sync)
CREATE OR REPLACE FUNCTION public.upsert_streak(
  p_current_streak INTEGER,
  p_longest_streak INTEGER,
  p_last_activity_date DATE,
  p_freezes_available INTEGER
)
RETURNS VOID AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  -- SECURITY: Reject unauthenticated calls
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- SECURITY: Validate input ranges
  IF p_current_streak < 0 OR p_current_streak > 36500 THEN
    RAISE EXCEPTION 'Invalid current_streak';
  END IF;
  IF p_longest_streak < 0 OR p_longest_streak > 36500 THEN
    RAISE EXCEPTION 'Invalid longest_streak';
  END IF;
  IF p_freezes_available < 0 OR p_freezes_available > 30 THEN
    RAISE EXCEPTION 'Invalid freezes_available';
  END IF;

  INSERT INTO public.streaks (user_id, current_streak, longest_streak, last_activity_date, freezes_available)
  VALUES (v_uid, p_current_streak, p_longest_streak, p_last_activity_date, p_freezes_available)
  ON CONFLICT (user_id)
  DO UPDATE SET
    current_streak = GREATEST(streaks.current_streak, p_current_streak),
    longest_streak = GREATEST(streaks.longest_streak, p_longest_streak),
    last_activity_date = GREATEST(streaks.last_activity_date, p_last_activity_date),
    freezes_available = p_freezes_available,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Upsert XP (takes the max — prevents cheating)
CREATE OR REPLACE FUNCTION public.upsert_xp(p_total_xp INTEGER)
RETURNS VOID AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  -- SECURITY: Reject unauthenticated calls
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- SECURITY: Validate input range
  IF p_total_xp < 0 OR p_total_xp > 100000000 THEN
    RAISE EXCEPTION 'Invalid total_xp';
  END IF;

  INSERT INTO public.xp (user_id, total_xp)
  VALUES (v_uid, p_total_xp)
  ON CONFLICT (user_id)
  DO UPDATE SET
    total_xp = GREATEST(xp.total_xp, p_total_xp),
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ═══════════════════════════════════════════════════════════════════════════════
--  Revoke direct access to RPC functions from anon role
--  Only authenticated users should be able to call these
-- ═══════════════════════════════════════════════════════════════════════════════

REVOKE EXECUTE ON FUNCTION public.upsert_ayah_progress(JSONB) FROM anon;
REVOKE EXECUTE ON FUNCTION public.upsert_streak(INTEGER, INTEGER, DATE, INTEGER) FROM anon;
REVOKE EXECUTE ON FUNCTION public.upsert_xp(INTEGER) FROM anon;

GRANT EXECUTE ON FUNCTION public.upsert_ayah_progress(JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_streak(INTEGER, INTEGER, DATE, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_xp(INTEGER) TO authenticated;


-- ═══════════════════════════════════════════════════════════════════════════════
--  Storage Bucket (for certificate images)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Run this separately if needed:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('certificates', 'certificates', true);

-- Storage policy: users can upload to their own folder only
-- CREATE POLICY "Users can upload certificates"
--   ON storage.objects FOR INSERT
--   WITH CHECK (bucket_id = 'certificates' AND auth.uid()::TEXT = (storage.foldername(name))[1]);


-- ═══════════════════════════════════════════════════════════════════════════════
--  Done! 🎉
--
--  Security features:
--    ✅ RLS on ALL 7 tables (user isolation)
--    ✅ profiles: INSERT/DELETE blocked (trigger-only creation, CASCADE deletion)
--    ✅ xp_history: UPDATE/DELETE blocked (immutable audit log)
--    ✅ RPC functions: auth.uid() NULL check + input validation
--    ✅ RPC functions: REVOKE from anon, GRANT to authenticated only
--    ✅ CHECK constraints on all numeric/text fields (range + length limits)
--    ✅ Batch size limit on bulk upsert (max 6236 = total Quran ayahs)
--    ✅ ON DELETE CASCADE: user deletion cleans all related data
-- ═══════════════════════════════════════════════════════════════════════════════


-- ---------------------------------------------------------------------------
--  Daily Activities (Streak Activity Log)
--  Mirrors DailyActivityIsar -- one row per user per UTC calendar day
--  day_key is stored as YYYYMMDD integer (e.g. 20260504) for fast lookup
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.daily_activities (
  user_id     UUID    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  day_key     INTEGER NOT NULL
    CHECK (day_key >= 20200101 AND day_key <= 20991231),
  activity_count INTEGER NOT NULL DEFAULT 0
    CHECK (activity_count >= 0 AND activity_count <= 100000),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  PRIMARY KEY (user_id, day_key)
);

CREATE INDEX IF NOT EXISTS idx_daily_activities_user
  ON public.daily_activities(user_id, day_key DESC);

ALTER TABLE public.daily_activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "daily_activities_all_own"
  ON public.daily_activities FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Batch upsert daily activities (called during cloud sync).
-- Takes a max of GREATEST(local, cloud) to prevent data loss from both sides.
CREATE OR REPLACE FUNCTION public.upsert_daily_activities_batch(
  p_data JSONB  -- Array of { day_key: int, activity_count: int }
)
RETURNS VOID AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF jsonb_array_length(p_data) > 3650 THEN
    RAISE EXCEPTION 'Batch too large (max 3650 days = 10 years)';
  END IF;

  INSERT INTO public.daily_activities (user_id, day_key, activity_count)
  SELECT
    v_uid,
    (item->>'day_key')::INTEGER,
    (item->>'activity_count')::INTEGER
  FROM jsonb_array_elements(p_data) AS item
  ON CONFLICT (user_id, day_key)
  DO UPDATE SET
    activity_count = GREATEST(
      daily_activities.activity_count,
      EXCLUDED.activity_count
    ),
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.upsert_daily_activities_batch(JSONB) FROM anon;
GRANT  EXECUTE ON FUNCTION public.upsert_daily_activities_batch(JSONB) TO authenticated;
