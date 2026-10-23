import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account deletion migration validates the JWT session owner', () {
    final migration = File(
      'supabase/migrations/20261001235630_harden_delete_current_user_session.sql',
    ).readAsStringSync();

    expect(migration, contains("auth.jwt() ->> 'session_id'"));
    expect(migration, contains('FROM auth.sessions AS session'));
    expect(migration, contains('session.user_id = v_uid'));
    expect(migration, contains('DELETE FROM auth.users'));
    expect(migration, contains('REVOKE ALL ON FUNCTION'));
    expect(migration, contains('GRANT EXECUTE ON FUNCTION'));
  });

  test('the latest deletion RPC preserves session checks before group cleanup', () {
    // Migrations apply in lexical order. Verify the final behavior rather than
    // pinning an older filename when a reviewed extension is added.
    final definitions =
        Directory('supabase/migrations')
            .listSync()
            .whereType<File>()
            .where(
              (file) => file.readAsStringSync().contains(
                'FUNCTION public.delete_current_user()',
              ),
            )
            .map((file) => file.uri.pathSegments.last)
            .toList()
          ..sort();

    final source = File('supabase/migrations/${definitions.last}')
        .readAsStringSync();
    final start = source.indexOf(
      'CREATE OR REPLACE FUNCTION public.delete_current_user()',
    );
    expect(start, isNonNegative);
    final definition = source.substring(start);
    expect(definition, contains("auth.jwt() ->> 'session_id'"));
    expect(definition, contains('FROM auth.sessions AS session'));
    expect(definition, contains('session.user_id = v_uid'));
    expect(definition, contains("SECURITY DEFINER SET search_path = ''"));
    final cleanup = definition.indexOf('private.group_khatmah_cleanup_user(v_uid)');
    expect(cleanup, greaterThan(definition.indexOf('session.user_id = v_uid')));
    expect(cleanup, lessThan(definition.indexOf('DELETE FROM auth.users')));
  });
}
