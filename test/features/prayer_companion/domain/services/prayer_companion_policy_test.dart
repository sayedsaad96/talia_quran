import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_companion/domain/services/prayer_companion_policy.dart';

void main() {
  const policy = PrayerCompanionPolicy();

  const ownerId = 'owner-a';
  final day = DateTime(2026, 9, 16);
  final at1505 = DateTime(2026, 9, 16, 15, 5);
  final at1506 = DateTime(2026, 9, 16, 15, 6);
  final at1521 = DateTime(2026, 9, 16, 15, 21);

  PrayerOccurrence occurrenceFor(
    PrayerKey key,
    DateTime scheduledAt, {
    DateTime? localDate,
  }) {
    return PrayerOccurrence(
      ownerId: ownerId,
      localDate: localDate ?? day,
      prayerKey: key,
      scheduledAt: scheduledAt,
    );
  }

  final asr = occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15, 0));

  group('makeOccurrenceKey', () {
    test('combines owner, civil date, and prayer key', () {
      expect(
        makeOccurrenceKey(ownerId, DateTime(2026, 9, 16), PrayerKey.asr),
        'owner-a|2026-09-16|asr',
      );
    });

    test('ignores the time portion of the local date', () {
      expect(
        makeOccurrenceKey(
          ownerId,
          DateTime(2026, 9, 16, 23, 45),
          PrayerKey.isha,
        ),
        makeOccurrenceKey(ownerId, DateTime(2026, 9, 16), PrayerKey.isha),
      );
    });

    test('differs per owner and per prayer', () {
      expect(
        makeOccurrenceKey('owner-b', day, PrayerKey.asr),
        isNot(asr.occurrenceKey),
      );
      expect(
        makeOccurrenceKey(ownerId, day, PrayerKey.dhuhr),
        isNot(asr.occurrenceKey),
      );
    });
  });

  group('confirm', () {
    test('confirmation is terminal and idempotent', () {
      final first = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.confirm,
        now: at1505,
      );
      final second = policy.apply(
        existing: first.record,
        occurrence: asr,
        command: PrayerCompanionCommand.confirm,
        now: at1506,
      );
      expect(first.record.status, PrayerCompanionStatus.confirmed);
      expect(first.shouldCancelFollowUp, isTrue);
      expect(second.record, same(first.record));
    });

    test('confirm clears a pending follow-up', () {
      final reminded = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.remindLater,
        now: at1505,
        nextPrayerAt: DateTime(2026, 9, 16, 18),
      );
      final confirmed = policy.apply(
        existing: reminded.record,
        occurrence: asr,
        command: PrayerCompanionCommand.confirm,
        now: at1506,
      );
      expect(confirmed.record.followUpAt, isNull);
      expect(confirmed.record.followUpCount, 0);
      expect(confirmed.shouldCancelFollowUp, isTrue);
      expect(confirmed.shouldScheduleFollowUp, isFalse);
    });

    test('confirm preserves the original createdAt', () {
      final first = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.notYet,
        now: at1505,
      );
      final confirmed = policy.apply(
        existing: first.record,
        occurrence: asr,
        command: PrayerCompanionCommand.confirm,
        now: at1506,
      );
      expect(confirmed.record.createdAt, at1505);
      expect(confirmed.record.updatedAt, at1506);
      expect(confirmed.record.statusUpdatedAt, at1506);
    });
  });

  group('prayNow', () {
    test('creates one 15-minute follow-up before next prayer', () {
      final result = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.prayNow,
        now: at1505,
        nextPrayerAt: DateTime(2026, 9, 16, 18),
      );
      expect(result.record.status, PrayerCompanionStatus.prayNow);
      expect(result.record.followUpAt, DateTime(2026, 9, 16, 15, 20));
      expect(result.record.followUpCount, 1);
      expect(result.shouldScheduleFollowUp, isTrue);
      expect(result.shouldCancelFollowUp, isFalse);
    });
  });

  group('remindLater', () {
    test('remind later creates one 10-minute follow-up before next prayer', () {
      final result = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.remindLater,
        now: at1505,
        nextPrayerAt: DateTime(2026, 9, 16, 18),
      );
      expect(result.record.status, PrayerCompanionStatus.remindLater);
      expect(result.record.followUpAt, DateTime(2026, 9, 16, 15, 15));
      expect(result.record.followUpCount, 1);
    });
  });

  group('notYet', () {
    test('records notYet without an automatic follow-up', () {
      final result = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.notYet,
        now: at1505,
        nextPrayerAt: DateTime(2026, 9, 16, 18),
      );
      expect(result.record.status, PrayerCompanionStatus.notYet);
      expect(result.record.followUpAt, isNull);
      expect(result.record.followUpCount, 0);
      expect(result.shouldScheduleFollowUp, isFalse);
      expect(result.shouldCancelFollowUp, isTrue);
    });
  });

  group('clear', () {
    test('clear resets the occurrence to unconfirmed and clears follow-up', () {
      final reminded = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.remindLater,
        now: at1505,
        nextPrayerAt: DateTime(2026, 9, 16, 18),
      );
      final cleared = policy.apply(
        existing: reminded.record,
        occurrence: asr,
        command: PrayerCompanionCommand.clear,
        now: at1506,
      );
      expect(cleared.record.status, PrayerCompanionStatus.unconfirmed);
      expect(cleared.record.followUpAt, isNull);
      expect(cleared.record.followUpCount, 0);
      expect(cleared.shouldCancelFollowUp, isTrue);
      expect(cleared.shouldScheduleFollowUp, isFalse);
    });
  });

  group('one-follow-up limit', () {
    test('duplicate follow-up attempts schedule nothing', () {
      final first = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.remindLater,
        now: at1505,
        nextPrayerAt: DateTime(2026, 9, 16, 18),
      );
      final second = policy.apply(
        existing: first.record,
        occurrence: asr,
        command: PrayerCompanionCommand.prayNow,
        now: at1521,
        nextPrayerAt: DateTime(2026, 9, 16, 18),
      );
      expect(second.record.status, PrayerCompanionStatus.prayNow);
      expect(second.record.followUpAt, isNull);
      expect(second.record.followUpCount, 0);
      expect(second.shouldScheduleFollowUp, isFalse);
      expect(second.shouldCancelFollowUp, isTrue);
    });
  });

  group('next-prayer suppression', () {
    test('follow-up is suppressed when it lands at the next prayer', () {
      final result = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.remindLater,
        now: at1505,
        nextPrayerAt: DateTime(2026, 9, 16, 15, 15),
      );
      expect(result.record.followUpAt, isNull);
      expect(result.record.followUpCount, 0);
      expect(result.shouldScheduleFollowUp, isFalse);
    });

    test('follow-up is suppressed when it lands after the next prayer', () {
      final result = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.prayNow,
        now: at1505,
        nextPrayerAt: DateTime(2026, 9, 16, 15, 10),
      );
      expect(result.record.followUpAt, isNull);
      expect(result.shouldScheduleFollowUp, isFalse);
      expect(result.shouldCancelFollowUp, isTrue);
    });

    test('follow-up is scheduled when next prayer is unknown', () {
      final result = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.remindLater,
        now: at1505,
      );
      expect(result.record.followUpAt, DateTime(2026, 9, 16, 15, 15));
      expect(result.shouldScheduleFollowUp, isTrue);
    });
  });

  group('Isha/Fajr date boundaries', () {
    test('late Isha follow-up stays on its own civil day and is scheduled', () {
      final isha = occurrenceFor(PrayerKey.isha, DateTime(2026, 9, 16, 20, 30));
      final now = DateTime(2026, 9, 16, 23, 50);
      final nextFajr = DateTime(2026, 9, 17, 4, 30);
      final result = policy.apply(
        existing: null,
        occurrence: isha,
        command: PrayerCompanionCommand.remindLater,
        now: now,
        nextPrayerAt: nextFajr,
      );
      expect(result.record.followUpAt, DateTime(2026, 9, 17, 0, 0));
      expect(result.shouldScheduleFollowUp, isTrue);
      // The occurrence key still belongs to Isha's civil day.
      expect(result.record.occurrence.occurrenceKey, 'owner-a|2026-09-16|isha');
    });

    test('late Isha follow-up is suppressed when next Fajr comes first', () {
      final isha = occurrenceFor(PrayerKey.isha, DateTime(2026, 9, 16, 20, 30));
      final now = DateTime(2026, 9, 16, 23, 55);
      final nextFajr = DateTime(2026, 9, 17, 0, 3);
      final result = policy.apply(
        existing: null,
        occurrence: isha,
        command: PrayerCompanionCommand.remindLater,
        now: now,
        nextPrayerAt: nextFajr,
      );
      expect(result.record.followUpAt, isNull);
      expect(result.shouldScheduleFollowUp, isFalse);
    });

    test('next-day Fajr is a distinct occurrence from the previous day', () {
      final fajr = occurrenceFor(
        PrayerKey.fajr,
        DateTime(2026, 9, 17, 4, 30),
        localDate: DateTime(2026, 9, 17),
      );
      final result = policy.apply(
        existing: null,
        occurrence: fajr,
        command: PrayerCompanionCommand.confirm,
        now: DateTime(2026, 9, 17, 4, 45),
      );
      expect(result.record.occurrence.occurrenceKey, 'owner-a|2026-09-17|fajr');
      expect(result.record.status, PrayerCompanionStatus.confirmed);
    });
  });

  group('statusFor', () {
    test('unanswered occurrence is unconfirmed and never notYet', () {
      expect(
        policy.statusFor(occurrence: asr, record: null, now: at1521),
        PrayerCompanionStatus.unconfirmed,
      );
    });

    test('returns the persisted status for a stored record', () {
      final confirmed = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.confirm,
        now: at1505,
      );
      expect(
        policy.statusFor(
          occurrence: asr,
          record: confirmed.record,
          now: at1521,
        ),
        PrayerCompanionStatus.confirmed,
      );
    });
  });

  group('follow-up expiry', () {
    test('expired follow-up is cleared without changing the status', () {
      final reminded = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.remindLater,
        now: at1505,
        nextPrayerAt: DateTime(2026, 9, 16, 18),
      );
      final expired = policy.expireFollowUp(
        record: reminded.record,
        now: DateTime(2026, 9, 16, 15, 16),
      );
      expect(expired, isNotNull);
      expect(expired!.followUpAt, isNull);
      expect(expired.status, PrayerCompanionStatus.remindLater);
      expect(policy.expireFollowUp(record: expired, now: at1521), isNull);
    });

    test('non-expired follow-up is left untouched', () {
      final reminded = policy.apply(
        existing: null,
        occurrence: asr,
        command: PrayerCompanionCommand.remindLater,
        now: at1505,
        nextPrayerAt: DateTime(2026, 9, 16, 18),
      );
      expect(
        policy.expireFollowUp(record: reminded.record, now: at1506),
        isNull,
      );
    });
  });

  group('PrayerCompanionDaySummary', () {
    test('only confirmed counts in a summary', () {
      const summary = PrayerCompanionDaySummary(
        statusByPrayer: {
          PrayerKey.fajr: PrayerCompanionStatus.confirmed,
          PrayerKey.dhuhr: PrayerCompanionStatus.notYet,
          PrayerKey.asr: PrayerCompanionStatus.prayNow,
          PrayerKey.maghrib: PrayerCompanionStatus.remindLater,
        },
        confirmedCount: 1,
      );
      expect(summary.confirmedCount, 1);
      expect(
        summary.statusByPrayer.values
            .where((s) => s == PrayerCompanionStatus.confirmed)
            .length,
        summary.confirmedCount,
      );
      expect(summary.actionableOccurrence, isNull);
    });
  });

  group('PrayerCompanionSettings', () {
    test('companion defaults off with neutral defaults', () {
      const settings = PrayerCompanionSettings();
      expect(settings.enabled, isFalse);
      expect(settings.preparationMinutes, 10);
      expect(settings.checkInEnabled, isTrue);
      expect(settings.followUpEnabled, isTrue);
    });
  });
}
