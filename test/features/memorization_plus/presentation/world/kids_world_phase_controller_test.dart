// ignore_for_file: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_world_phase.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_phase_controller.dart';

void main() {
  final fajr = DateTime(2026, 10, 2, 4, 30);
  final maghrib = DateTime(2026, 10, 2, 17, 40);

  Future<({DateTime fajr, DateTime maghrib})?> times() async =>
      (fajr: fajr, maghrib: maghrib);

  test('starts at night, resolves to day after ensureStarted at 10:00', () {
    fakeAsync((async) {
      final now = DateTime(2026, 10, 2, 10);
      final c = KidsWorldPhaseController(prayerTimes: times, clock: () => now);
      expect(c.value, KidsWorldPhase.night);
      c.ensureStarted();
      c.ensureStarted();
      async.flushMicrotasks();
      expect(c.value, KidsWorldPhase.day);
      c.dispose();
    });
  });

  test('flips to night at maghrib without a refresh call', () {
    fakeAsync((async) {
      var now = DateTime(2026, 10, 2, 10);
      final c = KidsWorldPhaseController(prayerTimes: times, clock: () => now);
      c.ensureStarted();
      async.flushMicrotasks();
      expect(c.value, KidsWorldPhase.day);
      final target = DateTime(2026, 10, 2, 17, 40, 1);
      final delta = target.difference(now);
      now = target;
      async.elapse(delta);
      expect(c.value, KidsWorldPhase.night);
      c.dispose();
    });
  });

  test('loader throwing or returning null uses the 06:00/18:00 fallback', () {
    fakeAsync((async) {
      final now = DateTime(2026, 10, 2, 5, 30);
      final thrower = KidsWorldPhaseController(
        prayerTimes: () async => throw StateError('boom'),
        clock: () => DateTime(2026, 10, 2, 10),
      );
      thrower.ensureStarted();
      async.flushMicrotasks();
      expect(thrower.value, KidsWorldPhase.day);
      thrower.dispose();

      final nuller = KidsWorldPhaseController(
        prayerTimes: () async => null,
        clock: () => now,
      );
      nuller.ensureStarted();
      async.flushMicrotasks();
      expect(nuller.value, KidsWorldPhase.night);
      nuller.dispose();
    });
  });

  test('refresh after sleeping past fajr updates the value', () {
    fakeAsync((async) {
      var now = DateTime(2026, 10, 2, 3);
      final c = KidsWorldPhaseController(prayerTimes: times, clock: () => now);
      c.ensureStarted();
      async.flushMicrotasks();
      expect(c.value, KidsWorldPhase.night);
      // Device slept: clock jumps without timers firing.
      now = DateTime(2026, 10, 2, 9);
      c.refresh();
      async.flushMicrotasks();
      expect(c.value, KidsWorldPhase.day);
      c.dispose();
    });
  });

  test('dispose cancels the timer', () {
    fakeAsync((async) {
      final c = KidsWorldPhaseController(
        prayerTimes: times,
        clock: () => DateTime(2026, 10, 2, 10),
      );
      c.ensureStarted();
      async.flushMicrotasks();
      expect(async.pendingTimers, isNotEmpty);
      c.dispose();
      expect(async.pendingTimers, isEmpty);
    });
  });
}
