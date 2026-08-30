-- Fresh-database behavioral contract for migration 0012.
-- Execute only after all migrations have been applied. Every fixture rolls back.

BEGIN;

CREATE OR REPLACE FUNCTION pg_temp.assert_true(
  p_condition BOOLEAN,
  p_label TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_condition IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'contract assertion failed: %', p_label;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION pg_temp.assert_raises(
  p_statement TEXT,
  p_expected_message TEXT,
  p_label TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  BEGIN
    EXECUTE p_statement;
  EXCEPTION
    WHEN raise_exception THEN
      IF SQLERRM = p_expected_message THEN
        RETURN;
      END IF;
      RAISE EXCEPTION
        'contract assertion failed: % (expected %, got %)',
        p_label,
        p_expected_message,
        SQLERRM;
  END;

  RAISE EXCEPTION 'contract assertion failed: % (statement succeeded)', p_label;
END;
$$;

SELECT pg_temp.assert_true(
  pg_get_function_result(
    'public.revoke_guardian_link(uuid)'::regprocedure
  ) = 'void',
  'guardian RPC returns void'
);

SELECT pg_temp.assert_true(
  pg_get_function_arguments(
    'public.revoke_guardian_link(uuid)'::regprocedure
  ) = 'p_counterpart_user_id uuid',
  'guardian RPC keeps the exact named argument'
);

SELECT pg_temp.assert_true(
  (
    SELECT p.prosecdef
      AND p.proconfig = ARRAY['search_path=""']::TEXT[]
    FROM pg_proc p
    WHERE p.oid = 'public.revoke_guardian_link(uuid)'::regprocedure
  ),
  'guardian RPC is SECURITY DEFINER with an empty search_path'
);

SELECT pg_temp.assert_true(
  has_function_privilege(
    'authenticated',
    'public.revoke_guardian_link(uuid)',
    'EXECUTE'
  ),
  'authenticated can execute guardian RPC'
);

SELECT pg_temp.assert_true(
  NOT has_function_privilege(
    'anon',
    'public.revoke_guardian_link(uuid)',
    'EXECUTE'
  ),
  'anon cannot execute guardian RPC'
);

SELECT pg_temp.assert_true(
  NOT has_function_privilege(
    'service_role',
    'public.revoke_guardian_link(uuid)',
    'EXECUTE'
  ),
  'service_role cannot execute authenticated-only guardian RPC'
);

SELECT pg_temp.assert_true(
  NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    CROSS JOIN LATERAL aclexplode(
      COALESCE(p.proacl, acldefault('f', p.proowner))
    ) acl
    WHERE p.oid = 'public.revoke_guardian_link(uuid)'::regprocedure
      AND acl.grantee = 0
      AND acl.privilege_type = 'EXECUTE'
  ),
  'PUBLIC cannot execute guardian RPC'
);

SELECT pg_temp.assert_true(
  NOT has_function_privilege(
    'anon',
    'public.prune_audit_logs()',
    'EXECUTE'
  ),
  'anon cannot prune audit logs'
);

SELECT pg_temp.assert_true(
  NOT has_function_privilege(
    'authenticated',
    'public.prune_audit_logs()',
    'EXECUTE'
  ),
  'authenticated cannot prune audit logs'
);

SELECT pg_temp.assert_true(
  has_function_privilege(
    'service_role',
    'public.prune_audit_logs()',
    'EXECUTE'
  ),
  'service_role can prune audit logs'
);

SELECT pg_temp.assert_true(
  NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    CROSS JOIN LATERAL aclexplode(
      COALESCE(p.proacl, acldefault('f', p.proowner))
    ) acl
    WHERE p.oid = 'public.prune_audit_logs()'::regprocedure
      AND acl.grantee = 0
      AND acl.privilege_type = 'EXECUTE'
  ),
  'PUBLIC cannot prune audit logs'
);

INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
VALUES
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'parent-one@example.test', '', NOW(), '{}'::JSONB, '{}'::JSONB, NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'child-one@example.test', '', NOW(), '{}'::JSONB, '{}'::JSONB, NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'child-two@example.test', '', NOW(), '{}'::JSONB, '{}'::JSONB, NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'parent-two@example.test', '', NOW(), '{}'::JSONB, '{}'::JSONB, NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'child-three@example.test', '', NOW(), '{}'::JSONB, '{}'::JSONB, NOW(), NOW());

INSERT INTO public.parent_child_links (parent_user_id, child_user_id)
VALUES
  ('10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001'),
  ('10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002'),
  ('10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003');

SELECT set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000001',
  TRUE
);
SELECT public.revoke_guardian_link(
  '20000000-0000-0000-0000-000000000001'
);
SELECT pg_temp.assert_true(
  (
    SELECT status = 'revoked' AND revoked_at IS NOT NULL
    FROM public.parent_child_links
    WHERE parent_user_id = '10000000-0000-0000-0000-000000000001'
      AND child_user_id = '20000000-0000-0000-0000-000000000001'
  ),
  'parent can revoke the exact active child link'
);
SELECT pg_temp.assert_true(
  (
    SELECT status = 'active' AND revoked_at IS NULL
    FROM public.parent_child_links
    WHERE parent_user_id = '10000000-0000-0000-0000-000000000001'
      AND child_user_id = '20000000-0000-0000-0000-000000000002'
  ),
  'parent revocation leaves the other active child link unchanged'
);

UPDATE public.parent_child_links
SET status = 'active', revoked_at = NULL
WHERE parent_user_id = '10000000-0000-0000-0000-000000000001'
  AND child_user_id = '20000000-0000-0000-0000-000000000001';

SELECT set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000001',
  TRUE
);
SELECT public.revoke_guardian_link(
  '10000000-0000-0000-0000-000000000001'
);
SELECT pg_temp.assert_true(
  (
    SELECT status = 'revoked' AND revoked_at IS NOT NULL
    FROM public.parent_child_links
    WHERE parent_user_id = '10000000-0000-0000-0000-000000000001'
      AND child_user_id = '20000000-0000-0000-0000-000000000001'
  ),
  'child can revoke the exact active guardian link'
);

UPDATE public.parent_child_links
SET status = 'active', revoked_at = NULL
WHERE parent_user_id = '10000000-0000-0000-0000-000000000001'
  AND child_user_id = '20000000-0000-0000-0000-000000000001';

SELECT set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000001',
  TRUE
);
SELECT pg_temp.assert_raises(
  $$SELECT public.revoke_guardian_link('20000000-0000-0000-0000-000000000003')$$,
  'No active guardian link between these users',
  'wrong counterpart is rejected'
);
SELECT pg_temp.assert_true(
  NOT EXISTS (
    SELECT 1
    FROM public.parent_child_links
    WHERE status <> 'active' OR revoked_at IS NOT NULL
  ),
  'wrong counterpart does not mutate any link'
);

SELECT set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000002',
  TRUE
);
SELECT pg_temp.assert_raises(
  $$SELECT public.revoke_guardian_link('20000000-0000-0000-0000-000000000001')$$,
  'No active guardian link between these users',
  'unrelated caller is rejected'
);
SELECT pg_temp.assert_true(
  NOT EXISTS (
    SELECT 1
    FROM public.parent_child_links
    WHERE status <> 'active' OR revoked_at IS NOT NULL
  ),
  'unrelated caller does not mutate any link'
);

SELECT set_config('request.jwt.claim.sub', '', TRUE);
SELECT pg_temp.assert_raises(
  $$SELECT public.revoke_guardian_link('20000000-0000-0000-0000-000000000001')$$,
  'Not authenticated',
  'unauthenticated caller is rejected by the function guard'
);
SELECT pg_temp.assert_true(
  NOT EXISTS (
    SELECT 1
    FROM public.parent_child_links
    WHERE status <> 'active' OR revoked_at IS NOT NULL
  ),
  'unauthenticated call does not mutate any link'
);

ROLLBACK;
