begin;
create function pg_temp.checkpoint_assert(ok boolean, message text) returns void language plpgsql as $$
begin if ok is distinct from true then raise exception 'checkpoint: %', message; end if; end $$;
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
values ('00000000-0000-0000-0000-000000000000','81000000-0000-0000-0000-000000000001','authenticated','authenticated','checkpoint1@example.test','',now(),'{}','{}',now(),now()),
('00000000-0000-0000-0000-000000000000','81000000-0000-0000-0000-000000000002','authenticated','authenticated','checkpoint2@example.test','',now(),'{}','{}',now(),now());
select set_config('request.jwt.claims','{"sub":"81000000-0000-0000-0000-000000000001"}',true);
set local role authenticated;
select pg_temp.checkpoint_assert((public.put_quran_reading_checkpoint(12,0,'82000000-0000-0000-0000-000000000001','81000000-0000-0000-0000-000000000001')->>'revision')::int = 1,'first mutation');
select pg_temp.checkpoint_assert((public.put_quran_reading_checkpoint(12,0,'82000000-0000-0000-0000-000000000001','81000000-0000-0000-0000-000000000001')->>'revision')::int = 1,'retry is idempotent');
select pg_temp.checkpoint_assert(public.put_quran_reading_checkpoint(20,0,'82000000-0000-0000-0000-000000000002','81000000-0000-0000-0000-000000000001')->>'status' = 'conflict','stale device conflicts');
select pg_temp.checkpoint_assert((public.get_quran_reading_checkpoint('81000000-0000-0000-0000-000000000001')->>'page_number')::int = 12,'conflict does not overwrite');
do $$ begin
  begin perform public.put_quran_reading_checkpoint(605,1,'82000000-0000-0000-0000-000000000003','81000000-0000-0000-0000-000000000001'); raise exception 'invalid page accepted'; exception when invalid_parameter_value then null; end;
  begin perform public.put_quran_reading_checkpoint(13,0,'82000000-0000-0000-0000-000000000001','81000000-0000-0000-0000-000000000001'); raise exception 'mutation reuse accepted'; exception when invalid_parameter_value then null; end;
  begin perform * from public.quran_reading_checkpoints; raise exception 'direct table read allowed'; exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claims','{"sub":"81000000-0000-0000-0000-000000000002"}',true);
do $$ begin
  begin
    perform public.put_quran_reading_checkpoint(42,0,'82000000-0000-0000-0000-000000000004','81000000-0000-0000-0000-000000000001');
    raise exception 'old owner request was accepted under another session';
  exception when insufficient_privilege then null; end;
  begin
    perform public.get_quran_reading_checkpoint('81000000-0000-0000-0000-000000000001');
    raise exception 'old owner read was accepted under another session';
  exception when insufficient_privilege then null; end;
end $$;
select pg_temp.checkpoint_assert(public.get_quran_reading_checkpoint('81000000-0000-0000-0000-000000000002') is null,'other owner cannot read');
select set_config('request.jwt.claims','{"sub":"81000000-0000-0000-0000-000000000001","is_anonymous":true}',true);
do $$ begin begin perform public.get_quran_reading_checkpoint('81000000-0000-0000-0000-000000000001'); raise exception 'anonymous account accepted'; exception when insufficient_privilege then null; end; end $$;
reset role;
rollback;

