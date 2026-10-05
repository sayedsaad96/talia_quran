import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationName = '20261005170359_parent_reward_request_approval.sql';

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

  String functionBody(String name) {
    final start = RegExp(
      'create (or replace )?function public\\.$name\\(',
    ).firstMatch(migration);
    expect(start, isNotNull, reason: '$name must be defined');
    final next = RegExp(
      r'create (or replace )?function |revoke all ',
    ).allMatches(migration).where((m) => m.start > start!.start);
    return migration.substring(start!.start, next.first.start);
  }

  test('requested sits between unlocked and claimed', () {
    expect(
      migration,
      contains('add column if not exists requested_at timestamptz'),
    );
    expect(
      migration,
      contains(
        "check (status in ('locked', 'unlocked', 'requested', 'claimed'))",
      ),
    );
  });

  test('plpgsql gift RPCs authenticate, lock the row and need a link', () {
    for (final name in [
      'unlock_parent_reward',
      'request_parent_reward',
      'approve_parent_reward',
    ]) {
      final body = functionBody(name);
      expect(body, contains("security definer set search_path = ''"));
      expect(
        body.indexOf("raise exception 'not authenticated'"),
        lessThan(body.indexOf('from public.')),
        reason: '$name must authenticate before reading',
      );
      expect(body, contains('where r.id = p_reward_id for update'));
      expect(body, contains("pcl.status = 'active' for update"));
    }
  });

  test('only the child requests, from unlocked, idempotently', () {
    final request = functionBody('request_parent_reward');
    expect(request, contains('v_reward.child_user_id <> v_uid'));
    expect(
      request,
      contains(
        "if v_reward.status in ('requested', 'claimed') then return next "
        'v_reward; return; end if;',
      ),
    );
    expect(request, contains("v_reward.status <> 'unlocked'"));
    expect(request, contains("set status = 'requested', requested_at = now()"));
  });

  test('only the guardian approves, from requested, idempotently', () {
    final approve = functionBody('approve_parent_reward');
    expect(approve, contains('v_reward.parent_user_id <> v_uid'));
    expect(
      approve,
      contains(
        "if v_reward.status = 'claimed' then return next v_reward; "
        'return; end if;',
      ),
    );
    expect(approve, contains("v_reward.status <> 'requested'"));
    expect(approve, contains("set status = 'claimed', claimed_at = now()"));
  });

  test('unlock stays idempotent for a requested gift', () {
    expect(
      functionBody('unlock_parent_reward'),
      contains("if v_reward.status in ('unlocked', 'requested', 'claimed')"),
    );
  });

  test('legacy claim can no longer skip the guardian', () {
    final claim = functionBody('claim_parent_reward');
    expect(claim, contains("security definer set search_path = ''"));
    expect(claim, contains('from public.request_parent_reward(p_reward_id)'));
    expect(claim, isNot(contains("'claimed'")));
  });

  test('gift RPCs are granted to authenticated and revoked from anon', () {
    const signatures =
        'public.unlock_parent_reward(bigint), '
        'public.request_parent_reward(bigint), '
        'public.approve_parent_reward(bigint), '
        'public.claim_parent_reward(bigint)';
    expect(
      migration,
      contains('revoke all on function $signatures from public, anon;'),
    );
    expect(
      migration,
      contains('grant execute on function $signatures to authenticated;'),
    );
  });

  test('migration uses no dynamic SQL', () {
    expect(migration, isNot(contains('execute format')));
    expect(migration, isNot(matches(RegExp(r'(;|begin|then|loop) execute '))));
  });

  test('contract verifier covers the new RPCs and status', () {
    for (final name in ['request_parent_reward', 'approve_parent_reward']) {
      expect(
        verifier,
        contains(
          "has_function_privilege('authenticated','public.$name(bigint)'",
        ),
      );
    }
    expect(verifier, contains('gift receipt needs guardian approval'));
    expect(verifier, contains('claim_parent_reward only files a request'));
  });
}

String _normalized(String source) =>
    source.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
