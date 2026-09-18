import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('London summer prayers use British Summer Time', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
      PrayerTimesService.cityIdKey: 'london',
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(
      prefs,
      now: () => DateTime.utc(2026, 7, 15, 12),
    );

    final snapshot = (await service.current(isArabic: false))!;

    expect(snapshot.fajr!.timeZoneOffset, const Duration(hours: 1));
    expect(snapshot.dhuhr!.hour, 13);
    expect(snapshot.fajr!.day, 15);
  });

  test('London uses the city date near UTC midnight', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
      PrayerTimesService.cityIdKey: 'london',
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(
      prefs,
      now: () => DateTime.utc(2026, 7, 15, 23, 30),
    );

    final snapshot = (await service.current(isArabic: false))!;

    expect(snapshot.fajr!.day, 16);
    expect(snapshot.nextTime, snapshot.fajr);
  });

  test('London tomorrow fajr is recalculated across DST change', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
      PrayerTimesService.cityIdKey: 'london',
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(
      prefs,
      now: () => DateTime.utc(2026, 3, 28, 23),
    );
    final snapshot = (await service.current(isArabic: false))!;
    final tomorrow = await service.timesForDate(DateTime.utc(2026, 3, 29, 12));

    expect(snapshot.nextName, 'fajr');
    expect(snapshot.nextTime.isAtSameMomentAs(tomorrow.first.time), isTrue);
    expect(snapshot.nextTime.timeZoneOffset, const Duration(hours: 1));
    expect(snapshot.nextTime.day, 29);
  });

  for (final scenario in [
    (city: 'london', month: 1, offset: 0),
    (city: 'london', month: 7, offset: 1),
    (city: 'cairo', month: 1, offset: 2),
    (city: 'cairo', month: 7, offset: 3),
    (city: 'newyork', month: 1, offset: -5),
    (city: 'newyork', month: 7, offset: -4),
  ]) {
    test(
      '${scenario.city} month ${scenario.month} uses city timezone',
      () async {
        SharedPreferences.setMockInitialValues({
          PrayerTimesService.cityIdKey: scenario.city,
        });
        final prefs = await SharedPreferences.getInstance();
        final service = PrayerTimesService(prefs);
        final times = await service.timesForDate(
          DateTime.utc(2026, scenario.month, 15, 12),
        );

        final city = (await service.cities()).singleWhere(
          (city) => city.id == scenario.city,
        );
        final reference = PrayerTimes.utc(
          Coordinates(city.latitude, city.longitude),
          DateComponents(2026, scenario.month, 15),
          CalculationMethod.muslim_world_league.getParameters(),
        );
        final expected = [
          reference.fajr,
          reference.dhuhr,
          reference.asr,
          reference.maghrib,
          reference.isha,
        ];

        expect(times, hasLength(5));
        for (var i = 0; i < times.length; i++) {
          expect(
            times[i].time.timeZoneOffset,
            Duration(hours: scenario.offset),
          );
          expect(times[i].time.toUtc(), expected[i]);
        }
      },
    );
  }

  test(
    'selecting a city applies its country default method automatically',
    () async {
      SharedPreferences.setMockInitialValues({
        PrayerTimesService.enabledKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = PrayerTimesService(prefs);

      expect(service.isMethodManual, isFalse);

      await service.setCityId('cairo');

      expect(service.calculationMethod, 'egyptian');
      expect(service.isMethodManual, isFalse);
    },
  );

  test('manual method choice survives city changes', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(prefs);

    await service.setCalculationMethod('karachi');
    await service.setCityId('london');

    expect(service.calculationMethod, 'karachi');
    expect(service.isMethodManual, isTrue);
  });

  test('returning to automatic follows the new city country', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(prefs);

    await service.setCalculationMethod('karachi');
    await service.setMethodAutomatic();
    await service.setCityId('cairo');

    expect(service.calculationMethod, 'egyptian');
    expect(service.isMethodManual, isFalse);
  });

  test('countries group cities by country', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(prefs);

    final countries = await service.countries();

    final egypt = countries.singleWhere((c) => c.id == 'eg');
    expect(egypt.nameAr, 'مصر');
    expect(egypt.cities.map((c) => c.id), containsAll(['cairo', 'alexandria']));
    for (final city in egypt.cities) {
      expect(city.timeZone, 'Africa/Cairo');
      expect(city.defaultMethod, 'egyptian');
    }
  });

  test('switching city changes computed instants for the same date', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(prefs);

    await service.setCityId('cairo');
    final cairo = await service.timesForDate(DateTime.utc(2026, 7, 15, 12));
    await service.setCityId('london');
    final london = await service.timesForDate(DateTime.utc(2026, 7, 15, 12));

    expect(cairo, hasLength(5));
    expect(london, hasLength(5));
    expect(
      london.first.time.isAtSameMomentAs(cairo.first.time),
      isFalse,
      reason: 'Cairo and London fajr must be different instants',
    );
  });

  test('disabled service returns null', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: false,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(prefs);
    final snapshot = await service.current(isArabic: true);
    expect(snapshot, isNull);
  });

  test(
    'notification scheduling requires explicit city and calculation method',
    () async {
      SharedPreferences.setMockInitialValues({
        PrayerTimesService.enabledKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = PrayerTimesService(prefs);

      expect(service.isReadyForNotificationScheduling, isFalse);

      await service.setCityId('cairo');
      await service.setCalculationMethod('egyptian');

      expect(service.isReadyForNotificationScheduling, isTrue);
    },
  );

  test('exposes all six computed times in canonical order', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(
      prefs,
      now: () => DateTime(2026, 9, 12, 12),
    );
    final snapshot = await service.current(isArabic: true);

    expect(snapshot, isNotNull);
    final times = [
      snapshot!.fajr!,
      snapshot.sunrise!,
      snapshot.dhuhr!,
      snapshot.asr!,
      snapshot.maghrib!,
      snapshot.isha!,
    ];
    expect(
      times,
      orderedEquals([...times]..sort()),
      reason: 'fajr < sunrise < dhuhr < asr < maghrib < isha',
    );
    for (final t in times) {
      expect(
        DateTime(t.year, t.month, t.day),
        DateTime(2026, 9, 12),
        reason: 'all six times on the computation date',
      );
    }
    expect(snapshot.nextName, anyOf('dhuhr', 'asr'));
    expect(snapshot.minutesUntil, greaterThan(0));
  });

  test('next-prayer wraps to tomorrow fajr after isha', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(
      prefs,
      now: () => DateTime(2026, 9, 12, 23),
    );
    final snapshot = await service.current(isArabic: true);

    expect(snapshot, isNotNull);
    expect(snapshot!.nextName, 'fajr');
    expect(snapshot.nextTime.isAfter(snapshot.isha!), isTrue);
    expect(snapshot.minutesUntil, greaterThan(0));
  });
}
