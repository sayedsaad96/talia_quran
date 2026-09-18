import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class PrayerCity {
  const PrayerCity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
    required this.countryId,
    required this.countryAr,
    required this.countryEn,
    required this.defaultMethod,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final double latitude;
  final double longitude;

  /// IANA time-zone of the city; all math and display use it, never the
  /// device zone.
  final String timeZone;
  final String countryId;
  final String countryAr;
  final String countryEn;

  /// Calculation method default for the city country. Only pinned where an
  /// official method is well established (SA/EG/PK/US/CA); MWL elsewhere.
  /// Always overridable via [PrayerTimesService.setCalculationMethod].
  final String defaultMethod;
}

class PrayerCountry {
  const PrayerCountry({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.cities,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final List<PrayerCity> cities;
}

class PrayerTimesSnapshot {
  const PrayerTimesSnapshot({
    required this.city,
    required this.nextName,
    required this.nextTime,
    required this.minutesUntil,
    this.fajr,
    this.sunrise,
    this.dhuhr,
    this.asr,
    this.maghrib,
    this.isha,
  });

  final PrayerCity city;
  final String nextName;
  final DateTime nextTime;
  final int minutesUntil;

  /// All six computed times for the selected city and calculation date.
  /// Null only for legacy call sites constructed before the prayer sheet
  /// feature; `current()` always fills them.
  final DateTime? fajr;
  final DateTime? sunrise;
  final DateTime? dhuhr;
  final DateTime? asr;
  final DateTime? maghrib;
  final DateTime? isha;
}

class PrayerTimesService {
  PrayerTimesService(this._prefs, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    if (tz.timeZoneDatabase.locations.isEmpty) {
      tz_data.initializeTimeZones();
    }
  }

  static const enabledKey = 'prayer_times_enabled';
  static const cityIdKey = 'prayer_city_id';
  static const methodKey = 'prayer_calc_method';
  static const methodManualKey = 'prayer_calc_method_manual';
  static const citiesAsset = 'assets/data/prayer_cities.json';

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  List<PrayerCity>? _cities;

  bool get isEnabled => _prefs.getBool(enabledKey) ?? false;

  String? get selectedCityId => _prefs.getString(cityIdKey);

  String get calculationMethod =>
      _prefs.getString(methodKey) ?? CalculationMethod.muslim_world_league.name;

  /// True after the user explicitly picks a calculation method. A method
  /// stored before this flag existed is treated as manual so existing users
  /// keep their current behavior.
  bool get isMethodManual =>
      _prefs.getBool(methodManualKey) ?? _prefs.getString(methodKey) != null;

  /// Prayer alerts must not be scheduled from an implicit fallback location or
  /// calculation method. The prayer-times view can still use its display
  /// defaults, but an alert is only trustworthy after the user has explicitly
  /// configured both values.
  bool get isReadyForNotificationScheduling {
    final cityId = selectedCityId;
    final method = _prefs.getString(methodKey);
    return isEnabled &&
        cityId != null &&
        cityId.isNotEmpty &&
        method != null &&
        CalculationMethod.values.any((value) => value.name == method);
  }

  Future<void> setEnabled(bool enabled) => _prefs.setBool(enabledKey, enabled);

  /// Persists the city; when the method was never chosen manually it follows
  /// the new city country automatically.
  Future<void> setCityId(String id) async {
    await _prefs.setString(cityIdKey, id);
    if (!isMethodManual) {
      await _prefs.setString(methodKey, await defaultMethodFor(id));
      // The stored method above is derived, not chosen: keep the automatic
      // state explicit so later reads don't mistake it for a manual choice.
      await _prefs.setBool(methodManualKey, false);
    }
  }

  Future<void> setCalculationMethod(String method) async {
    await _prefs.setString(methodKey, method);
    await _prefs.setBool(methodManualKey, true);
  }

  /// Returns to country-driven method selection and applies the current
  /// city default immediately.
  Future<void> setMethodAutomatic() async {
    await _prefs.setBool(methodManualKey, false);
    final id = selectedCityId;
    if (id != null) {
      await _prefs.setString(methodKey, await defaultMethodFor(id));
    }
  }

  Future<String> defaultMethodFor(String cityId) async {
    final all = await cities();
    for (final city in all) {
      if (city.id == cityId) return city.defaultMethod;
    }
    return CalculationMethod.muslim_world_league.name;
  }

  Future<List<PrayerCity>> cities() async {
    if (_cities != null) return _cities!;
    try {
      final raw = await rootBundle.loadString(citiesAsset);
      final list = jsonDecode(raw) as List<dynamic>;
      _cities = [
        for (final item in list)
          if (item is Map<String, dynamic>)
            PrayerCity(
              id: item['id'] as String,
              nameAr: item['nameAr'] as String,
              nameEn: item['nameEn'] as String,
              latitude: (item['latitude'] as num).toDouble(),
              longitude: (item['longitude'] as num).toDouble(),
              timeZone: item['timeZone'] as String? ?? 'UTC',
              countryId: item['countryId'] as String? ?? 'other',
              countryAr:
                  item['countryAr'] as String? ?? item['nameAr'] as String,
              countryEn:
                  item['countryEn'] as String? ?? item['nameEn'] as String,
              defaultMethod:
                  item['method'] as String? ??
                  CalculationMethod.muslim_world_league.name,
            ),
      ];
    } catch (_) {
      _cities = const [
        PrayerCity(
          id: 'makkah',
          nameAr: 'مكة المكرمة',
          nameEn: 'Makkah',
          latitude: 21.4225,
          longitude: 39.8262,
          timeZone: 'Asia/Riyadh',
          countryId: 'sa',
          countryAr: 'السعودية',
          countryEn: 'Saudi Arabia',
          defaultMethod: 'umm_al_qura',
        ),
      ];
    }
    return _cities!;
  }

  /// Cities grouped by country, preserving asset order.
  Future<List<PrayerCountry>> countries() async {
    final all = await cities();
    final groups = <String, List<PrayerCity>>{};
    for (final city in all) {
      groups.putIfAbsent(city.countryId, () => []).add(city);
    }
    return [
      for (final entry in groups.entries)
        PrayerCountry(
          id: entry.key,
          nameAr: entry.value.first.countryAr,
          nameEn: entry.value.first.countryEn,
          cities: entry.value,
        ),
    ];
  }

  Future<PrayerTimesSnapshot?> current({required bool isArabic}) async {
    if (!isEnabled) return null;
    final all = await cities();
    if (all.isEmpty) return null;
    final id = selectedCityId;
    final city =
        all.cast<PrayerCity?>().firstWhere(
          (c) => c?.id == id,
          orElse: () => all.first,
        ) ??
        all.first;
    final location = tz.getLocation(city.timeZone);
    final now = tz.TZDateTime.from(_now(), location);
    final times = _calculate(city, now);
    final upcoming = <(String, DateTime)>[
      ('fajr', times.fajr),
      ('sunrise', times.sunrise),
      ('dhuhr', times.dhuhr),
      ('asr', times.asr),
      ('maghrib', times.maghrib),
      ('isha', times.isha),
    ];
    (String, DateTime)? next;
    for (final entry in upcoming) {
      if (entry.$2.isAfter(now)) {
        next = entry;
        break;
      }
    }
    if (next == null) {
      final tomorrow = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day + 1,
      );
      next = ('fajr', _calculate(city, tomorrow).fajr);
    }
    return PrayerTimesSnapshot(
      city: city,
      nextName: next.$1,
      nextTime: next.$2,
      minutesUntil: next.$2.difference(now).inMinutes,
      fajr: times.fajr,
      sunrise: times.sunrise,
      dhuhr: times.dhuhr,
      asr: times.asr,
      maghrib: times.maghrib,
      isha: times.isha,
    );
  }

  ({
    DateTime fajr,
    DateTime sunrise,
    DateTime dhuhr,
    DateTime asr,
    DateTime maghrib,
    DateTime isha,
  })
  _calculate(PrayerCity city, DateTime date) {
    final location = tz.getLocation(city.timeZone);
    final cityDate = tz.TZDateTime.from(date, location);
    final times = PrayerTimes.utc(
      Coordinates(city.latitude, city.longitude),
      DateComponents.from(cityDate),
      _paramsFor(calculationMethod),
    );
    return (
      fajr: tz.TZDateTime.from(times.fajr, location),
      sunrise: tz.TZDateTime.from(times.sunrise, location),
      dhuhr: tz.TZDateTime.from(times.dhuhr, location),
      asr: tz.TZDateTime.from(times.asr, location),
      maghrib: tz.TZDateTime.from(times.maghrib, location),
      isha: tz.TZDateTime.from(times.isha, location),
    );
  }

  CalculationParameters _paramsFor(String method) {
    final match = CalculationMethod.values.where((m) => m.name == method);
    final resolved = match.isEmpty
        ? CalculationMethod.muslim_world_league
        : match.first;
    return resolved.getParameters();
  }

  /// Calculates prayer times for a specific date using the active city and method.
  Future<List<({String key, String nameAr, String nameEn, DateTime time})>>
  timesForDate(DateTime date) async {
    final all = await cities();
    if (all.isEmpty) return const [];
    final id = selectedCityId;
    final city =
        all.cast<PrayerCity?>().firstWhere(
          (c) => c?.id == id,
          orElse: () => all.first,
        ) ??
        all.first;
    final times = _calculate(city, date);
    return [
      (key: 'fajr', nameAr: 'الفجر', nameEn: 'Fajr', time: times.fajr),
      (key: 'dhuhr', nameAr: 'الظهر', nameEn: 'Dhuhr', time: times.dhuhr),
      (key: 'asr', nameAr: 'العصر', nameEn: 'Asr', time: times.asr),
      (
        key: 'maghrib',
        nameAr: 'المغرب',
        nameEn: 'Maghrib',
        time: times.maghrib,
      ),
      (key: 'isha', nameAr: 'العشاء', nameEn: 'Isha', time: times.isha),
    ];
  }
}
