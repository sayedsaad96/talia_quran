import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';

import '../../../prayer_companion/domain/entities/prayer_companion.dart';
import '../../../../core/constants/surah_names.dart';

/// IDs-only passage selected for a single, adult prayer occurrence.
///
/// The occurrence and timestamps are frozen when it is first exposed. This
/// object intentionally has no database id, Quran text, audio, or speech data.
final class PrayerReviewSelection extends Equatable {
  PrayerReviewSelection({
    required this.ownerId,
    required this.localDayKey,
    required this.prayerKey,
    required this.scheduledAt,
    required this.selectedAt,
    required this.surahId,
    required this.startAyah,
    required this.endAyah,
    this.selectionVersion = currentSelectionVersion,
    this.promptConsumed = false,
  }) : occurrenceKey = PrayerReviewIdentity.occurrenceKey(
         ownerId: ownerId,
         localDayKey: localDayKey,
         prayerKey: prayerKey,
       ) {
    PrayerReviewValidation.checkSelection(this);
  }

  static const currentSelectionVersion = 1;

  final String ownerId;
  final String occurrenceKey;
  final String localDayKey;
  final PrayerKey prayerKey;
  final DateTime scheduledAt;
  final DateTime selectedAt;
  final int surahId;
  final int startAyah;
  final int endAyah;
  final int selectionVersion;
  final bool promptConsumed;

  PrayerReviewSelection copyWith({bool? promptConsumed}) =>
      PrayerReviewSelection(
        ownerId: ownerId,
        localDayKey: localDayKey,
        prayerKey: prayerKey,
        scheduledAt: scheduledAt,
        selectedAt: selectedAt,
        surahId: surahId,
        startAyah: startAyah,
        endAyah: endAyah,
        selectionVersion: selectionVersion,
        promptConsumed: promptConsumed ?? this.promptConsumed,
      );

  @override
  List<Object?> get props => [
    ownerId,
    occurrenceKey,
    localDayKey,
    prayerKey,
    scheduledAt,
    selectedAt,
    surahId,
    startAyah,
    endAyah,
    selectionVersion,
    promptConsumed,
  ];
}

/// A first-writer-wins receipt for an exact passage on a local civil day.
final class PrayerReviewReceipt extends Equatable {
  PrayerReviewReceipt({
    required this.ownerId,
    required this.localDayKey,
    required this.surahId,
    required this.startAyah,
    required this.endAyah,
    required this.gradeIndex,
    required this.committedAt,
    required List<String> eventIds,
  }) : receiptKey = PrayerReviewIdentity.receiptKey(
         ownerId: ownerId,
         localDayKey: localDayKey,
         surahId: surahId,
         startAyah: startAyah,
         endAyah: endAyah,
       ),
       eventIds = List.unmodifiable(eventIds) {
    PrayerReviewValidation.checkReceipt(this);
  }

  final String ownerId;
  final String receiptKey;
  final String localDayKey;
  final int surahId;
  final int startAyah;
  final int endAyah;
  final int gradeIndex;
  final DateTime committedAt;
  final List<String> eventIds;

  @override
  List<Object?> get props => [
    ownerId,
    receiptKey,
    localDayKey,
    surahId,
    startAyah,
    endAyah,
    gradeIndex,
    committedAt,
    eventIds,
  ];
}

/// Stable identity uses JSON arrays before hashing, never delimiter joining.
abstract final class PrayerReviewIdentity {
  static const _assignmentNamespace = 'prayer-review-assignment-v1';
  static const _receiptNamespace = 'prayer-review-receipt-v1';
  static const adultAudience = 'adult';

  static String occurrenceKey({
    required String ownerId,
    required String localDayKey,
    required PrayerKey prayerKey,
  }) => _hash([
    _assignmentNamespace,
    ownerId,
    adultAudience,
    localDayKey,
    prayerKey.name,
  ]);

  static String receiptKey({
    required String ownerId,
    required String localDayKey,
    required int surahId,
    required int startAyah,
    required int endAyah,
  }) => _hash([
    _receiptNamespace,
    ownerId,
    adultAudience,
    localDayKey,
    surahId,
    startAyah,
    endAyah,
  ]);

  static String _hash(List<Object> tuple) =>
      sha256.convert(utf8.encode(jsonEncode(tuple))).toString();
}

/// Shared strict checks for domain values and persisted rows.
abstract final class PrayerReviewValidation {
  static const maxAyahs = 15;
  static const gradeCount = 3;

  static void checkSelection(PrayerReviewSelection selection) {
    _checkOwner(selection.ownerId);
    checkLocalDayKey(selection.localDayKey);
    _checkPrayer(selection.prayerKey);
    _checkUtc(selection.scheduledAt, 'scheduledAt');
    _checkUtc(selection.selectedAt, 'selectedAt');
    if (selection.selectionVersion !=
        PrayerReviewSelection.currentSelectionVersion) {
      throw const FormatException('Unsupported prayer review selection version');
    }
    checkPassage(
      surahId: selection.surahId,
      startAyah: selection.startAyah,
      endAyah: selection.endAyah,
    );
    final expected = PrayerReviewIdentity.occurrenceKey(
      ownerId: selection.ownerId,
      localDayKey: selection.localDayKey,
      prayerKey: selection.prayerKey,
    );
    if (selection.occurrenceKey != expected) {
      throw const FormatException('Invalid prayer review occurrence key');
    }
  }

  static void checkReceipt(PrayerReviewReceipt receipt) {
    _checkOwner(receipt.ownerId);
    checkLocalDayKey(receipt.localDayKey);
    checkPassage(
      surahId: receipt.surahId,
      startAyah: receipt.startAyah,
      endAyah: receipt.endAyah,
    );
    if (receipt.gradeIndex < 0 || receipt.gradeIndex >= gradeCount) {
      throw const FormatException('Invalid prayer review grade');
    }
    _checkUtc(receipt.committedAt, 'committedAt');
    if (receipt.eventIds.length != receipt.endAyah - receipt.startAyah + 1 ||
        receipt.eventIds.any((id) => id.isEmpty) ||
        receipt.eventIds.toSet().length != receipt.eventIds.length) {
      throw const FormatException('Invalid prayer review event ids');
    }
    final expected = PrayerReviewIdentity.receiptKey(
      ownerId: receipt.ownerId,
      localDayKey: receipt.localDayKey,
      surahId: receipt.surahId,
      startAyah: receipt.startAyah,
      endAyah: receipt.endAyah,
    );
    if (receipt.receiptKey != expected) {
      throw const FormatException('Invalid prayer review receipt key');
    }
  }

  static void checkLocalDayKey(String value) {
    final match = RegExp(r'^([0-9]{4})-([0-9]{2})-([0-9]{2})$').firstMatch(value);
    if (match == null) throw const FormatException('Invalid local day key');
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (year < 1900 || year > 9999) {
      throw const FormatException('Invalid local day key');
    }
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw const FormatException('Invalid local day key');
    }
  }

  static void checkPassage({
    required int surahId,
    required int startAyah,
    required int endAyah,
  }) {
    final ayahCount = SurahNames.ayahCount(surahId);
    if (ayahCount == 0 ||
        startAyah < 1 ||
        endAyah < startAyah ||
        endAyah > ayahCount ||
        endAyah - startAyah + 1 > maxAyahs) {
      throw const FormatException('Invalid prayer review passage');
    }
  }

  static PrayerKey prayerKeyFromIndex(int index) {
    if (index < 0 || index >= PrayerKey.values.length) {
      throw const FormatException('Invalid prayer key');
    }
    return PrayerKey.values[index];
  }

  static void _checkOwner(String value) {
    if (value.isEmpty) throw const FormatException('Invalid owner');
  }

  static void _checkPrayer(PrayerKey value) {
    if (!PrayerKey.values.contains(value)) {
      throw const FormatException('Invalid prayer key');
    }
  }

  static void _checkUtc(DateTime value, String field) {
    if (!value.isUtc) throw FormatException('$field must be UTC');
  }
}
