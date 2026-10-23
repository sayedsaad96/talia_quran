import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Packaging checks only. Database behavior belongs to the executable SQL tests.
void main() {
  const signatures = [
    'public.create_group_khatmah(text,text,uuid)',
    'public.join_group_khatmah(text,text,uuid)',
    'public.claim_group_part(uuid,smallint,bigint,uuid,uuid)',
    'public.complete_group_part(uuid,smallint,bigint,uuid,uuid)',
    'public.release_group_part(uuid,smallint,bigint,uuid,uuid)',
    'public.leave_group_khatmah(uuid,uuid,uuid)',
  ];

  test(
    'catalog verifier covers every approved RPC and authorization boundary',
    () {
      final verifier = File(
        'scripts/verify_group_khatmah_contract.ps1',
      ).readAsStringSync();
      for (final signature in signatures) {
        expect(verifier, contains(signature), reason: signature);
      }
      for (final boundary in [
        'prosecdef',
        'search_path=',
        'aclexplode',
        'relrowsecurity',
        'has_table_privilege',
        'has_function_privilege',
        'confdeltype',
        'group_khatmah_member',
        'group_khatmah_part',
      ]) {
        expect(verifier, contains(boundary), reason: boundary);
      }
      expect(verifier, isNot(contains('SUPABASE_DB_URL')));
      expect(verifier, isNot(contains('Invoke-Expression')));
    },
  );

  test(
    'aggregate verifier includes group checks without deploying migrations',
    () {
      final aggregate = File(
        'scripts/verify_supabase_contract.ps1',
      ).readAsStringSync();
      expect(aggregate, contains("'verify_group_khatmah_contract.ps1'"));
    },
  );
}
