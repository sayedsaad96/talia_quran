import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationName = '20261004132950_family_activity_and_parent_recovery.sql';

void main() {
  late String migration;
  late String verifier;

  setUpAll(() {
    final file = File('supabase/migrations/$_migrationName');
    expect(file.existsSync(), isTrue, reason: 'deployed migration must exist');
    migration = _normalized(
      file.readAsStringSync().replaceAll(RegExp(r'--[^\r\n]*'), ''),
    );
    verifier = _normalized(
      File('scripts/verify_supabase_contract.ps1').readAsStringSync(),
    );
  });

  String functionBody(String name) {
    final start = RegExp(
      'create (or replace )?function public\\.$name\\(',
    ).firstMatch(migration);
    expect(start, isNotNull, reason: '$name must be defined');
    final next = RegExp(
      r'create (or replace )?(function|table) ',
    ).allMatches(migration).where((m) => m.start > start!.start);
    return migration.substring(
      start!.start,
      next.isEmpty ? migration.length : next.first.start,
    );
  }

  const functions = [
    'unlock_parent_reward',
    'claim_parent_reward',
    'publish_child_family_activity',
    'request_parent_pin_recovery',
    'get_child_pin_recovery_requests',
    'approve_parent_pin_recovery',
    'consume_parent_pin_recovery',
    'get_remote_children_dashboard',
  ];

  test('every RPC is SECURITY DEFINER and authenticates first', () {
    for (final name in functions) {
      final body = functionBody(name);
      expect(body, contains("security definer set search_path = ''"));
      expect(body, contains("raise exception 'not authenticated'"));
      final firstRead = body.indexOf('from public.');
      if (firstRead != -1) {
        expect(
          body.indexOf("raise exception 'not authenticated'"),
          lessThan(firstRead),
          reason: '$name must authenticate before reading any data',
        );
      }
    }
  });

  test('reward transitions lock the row and are retry-idempotent', () {
    final unlock = functionBody('unlock_parent_reward');
    expect(unlock, contains('v_reward.parent_user_id <> v_uid'));
    expect(unlock, contains("pcl.status = 'active' for update"));
    expect(
      unlock,
      contains(
        "if v_reward.status in ('unlocked', 'claimed') then return next "
        'v_reward; return; end if;',
      ),
    );
    final claim = functionBody('claim_parent_reward');
    expect(claim, contains('v_reward.child_user_id <> v_uid'));
    expect(claim, contains("v_reward.status <> 'unlocked'"));
    expect(
      claim,
      contains(
        "if v_reward.status = 'claimed' then return next v_reward; "
        'return; end if;',
      ),
    );
  });

  test('activity snapshots are read-only to clients and revision-guarded', () {
    expect(
      migration,
      contains(
        'alter table public.family_child_activity_snapshots '
        'enable row level security',
      ),
    );
    expect(
      migration,
      contains(
        'revoke all on public.family_child_activity_snapshots '
        'from anon, authenticated',
      ),
    );
    expect(
      migration,
      contains(
        'grant select on public.family_child_activity_snapshots '
        'to authenticated',
      ),
    );
    final publish = functionBody('publish_child_family_activity');
    expect(publish, contains("p.selected_path = 'child'"));
    expect(publish, contains('octet_length(p_snapshot::text) > 131072'));
    expect(publish, contains('where excluded.revision > current.revision'));
  });

  test('PIN recovery requests are never readable by clients', () {
    expect(
      migration,
      contains(
        'alter table public.parent_pin_recovery_requests '
        'enable row level security',
      ),
    );
    expect(
      migration,
      contains(
        'revoke all on public.parent_pin_recovery_requests '
        'from public, anon, authenticated',
      ),
    );
    final policies = RegExp(
      r'create policy [^;]*;',
    ).allMatches(migration).map((m) => m.group(0)!).toList();
    expect(policies, hasLength(1));
    expect(policies.single, contains('family_activity_read'));
  });

  test('PIN recovery is bound to an active adult guardian and attempts', () {
    final approve = functionBody('approve_parent_pin_recovery');
    expect(approve, contains("pcl.status = 'active'"));
    expect(approve, contains("p.selected_path = 'adult'"));
    expect(approve, contains('v_request.attempts >= 5'));
    expect(approve, contains("extensions.digest(v_code, 'sha256')"));
    final consume = functionBody('consume_parent_pin_recovery');
    expect(consume, contains('r.child_user_id = v_uid'));
    expect(consume, contains('r.device_id = p_device_id for update'));
    expect(consume, contains('set attempts = attempts + 1'));
    expect(consume, contains('set consumed_at = now(), code_hash = null'));
  });

  test('family dashboard exposes tracked_count and activity_snapshot', () {
    final dashboard = functionBody('get_remote_children_dashboard');
    expect(dashboard, contains("'tracked_count', count(*)"));
    expect(
      dashboard,
      contains("'review_count', coalesce(sum(rr.total_reviews), 0)"),
    );
    expect(dashboard, contains("'activity_snapshot'"));
    expect(dashboard, contains("rr.audience = 'kids'"));
  });

  test('every RPC is granted to authenticated and revoked from anon', () {
    for (final signature in [
      'public.publish_child_family_activity(uuid,bigint,jsonb)',
      'public.request_parent_pin_recovery(uuid)',
      'public.get_child_pin_recovery_requests(uuid)',
      'public.approve_parent_pin_recovery(uuid)',
      'public.consume_parent_pin_recovery(uuid,uuid,text)',
    ]) {
      expect(migration, contains('revoke all on function $signature'));
      expect(migration, contains('$signature to authenticated;'));
    }
  });

  test('migration uses no dynamic SQL', () {
    expect(migration, isNot(contains('execute format')));
    expect(migration, isNot(matches(RegExp(r'(;|begin|then|loop) execute '))));
  });

  test('contract verifier covers the new tables and RPCs', () {
    for (final table in [
      'family_child_activity_snapshots',
      'parent_pin_recovery_requests',
    ]) {
      expect(verifier, contains("'$table'"));
    }
    for (final signature in [
      'public.publish_child_family_activity(uuid,bigint,jsonb)',
      'public.request_parent_pin_recovery(uuid)',
      'public.get_child_pin_recovery_requests(uuid)',
      'public.approve_parent_pin_recovery(uuid)',
      'public.consume_parent_pin_recovery(uuid,uuid,text)',
    ]) {
      expect(
        verifier,
        contains("has_function_privilege('authenticated','$signature'"),
      );
    }
    expect(verifier, contains('tracked_count'));
  });
}

String _normalized(String source) =>
    source.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
