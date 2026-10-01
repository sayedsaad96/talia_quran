-- Production matched 0012 except the service_role grant; restore it.
REVOKE ALL ON FUNCTION public.prune_audit_logs()
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.prune_audit_logs() TO service_role;
