-- Fresh-database behavioral contract for migration
-- 20260929195346_guardian_child_identity. Execute only after all migrations
-- have been applied. Every fixture rolls back.

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

-- ── Signatures, security and grants ─────────────────────────────────────────

SELECT pg_temp.assert_true(
  pg_get_function_arguments(
    'public.set_own_child_nickname(text)'::regprocedure
  ) = 'p_nickname text',
  'child nickname RPC keeps the exact named argument'
);

SELECT pg_temp.assert_true(
  pg_get_function_arguments(
    'public.update_linked_child_identity(uuid,text,integer)'::regprocedure
  ) = 'p_child_user_id uuid, p_nickname text, p_age integer',
  'guardian identity RPC keeps the exact named arguments'
);

SELECT pg_temp.assert_true(
  (
    SELECT bool_and(
      p.prosecdef AND p.proconfig = ARRAY['search_path=""']::TEXT[]
    )
    FROM pg_proc p
    WHERE p.oid IN (
      'public.set_own_child_nickname(text)'::regprocedure,
      'public.update_linked_child_identity(uuid,text,integer)'::regprocedure
    )
  ),
  'identity RPCs are SECURITY DEFINER with an empty search_path'
);

SELECT pg_temp.assert_true(
  has_function_privilege('authenticated', 'public.set_own_child_nickname(text)', 'EXECUTE')
    AND has_function_privilege('authenticated', 'public.update_linked_child_identity(uuid,text,integer)', 'EXECUTE')
    AND NOT has_function_privilege('anon', 'public.set_own_child_nickname(text)', 'EXECUTE')
    AND NOT has_function_privilege('anon', 'public.update_linked_child_identity(uuid,text,integer)', 'EXECUTE')
    AND NOT has_function_privilege('anon', 'public.normalize_child_nickname(text)', 'EXECUTE')
    AND NOT has_function_privilege('authenticated', 'public.normalize_child_nickname(text)', 'EXECUTE'),
  'identity RPCs are authenticated-only and the helper is internal'
);

SELECT pg_temp.assert_true(
  NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    CROSS JOIN LATERAL aclexplode(
      COALESCE(p.proacl, acldefault('f', p.proowner))
    ) acl
    WHERE p.oid IN (
      'public.set_own_child_nickname(text)'::regprocedure,
      'public.update_linked_child_identity(uuid,text,integer)'::regprocedure,
      'public.normalize_child_nickname(text)'::regprocedure
    )
      AND acl.grantee = 0
      AND acl.privilege_type = 'EXECUTE'
  ),
  'PUBLIC cannot execute identity functions'
);

-- ── Fixtures ────────────────────────────────────────────────────────────────

INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
VALUES
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'parent-one@example.test', '', NOW(), '{}'::JSONB, '{"display_name":"Account One"}'::JSONB, NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'parent-two@example.test', '', NOW(), '{}'::JSONB, '{}'::JSONB, NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'child-one@example.test', '', NOW(), '{}'::JSONB, '{"display_name":"Child Account"}'::JSONB, NOW(), NOW());

UPDATE public.profiles SET selected_path = 'adult'
WHERE id IN (
  '10000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000002'
);
UPDATE public.profiles SET selected_path = 'child', age = 7
WHERE id = '20000000-0000-0000-0000-000000000001';

INSERT INTO public.parent_child_links (parent_user_id, child_user_id)
VALUES ('10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001');

-- ── Child publishes its own name ────────────────────────────────────────────

SELECT set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000001', TRUE);
SELECT public.set_own_child_nickname(E'  Maryam \t Ali  ');
SELECT pg_temp.assert_true(
  (SELECT child_nickname = 'Maryam Ali' AND display_name = 'Child Account'
   FROM public.profiles WHERE id = '20000000-0000-0000-0000-000000000001'),
  'child nickname is normalized and the account name is kept'
);
SELECT pg_temp.assert_raises(
  $$SELECT public.set_own_child_nickname('   ')$$,
  'Invalid child nickname',
  'blank nickname is rejected'
);
SELECT pg_temp.assert_raises(
  $$SELECT public.set_own_child_nickname(repeat('a', 51))$$,
  'Invalid child nickname',
  'nickname over 50 characters is rejected'
);

SELECT set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000002', TRUE);
SELECT pg_temp.assert_raises(
  $$SELECT public.set_own_child_nickname('Grown up')$$,
  'Only child profiles have a nickname',
  'an adult profile cannot publish a child nickname'
);

-- ── Guardian corrects name and age ──────────────────────────────────────────

SELECT set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', TRUE);
SELECT public.update_linked_child_identity(
  '20000000-0000-0000-0000-000000000001', 'Maryam', 9
);
SELECT pg_temp.assert_true(
  (SELECT child_nickname = 'Maryam' AND age = 9
   FROM public.profiles WHERE id = '20000000-0000-0000-0000-000000000001'),
  'linked guardian updates the child name and age'
);
SELECT pg_temp.assert_raises(
  $$SELECT public.update_linked_child_identity('20000000-0000-0000-0000-000000000001', 'Maryam', 4)$$,
  'Invalid child age',
  'age below 5 is rejected'
);
SELECT pg_temp.assert_raises(
  $$SELECT public.update_linked_child_identity('20000000-0000-0000-0000-000000000001', 'Maryam', 13)$$,
  'Invalid child age',
  'age above 12 is rejected'
);
SELECT pg_temp.assert_raises(
  $$SELECT public.update_linked_child_identity('20000000-0000-0000-0000-000000000001', '', 8)$$,
  'Invalid child nickname',
  'guardian cannot blank the name'
);

SELECT pg_temp.assert_true(
  (
    SELECT child ->> 'display_name' = 'Maryam'
      AND child ->> 'child_nickname' = 'Maryam'
      AND (child ->> 'age')::INTEGER = 9
    FROM jsonb_array_elements(public.get_remote_children_dashboard()) child
    WHERE child ->> 'child_user_id' = '20000000-0000-0000-0000-000000000001'
  ),
  'dashboard returns the nickname and age'
);

SELECT set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000002', TRUE);
SELECT pg_temp.assert_raises(
  $$SELECT public.update_linked_child_identity('20000000-0000-0000-0000-000000000001', 'Hacked', 8)$$,
  'No active guardian link for this child',
  'unrelated guardian is rejected'
);

UPDATE public.parent_child_links SET status = 'revoked', revoked_at = NOW()
WHERE parent_user_id = '10000000-0000-0000-0000-000000000001';
SELECT set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', TRUE);
SELECT pg_temp.assert_raises(
  $$SELECT public.update_linked_child_identity('20000000-0000-0000-0000-000000000001', 'Late', 8)$$,
  'No active guardian link for this child',
  'a revoked guardian is rejected'
);
SELECT pg_temp.assert_true(
  (SELECT child_nickname = 'Maryam' AND age = 9
   FROM public.profiles WHERE id = '20000000-0000-0000-0000-000000000001'),
  'rejected calls do not change the child profile'
);

SELECT set_config('request.jwt.claim.sub', '', TRUE);
SELECT pg_temp.assert_raises(
  $$SELECT public.update_linked_child_identity('20000000-0000-0000-0000-000000000001', 'Anon', 8)$$,
  'Not authenticated',
  'unauthenticated caller is rejected'
);

ROLLBACK;
