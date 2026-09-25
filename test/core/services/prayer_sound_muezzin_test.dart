import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/prayer_sound.dart';

void main() {
  group('MuezzinCatalog', () {
    test('contains the default clip plus five muezzin recordings', () {
      expect(MuezzinCatalog.all.length, 6);
      expect(MuezzinCatalog.byId('default'), isNotNull);
      expect(
        MuezzinCatalog.all.map((m) => m.id),
        containsAll(<String>[
          'makkah',
          'abdulbasit',
          'qatami',
          'suraihi',
          'afasy_fajr',
        ]),
      );
    });

    test('isSupported rejects unknown ids', () {
      expect(MuezzinCatalog.isSupported('default'), isTrue);
      expect(MuezzinCatalog.isSupported('makkah'), isTrue);
      expect(MuezzinCatalog.isSupported('not_a_muezzin'), isFalse);
    });
  });

  group('soundProfileForPrayer', () {
    test('non-fajr prayers carry the general muezzin id', () {
      expect(
        soundProfileForPrayer(
          prayerKey: 'dhuhr',
          muezzinId: 'makkah',
          fajrMuezzinId: 'qatami',
        ),
        'makkah',
      );
    });

    test('fajr uses the general muezzin when no override is set', () {
      expect(
        soundProfileForPrayer(
          prayerKey: 'fajr',
          muezzinId: 'makkah',
          fajrMuezzinId: '',
        ),
        'makkah',
      );
      expect(
        soundProfileForPrayer(
          prayerKey: 'fajr',
          muezzinId: 'makkah',
          fajrMuezzinId: 'makkah',
        ),
        'makkah',
      );
    });

    test('fajr override is encoded with the fajr: prefix', () {
      expect(
        soundProfileForPrayer(
          prayerKey: 'fajr',
          muezzinId: 'makkah',
          fajrMuezzinId: 'afasy_fajr',
        ),
        'fajr:afasy_fajr',
      );
    });

    test('unknown ids degrade to the default profile', () {
      expect(
        soundProfileForPrayer(
          prayerKey: 'isha',
          muezzinId: 'not_a_muezzin',
          fajrMuezzinId: '',
        ),
        'default',
      );
    });
  });

  group('resolvePrayerSound', () {
    test('athan disabled keeps the legacy system channel', () {
      final resolved = resolvePrayerSound(
        athanEnabled: false,
        prayerKey: 'fajr',
        soundProfile: 'makkah',
      );
      expect(resolved.mode, PrayerSoundMode.system);
      expect(resolved.androidChannelId, 'talia_prayer_times');
      expect(resolved.androidSoundName, isNull);
      expect(resolved.iOSSoundName, isNull);
    });

    test('default profile keeps the historical channel and clip', () {
      final resolved = resolvePrayerSound(
        athanEnabled: true,
        prayerKey: 'dhuhr',
        soundProfile: 'default',
      );
      expect(resolved.androidChannelId, 'talia_prayer_times_athan');
      expect(resolved.androidSoundName, 'adhan');
      expect(resolved.iOSSoundName, 'adhan.caf');
    });

    test('selected muezzin maps to its clip and dedicated channel', () {
      final resolved = resolvePrayerSound(
        athanEnabled: true,
        prayerKey: 'maghrib',
        soundProfile: 'makkah',
      );
      expect(resolved.androidChannelId, 'talia_prayer_times_athan_makkah');
      expect(resolved.androidSoundName, 'adhan_makkah');
      expect(resolved.iOSSoundName, 'adhan_makkah.caf');
    });

    test('fajr override applies its clip to fajr only', () {
      final fajr = resolvePrayerSound(
        athanEnabled: true,
        prayerKey: 'fajr',
        soundProfile: 'fajr:afasy_fajr',
      );
      expect(fajr.androidSoundName, 'adhan_afasy_fajr');

      final isha = resolvePrayerSound(
        athanEnabled: true,
        prayerKey: 'isha',
        soundProfile: 'fajr:afasy_fajr',
      );
      expect(isha.androidSoundName, 'adhan');
    });

    test('unknown profile degrades to the default clip', () {
      final resolved = resolvePrayerSound(
        athanEnabled: true,
        prayerKey: 'asr',
        soundProfile: 'not_a_muezzin',
      );
      expect(resolved.androidSoundName, 'adhan');
      expect(resolved.iOSSoundName, 'adhan.caf');
    });
  });
}
