import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationName = '20261002140000_kids_home_missions_and_policies.sql';

void main() {
  late String migration;
  late String verifier;

  setUpAll(() {
    final file = File('supabase/migrations/$_migrationName');
    expect(file.existsSync(), isTrue, reason: 'new migration must exist');
    migration = _normalized(
      file.readAsStringSync().replaceAll(RegExp(r'--[^\r\n]*'), ''),
    );
    verifier = _normalized(
      File('scripts/verify_supabase_contract.ps1').readAsStringSync(),
    );
  });

  String functionBody(String name) {
    final start = migration.indexOf('create or replace function public.$name(');
    expect(start, isNonNegative, reason: '$name must be defined');
    final end = migration.indexOf('create or replace function', start + 10);
    return migration.substring(start, end == -1 ? migration.length : end);
  }

  const functions = [
    'create_kids_home_mission',
    'report_kids_home_mission',
    'acknowledge_kids_home_mission',
    'compare_and_swap_child_policy',
  ];

  test('every RPC is SECURITY DEFINER with an empty search path', () {
    expect(
      RegExp(
        "security definer set search_path = ''",
      ).allMatches(migration).length,
      functions.length,
    );
    for (final name in functions) {
      expect(
        functionBody(name),
        contains("security definer set search_path = ''"),
      );
      expect(functionBody(name), contains('auth.uid()'));
      expect(
        functionBody(name),
        contains("raise exception 'not authenticated'"),
      );
      final body = functionBody(name);
      expect(
        body.indexOf("raise exception 'not authenticated'"),
        lessThan(body.indexOf('from public.')),
        reason: '$name must authenticate before reading any data',
      );
    }
    for (final name in [
      'report_kids_home_mission',
      'acknowledge_kids_home_mission',
    ]) {
      expect(functionBody(name), contains('for update'));
    }
  });

  test('direct DML is revoked and only SELECT policies exist', () {
    for (final table in ['kids_home_missions', 'kids_child_policies']) {
      expect(
        migration,
        contains(
          'revoke insert, update, delete on public.$table from authenticated',
        ),
      );
      expect(migration, contains('revoke all on public.$table from anon'));
      expect(
        migration,
        contains('alter table public.$table enable row level security'),
      );
      expect(
        migration,
        contains('create policy ${table}_read on public.$table for select'),
      );
    }
    final policies = RegExp(
      r'create policy [^;]*;',
    ).allMatches(migration).map((m) => m.group(0)!).toList();
    expect(policies, hasLength(2));
    for (final policy in policies) {
      expect(policy, contains(' for select '));
    }
    // P3-R14: the child branch requires an active link to the mission's
    // guardian, so a revoked guardian's missions are not returned.
    final missionsRead = policies.firstWhere(
      (p) => p.contains('kids_home_missions_read'),
    );
    expect(
      missionsRead,
      contains(
        'child_user_id = (select auth.uid()) and exists ( select 1 from '
        'public.parent_child_links pcl where pcl.parent_user_id = '
        'kids_home_missions.parent_user_id and pcl.child_user_id = '
        "(select auth.uid()) and pcl.status = 'active' )",
      ),
    );
  });

  test('RPCs are granted to authenticated only', () {
    for (final signature in [
      'public.create_kids_home_mission(uuid, text)',
      'public.report_kids_home_mission(bigint)',
      'public.acknowledge_kids_home_mission(bigint)',
      'public.compare_and_swap_child_policy(uuid, bigint, boolean, integer, '
          'boolean, integer)',
    ]) {
      expect(
        migration,
        contains(
          'revoke all on function $signature '
          'from public, anon, authenticated, service_role;',
        ),
      );
      expect(
        migration,
        contains('grant execute on function $signature to authenticated;'),
      );
    }
  });

  test('parent-side RPCs require an active link', () {
    const activeLink = "and pcl.status = 'active'";
    expect(functionBody('create_kids_home_mission'), contains(activeLink));
    expect(functionBody('acknowledge_kids_home_mission'), contains(activeLink));
    expect(functionBody('report_kids_home_mission'), contains(activeLink));
    expect(functionBody('compare_and_swap_child_policy'), contains(activeLink));
    expect(
      functionBody('create_kids_home_mission'),
      contains('pcl.parent_user_id = v_caller'),
    );
    expect(functionBody('create_kids_home_mission'), contains('for update'));
    expect(
      functionBody('create_kids_home_mission'),
      contains("raise exception 'invalid mission title'"),
    );
  });

  test('acknowledge needs reported; report needs the child', () {
    final ack = functionBody('acknowledge_kids_home_mission');
    expect(ack, contains("v_mission.status <> 'reported'"));
    expect(ack, contains("raise exception 'invalid mission transition'"));
    // P3-R15: any guardian actively linked to the child, not only the
    // creator; everyone else gets 'Mission not found'.
    expect(ack, isNot(contains('v_mission.parent_user_id <> v_caller')));
    expect(
      ack,
      contains(
        'where pcl.parent_user_id = v_caller and pcl.child_user_id = '
        "v_mission.child_user_id and pcl.status = 'active' for update; "
        'if not found then',
      ),
    );
    expect(ack, contains("raise exception 'mission not found'"));
    final report = functionBody('report_kids_home_mission');
    expect(report, contains('v_mission.child_user_id <> v_caller'));
    expect(report, contains("v_mission.status = 'assigned'"));
    expect(report, contains("set status = 'reported', reported_at = now()"));
  });

  test('acknowledging an acknowledged mission is an idempotent no-op', () {
    final ack = functionBody('acknowledge_kids_home_mission');
    expect(
      ack,
      contains(
        "if v_mission.status = 'acknowledged' then return next "
        'v_mission; return; end if;',
      ),
    );
    expect(
      ack.indexOf("v_mission.status = 'acknowledged'"),
      lessThan(ack.indexOf("v_mission.status <> 'reported'")),
    );
  });

  test('policy CAS compares and bumps the version, validating ranges', () {
    final cas = functionBody('compare_and_swap_child_policy');
    expect(cas, contains('version = p_expected_version'));
    expect(cas, contains('version = p.version + 1'));
    expect(cas, contains('updated_by = v_caller'));
    expect(cas, contains('p_expected_version = 0'));
    expect(cas, contains("'applied'"));
    expect(cas, contains('p_max_daily_suggestions not between 1 and 3'));
    expect(cas, contains('p_session_goal_minutes not between 1 and 60'));
    expect(
      cas,
      contains(
        'if v_caller = p_child_user_id then perform 1 from '
        'public.parent_child_links pcl where pcl.child_user_id = v_caller '
        "and pcl.status = 'active' for update; if not found then raise "
        "exception 'child link is not active'; end if; else",
      ),
    );
    expect(cas, contains('on conflict (child_user_id) do nothing'));
  });

  test('migration uses no dynamic SQL', () {
    expect(migration, isNot(contains('execute format')));
    expect(migration, isNot(contains('\nexecute ')));
  });

  test('contract verifier covers both tables and all four RPCs', () {
    expect(verifier, contains("'kids_home_missions'"));
    expect(verifier, contains("'kids_child_policies'"));
    for (final signature in [
      'public.create_kids_home_mission(uuid,text)',
      'public.report_kids_home_mission(bigint)',
      'public.acknowledge_kids_home_mission(bigint)',
      'public.compare_and_swap_child_policy(uuid,bigint,boolean,integer,'
          'boolean,integer)',
    ]) {
      expect(verifier, contains(signature));
      expect(
        verifier,
        contains("has_function_privilege('authenticated','$signature'"),
      );
    }
  });
}

String _normalized(String source) =>
    source.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
