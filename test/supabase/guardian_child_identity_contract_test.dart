import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;
  late String verifier;
  late String kidsCloudSync;
  late String repository;

  setUpAll(() {
    migration = _normalized(
      File(
        'supabase/migrations/20260929195346_guardian_child_identity.sql',
      ).readAsStringSync(),
    );
    verifier = _normalized(
      File('scripts/verify_supabase_contract.ps1').readAsStringSync(),
    );
    kidsCloudSync = _normalized(
      File(
        'lib/features/memorization_plus/data/repositories/collaborators/'
        'memorization_kids_cloud_sync_service.dart',
      ).readAsStringSync(),
    );
    repository = _normalized(
      File(
        'lib/features/memorization_plus/data/repositories/'
        'memorization_plus_repository_impl.dart',
      ).readAsStringSync(),
    );
  });

  test('identity RPCs are SECURITY DEFINER with an empty search path', () {
    expect(
      RegExp(
        "security definer set search_path = ''",
      ).allMatches(migration).length,
      3,
      reason:
          'Identity writers and the family dashboard run with owner rights '
          'and must not resolve through the caller schema.',
    );
  });

  test('identity writers use explicit least-privilege grants', () {
    for (final signature in [
      'public.set_own_child_nickname(text)',
      'public.update_linked_child_identity(uuid, text, integer)',
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
    expect(
      migration,
      contains(
        'revoke all on function public.normalize_child_nickname(text) '
        'from public, anon, authenticated, service_role;',
      ),
    );
  });

  test('guardian edits require an active link to that exact child', () {
    expect(
      migration,
      contains(
        'where pcl.parent_user_id = v_caller '
        'and pcl.child_user_id = p_child_user_id '
        "and pcl.status = 'active'",
      ),
    );
    expect(migration, contains('for update; if not found then'));
  });

  test('contract verifier checks the new column and RPC signatures', () {
    expect(verifier, contains('profiles.child_nickname'));
    expect(verifier, contains("'p_nickname text'"));
    expect(
      verifier,
      contains("'p_child_user_id uuid, p_nickname text, p_age integer'"),
    );
    expect(verifier, contains('child identity rpcs empty search_path'));
  });

  test('Dart client keeps the exact identity RPC boundaries', () {
    expect(
      kidsCloudSync,
      contains(
        "'update_linked_child_identity', params: { "
        "'p_child_user_id': childuserid, 'p_nickname': name, 'p_age': age, },",
      ),
    );
    expect(
      repository,
      contains("'set_own_child_nickname', params: {'p_nickname': nickname},"),
    );
  });
}

String _normalized(String source) =>
    source.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
