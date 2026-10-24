import '../../features/khatmah/domain/repositories/khatmah_repository.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../memorization/memorization_path_resolver.dart';
import '../memorization/progress_metrics_service.dart';
import '../memorization/review_record_audience_scope.dart';
import '../services/prayer_times_service.dart';
import 'widget_snapshot.dart';
import 'widget_snapshot_builder.dart';

final class WidgetSnapshotSource {
  WidgetSnapshotSource({
    required this.owner,
    required this.records,
    required this.path,
    required this.prayers,
    required this.khatmah,
    required this.isEnabled,
    DateTime Function()? now,
    String Function()? languageCode,
  }) : now = now ?? DateTime.now,
       languageCode = languageCode ?? (() => 'ar');
  final RecordOwnerProvider owner;
  final MemorizationPlusRepository records;
  final MemorizationPathResolver path;
  final PrayerTimesService prayers;
  final KhatmahRepository khatmah;
  final bool Function() isEnabled;
  final DateTime Function() now;

  /// App language (`ar`/`en`) the native renderer should use.
  final String Function() languageCode;

  Future<WidgetSnapshot> load(AccountDataLease lease, String ownerId) async {
    lease.checkOwner(ownerId);
    // Guests and local-only adults are served too: the barrier lease above
    // already proves this owner is the one the local stores belong to.
    if (!isEnabled()) return const WidgetSnapshot.empty();
    final profile = await path.currentProfile();
    lease.checkOwner(ownerId);
    if (profile?.isAdult != true) return const WidgetSnapshot.empty();
    final result = await records.getAllReviewRecords(
      scope: ReviewRecordReadScope.adult,
    );
    lease.checkOwner(ownerId);
    final reviewRecords = result.fold(
      (_) => throw StateError('Widget reviews unavailable'),
      (value) => value,
    );
    final prayer = await prayers.current(isArabic: true);
    lease.checkOwner(ownerId);
    final tomorrowFajr = await _tomorrowFajr();
    lease.checkOwner(ownerId);
    final instant = now();
    final tomorrowPrayers = await _tomorrowPrayers(instant);
    lease.checkOwner(ownerId);
    final plan = await khatmah.getActivePlan();
    lease.checkOwner(ownerId);
    final metrics = const ProgressMetricsService().calculate(
      records: reviewRecords,
      now: instant,
    );
    return buildWidgetSnapshot(
      enabled: isEnabled(),
      isAdult: true,
      signedOutOrSwitching: false,
      today: prayer,
      tomorrow: null,
      tomorrowFajr: tomorrowFajr,
      tomorrowPrayers: tomorrowPrayers,
      languageCode: languageCode(),
      dueReviewCount: metrics.dueReviews,
      activePlan: plan,
      now: instant,
    );
  }

  /// Tomorrow's five fard prayers so the widget survives local midnight.
  Future<List<WidgetPrayerTime>> _tomorrowPrayers(DateTime instant) async {
    try {
      final local = instant.toLocal();
      // Noon keeps the calendar date unambiguous across time zones.
      final times = await prayers.timesForDate(
        DateTime(local.year, local.month, local.day + 1, 12),
      );
      return [
        for (final prayer in times)
          if (WidgetSnapshot.fardPrayerKeys.contains(prayer.key))
            (key: prayer.key, at: prayer.time),
      ];
    } catch (_) {
      // Without them the widget falls back to tomorrow's Fajr only.
      return const [];
    }
  }

  Future<DateTime?> _tomorrowFajr() async {
    try {
      return await prayers.tomorrowFajr();
    } catch (_) {
      // Without it the widget only loses the post-Isha prayer line.
      return null;
    }
  }
}
