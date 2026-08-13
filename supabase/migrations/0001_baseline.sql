-- Talia Quran — Baseline schema
--
-- Deployment:
--   NEW projects: apply ../../supabase_schema.sql first, then numbered
--   migrations from 0008 onward that are not already folded into the
--   canonical file (currently through 0010).
--   EXISTING projects: skip this file and apply numbered migrations
--   starting from 0002_audit_patches.sql in order through 0010.
--
-- The Flutter client requires migrations through 0010:
--   0007 audience uniqueness, 0008 custom plans, 0009 composite cursor
--   + v2 push acknowledgement, 0010 kids session log ayah uniqueness.
--
-- Orphan RPCs from 0004 (pull_child_review_records_page,
-- prune_kids_session_logs) are unused by the client and are dropped in 0010.

SELECT 1;
