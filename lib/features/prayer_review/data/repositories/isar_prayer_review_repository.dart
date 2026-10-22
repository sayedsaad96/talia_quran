import 'package:isar_community/isar.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/entities/prayer_review_authority.dart';
import '../../domain/entities/prayer_review_selection.dart';
import '../../domain/repositories/prayer_review_repository.dart';
import '../models/isar_prayer_review_assignment.dart';
import '../models/isar_prayer_review_receipt.dart';

/// Owner-scoped storage for frozen adult prayer-review selections and receipts.
///
/// This repository writes assignments only. Receipt writes are intentionally
/// delegated to [PrayerReviewReceiptTransactionWriter] so a higher-level
/// manual-review transaction can atomically include SRS and evidence rows.
final class IsarPrayerReviewRepository implements PrayerReviewRepository {
  IsarPrayerReviewRepository(this._isar, this._owner, this._barrier);

  final Isar _isar;
  final RecordOwnerProvider _owner;
  final AccountDataBarrier _barrier;

  /// Capture before any selection, profile, or corpus await.
  PrayerReviewAuthority captureAuthority() {
    final authority = PrayerReviewAuthority(
      ownerId: _owner.currentOwnerId,
      lease: _barrier.capture(),
    );
    authority.check();
    return authority;
  }

  @override
  Future<PrayerReviewSelection?> readAssignment({
    required String localDayKey,
    required String occurrenceKey,
  }) async {
    PrayerReviewValidation.checkLocalDayKey(localDayKey);
    final authority = captureAuthority();
    return _barrier.run((lease) async {
      _check(authority.ownerId, lease);
      final row = await _isar.isarPrayerReviewAssignments
          .filter()
          .ownerIdEqualTo(authority.ownerId)
          .occurrenceKeyEqualTo(occurrenceKey)
          .findFirst();
      _check(authority.ownerId, lease);
      if (row == null) return null;
      final selection = selectionFromRow(row);
      if (selection.localDayKey != localDayKey) {
        throw const FormatException('Prayer review assignment day mismatch');
      }
      return selection;
    }, authority: authority.lease);
  }

  @override
  Future<List<PrayerReviewSelection>> readAssignmentsForDay(
    String localDayKey,
  ) async {
    PrayerReviewValidation.checkLocalDayKey(localDayKey);
    final authority = captureAuthority();
    return _barrier.run((lease) async {
      _check(authority.ownerId, lease);
      final rows = await _isar.isarPrayerReviewAssignments
          .filter()
          .ownerIdEqualTo(authority.ownerId)
          .localDayKeyEqualTo(localDayKey)
          .findAll();
      _check(authority.ownerId, lease);
      return rows.map(selectionFromRow).toList();
    }, authority: authority.lease);
  }

  @override
  Future<List<PrayerReviewReceipt>> readReceipts(String localDayKey) async {
    PrayerReviewValidation.checkLocalDayKey(localDayKey);
    final authority = captureAuthority();
    return _barrier.run((lease) async {
      _check(authority.ownerId, lease);
      final rows = await _isar.isarPrayerReviewReceipts
          .filter()
          .ownerIdEqualTo(authority.ownerId)
          .localDayKeyEqualTo(localDayKey)
          .findAll();
      _check(authority.ownerId, lease);
      final receipts = rows.map(receiptFromRow).toList()
        ..sort((a, b) {
          final surah = a.surahId.compareTo(b.surahId);
          if (surah != 0) return surah;
          final start = a.startAyah.compareTo(b.startAyah);
          return start != 0 ? start : a.endAyah.compareTo(b.endAyah);
        });
      return receipts;
    }, authority: authority.lease);
  }

  @override
  Future<PrayerReviewSelection> saveAssignmentIfAbsent(
    PrayerReviewSelection selection,
    PrayerReviewAuthority authority,
  ) async {
    PrayerReviewValidation.checkSelection(selection);
    authority.check();
    if (_owner.currentOwnerId != authority.ownerId) {
      throw const AccountDataUnavailableException();
    }
    if (selection.ownerId != authority.ownerId) {
      throw const AccountDataUnavailableException();
    }
    return _barrier.run((lease) async {
      _check(authority.ownerId, lease);
      return _isar.writeTxn(() async {
        _check(authority.ownerId, lease);
        final existing = await _isar.isarPrayerReviewAssignments
            .filter()
            .ownerIdEqualTo(authority.ownerId)
            .occurrenceKeyEqualTo(selection.occurrenceKey)
            .findFirst();
        _check(authority.ownerId, lease);
        if (existing != null) return selectionFromRow(existing);
        await _isar.isarPrayerReviewAssignments.put(assignmentFrom(selection));
        _check(authority.ownerId, lease);
        return selection;
      });
    }, authority: authority.lease);
  }

  @override
  Future<PrayerReviewSelection?> consumePrompt(
    String occurrenceKey,
    PrayerReviewAuthority authority,
  ) async {
    authority.check();
    if (_owner.currentOwnerId != authority.ownerId) {
      throw const AccountDataUnavailableException();
    }
    return _barrier.run((lease) async {
      _check(authority.ownerId, lease);
      return _isar.writeTxn(() async {
        final row = await _isar.isarPrayerReviewAssignments
            .filter()
            .ownerIdEqualTo(authority.ownerId)
            .occurrenceKeyEqualTo(occurrenceKey)
            .findFirst();
        _check(authority.ownerId, lease);
        if (row == null) return null;
        final current = selectionFromRow(row);
        if (current.promptConsumed) return null;
        row.promptConsumed = true;
        await _isar.isarPrayerReviewAssignments.put(row);
        _check(authority.ownerId, lease);
        return current.copyWith(promptConsumed: true);
      });
    }, authority: authority.lease);
  }

  static PrayerReviewSelection selectionFromRow(
    IsarPrayerReviewAssignment row,
  ) {
    if (row.audience != IsarPrayerReviewAssignment.adultAudience) {
      throw const FormatException('Invalid prayer review assignment audience');
    }
    final selection = PrayerReviewSelection(
      ownerId: row.ownerId,
      localDayKey: row.localDayKey,
      prayerKey: PrayerReviewValidation.prayerKeyFromIndex(row.prayerKeyIndex),
      scheduledAt: row.scheduledAt.toUtc(),
      selectedAt: row.selectedAt.toUtc(),
      surahId: row.surahId,
      startAyah: row.startAyah,
      endAyah: row.endAyah,
      selectionVersion: row.selectionVersion,
      promptConsumed: row.promptConsumed,
    );
    if (row.occurrenceKey != selection.occurrenceKey) {
      throw const FormatException('Invalid prayer review occurrence key');
    }
    return selection;
  }

  static PrayerReviewReceipt receiptFromRow(IsarPrayerReviewReceipt row) {
    if (row.audience != IsarPrayerReviewReceipt.adultAudience) {
      throw const FormatException('Invalid prayer review receipt audience');
    }
    final receipt = PrayerReviewReceipt(
      ownerId: row.ownerId,
      localDayKey: row.localDayKey,
      surahId: row.surahId,
      startAyah: row.startAyah,
      endAyah: row.endAyah,
      gradeIndex: row.gradeIndex,
      committedAt: row.committedAt.toUtc(),
      eventIds: row.eventIds,
    );
    if (row.receiptKey != receipt.receiptKey) {
      throw const FormatException('Invalid prayer review receipt key');
    }
    return receipt;
  }

  static IsarPrayerReviewAssignment assignmentFrom(
    PrayerReviewSelection selection,
  ) => IsarPrayerReviewAssignment()
    ..ownerId = selection.ownerId
    ..occurrenceKey = selection.occurrenceKey
    ..audience = IsarPrayerReviewAssignment.adultAudience
    ..localDayKey = selection.localDayKey
    ..prayerKeyIndex = selection.prayerKey.index
    ..scheduledAt = selection.scheduledAt
    ..selectedAt = selection.selectedAt
    ..surahId = selection.surahId
    ..startAyah = selection.startAyah
    ..endAyah = selection.endAyah
    ..selectionVersion = selection.selectionVersion
    ..promptConsumed = selection.promptConsumed;

  static void _check(String ownerId, AccountDataLease lease) {
    lease.checkOwner(ownerId);
  }
}

/// Internal receipt writer. The caller must own an active Isar write
/// transaction and serialize it using [AccountDataBarrier.run].
abstract final class PrayerReviewReceiptTransactionWriter {
  static Future<PrayerReviewReceiptWriteResult> record(
    Isar isar, {
    required PrayerReviewAuthority authority,
    required PrayerReviewReceipt proposed,
  }) async {
    authority.check();
    PrayerReviewValidation.checkReceipt(proposed);
    if (proposed.ownerId != authority.ownerId) {
      throw const AccountDataUnavailableException();
    }
    final existing = await isar.isarPrayerReviewReceipts
        .filter()
        .ownerIdEqualTo(authority.ownerId)
        .receiptKeyEqualTo(proposed.receiptKey)
        .findFirst();
    authority.check();
    if (existing != null) {
      return PrayerReviewReceiptWriteResult(
        receipt: IsarPrayerReviewRepository.receiptFromRow(existing),
        alreadyCommitted: true,
      );
    }
    await isar.isarPrayerReviewReceipts.put(rowFromReceipt(proposed));
    authority.check();
    return PrayerReviewReceiptWriteResult(
      receipt: proposed,
      alreadyCommitted: false,
    );
  }

  static IsarPrayerReviewReceipt rowFromReceipt(PrayerReviewReceipt receipt) =>
      IsarPrayerReviewReceipt()
        ..ownerId = receipt.ownerId
        ..receiptKey = receipt.receiptKey
        ..audience = IsarPrayerReviewReceipt.adultAudience
        ..localDayKey = receipt.localDayKey
        ..surahId = receipt.surahId
        ..startAyah = receipt.startAyah
        ..endAyah = receipt.endAyah
        ..gradeIndex = receipt.gradeIndex
        ..committedAt = receipt.committedAt
        ..eventIds = List<String>.from(receipt.eventIds);
}

final class PrayerReviewReceiptWriteResult {
  const PrayerReviewReceiptWriteResult({
    required this.receipt,
    required this.alreadyCommitted,
  });

  final PrayerReviewReceipt receipt;
  final bool alreadyCommitted;
}
