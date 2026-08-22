import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('baseline is self-contained and does not reference an external schema', () {
    final baseline = File('supabase/migrations/0001_baseline.sql').readAsStringSync();

    expect(baseline, isNot(contains('supabase_schema.sql')));
    expect(baseline, contains('CREATE TABLE'));
    expect(baseline, contains('public.profiles'));
    expect(baseline, contains('public.streaks'));
    expect(baseline, contains('public.parent_child_links'));
  });
}
