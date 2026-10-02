import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/sync/background_sync_scheduler.dart';

void main() {
  for (final task in ['talia.cloud_sync', 'legacy-cloud-task']) {
    test('retired $task needs no account services or platform stores', () async {
      // No Flutter binding, DI, Supabase session or Isar database is installed.
      expect(await dispatchBackgroundTask(task, {'owner_id': 'deleted-owner'}), isTrue);
    });
  }
}
