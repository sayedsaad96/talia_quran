import 'package:shared_preferences/shared_preferences.dart';

import '../identity/account_data_barrier.dart';

class AppSessionService {
  AppSessionService(this._prefs);

  static const _lastLocationKey = 'last_restorable_location';
  static const _dailyWirdTargetPrefix = 'daily_wird_target_';

  final SharedPreferences _prefs;

  String? getLastRestorableLocation() {
    final location = _prefs.getString(_lastLocationKey);
    if (location == null || !_isRestorableLocation(location)) {
      return null;
    }
    return location;
  }

  Future<void> saveLocation(String location) async {
    if (!_isRestorableLocation(location)) return;
    await _prefs.setString(_lastLocationKey, location);
  }

  Future<void> clearLastRestorableLocation() async {
    await _prefs.remove(_lastLocationKey);
  }

  /// Returns the ordinary daily-wird target fixed for this local calendar day.
  int? getDailyWirdTarget(DateTime date) {
    final target = _prefs.getInt(_dailyWirdTargetKey(date));
    return target != null && target >= 1 && target <= 604 ? target : null;
  }

  /// Persists an ordinary daily-wird target under the current account lease.
  Future<void> saveDailyWirdTarget(int pageNumber, DateTime date) async {
    if (pageNumber < 1 || pageNumber > 604) return;
    final barrier = AccountDataBarrier.forPreferences(_prefs);
    final authority = barrier.capture();
    await barrier.run<void>((lease) async {
      await _prefs.setInt(_dailyWirdTargetKey(date), pageNumber);
      lease.check();
    }, authority: authority);
  }

  String _dailyWirdTargetKey(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$_dailyWirdTargetPrefix${local.year}-$month-$day';
  }

  bool _isRestorableLocation(String location) {
    if (!location.startsWith('/')) return false;

    final uri = Uri.tryParse(location);
    if (uri == null || uri.path.isEmpty) return false;

    switch (uri.path) {
      case '/splash':
      case '/onboarding':
      case '/onboarding/child':
      case '/login':
      case '/certificate':
        return false;
      case '/memorization-v2/session':
        return _isValidSurahId(_readInt(uri, 'surahId'));
      case '/memorization-plus/kids-journey':
        return _isValidSurahId(_readInt(uri, 'surahId'));
      case '/family-dashboard':
        return true;

    }

    final segments = uri.pathSegments;
    if (segments.length == 3 &&
        segments[0] == 'memorization-plus' &&
        segments[1] == 'journey') {
      return _isValidSurahId(int.tryParse(segments[2]));
    }
    if (segments.length == 3 && segments[0] == 'quran') {
      final value = int.tryParse(segments[2]);
      if (segments[1] == 'surah') return _isValidSurahId(value);
      if (segments[1] == 'page') {
        return value != null && value >= 1 && value <= 604;
      }
    }

    return false;
  }

  int? _readInt(Uri uri, String key) {
    return int.tryParse(uri.queryParameters[key] ?? '');
  }

  bool _isValidSurahId(int? surahId) {
    return surahId != null && surahId >= 1 && surahId <= 114;
  }
}
