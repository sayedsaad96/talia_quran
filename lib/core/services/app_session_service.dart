import 'package:shared_preferences/shared_preferences.dart';

class AppSessionService {
  AppSessionService(this._prefs);

  static const _lastLocationKey = 'last_restorable_location';

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

  bool _isRestorableLocation(String location) {
    if (!location.startsWith('/')) return false;

    final uri = Uri.tryParse(location);
    if (uri == null || uri.path.isEmpty) return false;

    switch (uri.path) {
      case '/splash':
      case '/onboarding':
      case '/login':
      case '/certificate':
        return false;
      case '/hifz/session':
        return _isValidSurahId(_readInt(uri, 'surahId')) &&
            (_readInt(uri, 'startAyah') ?? 0) > 0;
      case '/memorization-plus/daily-plan':
        return _isValidSurahId(_readInt(uri, 'surahId'));
      case '/memorization-plus/kids-journey':
      case '/memorization-plus/parent-dashboard':
        return _isValidSurahId(_readInt(uri, 'surahId'));
      case '/memorization-plus/kids':
        return _isValidSurahId(_readInt(uri, 'surahId')) &&
            (_readInt(uri, 'ayahNumber') ?? 0) > 0;
      case '/memorization-plus/quiz':
        return _isValidSurahId(_readInt(uri, 'surahId'));
    }

    final segments = uri.pathSegments;
    if (segments.length == 3 && segments[0] == 'quran') {
      final value = int.tryParse(segments[2]);
      if (segments[1] == 'surah') return _isValidSurahId(value);
      if (segments[1] == 'page') {
        return value != null && value >= 1 && value <= 604;
      }
    }

    return true;
  }

  int? _readInt(Uri uri, String key) {
    return int.tryParse(uri.queryParameters[key] ?? '');
  }

  bool _isValidSurahId(int? surahId) {
    return surahId != null && surahId >= 1 && surahId <= 114;
  }
}
