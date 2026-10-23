CREATE OR REPLACE FUNCTION private.group_khatmah_create(
  p_title text,p_display_name text,p_operation_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_actor uuid;
DECLARE v_group public.group_khatmah;
DECLARE v_epoch uuid := pg_catalog.gen_random_uuid();
DECLARE v_fp text;
DECLARE v_replay jsonb;
DECLARE v_code text;
DECLARE v_bytes bytea;
DECLARE v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
BEGIN
  v_actor := private.group_khatmah_actor();
  IF NOT private.group_khatmah_adult(v_actor) THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','not_eligible');
  END IF;
  IF p_operation_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','invalid_operation');
  END IF;
  v_fp := pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(
    pg_catalog.jsonb_build_array('create',p_title,p_display_name)::text,'UTF8')),'hex');
  v_replay := private.group_khatmah_replay(v_actor,'create',p_operation_id,v_fp);
  IF v_replay IS NOT NULL THEN RETURN v_replay; END IF;
  p_title := pg_catalog.btrim(p_title);
  p_display_name := pg_catalog.btrim(p_display_name);
  IF NOT private.group_khatmah_valid_label(p_title,1,80)
    OR NOT private.group_khatmah_valid_label(p_display_name,2,24) THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','invalid_input');
  END IF;
  FOR v_try IN 1..10 LOOP
    v_bytes := pg_catalog.uuid_send(pg_catalog.gen_random_uuid());
    v_code := '';
    FOR v_i IN 0..5 LOOP
      v_code := v_code || pg_catalog.substr(v_alphabet,
        (pg_catalog.get_byte(v_bytes,v_i) % 32)+1,1);
    END LOOP;
    BEGIN
      INSERT INTO public.group_khatmah(code,title,owner_id)
        VALUES (v_code,p_title,v_actor) RETURNING * INTO v_group;
      EXIT;
    EXCEPTION WHEN unique_violation THEN
      IF v_try = 10 THEN RAISE EXCEPTION 'group_code_collision'; END IF;
    END;
  END LOOP;
  INSERT INTO public.group_khatmah_member
    (group_id,user_id,display_name,membership_epoch)
    VALUES (v_group.id,v_actor,p_display_name,v_epoch);
  INSERT INTO public.group_khatmah_part(group_id,juz)
    SELECT v_group.id,g.juz FROM pg_catalog.generate_series(1,30) AS g(juz);
  INSERT INTO private.group_khatmah_receipt
    (actor_id,operation_id,kind,group_id,fingerprint,membership_epoch,result)
    VALUES (v_actor,p_operation_id,'create',v_group.id,v_fp,v_epoch,
      pg_catalog.jsonb_build_object('applied',true,'code','created',
        'operation_id',p_operation_id,'group_id',v_group.id,'group_version',1));
  RETURN pg_catalog.jsonb_build_object('applied',true,'code','created',
    'operation_id',p_operation_id,'group_id',v_group.id,'group_version',1,
    'membership_epoch',v_epoch,'invite_code',v_group.code);
END;
$$;

CREATE OR REPLACE FUNCTION private.group_khatmah_join(
  p_code text,p_display_name text,p_operation_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_actor uuid;
DECLARE v_group public.group_khatmah;
DECLARE v_member public.group_khatmah_member;
DECLARE v_epoch uuid;
DECLARE v_fp text;
DECLARE v_replay jsonb;
DECLARE v_code text;
DECLARE v_result jsonb;
BEGIN
  v_actor := private.group_khatmah_actor();
  IF NOT private.group_khatmah_adult(v_actor) THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','not_eligible');
  END IF;
  IF p_operation_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','invalid_operation');
  END IF;
  v_fp := pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(
    pg_catalog.jsonb_build_array('join',p_code,p_display_name)::text,'UTF8')),'hex');
  v_replay := private.group_khatmah_replay(v_actor,'join',p_operation_id,v_fp);
  IF v_replay IS NOT NULL THEN RETURN v_replay; END IF;
  IF NOT private.group_khatmah_throttle(v_actor) THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','rate_limited');
  END IF;
  v_code := pg_catalog.btrim(p_code);
  p_display_name := pg_catalog.btrim(p_display_name);
  IF v_code IS NULL OR v_code !~ '^[A-Za-z2-9]{6}$' THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','invalid_invite');
  END IF;
  v_code := pg_catalog.upper(v_code);
  IF v_code IS NULL OR v_code !~ '^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$' THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','invalid_invite');
  END IF;
  IF NOT private.group_khatmah_valid_label(p_display_name,2,24) THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','invalid_input');
  END IF;
  SELECT * INTO v_group FROM public.group_khatmah g
    WHERE g.code = v_code FOR UPDATE;
  IF NOT FOUND OR v_group.status <> 'active' THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','invalid_invite');
  END IF;
  SELECT * INTO v_member FROM public.group_khatmah_member m
    WHERE m.group_id = v_group.id AND m.user_id = v_actor FOR UPDATE;
  IF FOUND AND v_member.left_at IS NULL THEN
    v_epoch := v_member.membership_epoch;
    v_result := pg_catalog.jsonb_build_object('applied',true,'code','already_member',
      'operation_id',p_operation_id,'group_id',v_group.id,
      'group_version',v_group.version);
  ELSE
    IF (SELECT count(*) FROM public.group_khatmah_member m
      WHERE m.group_id = v_group.id AND m.left_at IS NULL) >= 30 THEN
      RETURN pg_catalog.jsonb_build_object('applied',false,'code','group_full');
    END IF;
    v_epoch := pg_catalog.gen_random_uuid();
    IF v_member.group_id IS NULL THEN
      INSERT INTO public.group_khatmah_member
        (group_id,user_id,display_name,membership_epoch)
        VALUES (v_group.id,v_actor,p_display_name,v_epoch);
    ELSE
      UPDATE public.group_khatmah_member SET display_name=p_display_name,
        joined_at=now(),left_at=NULL,membership_epoch=v_epoch
        WHERE group_id=v_group.id AND user_id=v_actor;
    END IF;
    UPDATE public.group_khatmah SET version=version+1 WHERE id=v_group.id
      RETURNING * INTO v_group;
    v_result := pg_catalog.jsonb_build_object('applied',true,'code','joined',
      'operation_id',p_operation_id,'group_id',v_group.id,
      'group_version',v_group.version);
  END IF;
  INSERT INTO private.group_khatmah_receipt
    (actor_id,operation_id,kind,group_id,fingerprint,membership_epoch,result)
    VALUES (v_actor,p_operation_id,'join',v_group.id,v_fp,v_epoch,v_result);
  RETURN v_result || pg_catalog.jsonb_build_object('membership_epoch',v_epoch);
END;
$$;

REVOKE ALL ON FUNCTION private.group_khatmah_create(text,text,uuid),
  private.group_khatmah_join(text,text,uuid)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.group_khatmah_create(text,text,uuid),
  private.group_khatmah_join(text,text,uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.create_group_khatmah(
  p_title text,p_display_name text,p_operation_id uuid)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path = '' AS $$
  SELECT private.group_khatmah_create(p_title,p_display_name,p_operation_id);
$$;
CREATE OR REPLACE FUNCTION public.join_group_khatmah(
  p_code text,p_display_name text,p_operation_id uuid)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path = '' AS $$
  SELECT private.group_khatmah_join(p_code,p_display_name,p_operation_id);
$$;
REVOKE ALL ON FUNCTION public.create_group_khatmah(text,text,uuid),
  public.join_group_khatmah(text,text,uuid)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.create_group_khatmah(text,text,uuid),
  public.join_group_khatmah(text,text,uuid) TO authenticated;
