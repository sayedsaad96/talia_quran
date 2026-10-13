import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationName = '20261013120000_kids_child_reading_support.sql';
const _rpc = 'compare_and_swap_child_reading_support';
const _signature = 'public.$_rpc(uuid,bigint,text)';

/// Static contract for roadmap T7's reading-support sync. It checks the SQL
/// text only; applying it to a database is a separate, owner-run step
/// (`scripts/verify_supabase_migrations.ps1` against a disposable DB).
void main() {
  late String migration;
  late String verifier;

  setUpAll(() {
    final file = File('supabase/migrations/$_migrationName');
    expect(file.existsSync(), isTrue);
    migration = _normalized(
      file.readAsStringSync().replaceAll(RegExp(r'--[^\r\n]*'), ''),
    );
    verifier = _normalized(
      File('scripts/verify_supabase_contract.ps1').readAsStringSync(),
    );
  });

  test('is purely additive: no existing object is altered or dropped', () {
    expect(
      migration,
      isNot(contains('alter table public.kids_child_policies')),
    );
    expect(migration, isNot(contains('compare_and_swap_child_policy(')));
    expect(migration, isNot(contains('drop table')));
    expect(migration, isNot(contains('drop function')));
    expect(migration, isNot(contains('drop column')));
    expect(migration, contains('create table if not exists'));
  });

  test('the table is RLS-protected and read-only for clients', () {
    expect(
      migration,
      contains(
        'alter table public.kids_child_reading_support enable row level '
        'security',
      ),
    );
    expect(
      migration,
      contains('revoke all on public.kids_child_reading_support from anon'),
    );
    expect(
      migration,
      contains(
        'revoke all on public.kids_child_reading_support from authenticated',
      ),
    );
    expect(
      migration,
      contains(
        'grant select on public.kids_child_reading_support to '
        'authenticated',
      ),
    );
  });

  test('only the child or its actively linked guardian can read', () {
    expect(migration, contains('child_user_id = (select auth.uid())'));
    expect(migration, contains("pcl.status = 'active'"));
    expect(migration, contains('pcl.parent_user_id = (select auth.uid())'));
  });

  test('values are limited to the client enum names', () {
    expect(
      RegExp(
        "in \\('independent', 'withhelp', 'notyetreading'\\)",
      ).allMatches(migration).length,
      2,
      reason: 'the column check and the RPC validation',
    );
  });

  test('the RPC authenticates, authorizes the link, and does CAS', () {
    final start = migration.indexOf('create or replace function public.$_rpc(');
    expect(start, isNonNegative);
    final body = migration.substring(start);

    expect(body, contains("security definer set search_path = ''"));
    expect(
      body.indexOf("raise exception 'not authenticated'"),
      lessThan(body.indexOf('from public.')),
    );
    expect(body, contains("raise exception 'child link is not active'"));
    expect(
      body,
      contains("raise exception 'no active guardian link for this child'"),
    );
    expect(body, contains('for update'));
    expect(body, contains("raise exception 'invalid expected version'"));
    expect(body, contains('p_expected_version = 0'));
    expect(body, contains('on conflict (child_user_id) do nothing'));
    expect(body, contains('s.version = p_expected_version'));
    expect(body, contains('version = s.version + 1'));
    expect(body, contains("'applied'"));
    expect(body, contains("'support'"));
  });

  test('execute is granted to authenticated only', () {
    expect(
      migration,
      contains(
        'revoke all on function public.$_rpc(uuid, bigint, text) from '
        'public, anon, authenticated, service_role',
      ),
    );
    expect(
      migration,
      contains(
        'grant execute on function public.$_rpc(uuid, bigint, text) to '
        'authenticated',
      ),
    );
  });

  test('migration uses no dynamic SQL', () {
    expect(migration, isNot(contains('execute format')));
    expect(migration, isNot(contains('\nexecute ')));
  });

  test('the contract verifier covers the table and the RPC', () {
    expect(verifier, contains("'kids_child_reading_support'"));
    expect(verifier, contains(_signature));
    expect(
      verifier,
      contains("has_function_privilege('authenticated','$_signature'"),
    );
    expect(
      verifier,
      contains("not has_function_privilege('anon','$_signature'"),
    );
  });
}

String _normalized(String source) =>
    source.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
