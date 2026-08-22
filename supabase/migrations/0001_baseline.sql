-- Talia Quran — complete pre-migration baseline.
--
-- The migration chain is self-contained: no checked-out schema dump or live
-- database is needed to reconstruct a new environment.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT 'مستخدم' CHECK (char_length(display_name) <= 100),
  avatar_url TEXT CHECK (avatar_url IS NULL OR char_length(avatar_url) <= 500),
  age INTEGER CHECK (age IS NULL OR age BETWEEN 1 AND 150),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE public.child_link_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), child_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL UNIQUE CHECK (char_length(token_hash) = 64), expires_at TIMESTAMPTZ NOT NULL, used_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE public.parent_child_links (
  parent_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, child_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','revoked')), linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), revoked_at TIMESTAMPTZ,
  PRIMARY KEY (parent_user_id,child_user_id), CHECK (parent_user_id <> child_user_id)
);
CREATE TABLE public.kids_progress_cloud (
  child_user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE, total_points INTEGER NOT NULL DEFAULT 0 CHECK (total_points >= 0),
  current_level INTEGER NOT NULL DEFAULT 1 CHECK (current_level >= 1), current_streak INTEGER NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
  stars_earned INTEGER NOT NULL DEFAULT 0 CHECK (stars_earned >= 0), ayahs_completed INTEGER NOT NULL DEFAULT 0 CHECK (ayahs_completed >= 0), last_session_at TIMESTAMPTZ, updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE public.kids_session_logs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, child_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, local_id TEXT NOT NULL CHECK (char_length(local_id) <= 120),
  surah_id INTEGER NOT NULL CHECK (surah_id BETWEEN 1 AND 114), ayah_number INTEGER NOT NULL CHECK (ayah_number BETWEEN 1 AND 286),
  repeats_completed INTEGER NOT NULL DEFAULT 0 CHECK (repeats_completed >= 0), points_earned INTEGER NOT NULL DEFAULT 0 CHECK (points_earned >= 0), completed_at TIMESTAMPTZ NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_child_session_log UNIQUE (child_user_id,local_id)
);
CREATE TABLE public.parent_rewards (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, parent_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, child_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (char_length(title) BETWEEN 1 AND 120), status TEXT NOT NULL DEFAULT 'locked' CHECK (status IN ('locked','unlocked','claimed')), created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), unlocked_at TIMESTAMPTZ, claimed_at TIMESTAMPTZ
);
CREATE TABLE public.streaks (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE, current_streak INTEGER NOT NULL DEFAULT 0 CHECK (current_streak BETWEEN 0 AND 36500), longest_streak INTEGER NOT NULL DEFAULT 0 CHECK (longest_streak BETWEEN 0 AND 36500), last_activity_date DATE, freezes_available INTEGER NOT NULL DEFAULT 0 CHECK (freezes_available BETWEEN 0 AND 30), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE public.xp (user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE, total_xp INTEGER NOT NULL DEFAULT 0 CHECK (total_xp BETWEEN 0 AND 100000000), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE public.xp_history (id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, action TEXT NOT NULL CHECK (char_length(action) <= 50), xp_gained INTEGER NOT NULL CHECK (xp_gained BETWEEN 0 AND 1000), created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE public.daily_activities (id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, day_key INTEGER NOT NULL, activity_count INTEGER NOT NULL DEFAULT 0 CHECK (activity_count >= 0), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), CONSTRAINT unique_user_daily_activity UNIQUE (user_id,day_key));
CREATE TABLE public.ayah_progress (id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, payload JSONB NOT NULL DEFAULT '{}'::JSONB, updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE public.bookmarks (id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, payload JSONB NOT NULL DEFAULT '{}'::JSONB, updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE public.certificates (id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, payload JSONB NOT NULL DEFAULT '{}'::JSONB, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE public.ayah_review_records_cloud (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, surah_id INTEGER NOT NULL CHECK (surah_id BETWEEN 1 AND 114), ayah_number INTEGER NOT NULL CHECK (ayah_number BETWEEN 1 AND 286), strength_level INTEGER NOT NULL DEFAULT 0 CHECK (strength_level >= 0), interval_days INTEGER NOT NULL DEFAULT 0 CHECK (interval_days >= 0), last_reviewed_at TIMESTAMPTZ NOT NULL, next_review_date TIMESTAMPTZ NOT NULL, total_reviews INTEGER NOT NULL DEFAULT 0 CHECK (total_reviews >= 0), last_rating TEXT CHECK (last_rating IN ('excellent','average','weak')), ease_factor DOUBLE PRECISION NOT NULL DEFAULT 2.5, lapses INTEGER NOT NULL DEFAULT 0 CHECK (lapses >= 0), review_state TEXT NOT NULL DEFAULT 'newCard' CHECK (review_state IN ('newCard','learning','review','relearning')), created_by_mode TEXT NOT NULL CHECK (created_by_mode IN ('v2Session','kidsMode','hifz')), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), CONSTRAINT unique_user_ayah_review UNIQUE (user_id,surah_id,ayah_number)
);
CREATE TABLE public.daily_plans_cloud (user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE, surah_id INTEGER NOT NULL CHECK (surah_id BETWEEN 1 AND 114), generated_at TIMESTAMPTZ NOT NULL, total_items INTEGER NOT NULL DEFAULT 0 CHECK (total_items >= 0), completed_count INTEGER NOT NULL DEFAULT 0 CHECK (completed_count >= 0), payload JSONB NOT NULL DEFAULT '{}'::JSONB CHECK (pg_column_size(payload) <= 20000), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE public.certificate_awards_cloud (id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, cert_id TEXT NOT NULL CHECK (char_length(cert_id) <= 60), title_ar TEXT NOT NULL CHECK (char_length(title_ar) <= 200), cert_type TEXT NOT NULL CHECK (cert_type IN ('juz','surah','halfQuran','fullQuran')), earned_at TIMESTAMPTZ NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), CONSTRAINT unique_user_cert UNIQUE (user_id,cert_id));

CREATE INDEX idx_parent_child_links_child ON public.parent_child_links(child_user_id);
CREATE INDEX idx_kids_session_logs_child ON public.kids_session_logs(child_user_id,completed_at DESC);
CREATE INDEX idx_parent_rewards_child ON public.parent_rewards(child_user_id,created_at DESC);
CREATE INDEX idx_ayah_review_records_cloud_user ON public.ayah_review_records_cloud(user_id);

CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id,display_name,avatar_url) VALUES (NEW.id,LEFT(COALESCE(NEW.raw_user_meta_data->>'display_name',NEW.raw_user_meta_data->>'full_name',NEW.raw_user_meta_data->>'name','مستخدم'),100),LEFT(NEW.raw_user_meta_data->>'avatar_url',500)) ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
CREATE OR REPLACE FUNCTION public.update_updated_at() RETURNS TRIGGER LANGUAGE plpgsql AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$;

CREATE OR REPLACE FUNCTION public.create_child_link_request_with_hash(p_token_hash TEXT) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_uid UUID := auth.uid(); BEGIN
  IF v_uid IS NULL OR char_length(p_token_hash) <> 64 THEN RAISE EXCEPTION 'Invalid link request'; END IF;
  DELETE FROM public.child_link_requests WHERE child_user_id=v_uid AND expires_at<NOW();
  INSERT INTO public.child_link_requests(child_user_id,token_hash,expires_at) VALUES(v_uid,p_token_hash,NOW()+INTERVAL '10 minutes');
END; $$;
CREATE OR REPLACE FUNCTION public.accept_child_link_token_with_hash(p_token_hash TEXT) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_parent UUID := auth.uid(); v_child UUID; BEGIN
  IF v_parent IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  UPDATE public.child_link_requests SET used_at=NOW() WHERE token_hash=p_token_hash AND used_at IS NULL AND expires_at>NOW() RETURNING child_user_id INTO v_child;
  IF v_child IS NULL OR v_child=v_parent THEN RAISE EXCEPTION 'Invalid or expired link token'; END IF;
  INSERT INTO public.parent_child_links(parent_user_id,child_user_id) VALUES(v_parent,v_child) ON CONFLICT(parent_user_id,child_user_id) DO UPDATE SET status='active',revoked_at=NULL,linked_at=NOW();
END; $$;
CREATE OR REPLACE FUNCTION public.upsert_kids_progress_cloud(p_total_points INTEGER,p_current_level INTEGER,p_current_streak INTEGER,p_stars_earned INTEGER,p_ayahs_completed INTEGER,p_last_session_at TIMESTAMPTZ) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_uid UUID:=auth.uid(); BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  INSERT INTO public.kids_progress_cloud(child_user_id,total_points,current_level,current_streak,stars_earned,ayahs_completed,last_session_at) VALUES(v_uid,p_total_points,p_current_level,p_current_streak,p_stars_earned,p_ayahs_completed,p_last_session_at) ON CONFLICT(child_user_id) DO UPDATE SET total_points=GREATEST(kids_progress_cloud.total_points,EXCLUDED.total_points),current_level=GREATEST(kids_progress_cloud.current_level,EXCLUDED.current_level),current_streak=GREATEST(kids_progress_cloud.current_streak,EXCLUDED.current_streak),stars_earned=GREATEST(kids_progress_cloud.stars_earned,EXCLUDED.stars_earned),ayahs_completed=GREATEST(kids_progress_cloud.ayahs_completed,EXCLUDED.ayahs_completed),last_session_at=GREATEST(kids_progress_cloud.last_session_at,EXCLUDED.last_session_at),updated_at=NOW();
END; $$;
CREATE OR REPLACE FUNCTION public.insert_kids_session_log(p_local_id TEXT,p_surah_id INTEGER,p_ayah_number INTEGER,p_repeats_completed INTEGER,p_points_earned INTEGER,p_completed_at TIMESTAMPTZ) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_uid UUID:=auth.uid(); BEGIN IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF; INSERT INTO public.kids_session_logs(child_user_id,local_id,surah_id,ayah_number,repeats_completed,points_earned,completed_at) VALUES(v_uid,p_local_id,p_surah_id,p_ayah_number,p_repeats_completed,p_points_earned,p_completed_at) ON CONFLICT(child_user_id,local_id) DO NOTHING; END; $$;
CREATE OR REPLACE FUNCTION public.upsert_ayah_progress(p_data JSONB) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$ DECLARE v_uid UUID:=auth.uid(); BEGIN IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF; INSERT INTO public.ayah_progress(user_id,payload) VALUES(v_uid,p_data); END; $$;
CREATE OR REPLACE FUNCTION public.upsert_streak(p_current_streak INTEGER,p_longest_streak INTEGER,p_last_activity_date DATE,p_freezes_available INTEGER) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$ DECLARE v_uid UUID:=auth.uid(); BEGIN IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF; INSERT INTO public.streaks(user_id,current_streak,longest_streak,last_activity_date,freezes_available) VALUES(v_uid,p_current_streak,p_longest_streak,p_last_activity_date,p_freezes_available) ON CONFLICT(user_id) DO UPDATE SET current_streak=GREATEST(streaks.current_streak,EXCLUDED.current_streak),longest_streak=GREATEST(streaks.longest_streak,EXCLUDED.longest_streak),last_activity_date=GREATEST(streaks.last_activity_date,EXCLUDED.last_activity_date),freezes_available=EXCLUDED.freezes_available,updated_at=NOW(); END; $$;
CREATE OR REPLACE FUNCTION public.upsert_xp(p_total_xp INTEGER) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$ DECLARE v_uid UUID:=auth.uid(); BEGIN IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF; INSERT INTO public.xp(user_id,total_xp) VALUES(v_uid,p_total_xp) ON CONFLICT(user_id) DO UPDATE SET total_xp=GREATEST(xp.total_xp,EXCLUDED.total_xp),updated_at=NOW(); END; $$;
CREATE OR REPLACE FUNCTION public.upsert_daily_activities_batch(p_data JSONB) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$ DECLARE v_uid UUID:=auth.uid(); BEGIN IF v_uid IS NULL OR jsonb_typeof(p_data)<>'array' THEN RAISE EXCEPTION 'Invalid activity batch'; END IF; INSERT INTO public.daily_activities(user_id,day_key,activity_count) SELECT v_uid,(item->>'day_key')::INTEGER,(item->>'activity_count')::INTEGER FROM jsonb_array_elements(p_data)item ON CONFLICT(user_id,day_key) DO UPDATE SET activity_count=GREATEST(daily_activities.activity_count,EXCLUDED.activity_count),updated_at=NOW(); END; $$;
CREATE OR REPLACE FUNCTION public.upsert_memorization_identity(p_selected_path TEXT,p_guardian_onboarding_status TEXT,p_is_parent_guardian BOOLEAN,p_child_age INTEGER DEFAULT NULL,p_updated_at TIMESTAMPTZ DEFAULT NULL) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$ DECLARE v_uid UUID:=auth.uid(); BEGIN IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF; UPDATE public.profiles SET age=p_child_age,updated_at=NOW() WHERE id=v_uid; END; $$;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY; ALTER TABLE public.child_link_requests ENABLE ROW LEVEL SECURITY; ALTER TABLE public.parent_child_links ENABLE ROW LEVEL SECURITY; ALTER TABLE public.kids_progress_cloud ENABLE ROW LEVEL SECURITY; ALTER TABLE public.kids_session_logs ENABLE ROW LEVEL SECURITY; ALTER TABLE public.parent_rewards ENABLE ROW LEVEL SECURITY; ALTER TABLE public.streaks ENABLE ROW LEVEL SECURITY; ALTER TABLE public.xp ENABLE ROW LEVEL SECURITY; ALTER TABLE public.xp_history ENABLE ROW LEVEL SECURITY; ALTER TABLE public.daily_activities ENABLE ROW LEVEL SECURITY; ALTER TABLE public.ayah_progress ENABLE ROW LEVEL SECURITY; ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY; ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY; ALTER TABLE public.ayah_review_records_cloud ENABLE ROW LEVEL SECURITY; ALTER TABLE public.daily_plans_cloud ENABLE ROW LEVEL SECURITY; ALTER TABLE public.certificate_awards_cloud ENABLE ROW LEVEL SECURITY;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT,UPDATE ON public.profiles TO authenticated; GRANT SELECT ON public.child_link_requests,public.parent_child_links,public.kids_progress_cloud,public.kids_session_logs,public.ayah_review_records_cloud TO authenticated; GRANT SELECT,INSERT,UPDATE,DELETE ON public.parent_rewards,public.streaks,public.xp,public.daily_activities TO authenticated; GRANT SELECT,INSERT ON public.xp_history,public.certificate_awards_cloud TO authenticated; GRANT SELECT,INSERT,UPDATE ON public.daily_plans_cloud TO authenticated; GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
CREATE POLICY profiles_owner ON public.profiles FOR ALL TO authenticated USING ((SELECT auth.uid())=id) WITH CHECK ((SELECT auth.uid())=id);
CREATE POLICY child_link_requests_child_own ON public.child_link_requests FOR SELECT TO authenticated USING ((SELECT auth.uid())=child_user_id);
CREATE POLICY parent_child_links_parent_or_child_read ON public.parent_child_links FOR SELECT TO authenticated USING ((SELECT auth.uid()) IN(parent_user_id,child_user_id));
CREATE POLICY kids_progress_child_write ON public.kids_progress_cloud FOR ALL TO authenticated USING ((SELECT auth.uid())=child_user_id) WITH CHECK ((SELECT auth.uid())=child_user_id);
CREATE POLICY kids_session_logs_child_write ON public.kids_session_logs FOR ALL TO authenticated USING ((SELECT auth.uid())=child_user_id) WITH CHECK ((SELECT auth.uid())=child_user_id);
CREATE POLICY parent_rewards_parent_manage ON public.parent_rewards FOR ALL TO authenticated USING ((SELECT auth.uid())=parent_user_id) WITH CHECK ((SELECT auth.uid())=parent_user_id); CREATE POLICY parent_rewards_child_read ON public.parent_rewards FOR SELECT TO authenticated USING ((SELECT auth.uid())=child_user_id);
CREATE POLICY streaks_owner_all ON public.streaks FOR ALL TO authenticated USING ((SELECT auth.uid())=user_id) WITH CHECK ((SELECT auth.uid())=user_id); CREATE POLICY xp_owner_all ON public.xp FOR ALL TO authenticated USING ((SELECT auth.uid())=user_id) WITH CHECK ((SELECT auth.uid())=user_id); CREATE POLICY xp_history_owner_read ON public.xp_history FOR SELECT TO authenticated USING ((SELECT auth.uid())=user_id); CREATE POLICY xp_history_owner_insert ON public.xp_history FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid())=user_id); CREATE POLICY daily_activities_owner_all ON public.daily_activities FOR ALL TO authenticated USING ((SELECT auth.uid())=user_id) WITH CHECK ((SELECT auth.uid())=user_id); CREATE POLICY ayah_progress_all_own ON public.ayah_progress FOR ALL TO authenticated USING ((SELECT auth.uid())=user_id) WITH CHECK ((SELECT auth.uid())=user_id); CREATE POLICY bookmarks_all_own ON public.bookmarks FOR ALL TO authenticated USING ((SELECT auth.uid())=user_id) WITH CHECK ((SELECT auth.uid())=user_id); CREATE POLICY certificates_all_own ON public.certificates FOR ALL TO authenticated USING ((SELECT auth.uid())=user_id) WITH CHECK ((SELECT auth.uid())=user_id); CREATE POLICY ayah_review_records_cloud_owner_select ON public.ayah_review_records_cloud FOR SELECT TO authenticated USING ((SELECT auth.uid())=user_id); CREATE POLICY daily_plans_cloud_owner_all ON public.daily_plans_cloud FOR ALL TO authenticated USING ((SELECT auth.uid())=user_id) WITH CHECK ((SELECT auth.uid())=user_id); CREATE POLICY certificate_awards_cloud_owner_select ON public.certificate_awards_cloud FOR SELECT TO authenticated USING ((SELECT auth.uid())=user_id); CREATE POLICY certificate_awards_cloud_owner_insert ON public.certificate_awards_cloud FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid())=user_id);
CREATE POLICY profiles_parent_read_linked_child ON public.profiles FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.parent_child_links pcl WHERE pcl.child_user_id=profiles.id AND pcl.parent_user_id=(SELECT auth.uid()) AND pcl.status='active'));
CREATE POLICY kids_progress_parent_read ON public.kids_progress_cloud FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.parent_child_links pcl WHERE pcl.child_user_id=kids_progress_cloud.child_user_id AND pcl.parent_user_id=(SELECT auth.uid()) AND pcl.status='active'));
CREATE POLICY kids_session_logs_parent_read ON public.kids_session_logs FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.parent_child_links pcl WHERE pcl.child_user_id=kids_session_logs.child_user_id AND pcl.parent_user_id=(SELECT auth.uid()) AND pcl.status='active'));
CREATE POLICY streaks_parent_read ON public.streaks FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.parent_child_links pcl WHERE pcl.child_user_id=streaks.user_id AND pcl.parent_user_id=(SELECT auth.uid()) AND pcl.status='active'));
CREATE POLICY daily_activities_parent_read ON public.daily_activities FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.parent_child_links pcl WHERE pcl.child_user_id=daily_activities.user_id AND pcl.parent_user_id=(SELECT auth.uid()) AND pcl.status='active'));
CREATE POLICY ayah_review_records_cloud_parent_read ON public.ayah_review_records_cloud FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.parent_child_links pcl WHERE pcl.child_user_id=ayah_review_records_cloud.user_id AND pcl.parent_user_id=(SELECT auth.uid()) AND pcl.status='active'));
CREATE POLICY daily_plans_cloud_parent_read ON public.daily_plans_cloud FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.parent_child_links pcl WHERE pcl.child_user_id=daily_plans_cloud.user_id AND pcl.parent_user_id=(SELECT auth.uid()) AND pcl.status='active'));
CREATE POLICY certificate_awards_cloud_parent_read ON public.certificate_awards_cloud FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.parent_child_links pcl WHERE pcl.child_user_id=certificate_awards_cloud.user_id AND pcl.parent_user_id=(SELECT auth.uid()) AND pcl.status='active'));
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon; REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM anon;
GRANT EXECUTE ON FUNCTION public.create_child_link_request_with_hash(TEXT),public.accept_child_link_token_with_hash(TEXT),public.upsert_kids_progress_cloud(INTEGER,INTEGER,INTEGER,INTEGER,INTEGER,TIMESTAMPTZ),public.insert_kids_session_log(TEXT,INTEGER,INTEGER,INTEGER,INTEGER,TIMESTAMPTZ),public.upsert_ayah_progress(JSONB),public.upsert_streak(INTEGER,INTEGER,DATE,INTEGER),public.upsert_xp(INTEGER),public.upsert_daily_activities_batch(JSONB),public.upsert_memorization_identity(TEXT,TEXT,BOOLEAN,INTEGER,TIMESTAMPTZ) TO authenticated;
