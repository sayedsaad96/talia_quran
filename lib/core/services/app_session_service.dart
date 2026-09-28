import 'package:shared_preferences/shared_preferences.dart';

import '../identity/account_data_barrier.dart';

class AppSessionService {
  AppSessionService(this._prefs);

  static const _lastLocationKey = 'last_restorable_location';
  static const _dailyWirdTargetPrefix = 'daily_wird_target_';
  static const _dailyWirdLastCompletedKey = 'daily_wird_last_completed_page';

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
      final key = _dailyWirdTargetKey(date);
      await _prefs.setInt(key, pageNumber);
      lease.check();
      // Only today's target is ever read; drop older days so the keys do not
      // accumulate forever.
      for (final stale
          in _prefs
              .getKeys()
              .where(
                (candidate) =>
                    candidate.startsWith(_dailyWirdTargetPrefix) &&
                    candidate != key,
              )
              .toList()) {
        await _prefs.remove(stale);
      }
    }, authority: authority);
  }

  /// Returns the last Quran page the user confirmed as their daily wird.
  ///
  /// This is used to compute the next wird page (lastCompleted + 1) when no
  /// explicit target has been saved yet for today. Returns null if the user
  /// has never confirmed a wird page.
  int? getDailyWirdLastCompletedPage() {
    final page = _prefs.getInt(_dailyWirdLastCompletedKey);
    return page != null && page >= 1 && page <= 604 ? page : null;
  }

  /// Saves [pageNumber] as the last confirmed wird page.
  ///
  /// Call this when the user finishes reading their daily wird (free mode only).
  Future<void> saveDailyWirdLastCompletedPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) return;
    final barrier = AccountDataBarrier.forPreferences(_prefs);
    final authority = barrier.capture();
    await barrier.run<void>((lease) async {
      await _prefs.setInt(_dailyWirdLastCompletedKey, pageNumber);
      lease.check();
    }, authority: authority);
  }

  /// Advances the daily wird after a confirmed free-mode page, but only when
  /// the page belongs to the wird: today's target or the page right after the
  /// wird cursor. Reading anywhere else (Al-Kahf on Friday, going back, a
  /// surah the user picked) never moves tomorrow's wird. Returns whether the
  /// wird advanced.
  Future<bool> advanceDailyWird(int pageNumber, {DateTime? now}) async {
    final target = getDailyWirdTarget(now ?? DateTime.now());
    if (target == null) return false;
    final last = getDailyWirdLastCompletedPage();
    final cursor = last != null && last >= target ? last : target - 1;
    if (pageNumber != cursor + 1) return false;
    await saveDailyWirdLastCompletedPage(pageNumber);
    return true;
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
      // Khatmah reading progress is owned by the khatmah plan itself. A
      // khatmah-mode page must never become the ordinary reading continue
      // position (and vice versa), so those locations are not restorable.
      if (uri.queryParameters['mode'] == 'khatmah') return false;
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
