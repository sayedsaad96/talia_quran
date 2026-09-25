import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/prayer_sound.dart';

void main() {
  test('system mode keeps the legacy channel and default sounds', () {
    final resolved = resolvePrayerSound(athanEnabled: false, prayerKey: 'fajr');

    expect(resolved.mode, PrayerSoundMode.system);
    expect(resolved.androidChannelId, 'talia_prayer_times');
    expect(resolved.androidSoundName, isNull);
    expect(resolved.iOSSoundName, isNull);
  });

  test('athan mode uses the bundled package clip on a dedicated channel', () {
    final resolved = resolvePrayerSound(athanEnabled: true, prayerKey: 'dhuhr');

    expect(resolved.mode, PrayerSoundMode.athan);
    // New channel id: Android channels are immutable once created, so the
    // athan clip must not reuse the legacy channel id.
    expect(resolved.androidChannelId, 'talia_prayer_times_athan');
    expect(resolved.androidSoundName, 'adhan');
    expect(resolved.iOSSoundName, 'adhan.caf');
  });

  test('fajr uses the bundled clip until a fajr-specific asset exists', () {
    final fajr = resolvePrayerSound(athanEnabled: true, prayerKey: 'fajr');
    final dhuhr = resolvePrayerSound(athanEnabled: true, prayerKey: 'dhuhr');

    // The app bundles a single `adhan` clip; the resolver keeps the
    // per-prayer seam so a future `adhan_fajr` asset plugs in without
    // touching the scheduler.
    expect(fajr.androidSoundName, dhuhr.androidSoundName);
    expect(fajr.iOSSoundName, dhuhr.iOSSoundName);
  });
}
