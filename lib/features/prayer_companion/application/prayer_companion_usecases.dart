import '../../../../core/identity/record_owner_provider.dart';
import '../domain/entities/prayer_companion.dart';
import '../domain/repositories/prayer_companion_repository.dart';
import '../domain/services/prayer_companion_policy.dart';

/// Applies a single explicit user command to one prayer occurrence.
///
/// The use case delegates all transition rules to the policy, persists the
/// resulting record through the repository, and returns the saved record.
/// Follow-up notification rescheduling is handled by the notification
/// response controller, not here.
class ApplyPrayerCompanionCommand {
  const ApplyPrayerCompanionCommand(this._repository, this._policy);

  final PrayerCompanionRepository _repository;
  final PrayerCompanionPolicy _policy;

  Future<PrayerCompanionRecord> call({
    required PrayerOccurrence occurrence,
    required PrayerCompanionCommand command,
    required DateTime now,
    DateTime? nextPrayerAt,
  }) async {
    final existing = await _repository.read(occurrence);
    final transition = _policy.apply(
      existing: existing,
      occurrence: occurrence,
      command: command,
      now: now,
      nextPrayerAt: nextPrayerAt,
    );
    return _repository.save(transition.record);
  }
}

/// Builds the compact per-day projection shown in the prayer-times sheet.
///
/// Statuses are derived through the policy (never persisted by this use
/// case), [PrayerCompanionDaySummary.confirmedCount] counts only confirmed
/// records, and the actionable occurrence is the most recent prayer whose
/// time has passed, whose window (until the next prayer) contains `now`, and
/// whose status is not confirmed.
class GetPrayerCompanionDaySummary {
  const GetPrayerCompanionDaySummary(this._repository, this._owner);

  final PrayerCompanionRepository _repository;
  final RecordOwnerProvider _owner;

  static const _policy = PrayerCompanionPolicy();

  Future<PrayerCompanionDaySummary> call({
    required DateTime localDate,
    required List<({PrayerKey key, DateTime time})> prayerTimes,
    required DateTime now,
  }) async {
    final ownerId = _owner.currentOwnerId;
    final date = DateTime(localDate.year, localDate.month, localDate.day);
    final records = await _repository.readDay(
      ownerId: ownerId,
      localDate: date,
    );

    final statusByPrayer = <PrayerKey, PrayerCompanionStatus>{};
    var confirmedCount = 0;
    PrayerOccurrence? actionable;

    final entries = List<({PrayerKey key, DateTime time})>.of(prayerTimes)
      ..sort((a, b) => a.time.compareTo(b.time));

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final record = records[entry.key];
      final occurrence = PrayerOccurrence(
        ownerId: ownerId,
        localDate: date,
        prayerKey: entry.key,
        scheduledAt: entry.time,
      );
      final status = _policy.statusFor(
        occurrence: occurrence,
        record: record,
        now: now,
      );
      statusByPrayer[entry.key] = status;
      if (status == PrayerCompanionStatus.confirmed) confirmedCount++;

      final windowEnd = i + 1 < entries.length ? entries[i + 1].time : null;
      final inWindow =
          !now.isBefore(entry.time) &&
          (windowEnd == null || now.isBefore(windowEnd));
      if (inWindow && status != PrayerCompanionStatus.confirmed) {
        actionable = occurrence;
      }
    }

    return PrayerCompanionDaySummary(
      statusByPrayer: statusByPrayer,
      confirmedCount: confirmedCount,
      actionableOccurrence: actionable,
    );
  }
}
