import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'checkpoint migration separates access and retains mutation receipts',
    () {
      final sql = File(
        'supabase/migrations/20261031211819_reading_checkpoints.sql',
      ).readAsStringSync().toLowerCase();
      expect(sql, contains('pg_advisory_xact_lock'));
      expect(sql, contains('p_expected_owner is distinct from v_owner'));
      expect(sql, contains('primary key (user_id, mutation_id)'));
      expect(sql, contains('page_number between 1 and 604'));
      expect(sql, contains('revoke all on public.quran_reading_checkpoints'));
      expect(sql, contains("'status', 'conflict'"));
      expect(sql, isNot(contains('upsert_reading_progress')));
    },
  );
}
