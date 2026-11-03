begin;
create function pg_temp.checkpoint_assert(ok boolean, message text) returns void language plpgsql as $$
begin if ok is distinct from true then raise exception 'checkpoint: %', message; end if; end $$;
insert into auth.users(id) values ('81000000-0000-0000-0000-000000000003');
select pg_temp.checkpoint_assert(not has_table_privilege('authenticated','public.quran_reading_checkpoints','SELECT,INSERT,UPDATE,DELETE'), 'authenticated direct checkpoint access');
select pg_temp.checkpoint_assert(not has_table_privilege('authenticated','public.quran_reading_checkpoint_receipts','SELECT,INSERT,UPDATE,DELETE'), 'authenticated direct receipt access');
select pg_temp.checkpoint_assert(not has_table_privilege('anon','public.quran_reading_checkpoints','SELECT,INSERT,UPDATE,DELETE'), 'anon direct checkpoint access');
select pg_temp.checkpoint_assert(not has_table_privilege('anon','public.quran_reading_checkpoint_receipts','SELECT,INSERT,UPDATE,DELETE'), 'anon direct receipt access');
select pg_temp.checkpoint_assert(not has_function_privilege('anon','public.get_quran_reading_checkpoint(uuid)','EXECUTE'), 'anon get execute');
select pg_temp.checkpoint_assert(not has_function_privilege('anon','public.put_quran_reading_checkpoint(integer,bigint,uuid,uuid)','EXECUTE'), 'anon put execute');
select set_config('request.jwt.claims','{}',true);
set local role authenticated;
do $$ begin
  begin insert into public.quran_reading_checkpoints(user_id,page_number,revision) values ('81000000-0000-0000-0000-000000000003',1,1); raise exception 'direct insert accepted'; exception when insufficient_privilege then null; end;
  begin update public.quran_reading_checkpoints set page_number=1; raise exception 'direct update accepted'; exception when insufficient_privilege then null; end;
  begin delete from public.quran_reading_checkpoint_receipts; raise exception 'direct receipt delete accepted'; exception when insufficient_privilege then null; end;
  begin perform public.get_quran_reading_checkpoint('81000000-0000-0000-0000-000000000003'); raise exception 'null uid accepted'; exception when insufficient_privilege then null; end;
  begin perform public.put_quran_reading_checkpoint(1,0,'82000000-0000-0000-0000-000000000010','81000000-0000-0000-0000-000000000003'); raise exception 'null uid put accepted'; exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claims','{"sub":"81000000-0000-0000-0000-000000000003","is_anonymous":true}',true);
do $$ begin
  begin perform public.put_quran_reading_checkpoint(1,0,'82000000-0000-0000-0000-000000000010','81000000-0000-0000-0000-000000000003'); raise exception 'anonymous put accepted'; exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claims','{"sub":"81000000-0000-0000-0000-000000000003"}',true);
select pg_temp.checkpoint_assert(public.put_quran_reading_checkpoint(10,0,'82000000-0000-0000-0000-000000000011','81000000-0000-0000-0000-000000000003')->>'status' = 'accepted', 'first write');
select pg_temp.checkpoint_assert(public.put_quran_reading_checkpoint(20,1,'82000000-0000-0000-0000-000000000012','81000000-0000-0000-0000-000000000003')->>'status' = 'accepted', 'second write');
select pg_temp.checkpoint_assert(public.put_quran_reading_checkpoint(10,0,'82000000-0000-0000-0000-000000000011','81000000-0000-0000-0000-000000000003')->>'revision' = '1', 'replay returns original receipt');
select pg_temp.checkpoint_assert(public.get_quran_reading_checkpoint('81000000-0000-0000-0000-000000000003')->>'page_number' = '20', 'current read survives old receipt replay');
reset role;
delete from auth.users where id='81000000-0000-0000-0000-000000000003';
select pg_temp.checkpoint_assert(not exists(select 1 from public.quran_reading_checkpoints where user_id='81000000-0000-0000-0000-000000000003'), 'checkpoint cascade');
select pg_temp.checkpoint_assert(not exists(select 1 from public.quran_reading_checkpoint_receipts where user_id='81000000-0000-0000-0000-000000000003'), 'receipt cascade');
rollback;
