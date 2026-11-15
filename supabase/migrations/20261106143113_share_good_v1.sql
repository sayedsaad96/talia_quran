-- Share Good authority is private; tables are never Data API accessible.
CREATE SCHEMA IF NOT EXISTS private;
CREATE TABLE IF NOT EXISTS public.share_good_invites (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), token_hash text NOT NULL UNIQUE,
 creator_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
 mode text NOT NULL CHECK (mode IN ('personal','public')),
 moment text NOT NULL CHECK (moment IN ('before','after')),
 identity_mode text NOT NULL CHECK (identity_mode IN ('full_name','first_name','display_name','anonymous')),
 target jsonb NOT NULL, parent_invite_id uuid REFERENCES public.share_good_invites(id),
 root_invite_id uuid NOT NULL REFERENCES public.share_good_invites(id), timezone text NOT NULL, created_at timestamptz NOT NULL,
 expires_at timestamptz NOT NULL, revoked_at timestamptz
);
CREATE TABLE IF NOT EXISTS public.share_good_invite_identities (
 invite_id uuid PRIMARY KEY REFERENCES public.share_good_invites(id) ON DELETE CASCADE,
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 visible_name text NOT NULL CHECK (char_length(visible_name) BETWEEN 1 AND 40)
);
CREATE TABLE IF NOT EXISTS public.share_good_participations (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), invite_id uuid NOT NULL REFERENCES public.share_good_invites(id),
 participant_key_hash text NOT NULL, opened_as_guest boolean NOT NULL,
 status text NOT NULL CHECK (status IN ('opened','started','completed_private','completed_shared_identity','continued_as_new_invite')),
 opened_at timestamptz NOT NULL, started_at timestamptz, completed_at timestamptz,
 UNIQUE(invite_id,participant_key_hash)
);
CREATE TABLE IF NOT EXISTS public.share_good_completion_disclosures (
 participation_id uuid PRIMARY KEY REFERENCES public.share_good_participations(id) ON DELETE CASCADE,
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 visible_name text NOT NULL CHECK (char_length(visible_name) BETWEEN 1 AND 40)
);
CREATE TABLE IF NOT EXISTS public.share_good_rate_limits (
 scope_hash text NOT NULL, action text NOT NULL, window_start timestamptz NOT NULL, attempts integer NOT NULL DEFAULT 1,
 PRIMARY KEY(scope_hash,action,window_start)
);
CREATE INDEX IF NOT EXISTS share_good_invites_creator_idx ON public.share_good_invites(creator_user_id,created_at);
CREATE INDEX IF NOT EXISTS share_good_invites_root_idx ON public.share_good_invites(root_invite_id);
CREATE INDEX IF NOT EXISTS share_good_participations_invite_idx ON public.share_good_participations(invite_id);
CREATE INDEX IF NOT EXISTS share_good_rate_limits_time_idx ON public.share_good_rate_limits(window_start);
ALTER TABLE public.share_good_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.share_good_invite_identities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.share_good_participations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.share_good_completion_disclosures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.share_good_rate_limits ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.share_good_invites FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.share_good_invite_identities FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.share_good_participations FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.share_good_completion_disclosures FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.share_good_rate_limits FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.share_good_hash_v1(p_value text) RETURNS text
LANGUAGE sql IMMUTABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(p_value,'UTF8')),'hex');
$$;
CREATE OR REPLACE FUNCTION private.share_good_actor_v1() RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_actor uuid := auth.uid(); v_session uuid;
BEGIN
 IF v_actor IS NULL OR COALESCE((auth.jwt()->>'is_anonymous')::boolean,false) THEN RAISE EXCEPTION 'share_good_session_required';
 END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(7031,pg_catalog.hashtext(v_actor::text));
 BEGIN v_session := NULLIF(auth.jwt()->>'session_id','')::uuid;
 EXCEPTION WHEN invalid_text_representation THEN RAISE EXCEPTION 'share_good_session_required'; END;
 IF v_session IS NULL OR NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id=v_actor AND COALESCE(u.is_anonymous,false)=false)
 OR NOT EXISTS (SELECT 1 FROM auth.sessions s WHERE s.id=v_session AND s.user_id=v_actor AND (s.not_after IS NULL OR s.not_after > pg_catalog.clock_timestamp())) THEN
 RAISE EXCEPTION 'share_good_session_required';
 END IF;
 IF EXISTS (SELECT 1 FROM public.profiles p WHERE p.id=v_actor AND p.selected_path='child')
 OR EXISTS (SELECT 1 FROM public.parent_child_links l WHERE l.child_user_id=v_actor) THEN
 RAISE EXCEPTION 'share_good_not_eligible';
 END IF;
 RETURN v_actor;
END; $$;
CREATE OR REPLACE FUNCTION private.share_good_optional_actor_v1() RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
 IF auth.uid() IS NOT NULL OR (auth.jwt()->>'role')='authenticated' OR pg_catalog.current_setting('role',true)='authenticated' THEN RETURN private.share_good_actor_v1();
 END IF;
 RETURN NULL;
END; $$;
CREATE OR REPLACE FUNCTION private.share_good_valid_target_v1(p_target jsonb) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_type text; v_a integer; v_b integer; v_keys text[];
BEGIN
 IF pg_catalog.jsonb_typeof(p_target) IS DISTINCT FROM 'object' THEN RETURN false;
 END IF;
 SELECT pg_catalog.array_agg(k ORDER BY k) INTO v_keys FROM pg_catalog.jsonb_object_keys(p_target) k;
 IF p_target->'v' IS DISTINCT FROM '1'::jsonb OR p_target->>'v' IS DISTINCT FROM '1' THEN RETURN false;
 END IF;
 v_type := p_target->>'type';
 IF v_type='quran_page' AND v_keys=ARRAY['page','type','v'] THEN
 IF pg_catalog.jsonb_typeof(p_target->'page') <> 'number' OR (p_target->>'page') !~ '^[0-9]+$' THEN RETURN false;
 END IF;
 v_a := (p_target->>'page')::integer;
 RETURN v_a BETWEEN 1 AND 604;
 ELSIF v_type='quran_surah' AND v_keys=ARRAY['surah_id','type','v'] THEN
 IF pg_catalog.jsonb_typeof(p_target->'surah_id') <> 'number' OR (p_target->>'surah_id') !~ '^[0-9]+$' THEN RETURN false;
 END IF;
 v_a := (p_target->>'surah_id')::integer;
 RETURN v_a BETWEEN 1 AND 114;
 ELSIF v_type='quran_wird' AND v_keys=ARRAY['end_page','start_page','type','v'] THEN
 IF pg_catalog.jsonb_typeof(p_target->'start_page') <> 'number' OR pg_catalog.jsonb_typeof(p_target->'end_page') <> 'number'
 OR (p_target->>'start_page') !~ '^[0-9]+$' OR (p_target->>'end_page') !~ '^[0-9]+$' THEN RETURN false;
 END IF;
 v_a := (p_target->>'start_page')::integer; v_b := (p_target->>'end_page')::integer;
 RETURN v_a BETWEEN 1 AND 604 AND v_b BETWEEN v_a AND 604 AND v_b-v_a <= 19;
 ELSIF v_type='azkar_collection' AND v_keys=ARRAY['category','type','v'] THEN
 RETURN p_target->>'category' IN ('morning','evening');
 END IF;
 RETURN false;
EXCEPTION WHEN numeric_value_out_of_range THEN RETURN false;
END; $$;
CREATE OR REPLACE FUNCTION private.share_good_expires_at_v1(p_target jsonb,p_created_at timestamptz,p_tz text) RETURNS timestamptz
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_local timestamp; v_result timestamptz;
BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name=p_tz) THEN RAISE EXCEPTION 'invalid_timezone';
 END IF;
 IF p_target->>'type'='azkar_collection' THEN
 v_local := pg_catalog.date_trunc('day',p_created_at AT TIME ZONE p_tz) + CASE WHEN p_target->>'category'='morning' THEN interval '15 hours 30 minutes' ELSE interval '4 hours' END;
 v_result := v_local AT TIME ZONE p_tz;
 IF v_result <= p_created_at THEN v_result := (v_local + interval '1 day') AT TIME ZONE p_tz;
 END IF;
 RETURN v_result;
 END IF;
 RETURN p_created_at + CASE WHEN p_target->>'type'='quran_wird' THEN interval '72 hours' ELSE interval '168 hours' END;
END; $$;
CREATE OR REPLACE FUNCTION private.share_good_throttle_v1(p_scope text,p_action text,p_period interval,p_cap integer) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_now timestamptz; v_count bigint;
BEGIN
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(p_action),pg_catalog.hashtext(p_scope));
 v_now := pg_catalog.clock_timestamp();
 DELETE FROM public.share_good_rate_limits WHERE scope_hash=p_scope AND action=p_action AND window_start <= v_now-p_period;
 SELECT COALESCE(pg_catalog.sum(attempts),0) INTO v_count FROM public.share_good_rate_limits WHERE scope_hash=p_scope AND action=p_action AND window_start > v_now-p_period;
 IF v_count >= p_cap THEN RETURN false;
 END IF;
 INSERT INTO public.share_good_rate_limits(scope_hash,action,window_start,attempts) VALUES(p_scope,p_action,v_now,1)
 ON CONFLICT(scope_hash,action,window_start) DO UPDATE SET attempts=public.share_good_rate_limits.attempts+1;
 RETURN true;
END; $$;
CREATE OR REPLACE FUNCTION private.share_good_valid_name_v1(p_name text) RETURNS boolean
LANGUAGE sql IMMUTABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT p_name IS NOT NULL AND p_name=pg_catalog.btrim(p_name) AND pg_catalog.char_length(p_name) BETWEEN 1 AND 40
 AND p_name !~ '[[:cntrl:]]' AND pg_catalog.translate(p_name,U&'\202A\202B\202C\202D\202E\2066\2067\2068\2069','')=p_name;
$$;
CREATE OR REPLACE FUNCTION private.share_good_create_internal_v1(p_actor uuid,p_parent uuid,p_root uuid,p_target jsonb,p_moment text,p_mode text,p_identity_mode text,p_visible_name text,p_timezone text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_id uuid := pg_catalog.gen_random_uuid(); v_token text; v_now timestamptz := pg_catalog.clock_timestamp(); v_exp timestamptz;
BEGIN
 IF NOT COALESCE(private.share_good_valid_target_v1(p_target),false) OR p_moment NOT IN ('before','after') OR p_moment IS NULL
 OR p_mode NOT IN ('personal','public') OR p_mode IS NULL OR p_identity_mode NOT IN ('full_name','first_name','display_name','anonymous') OR p_identity_mode IS NULL
 OR (p_identity_mode='anonymous' AND p_visible_name IS NOT NULL) OR (p_identity_mode<>'anonymous' AND NOT private.share_good_valid_name_v1(p_visible_name))
 OR p_timezone IS NULL OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name=p_timezone) THEN RETURN pg_catalog.jsonb_build_object('error','invalid_input');
 END IF;
 IF NOT private.share_good_throttle_v1(private.share_good_hash_v1(p_actor::text),'create',interval '24 hours',30) THEN RETURN pg_catalog.jsonb_build_object('error','rate_limited');
 END IF;
 v_token := pg_catalog.translate(pg_catalog.rtrim(pg_catalog.encode(extensions.gen_random_bytes(32),'base64'),'='),'+/','-_');
 v_exp := private.share_good_expires_at_v1(p_target,v_now,p_timezone);
 INSERT INTO public.share_good_invites(id,token_hash,creator_user_id,mode,moment,identity_mode,target,parent_invite_id,root_invite_id,timezone,created_at,expires_at)
 VALUES(v_id,private.share_good_hash_v1(v_token),p_actor,p_mode,p_moment,p_identity_mode,p_target,p_parent,COALESCE(p_root,v_id),p_timezone,v_now,v_exp);
 IF p_identity_mode<>'anonymous' THEN INSERT INTO public.share_good_invite_identities(invite_id,user_id,visible_name) VALUES(v_id,p_actor,p_visible_name);
 END IF;
 RETURN pg_catalog.jsonb_build_object('token',v_token,'target',p_target,'moment',p_moment,'mode',p_mode,
 'inviter',pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object('mode',p_identity_mode,'visible_name',p_visible_name)), 'created_at',v_now,'expires_at',v_exp);
END; $$;
CREATE OR REPLACE FUNCTION private.share_good_create_invite_v1(p_target jsonb,p_moment text,p_mode text,p_identity_mode text,p_visible_name text,p_timezone text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_actor uuid;
BEGIN
 v_actor := private.share_good_actor_v1();
 RETURN private.share_good_create_internal_v1(v_actor,NULL,NULL,p_target,p_moment,p_mode,p_identity_mode,p_visible_name,p_timezone); END; $$;
CREATE OR REPLACE FUNCTION private.share_good_create_chain_invite_v1(p_parent_token text,p_participant_key text,p_target jsonb,p_moment text,p_mode text,p_identity_mode text,p_visible_name text,p_timezone text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_actor uuid; v_parent public.share_good_invites; v_part public.share_good_participations; v_result jsonb;
BEGIN
 v_actor := private.share_good_actor_v1();
 IF p_parent_token !~ '^[A-Za-z0-9_-]{43}$' OR p_participant_key !~ '^[A-Za-z0-9_-]{43}$' OR p_parent_token IS NULL OR p_participant_key IS NULL THEN RETURN pg_catalog.jsonb_build_object('error','invalid_input');
 END IF;
 SELECT * INTO v_parent FROM public.share_good_invites WHERE token_hash=private.share_good_hash_v1(p_parent_token) FOR UPDATE;
 IF NOT FOUND THEN RETURN pg_catalog.jsonb_build_object('error','invalid_invite');
 END IF;
 IF v_parent.revoked_at IS NOT NULL OR v_parent.expires_at <= pg_catalog.clock_timestamp() THEN RETURN pg_catalog.jsonb_build_object('error','expired');
 END IF;
 SELECT * INTO v_part FROM public.share_good_participations WHERE invite_id=v_parent.id AND participant_key_hash=private.share_good_hash_v1(p_participant_key) FOR UPDATE;
 IF NOT FOUND OR v_part.status NOT IN ('completed_private','completed_shared_identity') OR p_target IS DISTINCT FROM v_parent.target OR p_moment IS DISTINCT FROM 'after' THEN RETURN pg_catalog.jsonb_build_object('error','not_eligible');
 END IF;
 v_result := private.share_good_create_internal_v1(v_actor,v_parent.id,v_parent.root_invite_id,p_target,p_moment,p_mode,p_identity_mode,p_visible_name,p_timezone);
 IF NOT (v_result ? 'error') THEN UPDATE public.share_good_participations SET status='continued_as_new_invite' WHERE id=v_part.id;
 END IF;
 RETURN v_result;
END; $$;
CREATE OR REPLACE FUNCTION private.share_good_resolve_invite_v1(p_token text,p_participant_key text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_actor uuid; v_inv public.share_good_invites; v_part text; v_name text; v_status text;
BEGIN
 v_actor := private.share_good_optional_actor_v1();
 IF p_token IS NULL OR p_participant_key IS NULL OR p_token !~ '^[A-Za-z0-9_-]{43}$' OR p_participant_key !~ '^[A-Za-z0-9_-]{43}$' THEN RETURN pg_catalog.jsonb_build_object('error','invalid_input');
 END IF;
 IF NOT private.share_good_throttle_v1(private.share_good_hash_v1(p_participant_key),'resolve',interval '1 hour',60) THEN RETURN pg_catalog.jsonb_build_object('error','rate_limited');
 END IF;
 SELECT * INTO v_inv FROM public.share_good_invites WHERE token_hash=private.share_good_hash_v1(p_token);
 IF NOT FOUND THEN RETURN pg_catalog.jsonb_build_object('error','invalid_invite');
 END IF;
 SELECT status INTO v_part FROM public.share_good_participations WHERE invite_id=v_inv.id AND participant_key_hash=private.share_good_hash_v1(p_participant_key);
 SELECT visible_name INTO v_name FROM public.share_good_invite_identities WHERE invite_id=v_inv.id;
 v_status := CASE WHEN v_inv.revoked_at IS NOT NULL THEN 'revoked' WHEN v_inv.expires_at <= pg_catalog.clock_timestamp() THEN 'expired' ELSE 'active' END;
 RETURN pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object('target',v_inv.target,'moment',v_inv.moment,'mode',v_inv.mode,
 'inviter',pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object('mode',CASE WHEN v_name IS NULL THEN 'anonymous' ELSE v_inv.identity_mode END,'visible_name',v_name)),
 'status',v_status,'expires_at',v_inv.expires_at,'participation_status',v_part));
END; $$;
CREATE OR REPLACE FUNCTION private.share_good_advance_participation_v1(p_token text,p_participant_key text,p_status text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_actor uuid; v_inv public.share_good_invites; v_part public.share_good_participations; v_now timestamptz; v_rank integer; v_old integer;
BEGIN
 v_actor := private.share_good_optional_actor_v1();
 IF p_token IS NULL OR p_participant_key IS NULL OR p_token !~ '^[A-Za-z0-9_-]{43}$' OR p_participant_key !~ '^[A-Za-z0-9_-]{43}$' OR p_status IS NULL OR p_status NOT IN ('opened','started','completed_private') THEN RETURN pg_catalog.jsonb_build_object('error','invalid_input');
 END IF;
 SELECT * INTO v_inv FROM public.share_good_invites WHERE token_hash=private.share_good_hash_v1(p_token) FOR UPDATE;
 IF NOT FOUND THEN RETURN pg_catalog.jsonb_build_object('error','invalid_invite');
 END IF;
 v_now := pg_catalog.clock_timestamp();
 IF v_inv.revoked_at IS NOT NULL OR v_inv.expires_at <= v_now THEN RETURN pg_catalog.jsonb_build_object('error','expired');
 END IF;
 IF NOT private.share_good_throttle_v1(private.share_good_hash_v1(v_inv.id::text || ':' || p_participant_key),'advance',interval '24 hours',20) THEN RETURN pg_catalog.jsonb_build_object('error','rate_limited');
 END IF;
 v_now := pg_catalog.clock_timestamp();
 IF v_inv.expires_at <= v_now THEN RETURN pg_catalog.jsonb_build_object('error','expired');
 END IF;
 SELECT * INTO v_part FROM public.share_good_participations WHERE invite_id=v_inv.id AND participant_key_hash=private.share_good_hash_v1(p_participant_key) FOR UPDATE;
 IF NOT FOUND THEN
 INSERT INTO public.share_good_participations(invite_id,participant_key_hash,opened_as_guest,status,opened_at,started_at,completed_at)
 VALUES(v_inv.id,private.share_good_hash_v1(p_participant_key),v_actor IS NULL,p_status,v_now,CASE WHEN p_status IN ('started','completed_private') THEN v_now END,CASE WHEN p_status='completed_private' THEN v_now END);
 RETURN pg_catalog.jsonb_build_object('status',p_status);
 END IF;
 v_rank := CASE p_status WHEN 'opened' THEN 1 WHEN 'started' THEN 2 ELSE 3 END;
 v_old := CASE v_part.status WHEN 'opened' THEN 1 WHEN 'started' THEN 2 WHEN 'completed_private' THEN 3 WHEN 'completed_shared_identity' THEN 4 ELSE 5 END;
 IF v_rank > v_old THEN
 UPDATE public.share_good_participations SET status=p_status,started_at=COALESCE(started_at,CASE WHEN v_rank>=2 THEN v_now END),completed_at=COALESCE(completed_at,CASE WHEN v_rank>=3 THEN v_now END) WHERE id=v_part.id;
 RETURN pg_catalog.jsonb_build_object('status',p_status);
 END IF;
 RETURN pg_catalog.jsonb_build_object('status',v_part.status);
END; $$;
CREATE OR REPLACE FUNCTION private.share_good_disclose_completion_v1(p_token text,p_participant_key text,p_visible_name text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_actor uuid; v_part public.share_good_participations;
BEGIN
 v_actor := private.share_good_actor_v1();
 IF p_token IS NULL OR p_participant_key IS NULL OR p_token !~ '^[A-Za-z0-9_-]{43}$' OR p_participant_key !~ '^[A-Za-z0-9_-]{43}$' OR NOT private.share_good_valid_name_v1(p_visible_name) THEN RETURN pg_catalog.jsonb_build_object('error','invalid_input');
 END IF;
 SELECT p.* INTO v_part FROM public.share_good_participations p JOIN public.share_good_invites i ON i.id=p.invite_id WHERE i.token_hash=private.share_good_hash_v1(p_token) AND p.participant_key_hash=private.share_good_hash_v1(p_participant_key) FOR UPDATE OF p;
 IF NOT FOUND OR v_part.status NOT IN ('completed_private','completed_shared_identity','continued_as_new_invite') THEN RETURN pg_catalog.jsonb_build_object('error','not_eligible');
 END IF;
 INSERT INTO public.share_good_completion_disclosures(participation_id,user_id,visible_name) VALUES(v_part.id,v_actor,p_visible_name)
 ON CONFLICT(participation_id) DO UPDATE SET user_id=EXCLUDED.user_id,visible_name=EXCLUDED.visible_name;
 IF v_part.status<>'continued_as_new_invite' THEN UPDATE public.share_good_participations SET status='completed_shared_identity' WHERE id=v_part.id; v_part.status := 'completed_shared_identity';
 END IF;
 RETURN pg_catalog.jsonb_build_object('status',v_part.status);
END; $$;
CREATE OR REPLACE FUNCTION private.share_good_get_impact_v1() RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_actor uuid; v_result jsonb; v_now timestamptz;
BEGIN
 v_actor := private.share_good_actor_v1();
 v_now := pg_catalog.clock_timestamp();
 WITH owned AS (SELECT * FROM public.share_good_invites i WHERE i.creator_user_id=v_actor AND i.expires_at > v_now-interval '30 days'),
 counts AS (SELECT i.id,pg_catalog.count(p.id) AS opens,pg_catalog.count(p.id) FILTER (WHERE p.started_at IS NOT NULL) AS starts,pg_catalog.count(p.id) FILTER (WHERE p.completed_at IS NOT NULL) AS completions FROM owned i LEFT JOIN public.share_good_participations p ON p.invite_id=i.id GROUP BY i.id)
 SELECT pg_catalog.jsonb_build_object(
 'invites',COALESCE((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('target',i.target,'status',CASE WHEN i.revoked_at IS NOT NULL THEN 'revoked' WHEN i.expires_at <= v_now THEN 'expired' ELSE 'active' END,'expires_at',i.expires_at,'opens',c.opens,'starts',c.starts,'completions',c.completions) ORDER BY i.created_at DESC) FROM owned i JOIN counts c ON c.id=i.id),'[]'::jsonb),
 'responses',COALESCE((SELECT pg_catalog.sum(opens) FROM counts),0),
 'completions',COALESCE((SELECT pg_catalog.sum(completions) FROM counts),0),
 'downstream_reach',(SELECT pg_catalog.count(DISTINCT p.id) FROM public.share_good_participations p JOIN public.share_good_invites i ON i.id=p.invite_id WHERE p.completed_at IS NOT NULL AND i.root_invite_id IN (SELECT r.id FROM public.share_good_invites r WHERE r.creator_user_id=v_actor AND r.root_invite_id=r.id) AND i.creator_user_id IS DISTINCT FROM v_actor),
 'acknowledgements',COALESCE((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('target',i.target,'visible_name',d.visible_name,'completed_at',p.completed_at) ORDER BY p.completed_at DESC) FROM owned i JOIN public.share_good_participations p ON p.invite_id=i.id JOIN public.share_good_completion_disclosures d ON d.participation_id=p.id),'[]'::jsonb),
 'fetched_at',v_now) INTO v_result;
 RETURN v_result;
END; $$;

CREATE OR REPLACE FUNCTION public.create_share_good_invite_v1(p_target jsonb,p_moment text,p_mode text,p_identity_mode text,p_visible_name text,p_timezone text) RETURNS jsonb
LANGUAGE sql SECURITY INVOKER SET search_path = '' AS $$ SELECT private.share_good_create_invite_v1(p_target,p_moment,p_mode,p_identity_mode,p_visible_name,p_timezone); $$;
CREATE OR REPLACE FUNCTION public.create_share_good_chain_invite_v1(p_parent_token text,p_participant_key text,p_target jsonb,p_moment text,p_mode text,p_identity_mode text,p_visible_name text,p_timezone text) RETURNS jsonb
LANGUAGE sql SECURITY INVOKER SET search_path = '' AS $$ SELECT private.share_good_create_chain_invite_v1(p_parent_token,p_participant_key,p_target,p_moment,p_mode,p_identity_mode,p_visible_name,p_timezone); $$;
CREATE OR REPLACE FUNCTION public.resolve_share_good_invite_v1(p_token text,p_participant_key text) RETURNS jsonb
LANGUAGE sql SECURITY INVOKER SET search_path = '' AS $$ SELECT private.share_good_resolve_invite_v1(p_token,p_participant_key); $$;
CREATE OR REPLACE FUNCTION public.advance_share_good_participation_v1(p_token text,p_participant_key text,p_status text) RETURNS jsonb
LANGUAGE sql SECURITY INVOKER SET search_path = '' AS $$ SELECT private.share_good_advance_participation_v1(p_token,p_participant_key,p_status); $$;
CREATE OR REPLACE FUNCTION public.disclose_share_good_completion_v1(p_token text,p_participant_key text,p_visible_name text) RETURNS jsonb
LANGUAGE sql SECURITY INVOKER SET search_path = '' AS $$ SELECT private.share_good_disclose_completion_v1(p_token,p_participant_key,p_visible_name); $$;
CREATE OR REPLACE FUNCTION public.get_share_good_impact_v1() RETURNS jsonb
LANGUAGE sql SECURITY INVOKER SET search_path = '' AS $$ SELECT private.share_good_get_impact_v1(); $$;

REVOKE ALL ON FUNCTION private.share_good_hash_v1(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.share_good_actor_v1() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.share_good_optional_actor_v1() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.share_good_valid_target_v1(jsonb) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.share_good_expires_at_v1(jsonb,timestamptz,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.share_good_throttle_v1(text,text,interval,integer) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.share_good_valid_name_v1(text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.share_good_create_internal_v1(uuid,uuid,uuid,jsonb,text,text,text,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.share_good_create_invite_v1(jsonb,text,text,text,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.share_good_create_chain_invite_v1(text,text,jsonb,text,text,text,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.share_good_resolve_invite_v1(text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.share_good_advance_participation_v1(text,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.share_good_disclose_completion_v1(text,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.share_good_get_impact_v1() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.create_share_good_invite_v1(jsonb,text,text,text,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.create_share_good_chain_invite_v1(text,text,jsonb,text,text,text,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.resolve_share_good_invite_v1(text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.advance_share_good_participation_v1(text,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.disclose_share_good_completion_v1(text,text,text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.get_share_good_impact_v1() FROM PUBLIC, anon, authenticated, service_role;
GRANT USAGE ON SCHEMA private TO anon, authenticated;
GRANT EXECUTE ON FUNCTION private.share_good_create_invite_v1(jsonb,text,text,text,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION private.share_good_create_chain_invite_v1(text,text,jsonb,text,text,text,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION private.share_good_resolve_invite_v1(text,text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION private.share_good_advance_participation_v1(text,text,text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION private.share_good_disclose_completion_v1(text,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION private.share_good_get_impact_v1() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_share_good_invite_v1(jsonb,text,text,text,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_share_good_chain_invite_v1(text,text,jsonb,text,text,text,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_share_good_invite_v1(text,text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.advance_share_good_participation_v1(text,text,text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.disclose_share_good_completion_v1(text,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_share_good_impact_v1() TO authenticated;
