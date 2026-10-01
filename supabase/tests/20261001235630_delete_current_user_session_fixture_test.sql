-- Run only against an isolated local/staging Supabase database, inside a
-- transaction. The harness must create two disposable auth users and sessions
-- and set request.jwt.claims for each case; never run against production.
BEGIN;

-- Fixture assertions to execute with a valid A session:
--   1. public.delete_current_user() removes only A and its FK-cascade rows.
--   2. B and B's cascade rows remain.
--   3. Repeating with A's now-absent auth.users row returns successfully.
--   4. A JWT with B's session_id raises "no longer active".
--   5. A revoked/missing auth.sessions row raises "no longer active".
--   6. An anon JWT raises "Authenticated session is required".
--
-- The test runner supplies fixture UUIDs and claims because auth.users and
-- auth.sessions are Supabase-owned system tables. Keeping those identifiers
-- outside versioned SQL prevents accidental execution against real accounts.
DO $$
BEGIN
  IF pg_get_functiondef('public.delete_current_user()'::regprocedure)
      NOT LIKE '%auth.sessions%' THEN
    RAISE EXCEPTION 'fixture prerequisite: session validation missing';
  END IF;
END;
$$;

ROLLBACK;
