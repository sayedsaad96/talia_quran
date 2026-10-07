import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/khatmah_reminder_sync.dart';

void main() {
  const debounce = Duration(milliseconds: 60);

  test(
    'a burst of changes triggers one refresh after the quiet period',
    () {
      // Virtual time: the debounce window cannot be overrun by a slow
      // machine, so the test is deterministic.
      fakeAsync((async) {
        final changes = StreamController<void>.broadcast();
        var refreshes = 0;
        final sync = KhatmahReminderSync(changes.stream, () async {
          refreshes++;
        }, debounce: debounce);

        changes.add(null);
        async.elapse(debounce * 2);
        expect(refreshes, 0, reason: 'nothing is heard before start()');

        sync.start();
        for (var i = 0; i < 3; i++) {
          changes.add(null);
          async.elapse(debounce ~/ 3);
        }
        expect(refreshes, 0);
        async.elapse(debounce * 2);
        expect(refreshes, 1);

        sync.dispose();
        async.flushMicrotasks();
        changes.add(null);
        async.elapse(debounce * 2);
        expect(refreshes, 1);
        changes.close();
        async.flushMicrotasks();
      });
    },
  );
}
