import '../../features/memorization_plus/domain/entities/ayah_review_record.dart';
import '../../features/prayer_companion/domain/entities/prayer_companion.dart';
import '../../features/prayer_review/domain/entities/prayer_review_authority.dart';
import '../../features/prayer_review/domain/entities/prayer_review_selection.dart';
import '../../features/prayer_review/domain/repositories/prayer_review_repository.dart';
import '../../features/quran/domain/entities/quran_entities.dart';
import 'prayer_review_lengths.dart';
import 'prayer_review_picker.dart';
import '../identity/account_data_barrier.dart';

final class PrayerReviewOffer {
  const PrayerReviewOffer({required this.selection, required this.authority});
  final PrayerReviewSelection selection;
  final PrayerReviewAuthority authority;
}

/// Resolves an exposed selection without treating prayer confirmation as proof
/// of recitation. Callers own display and manual assessment separately.
final class PrayerReviewOfferService {
  PrayerReviewOfferService({
    required this._repository,
    required this._lengths,
    required this._isEnabled,
    required this._captureAuthority,
    required this._readAdultEligibility,
    required this._readRecords,
    required this._readCanonicalAyahs,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PrayerReviewRepository _repository;
  final PrayerReviewLengths _lengths;
  final bool Function() _isEnabled;
  final PrayerReviewAuthority Function() _captureAuthority;
  final Future<bool> Function() _readAdultEligibility;
  final Future<List<AyahReviewRecord>> Function() _readRecords;
  final Future<List<Ayah>> Function(Set<int>) _readCanonicalAyahs;
  final DateTime Function() _now;

  PrayerReviewAuthority captureAuthority() {
    final authority = _captureAuthority();
    _guard(authority);
    return authority;
  }

  Future<PrayerReviewOffer?> forOccurrence(
    PrayerOccurrence occurrence, {
    bool allowSelection = true,
  }) async {
    if (!_isEnabled()) return null;
    final authority = captureAuthority();
    if (occurrence.ownerId != authority.ownerId) {
      throw const AccountDataUnavailableException();
    }
    if (!await _eligible(authority)) return null;
    final day = _civilDay(occurrence.localDate);
    final key = PrayerReviewIdentity.occurrenceKey(
      ownerId: authority.ownerId,
      localDayKey: day,
      prayerKey: occurrence.prayerKey,
    );
    final existing = await _repository.readAssignment(
      localDayKey: day,
      occurrenceKey: key,
    );
    _guard(authority);
    final receipts = await _repository.readReceipts(day);
    _guard(authority);
    var selected = existing;
    if (selected == null) {
      if (!allowSelection || !_now().isBefore(occurrence.scheduledAt)) {
        return null;
      }
      selected = await _prepare(occurrence, day, authority, receipts);
    }
    _guard(authority);
    if (selected == null || _assessed(selected, receipts)) return null;
    if (selected.ownerId != authority.ownerId ||
        selected.occurrenceKey != key) {
      throw const FormatException('Prayer review assignment mismatch');
    }
    if (!await _eligible(authority)) return null;
    return PrayerReviewOffer(selection: selected, authority: authority);
  }

  Future<PrayerReviewSelection?> _prepare(
    PrayerOccurrence occurrence,
    String day,
    PrayerReviewAuthority authority,
    List<PrayerReviewReceipt> receipts,
  ) async {
    final records = await _readRecords();
    _guard(authority);
    final ayahs = await _readCanonicalAyahs(
      records.map((r) => r.surahId).toSet(),
    );
    _guard(authority);
    final assigned = await _repository.readAssignmentsForDay(day);
    _guard(authority);
    final now = _now();
    if (!now.isBefore(occurrence.scheduledAt)) return null;
    final passage = PrayerReviewPicker.pick(
      records: records,
      canonicalAyahs: ayahs,
      now: now,
      maxAyahs: _lengths.read(authority.ownerId, occurrence.prayerKey),
      excludedPassages: {
        for (final receipt in receipts)
          PrayerReviewPassage(
            surahId: receipt.surahId,
            startAyah: receipt.startAyah,
            endAyah: receipt.endAyah,
          ),
        // One passage is offered once per local day across all prayers.
        for (final other in assigned)
          if (other.ownerId == authority.ownerId)
            PrayerReviewPassage(
              surahId: other.surahId,
              startAyah: other.startAyah,
              endAyah: other.endAyah,
            ),
      },
    );
    if (passage == null || !await _eligible(authority)) return null;
    final proposed = PrayerReviewSelection(
      ownerId: authority.ownerId,
      localDayKey: day,
      prayerKey: occurrence.prayerKey,
      scheduledAt: occurrence.scheduledAt.toUtc(),
      selectedAt: now.toUtc(),
      surahId: passage.surahId,
      startAyah: passage.startAyah,
      endAyah: passage.endAyah,
    );
    final stored = await _repository.saveAssignmentIfAbsent(
      proposed,
      authority,
    );
    _guard(authority);
    return stored;
  }

  Future<bool> _eligible(PrayerReviewAuthority authority) async {
    final adult = await _readAdultEligibility();
    _guard(authority);
    return adult;
  }

  void _guard(PrayerReviewAuthority authority) {
    authority.check();
    if (!_isEnabled()) throw StateError('Prayer review is unavailable');
  }

  bool _assessed(
    PrayerReviewSelection selection,
    List<PrayerReviewReceipt> receipts,
  ) => receipts.any(
    (r) =>
        r.ownerId == selection.ownerId &&
        r.localDayKey == selection.localDayKey &&
        r.surahId == selection.surahId &&
        r.startAyah == selection.startAyah &&
        r.endAyah == selection.endAyah,
  );

  String _civilDay(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
