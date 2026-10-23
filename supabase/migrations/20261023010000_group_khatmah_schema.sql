-- Group khatmah is isolated from personal khatmah and Quran content.
-- Administrative adult provisioning only. Direct Auth-admin deletion of a
-- participant is intentionally RESTRICTed: use delete_current_user() cleanup.
CREATE SCHEMA IF NOT EXISTS private;
REVOKE CREATE ON SCHEMA private FROM PUBLIC, anon, authenticated, service_role;

CREATE TABLE IF NOT EXISTS private.group_khatmah_eligibility (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  eligible boolean NOT NULL DEFAULT false,
  policy_version integer NOT NULL CHECK (policy_version > 0),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS private.group_khatmah_join_throttle (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  minute_start timestamptz NOT NULL,
  minute_count integer NOT NULL CHECK (minute_count >= 0),
  day_start timestamptz NOT NULL,
  day_count integer NOT NULL CHECK (day_count >= 0)
);

CREATE TABLE IF NOT EXISTS public.group_khatmah (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  code text NOT NULL UNIQUE CHECK (code ~ '^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$'),
  title text NOT NULL CHECK (title = btrim(title) AND char_length(title) BETWEEN 1 AND 80),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  max_members smallint NOT NULL DEFAULT 30 CHECK (max_members = 30),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','completed')),
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  CHECK ((status = 'completed') = (completed_at IS NOT NULL))
);
CREATE INDEX IF NOT EXISTS group_khatmah_owner_idx ON public.group_khatmah(owner_id);

CREATE TABLE IF NOT EXISTS public.group_khatmah_member (
  group_id uuid NOT NULL REFERENCES public.group_khatmah(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  display_name text NOT NULL,
  joined_at timestamptz NOT NULL DEFAULT now(),
  left_at timestamptz,
  membership_epoch uuid NOT NULL DEFAULT pg_catalog.gen_random_uuid(),
  PRIMARY KEY (group_id,user_id),
  CHECK ((left_at IS NULL AND display_name = btrim(display_name)
    AND char_length(display_name) BETWEEN 2 AND 24)
    OR (left_at IS NOT NULL AND display_name = ''))
);
CREATE INDEX IF NOT EXISTS group_khatmah_member_user_idx
  ON public.group_khatmah_member(user_id,group_id) WHERE left_at IS NULL;
CREATE INDEX IF NOT EXISTS group_khatmah_member_active_idx
  ON public.group_khatmah_member(group_id) WHERE left_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS group_khatmah_member_epoch_key
  ON public.group_khatmah_member(membership_epoch);

CREATE TABLE IF NOT EXISTS public.group_khatmah_part (
  group_id uuid NOT NULL REFERENCES public.group_khatmah(id) ON DELETE CASCADE,
  juz smallint NOT NULL CHECK (juz BETWEEN 1 AND 30),
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','claimed','completed')),
  claimed_by uuid,
  claim_epoch uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (group_id,juz),
  FOREIGN KEY (group_id,claimed_by)
    REFERENCES public.group_khatmah_member(group_id,user_id) ON DELETE NO ACTION,
  CHECK ((status = 'open' AND claimed_by IS NULL AND claim_epoch IS NULL)
    OR (status = 'claimed' AND claimed_by IS NOT NULL AND claim_epoch IS NOT NULL)
    OR (status = 'completed' AND
      ((claimed_by IS NULL AND claim_epoch IS NULL) OR
       (claimed_by IS NOT NULL AND claim_epoch IS NOT NULL))))
);

CREATE TABLE IF NOT EXISTS private.group_khatmah_receipt (
  actor_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  operation_id uuid NOT NULL,
  kind text NOT NULL CHECK (kind IN ('create','join','claim','complete','release','leave')),
  group_id uuid NOT NULL, -- deliberately no FK: gone tombstones survive group deletion
  fingerprint text,
  membership_epoch uuid,
  result jsonb,
  gone boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (actor_id,operation_id),
  CHECK ((gone AND fingerprint IS NULL AND membership_epoch IS NULL AND result IS NULL)
    OR (NOT gone AND fingerprint IS NOT NULL AND result IS NOT NULL))
);
CREATE INDEX IF NOT EXISTS group_khatmah_receipt_group_idx
  ON private.group_khatmah_receipt(group_id);

ALTER TABLE public.group_khatmah ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_khatmah_member ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_khatmah_part ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.group_khatmah_eligibility ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.group_khatmah_join_throttle ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.group_khatmah_receipt ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.group_khatmah, public.group_khatmah_member,
  public.group_khatmah_part, private.group_khatmah_eligibility,
  private.group_khatmah_join_throttle, private.group_khatmah_receipt
  FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT (id,code,title,owner_id,max_members,status,version,created_at,completed_at)
  ON public.group_khatmah TO authenticated;
GRANT SELECT (group_id,user_id,display_name,joined_at,left_at,membership_epoch)
  ON public.group_khatmah_member TO authenticated;
GRANT SELECT (group_id,juz,status,claimed_by,claim_epoch,version,updated_at)
  ON public.group_khatmah_part TO authenticated;
