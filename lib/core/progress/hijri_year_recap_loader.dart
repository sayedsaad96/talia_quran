import 'package:shared_preferences/shared_preferences.dart';

import '../../features/khatmah/domain/repositories/khatmah_repository.dart';
import '../../features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../memorization/review_record_audience_scope.dart';
import '../services/hijri_date_adjustment.dart';
import '../services/streak_service.dart';
import 'hijri_year_recap.dart';

final class HijriYearRecapLoadResult {
  const HijriYearRecapLoadResult(this.recap, {required this.dismissed});
  final HijriYearRecap recap;
  final bool dismissed;
}

/// Account-scoped bridge from existing stores to the pure recap calculator.
abstract interface class HijriYearRecapSource {
  Future<HijriYearRecapLoadResult> load();
  Future<void> dismiss(int hijriYear);
}

final class HijriYearRecapLoader implements HijriYearRecapSource {
  HijriYearRecapLoader(
    this._khatmah,
    this._reviews,
    this._streaks,
    this._prefs,
    this._owner,
    this._barrier,
    this._adjustment, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const dismissalPrefix = 'hijri_year_recap_dismissed_';
  final KhatmahRepository _khatmah;
  final MemorizationPlusLocalDatasource _reviews;
  final StreakService _streaks;
  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;
  final AccountDataBarrier _barrier;
  final HijriDateAdjustment _adjustment;
  final DateTime Function() _now;

  static String dismissalKey(String ownerId, int hijriYear) =>
      '$dismissalPrefix$hijriYear|$ownerId';

  @override
  Future<HijriYearRecapLoadResult> load() async {
    final ownerId = _owner.currentOwnerId;
    final lease = _barrier.capture();
    _check(ownerId, lease);
    // Decide visibility from the date alone; outside the window nothing else
    // (khatmah history, every review record, a year of activity) is read.
    final windowProbe = HijriYearRecapCalculator.calculate(
      HijriYearRecapInput(
        now: _now(),
        hijriAdjustmentDays: _adjustment.days,
        khatmahCompletionDates: const [],
        reviews: const [],
        lifetimeLongestStreak: 0,
        activityByDay: const {},
      ),
    );
    if (!windowProbe.isVisible) {
      return HijriYearRecapLoadResult(windowProbe, dismissed: false);
    }
    final history = await _khatmah.getHistory();
    _check(ownerId, lease);
    final reviews = await _reviews.getAllReviewRecords(
      scope: ReviewRecordReadScope.adult,
    );
    _check(ownerId, lease);
    final streak = await _streaks.getStreak();
    _check(ownerId, lease);
    final activity = await _streaks.getActivityMap(days: 365);
    _check(ownerId, lease);
    final recap = HijriYearRecapCalculator.calculate(
      HijriYearRecapInput(
        now: _now(),
        hijriAdjustmentDays: _adjustment.days,
        khatmahCompletionDates: history.map((entry) => entry.completedDate),
        reviews: reviews.map(
          (record) => HijriYearRecapReview(
            isCurrentlyMemorized: record.isMemorized,
            lastReviewedAt: record.lastReviewedAt,
          ),
        ),
        lifetimeLongestStreak: streak.longestStreak,
        activityByDay: activity,
      ),
    );
    _check(ownerId, lease);
    return HijriYearRecapLoadResult(
      recap,
      dismissed: _prefs.getBool(dismissalKey(ownerId, recap.hijriYear)) ?? false,
    );
  }

  @override
  Future<void> dismiss(int hijriYear) async {
    final ownerId = _owner.currentOwnerId;
    final authority = _barrier.capture();
    await _barrier.run((lease) async {
      _check(ownerId, lease);
      if (!await _prefs.setBool(dismissalKey(ownerId, hijriYear), true)) {
        throw StateError('Unable to dismiss Hijri recap');
      }
      _check(ownerId, lease);
    }, authority: authority);
  }

  void _check(String ownerId, AccountDataLease lease) {
    lease.check();
    if (_owner.currentOwnerId != ownerId) {
      throw const AccountDataUnavailableException();
    }
  }
}
