import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;
  late String verifier;
  late String parentAccessService;

  setUpAll(() {
    migration = _normalized(
      File(
        'supabase/migrations/0012_guardian_unlink_and_prune_privilege.sql',
      ).readAsStringSync(),
    );
    verifier = _normalized(
      File('scripts/verify_supabase_contract.ps1').readAsStringSync(),
    );
    parentAccessService = _normalized(
      File(
        'lib/features/memorization_plus/data/repositories/collaborators/'
        'memorization_parent_access_service.dart',
      ).readAsStringSync(),
    );
  });

  test('guardian revocation migration pins an empty search path', () {
    expect(
      migration,
      contains("security definer set search_path = ''"),
      reason:
          'A SECURITY DEFINER function must not resolve objects through a '
          'caller-influenced schema.',
    );
  });

  test('guardian and prune functions use explicit least-privilege grants', () {
    expect(
      migration,
      contains(
        'revoke all on function public.revoke_guardian_link(uuid) '
        'from public, anon, authenticated, service_role;',
      ),
    );
    expect(
      migration,
      contains(
        'grant execute on function public.revoke_guardian_link(uuid) '
        'to authenticated;',
      ),
    );
    expect(
      migration,
      contains(
        'revoke all on function public.prune_audit_logs() '
        'from public, anon, authenticated, service_role;',
      ),
    );
    expect(
      migration,
      contains(
        'grant execute on function public.prune_audit_logs() '
        'to service_role;',
      ),
    );
  });

  test(
    'contract verifier checks the exact guardian RPC signature and grants',
    () {
      expect(verifier, contains('p_counterpart_user_id uuid'));
      expect(verifier, contains('guardian rpc denied to public'));
      expect(
        verifier,
        contains(
          "not has_function_privilege('anon',"
          "'public.revoke_guardian_link(uuid)','execute')",
        ),
      );
      expect(
        verifier,
        contains(
          "has_function_privilege('authenticated',"
          "'public.revoke_guardian_link(uuid)','execute')",
        ),
      );
      expect(
        verifier,
        contains(
          "not has_function_privilege('service_role',"
          "'public.revoke_guardian_link(uuid)','execute')",
        ),
      );
    },
  );

  test('contract verifier restricts pruning to service_role', () {
    for (final deniedRole in ['public', 'anon', 'authenticated']) {
      expect(verifier, contains('prune_audit_logs denied to $deniedRole'));
    }
    expect(
      verifier,
      contains(
        "has_function_privilege('service_role',"
        "'public.prune_audit_logs()','execute')",
      ),
    );
  });

  test('Dart client keeps the exact guardian revocation RPC boundary', () {
    expect(
      parentAccessService,
      contains(
        "await client.rpc( 'revoke_guardian_link', params: "
        "{'p_counterpart_user_id': counterpartuserid}, );",
      ),
    );
  });
}

String _normalized(String source) =>
    source.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
