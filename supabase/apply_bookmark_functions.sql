-- ─────────────────────────────────────────────────────────────────────────────
-- إصلاح خطأ PGRST202: دالة pull_quran_bookmarks غير موجودة على القاعدة البعيدة
-- ─────────────────────────────────────────────────────────────────────────────
-- هذا الملف مستخرج من migration:
--   supabase/migrations/20260820221531_production_data_layer_remediation.sql
-- الذي لم يُطبَّق على قاعدة بيانات Supabase البعيدة.
--
-- خطوات التطبيق:
--   1. افتح Supabase Dashboard → مشروعك → SQL Editor → New query.
--   2. الصق محتوى هذا الملف كاملاً واضغط Run.
--   3. تأكد من نجاح التنفيذ، ثم أعد تشغيل التطبيق وسجّل دخول —
--      لا يجب أن تظهر تحذيرات "Could not find the function public.pull_quran_bookmarks".
--
-- كل الأوامر أدناه idempotent (آمنة لإعادة التشغيل أكثر من مرة).
-- ─────────────────────────────────────────────────────────────────────────────

-- Bookmarks are account data. Tombstones make deletes durable across devices.
CREATE TABLE IF NOT EXISTS public.quran_bookmarks_cloud (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  surah_id INTEGER NOT NULL CHECK (surah_id BETWEEN 1 AND 114),
  ayah_number INTEGER NOT NULL CHECK (ayah_number BETWEEN 1 AND 286),
  payload JSONB NOT NULL DEFAULT '{}'::JSONB CHECK (pg_column_size(payload) <= 12000),
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  revision BIGINT NOT NULL DEFAULT 0 CHECK (revision >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, surah_id, ayah_number)
);

CREATE INDEX IF NOT EXISTS idx_quran_bookmarks_cloud_user_updated
  ON public.quran_bookmarks_cloud (user_id, updated_at DESC);

ALTER TABLE public.quran_bookmarks_cloud ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.quran_bookmarks_cloud FROM anon, authenticated;
GRANT SELECT ON public.quran_bookmarks_cloud TO authenticated;

DROP POLICY IF EXISTS quran_bookmarks_cloud_owner_read ON public.quran_bookmarks_cloud;
CREATE POLICY quran_bookmarks_cloud_owner_read
  ON public.quran_bookmarks_cloud FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE OR REPLACE FUNCTION public.upsert_quran_bookmark(
  p_surah_id INTEGER,
  p_ayah_number INTEGER,
  p_payload JSONB,
  p_revision BIGINT,
  p_is_deleted BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (surah_id INTEGER, ayah_number INTEGER, revision BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF p_surah_id NOT BETWEEN 1 AND 114 OR p_ayah_number NOT BETWEEN 1 AND 286 THEN
    RAISE EXCEPTION 'Invalid verse identity';
  END IF;
  IF p_revision < 1 OR pg_column_size(COALESCE(p_payload, '{}'::JSONB)) > 12000 THEN
    RAISE EXCEPTION 'Invalid bookmark mutation';
  END IF;

  RETURN QUERY
  INSERT INTO public.quran_bookmarks_cloud (
    user_id, surah_id, ayah_number, payload, is_deleted, revision, updated_at, deleted_at
  ) VALUES (
    v_uid, p_surah_id, p_ayah_number, COALESCE(p_payload, '{}'::JSONB),
    p_is_deleted, p_revision, NOW(), CASE WHEN p_is_deleted THEN NOW() ELSE NULL END
  )
  ON CONFLICT (user_id, surah_id, ayah_number) DO UPDATE SET
    payload = EXCLUDED.payload,
    is_deleted = EXCLUDED.is_deleted,
    revision = EXCLUDED.revision,
    updated_at = NOW(),
    deleted_at = CASE WHEN EXCLUDED.is_deleted THEN NOW() ELSE NULL END
  WHERE EXCLUDED.revision > quran_bookmarks_cloud.revision
  RETURNING quran_bookmarks_cloud.surah_id, quran_bookmarks_cloud.ayah_number,
    quran_bookmarks_cloud.revision;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.pull_quran_bookmarks()
RETURNS SETOF public.quran_bookmarks_cloud
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $fn$
  SELECT * FROM public.quran_bookmarks_cloud
  WHERE user_id = auth.uid()
  ORDER BY updated_at ASC, surah_id ASC, ayah_number ASC;
$fn$;

REVOKE ALL ON FUNCTION public.upsert_quran_bookmark(INTEGER, INTEGER, JSONB, BIGINT, BOOLEAN)
  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.pull_quran_bookmarks() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.upsert_quran_bookmark(INTEGER, INTEGER, JSONB, BIGINT, BOOLEAN)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.pull_quran_bookmarks() TO authenticated;
