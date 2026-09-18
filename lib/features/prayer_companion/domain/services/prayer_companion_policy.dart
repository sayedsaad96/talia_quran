import 'package:equatable/equatable.dart';

import '../entities/prayer_companion.dart';

/// Result of applying a command: the record to persist plus follow-up
/// scheduling instructions for the notification layer.
class PrayerCompanionTransition extends Equatable {
  const PrayerCompanionTransition({
    required this.record,
    required this.shouldScheduleFollowUp,
    required this.shouldCancelFollowUp,
  });

  final PrayerCompanionRecord record;
  final bool shouldScheduleFollowUp;
  final bool shouldCancelFollowUp;

  @override
  List<Object?> get props => [
    record,
    shouldScheduleFollowUp,
    shouldCancelFollowUp,
  ];
}

/// Pure state-transition rules for the Prayer Companion.
///
/// Only explicit user commands change state. Confirmation is terminal and
/// idempotent; at most one follow-up is ever scheduled per occurrence, and
/// only when it lands strictly before the next prayer.
class PrayerCompanionPolicy {
  const PrayerCompanionPolicy();

  static const Duration prayNowFollowUpDelay = Duration(minutes: 15);
  static const Duration remindLaterFollowUpDelay = Duration(minutes: 10);

  PrayerCompanionTransition apply({
    required PrayerCompanionRecord? existing,
    required PrayerOccurrence occurrence,
    required PrayerCompanionCommand command,
    required DateTime now,
    DateTime? nextPrayerAt,
  }) {
    if (command == PrayerCompanionCommand.confirm &&
        existing?.status == PrayerCompanionStatus.confirmed) {
      return PrayerCompanionTransition(
        record: existing!,
        shouldScheduleFollowUp: false,
        shouldCancelFollowUp: true,
      );
    }
    final candidateFollowUp = switch (command) {
      PrayerCompanionCommand.prayNow => now.add(prayNowFollowUpDelay),
      PrayerCompanionCommand.remindLater => now.add(remindLaterFollowUpDelay),
      _ => null,
    };
    final canScheduleFollowUp =
        candidateFollowUp != null &&
        existing?.followUpCount != 1 &&
        (nextPrayerAt == null || candidateFollowUp.isBefore(nextPrayerAt));
    final status = switch (command) {
      PrayerCompanionCommand.confirm => PrayerCompanionStatus.confirmed,
      PrayerCompanionCommand.prayNow => PrayerCompanionStatus.prayNow,
      PrayerCompanionCommand.remindLater => PrayerCompanionStatus.remindLater,
      PrayerCompanionCommand.notYet => PrayerCompanionStatus.notYet,
      PrayerCompanionCommand.clear => PrayerCompanionStatus.unconfirmed,
    };
    return PrayerCompanionTransition(
      record: PrayerCompanionRecord(
        occurrence: occurrence,
        status: status,
        statusUpdatedAt: now,
        followUpAt: canScheduleFollowUp ? candidateFollowUp : null,
        followUpCount: canScheduleFollowUp ? 1 : 0,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
      shouldScheduleFollowUp: canScheduleFollowUp,
      shouldCancelFollowUp: !canScheduleFollowUp,
    );
  }

  /// Derives the display status without persisting anything. An occurrence
  /// with no record is [PrayerCompanionStatus.unconfirmed], never notYet.
  PrayerCompanionStatus statusFor({
    required PrayerOccurrence occurrence,
    required PrayerCompanionRecord? record,
    required DateTime now,
  }) {
    if (record == null) return PrayerCompanionStatus.unconfirmed;
    return record.status;
  }

  /// Clears an elapsed pending follow-up, returning the updated record, or
  /// null when there is nothing to expire.
  PrayerCompanionRecord? expireFollowUp({
    required PrayerCompanionRecord record,
    required DateTime now,
  }) {
    final followUpAt = record.followUpAt;
    if (followUpAt == null || followUpAt.isAfter(now)) return null;
    return record.copyWith(
      clearFollowUp: true,
      followUpCount: 0,
      updatedAt: now,
    );
  }
}
