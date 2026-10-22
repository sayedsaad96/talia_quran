import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Static contract checks complement disposable-database tests; they cannot
// establish SQL execution, row isolation or concurrent quota correctness.
void main() {
  final migrations = Directory('supabase/migrations')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.contains('_roadmap_phase2_'))
      .map((file) => file.readAsStringSync())
      .join('\n');
  final sql = migrations
      .replaceAll(RegExp(r'--[^\r\n]*'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();
  const signatures = {
    'compare_and_swap_child_policy_v2':
        'uuid,bigint,boolean,integer,boolean,integer,integer,integer,integer',
    'create_parent_reward_v2': 'uuid,text,integer',
    'unlock_parent_reward_by_milestone': 'bigint',
    'send_kids_encouragement': 'uuid,text,text,uuid',
    'mark_kids_encouragements_seen': 'bigint[]',
  };

  test(
    'v2 additions preserve old RPC definitions and authenticate new ones',
    () {
      for (final name in signatures.keys) {
        final start = sql.indexOf('create or replace function public.$name(');
        expect(start, isNonNegative, reason: name);
        final end = sql.indexOf(r'$$;', start);
        final body = sql.substring(start, end);
        expect(body, contains("security definer set search_path = ''"));
        expect(body, contains('auth.uid()'));
        expect(body, contains("raise exception 'not authenticated'"));
        expect(body, contains("l.status = 'active'"));
        expect(body, contains('for update'));
      }
      // Migrations must be re-runnable.
      expect(sql, isNot(contains('create function')));
      expect(sql, isNot(contains('create table public.')));
      expect(sql, isNot(contains('create index kids_')));
      expect(sql, isNot(contains('add column next_surah_id')));
      expect(sql, isNot(contains('add column milestone_surah_id')));
      expect(
        sql,
        contains('drop policy if exists kids_encouragements_read'),
      );
      expect(sql, isNot(contains('user_metadata')));
    },
  );

  test(
    'new RPC signature/ACL and table assertions are in runtime verifier',
    () {
      final verifier = File(
        'scripts/verify_roadmap_phase2_contract.ps1',
      ).readAsStringSync().toLowerCase().replaceAll(RegExp(r'\s+'), '');
      for (final entry in signatures.entries) {
        expect(verifier, contains('public.${entry.key}(${entry.value})'));
      }
      expect(verifier, contains('pg_get_function_arguments'));
      expect(verifier, contains('pg_get_function_result'));
      expect(verifier, contains('aclexplode'));
      expect(verifier, contains('kids_encouragement_quotas'));
      expect(verifier, contains('relrowsecurity'));
      expect(
        File('scripts/verify_supabase_contract.ps1').readAsStringSync(),
        contains('verify_roadmap_phase2_contract.ps1'),
      );
    },
  );

  test('quota and retry state share transaction and server UTC clock', () {
    expect(sql, contains("v_now := pg_catalog.clock_timestamp()"));
    expect(sql, contains("(v_now at time zone 'utc')::date"));
    expect(sql, contains('on conflict (child_user_id, utc_day) do update'));
    expect(sql, contains('where q.used < 10'));
    expect(sql, contains('unique (parent_user_id, client_request_id)'));
    expect(
      sql.indexOf('if found then'),
      lessThan(
        sql.indexOf('insert into public.kids_encouragement_quotas as q'),
      ),
    );
    expect(sql, contains('pg_catalog.cardinality(p_ids) > 100'));
    expect(sql, contains('for select to authenticated'));
    expect(sql, isNot(contains('for insert to authenticated')));
  });
}
