import '../../features/prayer_companion/domain/entities/prayer_companion.dart';
import '../../features/prayer_review/domain/entities/prayer_review_authority.dart';
import '../../features/prayer_review/domain/entities/prayer_review_selection.dart';
import 'prayer_review_offer_service.dart';

final class PrayerReviewPromptCoordinator {
  PrayerReviewPromptCoordinator({
    required this._isEnabled,
    required this._loadExisting,
    required this._readAdultEligibility,
    required this._claimPrompt,
    required this._captureAuthority,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final bool Function() _isEnabled;
  final Future<PrayerReviewOffer?> Function(PrayerOccurrence) _loadExisting;
  final Future<bool> Function() _readAdultEligibility;
  final Future<PrayerReviewSelection?> Function(String, PrayerReviewAuthority)
  _claimPrompt;
  final DateTime Function() _now;
  final PrayerReviewAuthority Function() _captureAuthority;

  PrayerReviewAuthority captureAuthority() {
    final authority = _captureAuthority();
    _check(authority);
    return authority;
  }

  Future<PrayerReviewOffer?> forConfirmation(
    PrayerCompanionRecord record, {
    required PrayerReviewAuthority authority,
    required bool newlyConfirmed,
    required bool foreground,
  }) async {
    if (!_isEnabled() ||
        !newlyConfirmed ||
        !foreground ||
        record.status != PrayerCompanionStatus.confirmed) {
      return null;
    }
    _check(authority);
    final now = _now();
    if (record.occurrence.ownerId != authority.ownerId ||
        now.isBefore(record.occurrence.scheduledAt) ||
        _day(now.toLocal()) != _day(record.occurrence.localDate)) {
      return null;
    }
    final adult = await _readAdultEligibility();
    _check(authority);
    if (!adult) return null;
    final offer = await _loadExisting(record.occurrence);
    _check(authority);
    if (offer == null) return null;
    offer.authority.check();
    final selected = offer.selection;
    if (selected.ownerId != authority.ownerId ||
        selected.localDayKey != _day(record.occurrence.localDate) ||
        selected.prayerKey != record.occurrence.prayerKey) {
      throw const FormatException('Prayer confirmation selection mismatch');
    }
    final claimed = await _claimPrompt(selected.occurrenceKey, authority);
    _check(authority);
    if (claimed == null) return null;
    if (!claimed.promptConsumed ||
        claimed.copyWith(promptConsumed: false) !=
            selected.copyWith(promptConsumed: false)) {
      throw const FormatException('Prayer review prompt claim mismatch');
    }
    final stillAdult = await _readAdultEligibility();
    _check(authority);
    return stillAdult ? offer : null;
  }

  void _check(PrayerReviewAuthority authority) {
    authority.check();
    if (!_isEnabled()) throw StateError('Prayer review is unavailable');
  }

  String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
