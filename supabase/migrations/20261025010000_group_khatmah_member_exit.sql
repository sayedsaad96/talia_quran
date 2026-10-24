-- Group khatmah: exits never need eligibility (independent review, P3).
-- Self-grants (policy_version 2) are re-checked live, so a member can lose
-- eligibility by becoming a linked child or switching to the child path.
-- Leaving a group and releasing an own claimed part only undo the member's
-- own presence, so they no longer require eligibility; claim and complete
-- still do. Bodies are the deployed 20261023010003 ones with that check
-- narrowed. Trusted provisioning may no longer grant at the self-grant version.

CREATE OR REPLACE FUNCTION private.group_khatmah_change_part(
  p_action text,p_group_id uuid,p_juz smallint,p_expected_version bigint,
  p_membership_epoch uuid,p_operation_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_actor uuid;
DECLARE v_group public.group_khatmah;
DECLARE v_member public.group_khatmah_member;
DECLARE v_part public.group_khatmah_part;
DECLARE v_fp text;
DECLARE v_replay jsonb;
DECLARE v_result jsonb;
BEGIN
  v_actor := private.group_khatmah_actor();
  IF p_action IS DISTINCT FROM 'release'
    AND NOT private.group_khatmah_adult(v_actor) THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','not_eligible');
  END IF;
  IF p_action IS NULL OR p_action NOT IN ('claim','complete','release')
    OR p_group_id IS NULL
    OR p_juz IS NULL OR p_juz NOT BETWEEN 1 AND 30
    OR p_expected_version IS NULL OR p_expected_version < 1
    OR p_membership_epoch IS NULL OR p_operation_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','invalid_operation');
  END IF;
  v_fp := pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(
    pg_catalog.jsonb_build_array(p_action,p_group_id,p_juz,
      p_expected_version,p_membership_epoch)::text,'UTF8')),'hex');
  v_replay := private.group_khatmah_replay(v_actor,p_action,p_operation_id,v_fp);
  IF v_replay IS NOT NULL THEN RETURN v_replay; END IF;
  SELECT * INTO v_group FROM public.group_khatmah g WHERE g.id=p_group_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','gone');
  END IF;
  SELECT * INTO v_member FROM public.group_khatmah_member m
    WHERE m.group_id=p_group_id AND m.user_id=v_actor FOR UPDATE;
  IF NOT FOUND OR v_member.left_at IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','not_member');
  END IF;
  IF v_member.membership_epoch <> p_membership_epoch THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','stale_operation');
  END IF;
  IF v_group.status <> 'active' THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','group_completed',
      'group_version',v_group.version);
  END IF;
  SELECT * INTO v_part FROM public.group_khatmah_part p
    WHERE p.group_id=p_group_id AND p.juz=p_juz FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','invalid_operation');
  END IF;
  IF v_part.version <> p_expected_version OR
    (p_action='claim' AND v_part.status<>'open') OR
    (p_action IN ('complete','release') AND
      (v_part.status<>'claimed' OR v_part.claimed_by<>v_actor
        OR v_part.claim_epoch<>p_membership_epoch)) THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','conflict',
      'operation_id',p_operation_id,'group_version',v_group.version,
      'part',pg_catalog.to_jsonb(v_part));
  END IF;
  IF p_action='claim' THEN
    UPDATE public.group_khatmah_part SET status='claimed',claimed_by=v_actor,
      claim_epoch=p_membership_epoch,version=version+1,updated_at=now()
      WHERE group_id=p_group_id AND juz=p_juz RETURNING * INTO v_part;
  ELSIF p_action='complete' THEN
    UPDATE public.group_khatmah_part SET status='completed',version=version+1,
      updated_at=now() WHERE group_id=p_group_id AND juz=p_juz
      RETURNING * INTO v_part;
  ELSE
    UPDATE public.group_khatmah_part SET status='open',claimed_by=NULL,
      claim_epoch=NULL,version=version+1,updated_at=now()
      WHERE group_id=p_group_id AND juz=p_juz RETURNING * INTO v_part;
  END IF;
  IF p_action='complete' AND (SELECT count(*) FROM public.group_khatmah_part p
      WHERE p.group_id=p_group_id AND p.status='completed')=30 THEN
    UPDATE public.group_khatmah SET status='completed',completed_at=now(),
      version=version+1 WHERE id=p_group_id RETURNING * INTO v_group;
  ELSE
    UPDATE public.group_khatmah SET version=version+1
      WHERE id=p_group_id RETURNING * INTO v_group;
  END IF;
  v_result := pg_catalog.jsonb_build_object('applied',true,'code',
    CASE p_action WHEN 'release' THEN 'released'
      WHEN 'complete' THEN 'completed' ELSE 'claimed' END,
    'operation_id',p_operation_id,'group_id',p_group_id,
    'group_version',v_group.version,'part_version',v_part.version,
    'juz',p_juz,'group_status',v_group.status);
  INSERT INTO private.group_khatmah_receipt
    (actor_id,operation_id,kind,group_id,fingerprint,membership_epoch,result)
    VALUES (v_actor,p_operation_id,p_action,p_group_id,v_fp,
      p_membership_epoch,v_result);
  RETURN v_result || pg_catalog.jsonb_build_object('membership_epoch',p_membership_epoch);
END;
$$;

CREATE OR REPLACE FUNCTION private.group_khatmah_leave(
  p_group_id uuid,p_membership_epoch uuid,p_operation_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_actor uuid;
DECLARE v_group public.group_khatmah;
DECLARE v_member public.group_khatmah_member;
DECLARE v_fp text;
DECLARE v_replay jsonb;
DECLARE v_result jsonb;
BEGIN
  -- Session and actor lock only: a member may always leave.
  v_actor := private.group_khatmah_actor();
  IF p_group_id IS NULL OR p_membership_epoch IS NULL OR p_operation_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','invalid_operation');
  END IF;
  v_fp := pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(
    pg_catalog.jsonb_build_array('leave',p_group_id,p_membership_epoch)::text,'UTF8')),'hex');
  v_replay := private.group_khatmah_replay(v_actor,'leave',p_operation_id,v_fp);
  IF v_replay IS NOT NULL THEN RETURN v_replay; END IF;
  SELECT * INTO v_group FROM public.group_khatmah g WHERE g.id=p_group_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','gone');
  END IF;
  SELECT * INTO v_member FROM public.group_khatmah_member m
    WHERE m.group_id=p_group_id AND m.user_id=v_actor FOR UPDATE;
  IF NOT FOUND OR v_member.left_at IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','not_member');
  END IF;
  IF v_member.membership_epoch<>p_membership_epoch THEN
    RETURN pg_catalog.jsonb_build_object('applied',false,'code','stale_operation');
  END IF;
  IF v_group.owner_id=v_actor THEN
    IF EXISTS (SELECT 1 FROM public.group_khatmah_member m
      WHERE m.group_id=p_group_id AND m.user_id<>v_actor AND m.left_at IS NULL) THEN
      RETURN pg_catalog.jsonb_build_object('applied',false,'code','owner_has_members');
    END IF;
    UPDATE private.group_khatmah_receipt SET gone=true,fingerprint=NULL,
      membership_epoch=NULL,result=NULL WHERE group_id=p_group_id;
    INSERT INTO private.group_khatmah_receipt
      (actor_id,operation_id,kind,group_id,gone)
      VALUES (v_actor,p_operation_id,'leave',p_group_id,true);
    DELETE FROM public.group_khatmah WHERE id=p_group_id;
    RETURN pg_catalog.jsonb_build_object('applied',true,'code','group_deleted',
      'operation_id',p_operation_id,'group_id',p_group_id);
  END IF;
  -- Privacy exit is permitted after completion, without undoing completion.
  UPDATE public.group_khatmah_part SET status='open',claimed_by=NULL,
    claim_epoch=NULL,version=version+1,updated_at=now()
    WHERE group_id=p_group_id AND claimed_by=v_actor AND status='claimed';
  UPDATE public.group_khatmah_part SET claimed_by=NULL,claim_epoch=NULL,
    version=version+1,updated_at=now()
    WHERE group_id=p_group_id AND claimed_by=v_actor AND status='completed';
  UPDATE public.group_khatmah_member SET display_name='',left_at=now()
    WHERE group_id=p_group_id AND user_id=v_actor;
  UPDATE public.group_khatmah SET version=version+1 WHERE id=p_group_id
    RETURNING * INTO v_group;
  v_result := pg_catalog.jsonb_build_object('applied',true,'code','left',
    'operation_id',p_operation_id,'group_id',p_group_id,
    'group_version',v_group.version);
  INSERT INTO private.group_khatmah_receipt
    (actor_id,operation_id,kind,group_id,fingerprint,membership_epoch,result)
    VALUES (v_actor,p_operation_id,'leave',p_group_id,v_fp,p_membership_epoch,v_result);
  RETURN v_result;
END;
$$;

-- A trusted grant may not use policy_version 2, which marks self-grants
-- that are re-checked live. A denial at any version stays allowed.
CREATE OR REPLACE FUNCTION private.group_khatmah_provision(
  p_user uuid,p_eligible boolean,p_policy_version integer)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF p_user IS NULL OR p_eligible IS NULL OR p_policy_version IS NULL
    OR p_policy_version <= 0 OR (p_eligible AND p_policy_version = 2)
    THEN RAISE EXCEPTION 'invalid_eligibility'; END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(7031,pg_catalog.hashtext(p_user::text));
  INSERT INTO private.group_khatmah_eligibility(user_id,eligible,policy_version)
    VALUES (p_user,p_eligible,p_policy_version)
  ON CONFLICT (user_id) DO UPDATE SET eligible = EXCLUDED.eligible,
    policy_version = EXCLUDED.policy_version,updated_at = now();
END;
$$;
