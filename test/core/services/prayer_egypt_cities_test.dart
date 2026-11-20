import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PrayerTimesService service;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
    });
    service = PrayerTimesService(await SharedPreferences.getInstance());
  });

  test('Egypt offers a city for each of its 27 governorate capitals', () async {
    final egypt = (await service.countries()).singleWhere((c) => c.id == 'eg');
    expect(
      egypt.cities.map((c) => c.id),
      containsAll([
        'cairo',
        'alexandria',
        'giza',
        'banha',
        'tanta',
        'mansoura',
        'zagazig',
        'damanhur',
        'kafr_el_sheikh',
        'shebin_el_kom',
        'damietta',
        'port_said',
        'ismailia',
        'suez',
        'fayoum',
        'beni_suef',
        'minya',
        'asyut',
        'sohag',
        'qena',
        'luxor',
        'aswan',
        'hurghada',
        'marsa_matruh',
        'arish',
        'el_tor',
        'kharga',
      ]),
    );
  });

  test(
    'every Egyptian location can be selected and calculates daily prayers',
    () async {
      final egypt = (await service.countries()).singleWhere(
        (c) => c.id == 'eg',
      );
      for (final city in egypt.cities) {
        await service.setCityId(city.id);
        expect((await service.selectedCity())?.id, city.id);
        expect(service.isReadyForNotificationScheduling, isTrue);
        expect(service.calculationMethod, 'egyptian');
        expect(city.timeZone, 'Africa/Cairo');
        expect(city.latitude, inInclusiveRange(22, 32));
        expect(city.longitude, inInclusiveRange(24, 37));
        final prayers = await service.timesForDate(DateTime(2026, 7, 15));
        expect(prayers, hasLength(5), reason: city.id);
        for (var i = 0; i < prayers.length; i++) {
          expect(prayers[i].time.timeZoneOffset, const Duration(hours: 3));
          if (i > 0) {
            expect(prayers[i].time.isAfter(prayers[i - 1].time), isTrue);
          }
        }
      }
    },
  );

  test(
    'Desouk has its own coordinates and survives service recreation',
    () async {
      await service.setCityId('desouk');
      final restored = PrayerTimesService(
        await SharedPreferences.getInstance(),
      );
      final city = await restored.selectedCity();
      expect(city, isNotNull);
      expect(city!.nameAr, 'دسوق');
      expect(city.latitude, closeTo(31.13259, 0.00001));
      expect(city.longitude, closeTo(30.647842, 0.00001));
      final winter = await restored.timesForDate(DateTime(2026, 1, 15));
      expect(winter.first.time.timeZoneOffset, const Duration(hours: 2));
    },
  );

  test('expanded catalog keeps unique ids and localized place names', () async {
    final cities = await service.cities();
    expect(cities.map((c) => c.id).toSet(), hasLength(cities.length));
    final egypt = cities.where((c) => c.countryId == 'eg');
    expect(
      egypt.map((c) => c.id),
      containsAll([
        'desouk',
        'fowa',
        'mahalla_el_kubra',
        'shubra_el_kheima',
        'sharm_el_sheikh',
        'mallawi',
        'edfu',
        'safaga',
      ]),
    );
    for (final city in egypt) {
      expect(RegExp(r'[\u0600-\u06ff]').hasMatch(city.nameAr), isTrue);
      expect(city.nameEn.trim(), isNotEmpty);
    }
  });
}
