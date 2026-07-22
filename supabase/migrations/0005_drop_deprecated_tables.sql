-- ═══════════════════════════════════════════════════════════════════════════════
--  Talia Quran — Phase 8 Migration: Deprecated Legacy Cleanup
--  Safely drops legacy V1 tables and RPCs that have been fully superseded
--  by production V2 cloud tables and Isar local storage.
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. Drop unused legacy RPC function
DROP FUNCTION IF EXISTS public.upsert_ayah_progress(JSONB);

-- 2. Drop deprecated legacy tables (superseded by ayah_review_records_cloud & certificate_awards_cloud)
DROP TABLE IF EXISTS public.ayah_progress CASCADE;
DROP TABLE IF EXISTS public.bookmarks CASCADE;
DROP TABLE IF EXISTS public.certificates CASCADE;
