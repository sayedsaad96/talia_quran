-- Synthetic local-only Supabase auth fixtures; no JWT verification or PostgREST.
-- Definitions follow Supabase Auth migrations 20220224000811 and 20220531120530:
-- https://github.com/supabase/auth/blob/master/migrations/20220224000811_update_auth_functions.up.sql
-- https://github.com/supabase/auth/blob/master/migrations/20220531120530_add_auth_jwt_function.up.sql
create role anon nologin;
create role authenticated nologin;
create schema auth;
create table auth.users (
  instance_id uuid, id uuid primary key, aud text, role text, email text,
  encrypted_password text, email_confirmed_at timestamptz,
  raw_app_meta_data jsonb, raw_user_meta_data jsonb,
  created_at timestamptz, updated_at timestamptz
);
create function auth.uid() returns uuid language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'))::uuid
$$;
create function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claim', true), ''),
    nullif(current_setting('request.jwt.claims', true), ''))::jsonb
$$;
