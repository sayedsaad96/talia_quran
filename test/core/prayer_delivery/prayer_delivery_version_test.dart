import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/prayer_delivery/prayer_delivery_version.dart';

void main() {
  group('PrayerDeliveryVersion', () {
    test('fresh installs default to legacy (1)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      expect(PrayerDeliveryVersion.read(prefs),
          PrayerDeliveryVersion.legacy);
    });

    test('save persists the native V2 marker and read round-trips',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      await PrayerDeliveryVersion.save(
        prefs,
        PrayerDeliveryVersion.nativeAndroidV2,
      );

      expect(PrayerDeliveryVersion.read(prefs),
          PrayerDeliveryVersion.nativeAndroidV2);
    });

    test('rollback to legacy is a plain integer write', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrayerDeliveryVersion.prefsKey: PrayerDeliveryVersion.nativeAndroidV2,
      });
      final prefs = await SharedPreferences.getInstance();

      await PrayerDeliveryVersion.save(prefs, PrayerDeliveryVersion.legacy);

      expect(PrayerDeliveryVersion.read(prefs), PrayerDeliveryVersion.legacy);
    });

    test('uses the documented preference key', () {
      expect(PrayerDeliveryVersion.prefsKey, 'prayer_delivery_version');
    });
  });
}