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
