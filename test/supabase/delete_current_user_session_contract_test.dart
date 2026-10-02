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

  test('the hardened deletion RPC is the last definition applied', () {
    // Migrations apply in lexical order; a later redefinition would silently
    // drop the session check.
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

    expect(
      definitions.last,
      '20261001235630_harden_delete_current_user_session.sql',
    );
  });
}
