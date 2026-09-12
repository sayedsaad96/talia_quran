-- Correct the upsert_quran_bookmark RPC to prevent PL/pgSQL variable ambiguity.
--
-- When RETURNS TABLE (surah_id INTEGER, ayah_number INTEGER, revision BIGINT) is used,
-- PL/pgSQL declares output parameters named surah_id, ayah_number, and revision.
-- In ON CONFLICT (user_id, surah_id, ayah_number), PostgreSQL parser treats surah_id
-- as an expression and cannot resolve whether it refers to the PL/pgSQL variable or
-- the table column, throwing error 42702 (column reference "surah_id" is ambiguous).
--
-- Adding the #variable_conflict use_column directive instructs PL/pgSQL to resolve
-- ambiguous references in SQL statements to table columns.

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
#variable_conflict use_column
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

REVOKE ALL ON FUNCTION public.upsert_quran_bookmark(INTEGER, INTEGER, JSONB, BIGINT, BOOLEAN)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.upsert_quran_bookmark(INTEGER, INTEGER, JSONB, BIGINT, BOOLEAN)
  TO authenticated;
