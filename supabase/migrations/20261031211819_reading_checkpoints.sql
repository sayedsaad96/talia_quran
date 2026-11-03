-- Separate from read_pages. Receipts remain until account deletion: pruning
-- them could turn an offline retry into a second successful mutation.
create table public.quran_reading_checkpoints (
  user_id uuid primary key references auth.users(id) on delete cascade,
  page_number integer not null check (page_number between 1 and 604),
  revision bigint not null check (revision > 0),
  updated_at timestamptz not null default now()
);
create table public.quran_reading_checkpoint_receipts (
  user_id uuid not null references auth.users(id) on delete cascade,
  mutation_id uuid not null,
  page_number integer not null check (page_number between 1 and 604),
  expected_revision bigint not null check (expected_revision >= 0),
  accepted_revision bigint not null check (accepted_revision > 0),
  primary key (user_id, mutation_id)
);
alter table public.quran_reading_checkpoints enable row level security;
alter table public.quran_reading_checkpoint_receipts enable row level security;
revoke all on public.quran_reading_checkpoints from public, anon, authenticated;
revoke all on public.quran_reading_checkpoint_receipts from public, anon, authenticated;

create or replace function public.get_quran_reading_checkpoint(p_expected_owner uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_owner uuid := auth.uid(); v_row public.quran_reading_checkpoints%rowtype;
begin
  if v_owner is null or p_expected_owner is distinct from v_owner or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  select * into v_row from public.quran_reading_checkpoints where user_id = v_owner;
  if not found then return null; end if;
  return jsonb_build_object('page_number', v_row.page_number, 'revision', v_row.revision);
end $$;

create or replace function public.put_quran_reading_checkpoint(p_page integer, p_expected_revision bigint, p_mutation_id uuid, p_expected_owner uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_owner uuid := auth.uid();
  v_row public.quran_reading_checkpoints%rowtype;
  v_receipt public.quran_reading_checkpoint_receipts%rowtype;
  v_revision bigint;
begin
  if v_owner is null or p_expected_owner is distinct from v_owner or coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_page is null or p_page not between 1 and 604 or p_expected_revision is null or p_expected_revision < 0 or p_mutation_id is null then
    raise exception 'invalid checkpoint' using errcode = '22023';
  end if;
  -- Serialize first insert as well as subsequent updates for this owner.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_owner::text, 0));
  select * into v_receipt from public.quran_reading_checkpoint_receipts where user_id = v_owner and mutation_id = p_mutation_id;
  if found then
    if v_receipt.page_number <> p_page or v_receipt.expected_revision <> p_expected_revision then
      raise exception 'mutation id reused with different payload' using errcode = '22023';
    end if;
    return jsonb_build_object('status', 'accepted', 'page_number', v_receipt.page_number, 'revision', v_receipt.accepted_revision);
  end if;
  select * into v_row from public.quran_reading_checkpoints where user_id = v_owner;
  v_revision := coalesce(v_row.revision, 0);
  if v_revision <> p_expected_revision then
    return jsonb_build_object('status', 'conflict', 'page_number', v_row.page_number, 'revision', v_revision);
  end if;
  insert into public.quran_reading_checkpoints(user_id, page_number, revision, updated_at)
  values(v_owner, p_page, v_revision + 1, pg_catalog.now())
  on conflict (user_id) do update set page_number = excluded.page_number, revision = excluded.revision, updated_at = excluded.updated_at;
  insert into public.quran_reading_checkpoint_receipts(user_id, mutation_id, page_number, expected_revision, accepted_revision)
  values(v_owner, p_mutation_id, p_page, p_expected_revision, v_revision + 1);
  return jsonb_build_object('status', 'accepted', 'page_number', p_page, 'revision', v_revision + 1);
end $$;
revoke all on function public.get_quran_reading_checkpoint(uuid) from public, anon;
revoke all on function public.put_quran_reading_checkpoint(integer, bigint, uuid, uuid) from public, anon;
grant execute on function public.get_quran_reading_checkpoint(uuid) to authenticated;
grant execute on function public.put_quran_reading_checkpoint(integer, bigint, uuid, uuid) to authenticated;
