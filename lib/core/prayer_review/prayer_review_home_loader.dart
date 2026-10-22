import '../../features/prayer_companion/domain/entities/prayer_companion.dart';
import '../../features/prayer_review/domain/entities/prayer_review_authority.dart';
import '../services/prayer_times_service.dart';
import 'prayer_review_home_window.dart';
import 'prayer_review_offer_service.dart';

/// A Home-surface offer and the occurrence that owns its stable selection.
final class PrayerReviewHomeOffer {
  const PrayerReviewHomeOffer({required this.offer, required this.occurrence});

  final PrayerReviewOffer offer;
  final PrayerOccurrence occurrence;
}

/// Loads a temporary Home fallback without altering Companion scheduling.
///
/// Selection remains in [PrayerReviewOfferService]. This bridge only decides
/// whether the current prayer window may expose that already-safe flow.
final class PrayerReviewHomeLoader {
  PrayerReviewHomeLoader({
    required this.offers,
    required this.isEnabled,
    required this.readAdultEligibility,
    required this.readSettings,
    required this.readPrayerTimes,
    required this.accountChanges,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final PrayerReviewOfferService offers;
  final bool Function() isEnabled;
  final Future<bool> Function() readAdultEligibility;
  final Future<PrayerCompanionSettings> Function() readSettings;
  final Future<PrayerTimesSnapshot?> Function() readPrayerTimes;
  final Stream<void> accountChanges;
  final DateTime Function() now;

  Future<PrayerReviewHomeOffer?> load() async {
    if (!isEnabled()) {
      return null;
    }
    final authority = offers.captureAuthority();
    if (!await _isAdult(authority)) {
      return null;
    }
    final settings = await readSettings();
    _check(authority);
    if (_hasPreparationReminder(settings)) {
      return null;
    }
    final snapshot = await readPrayerTimes();
    _check(authority);
    final occurrence = _occurrence(authority.ownerId, snapshot, settings);
    if (occurrence == null) {
      return null;
    }
    final offer = await offers.forOccurrence(occurrence);
    _check(authority);
    if (!now().isBefore(occurrence.scheduledAt) ||
        offer == null ||
        offer.authority.ownerId != authority.ownerId) {
      return null;
    }
    offer.authority.check();
    return PrayerReviewHomeOffer(offer: offer, occurrence: occurrence);
  }

  Future<bool> _isAdult(PrayerReviewAuthority authority) async {
    final adult = await readAdultEligibility();
    _check(authority);
    return adult;
  }

  PrayerOccurrence? _occurrence(
    String ownerId,
    PrayerTimesSnapshot? snapshot,
    PrayerCompanionSettings settings,
  ) {
    final times = _obligatoryTimes(snapshot);
    if (times == null) {
      return null;
    }
    return prayerReviewHomeOccurrence(
      ownerId: ownerId,
      times: times,
      now: now(),
      preparationNotificationsEnabled: _hasPreparationReminder(settings),
      preparationMinutes: settings.preparationMinutes,
    );
  }

  Map<PrayerKey, DateTime>? _obligatoryTimes(PrayerTimesSnapshot? snapshot) {
    if (snapshot == null ||
        snapshot.fajr == null ||
        snapshot.dhuhr == null ||
        snapshot.asr == null ||
        snapshot.maghrib == null ||
        snapshot.isha == null) {
      return null;
    }
    return {
      PrayerKey.fajr: snapshot.fajr!,
      PrayerKey.dhuhr: snapshot.dhuhr!,
      PrayerKey.asr: snapshot.asr!,
      PrayerKey.maghrib: snapshot.maghrib!,
      PrayerKey.isha: snapshot.isha!,
    };
  }

  bool _hasPreparationReminder(PrayerCompanionSettings settings) {
    return settings.enabled && settings.preparationMinutes > 0;
  }

  void _check(PrayerReviewAuthority authority) {
    authority.check();
    if (!isEnabled()) {
      throw StateError('Prayer review is unavailable');
    }
  }
}
