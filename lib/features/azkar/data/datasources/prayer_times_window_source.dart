import '../../../../core/services/prayer_times_service.dart';
import '../../domain/services/azkar_period_resolver.dart';

/// Reads today's Fajr and Asr from the offline prayer-times service. Returns
/// null when prayer times are off, no city is chosen, or the lookup fails, so
/// callers fall back to the fixed period rule.
class PrayerTimesWindowSource implements AzkarPrayerWindowSource {
  PrayerTimesWindowSource(this._service);

  final PrayerTimesService _service;

  @override
  Future<AzkarPrayerWindow?> load(DateTime now) async {
    try {
      final snapshot = await _service.current(isArabic: true);
      final fajr = snapshot?.fajr;
      final asr = snapshot?.asr;
      if (fajr == null || asr == null) return null;
      return AzkarPrayerWindow(fajr: fajr, asr: asr);
    } catch (_) {
      return null;
    }
  }
}
