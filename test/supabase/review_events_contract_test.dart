import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;

  setUpAll(() {
    migration = _normalized(
      File(
        'supabase/migrations/20260908120939_ayah_review_events_v1.sql',
      ).readAsStringSync(),
    );
  });

  test('event ledger is append-only and protected by RLS', () {
    expect(migration, contains('create table if not exists public.ayah_review_events'));
    expect(migration, contains('server_sequence bigint generated always as identity primary key'));
    expect(migration, contains('unique (user_id, event_id)'));
    expect(migration, contains('ayah_review_events_logical_event_unique'));
    expect(migration, contains('enable row level security'));
    expect(migration, contains('for insert'));
    expect(migration, isNot(contains('for update')));
    expect(migration, isNot(contains('for delete')));
  });

  test('append RPC derives the owner and validates event-only payloads', () {
    expect(migration, contains('append_ayah_review_events_v1(p_events jsonb)'));
    expect(migration, contains('v_uid uuid := auth.uid()'));
    expect(migration, contains('public.is_valid_quran_ayah_reference'));
    expect(migration, contains("v_audience not in ('adult', 'kids')"));
    expect(migration, contains('jsonb_object_keys(v_item)'));
    expect(migration, contains("result := 'alreadyapplied'"));
    expect(migration, contains('v_existing_same'));
    expect(
      migration,
      contains('returning inserted.server_sequence into v_sequence'),
    );
    expect(migration, contains('security definer set search_path = \'\''));
    expect(migration, contains('revoke all on function public.append_ayah_review_events_v1(jsonb)'));
    expect(migration, contains('grant execute on function public.append_ayah_review_events_v1(jsonb) to authenticated'));
    expect(migration, isNot(contains('spoken_text')));
    expect(migration, isNot(contains('audio_recording')));
  });

  test('append RPC hotfix preserves the qualified RETURNING contract', () {
    final hotfix = _normalized(
      File(
        'supabase/migrations/20260908153934_fix_ayah_review_event_append_v1.sql',
      ).readAsStringSync(),
    );

    expect(hotfix, contains('create or replace function public.append_ayah_review_events_v1'));
    expect(
      hotfix,
      contains('returning inserted.server_sequence into v_sequence'),
    );
    expect(hotfix, contains('revoke all on function public.append_ayah_review_events_v1(jsonb)'));
    expect(hotfix, contains('grant execute on function public.append_ayah_review_events_v1(jsonb) to authenticated'));
  });

  test('pull RPC uses a stable server cursor and allows linked guardians only', () {
    expect(migration, contains('pull_ayah_review_events_since'));
    expect(migration, contains('p_cursor_sequence bigint default 0'));
    expect(migration, contains('order by server_sequence asc, event_id asc'));
    expect(migration, contains('public.parent_child_links'));
    expect(migration, contains("pcl.status = 'active'"));
  });

  test('deployment verifier checks the ledger table and RPC privileges', () {
    final verifier = _normalized(
      File('scripts/verify_supabase_contract.ps1').readAsStringSync(),
    );
    expect(verifier, contains('ayah_review_events'));
    expect(verifier, contains('append_ayah_review_events_v1'));
    expect(verifier, contains('pull_ayah_review_events_since'));
    expect(verifier, contains('review events direct dml revoked'));
  });
}

String _normalized(String source) =>
    source.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
