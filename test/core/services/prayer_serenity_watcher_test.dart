import 'package:flutter_test/flutter_test.dart';

import 'package:talia_quran/core/services/prayer_serenity_watcher.dart';

/// Tests for [PrayerSerenityWatcher] orchestration: dedup per occurrence,
/// the enabled gate, quiet behavior outside windows, and failure containment.
void main() {
  final dhuhr = DateTime(2025, 9, 19, 12, 5);
  final asr = DateTime(2025, 9, 19, 15, 40);

  test('pauses audio and fires the moment once per occurrence', () async {
    var pauses = 0;
    var moments = 0;
    final watcher = PrayerSerenityWatcher(
      prayerTimesProvider: () async => {'dhuhr': dhuhr},
      pauseAudio: () async => pauses++,
      showSerenityMoment: () async => moments++,
      isEnabled: () async => true,
      now: () => DateTime(2025, 9, 19, 12, 6),
    );

    await watcher.tick();
    expect(pauses, equals(1));
    expect(moments, equals(1));

    // The same occurrence must not re-fire on subsequent ticks.
    await watcher.tick();
    await watcher.tick();
    expect(pauses, equals(1));
    expect(moments, equals(1));
  });

  test('fires again for the next occurrence', () async {
    var now = DateTime(2025, 9, 19, 12, 6);
    var pauses = 0;
    final watcher = PrayerSerenityWatcher(
      prayerTimesProvider: () async => {'dhuhr': dhuhr, 'asr': asr},
      pauseAudio: () async => pauses++,
      showSerenityMoment: () async {},
      isEnabled: () async => true,
      now: () => now,
    );

    await watcher.tick();
    expect(pauses, equals(1));

    now = DateTime(2025, 9, 19, 15, 41);
    await watcher.tick();
    expect(pauses, equals(2));
  });

  test('stays quiet when the mode is disabled', () async {
    var pauses = 0;
    var providerCalls = 0;
    final watcher = PrayerSerenityWatcher(
      prayerTimesProvider: () async {
        providerCalls++;
        return {'dhuhr': dhuhr};
      },
      pauseAudio: () async => pauses++,
      showSerenityMoment: () async {},
      isEnabled: () async => false,
      now: () => DateTime(2025, 9, 19, 12, 6),
    );

    await watcher.tick();
    expect(pauses, equals(0));
    expect(providerCalls, equals(0), reason: 'the gate short-circuits first');
  });

  test('stays quiet outside serenity windows', () async {
    var pauses = 0;
    final watcher = PrayerSerenityWatcher(
      prayerTimesProvider: () async => {'dhuhr': dhuhr},
      pauseAudio: () async => pauses++,
      showSerenityMoment: () async {},
      isEnabled: () async => true,
      now: () => DateTime(2025, 9, 19, 14, 0),
    );

    await watcher.tick();
    expect(pauses, equals(0));
  });

  test('stays quiet when prayer times are unavailable', () async {
    var pauses = 0;
    final watcher = PrayerSerenityWatcher(
      prayerTimesProvider: () async => null,
      pauseAudio: () async => pauses++,
      showSerenityMoment: () async {},
      isEnabled: () async => true,
      now: () => DateTime(2025, 9, 19, 12, 6),
    );

    await watcher.tick();
    expect(pauses, equals(0));
  });

  test('still fires the moment when pausing audio fails', () async {
    var moments = 0;
    final watcher = PrayerSerenityWatcher(
      prayerTimesProvider: () async => {'dhuhr': dhuhr},
      pauseAudio: () async => throw StateError('player gone'),
      showSerenityMoment: () async => moments++,
      isEnabled: () async => true,
      now: () => DateTime(2025, 9, 19, 12, 6),
    );

    await watcher.tick();
    expect(moments, equals(1), reason: 'failure containment, not propagation');
  });

  test('start schedules ticks and dispose cancels them', () async {
    var pauses = 0;
    final watcher = PrayerSerenityWatcher(
      prayerTimesProvider: () async => {'dhuhr': dhuhr},
      pauseAudio: () async => pauses++,
      showSerenityMoment: () async {},
      isEnabled: () async => true,
      now: () => DateTime(2025, 9, 19, 12, 6),
      tickInterval: const Duration(milliseconds: 10),
    );

    watcher.start();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(pauses, greaterThanOrEqualTo(1), reason: 'first occurrence fired');
    final pausesAfterFirstOccurrence = pauses;

    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(
      pauses,
      equals(pausesAfterFirstOccurrence),
      reason: 'deduped — the same occurrence never re-fires',
    );

    watcher.dispose();
  });
}
