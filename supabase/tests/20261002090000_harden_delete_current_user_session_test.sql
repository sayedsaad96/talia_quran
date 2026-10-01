BEGIN;

DO $$
DECLARE
  function_definition text;
BEGIN
  SELECT pg_get_functiondef('public.delete_current_user()'::regprocedure)
  INTO function_definition;

  IF function_definition NOT LIKE '%auth.users WHERE id = v_uid%' OR
      function_definition NOT LIKE '%auth.sessions%' OR
      function_definition NOT LIKE '%session.user_id = v_uid%' OR
      function_definition NOT LIKE '%DELETE FROM auth.users%' THEN
    RAISE EXCEPTION 'delete_current_user must bind the live session to auth.uid before deletion';
  END IF;
END;
$$;

ROLLBACK;
