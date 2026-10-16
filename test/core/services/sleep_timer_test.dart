import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/sleep_timer.dart';

void main() {
  test('fades in the last 10 s, stops, restores volume', () {
    fakeAsync((async) {
      final origin = DateTime(2026);
      final volumes = <double>[];
      var stops = 0;
      final t = SleepTimer(
        setVolume: volumes.add,
        stop: () async {
          stops++;
          volumes.add(-1); // ordering marker
        },
        clock: () => origin.add(async.elapsed),
      );
      t.start(const Duration(seconds: 30));
      expect(t.isActive, isTrue);
      expect(t.remaining, const Duration(seconds: 30));

      async.elapse(const Duration(seconds: 19));
      expect(volumes, isEmpty);
      expect(t.remaining, const Duration(seconds: 11));

      async.elapse(const Duration(seconds: 10));
      final fading = volumes.where((v) => v >= 0).toList();
      expect(fading.where((v) => v < 1).length, greaterThanOrEqualTo(5));
      for (var i = 1; i < fading.length; i++) {
        expect(fading[i], lessThanOrEqualTo(fading[i - 1]));
      }
      expect(stops, 0);

      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(stops, 1);
      expect(volumes.last, 1.0);
      expect(volumes[volumes.length - 2], -1);
      expect(t.isActive, isFalse);
      expect(t.remaining, isNull);
    });
  });

  test('cancel restores volume and stops timers', () {
    fakeAsync((async) {
      final origin = DateTime(2026);
      final volumes = <double>[];
      var stops = 0;
      final t = SleepTimer(
        setVolume: volumes.add,
        stop: () async => stops++,
        clock: () => origin.add(async.elapsed),
      );
      t.start(const Duration(seconds: 20));
      async.elapse(const Duration(seconds: 15));
      t.cancel();
      expect(volumes.last, 1.0);
      expect(t.isActive, isFalse);
      final n = volumes.length;
      async.elapse(const Duration(minutes: 1));
      expect(volumes.length, n);
      expect(stops, 0);
    });
  });
}
