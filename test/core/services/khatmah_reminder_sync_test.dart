import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/khatmah_reminder_sync.dart';

void main() {
  const debounce = Duration(milliseconds: 60);

  test(
    'a burst of changes triggers one refresh after the quiet period',
    () async {
      final changes = StreamController<void>.broadcast();
      var refreshes = 0;
      final sync = KhatmahReminderSync(changes.stream, () async {
        refreshes++;
      }, debounce: debounce);

      changes.add(null);
      await Future<void>.delayed(debounce * 2);
      expect(refreshes, 0, reason: 'nothing is heard before start()');

      sync.start();
      for (var i = 0; i < 3; i++) {
        changes.add(null);
        await Future<void>.delayed(debounce ~/ 3);
      }
      expect(refreshes, 0);
      await Future<void>.delayed(debounce * 2);
      expect(refreshes, 1);

      await sync.dispose();
      changes.add(null);
      await Future<void>.delayed(debounce * 2);
      expect(refreshes, 1);
      await changes.close();
    },
  );
}
