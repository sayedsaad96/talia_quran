import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerCity {
  const PrayerCity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final double latitude;
  final double longitude;
}

class PrayerTimesSnapshot {
  const PrayerTimesSnapshot({
    required this.city,
    required this.nextName,
    required this.nextTime,
    required this.minutesUntil,
  });

  final PrayerCity city;
  final String nextName;
  final DateTime nextTime;
  final int minutesUntil;
}

class PrayerTimesService {
  PrayerTimesService(this._prefs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const enabledKey = 'prayer_times_enabled';
  static const cityIdKey = 'prayer_city_id';
  static const methodKey = 'prayer_calc_method';
  static const citiesAsset = 'assets/data/prayer_cities.json';

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  List<PrayerCity>? _cities;

  bool get isEnabled => _prefs.getBool(enabledKey) ?? false;

  String? get selectedCityId => _prefs.getString(cityIdKey);

  String get calculationMethod =>
      _prefs.getString(methodKey) ?? CalculationMethod.muslim_world_league.name;

  Future<void> setEnabled(bool enabled) => _prefs.setBool(enabledKey, enabled);

  Future<void> setCityId(String id) => _prefs.setString(cityIdKey, id);

  Future<void> setCalculationMethod(String method) =>
      _prefs.setString(methodKey, method);

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
        ),
      ];
    }
    return _cities!;
  }

  Future<PrayerTimesSnapshot?> current({required bool isArabic}) async {
    if (!isEnabled) return null;
    final all = await cities();
    if (all.isEmpty) return null;
    final id = selectedCityId;
    final city = all.cast<PrayerCity?>().firstWhere(
          (c) => c?.id == id,
          orElse: () => all.first,
        ) ??
        all.first;
    final params = _paramsFor(calculationMethod);
    final now = _now();
    final times = PrayerTimes(
      Coordinates(city.latitude, city.longitude),
      DateComponents.from(now),
      params,
    );
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
    next ??= ('fajr', times.fajr.add(const Duration(days: 1)));
    return PrayerTimesSnapshot(
      city: city,
      nextName: next.$1,
      nextTime: next.$2,
      minutesUntil: next.$2.difference(now).inMinutes,
    );
  }

  CalculationParameters _paramsFor(String method) {
    final match = CalculationMethod.values.where((m) => m.name == method);
    final resolved = match.isEmpty
        ? CalculationMethod.muslim_world_league
        : match.first;
    return resolved.getParameters();
  }
}
