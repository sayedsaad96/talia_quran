import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/prayer_companion/application/prayer_companion_usecases.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_companion/domain/repositories/prayer_companion_repository.dart';
import 'package:talia_quran/features/prayer_companion/domain/services/prayer_companion_policy.dart';

class InMemoryPrayerCompanionRepository implements PrayerCompanionRepository {
  final Map<String, PrayerCompanionRecord> records = {};

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<PrayerCompanionRecord?> read(PrayerOccurrence occurrence) async =>
      records[occurrence.occurrenceKey];

  @override
  Future<Map<PrayerKey, PrayerCompanionRecord>> readDay({
    required String ownerId,
    required DateTime localDate,
  }) async {
    final result = <PrayerKey, PrayerCompanionRecord>{};
    for (final record in records.values) {
      final occurrence = record.occurrence;
      if (occurrence.ownerId != ownerId) continue;
      if (occurrence.localDate.year == localDate.year &&
          occurrence.localDate.month == localDate.month &&
          occurrence.localDate.day == localDate.day) {
        result[occurrence.prayerKey] = record;
      }
    }
    return result;
  }

  @override
  Future<PrayerCompanionRecord> save(PrayerCompanionRecord record) async {
    records[record.occurrence.occurrenceKey] = record;
    return record;
  }

  @override
  Future<void> clearOwner(String ownerId) async {
    records.removeWhere((key, _) => key.startsWith('$ownerId|'));
  }
}

void main() {
  const ownerId = 'owner-a';
  final day = DateTime(2026, 9, 16);
  final at1505 = DateTime(2026, 9, 16, 15, 5);

  PrayerOccurrence occurrenceFor(PrayerKey key, DateTime scheduledAt) {
    return PrayerOccurrence(
      ownerId: ownerId,
      localDate: day,
      prayerKey: key,
      scheduledAt: scheduledAt,
    );
  }

  List<({PrayerKey key, DateTime time})> defaultPrayerTimes() => [
    (key: PrayerKey.fajr, time: DateTime(2026, 9, 16, 5)),
    (key: PrayerKey.dhuhr, time: DateTime(2026, 9, 16, 12)),
    (key: PrayerKey.asr, time: DateTime(2026, 9, 16, 15)),
    (key: PrayerKey.maghrib, time: DateTime(2026, 9, 16, 18, 30)),
    (key: PrayerKey.isha, time: DateTime(2026, 9, 16, 20)),
  ];

  PrayerCompanionRecord recordFor(PrayerKey key, PrayerCompanionStatus status) {
    final time = defaultPrayerTimes().firstWhere((e) => e.key == key).time;
    return PrayerCompanionRecord(
      occurrence: occurrenceFor(key, time),
      status: status,
      statusUpdatedAt: at1505,
      followUpCount: 0,
      createdAt: at1505,
      updatedAt: at1505,
    );
  }

  late InMemoryPrayerCompanionRepository repository;

  setUp(() {
    repository = InMemoryPrayerCompanionRepository();
  });

  group('ApplyPrayerCompanionCommand', () {
    late ApplyPrayerCompanionCommand useCase;

    setUp(() {
      useCase = ApplyPrayerCompanionCommand(
        repository,
        const PrayerCompanionPolicy(),
        const FixedRecordOwnerProvider(ownerId),
      );
    });

    test(
      'applies the policy, persists, and returns the saved record',
      () async {
        final asr = occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15));
        final saved = await useCase(
          occurrence: asr,
          command: PrayerCompanionCommand.confirm,
          now: at1505,
        );
        expect(saved.status, PrayerCompanionStatus.confirmed);
        expect(saved.statusUpdatedAt, at1505);
        expect(repository.records[asr.occurrenceKey], saved);
      },
    );

    test('updates an existing record instead of duplicating it', () async {
      final asr = occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15));
      await useCase(
        occurrence: asr,
        command: PrayerCompanionCommand.remindLater,
        now: at1505,
        nextPrayerAt: DateTime(2026, 9, 16, 18, 30),
      );
      final second = await useCase(
        occurrence: asr,
        command: PrayerCompanionCommand.confirm,
        now: DateTime(2026, 9, 16, 15, 6),
      );
      expect(repository.records.length, 1);
      expect(second.status, PrayerCompanionStatus.confirmed);
      // The original creation timestamp is preserved.
      expect(second.createdAt, at1505);
    });

    test('schedules a follow-up only before the next prayer', () async {
      final asr = occurrenceFor(PrayerKey.asr, DateTime(2026, 9, 16, 15));
      final saved = await useCase(
        occurrence: asr,
        command: PrayerCompanionCommand.remindLater,
        now: at1505,
        nextPrayerAt: DateTime(2026, 9, 16, 18, 30),
      );
      expect(saved.followUpAt, DateTime(2026, 9, 16, 15, 15));
      expect(saved.followUpCount, 1);

      final late = await useCase(
        occurrence: occurrenceFor(
          PrayerKey.maghrib,
          DateTime(2026, 9, 16, 18, 30),
        ),
        command: PrayerCompanionCommand.remindLater,
        now: DateTime(2026, 9, 16, 18, 31),
        nextPrayerAt: DateTime(2026, 9, 16, 18, 35),
      );
      expect(late.followUpAt, isNull);
      expect(late.followUpCount, 0);
    });
  });

  group('GetPrayerCompanionDaySummary', () {
    late GetPrayerCompanionDaySummary useCase;

    setUp(() {
      useCase = GetPrayerCompanionDaySummary(
        repository,
        const FixedRecordOwnerProvider(ownerId),
      );
    });

    Future<PrayerCompanionDaySummary> summaryAt(DateTime now) =>
        useCase(localDate: day, prayerTimes: defaultPrayerTimes(), now: now);

    test('daily progress counts confirmed records only', () async {
      await repository.save(
        recordFor(PrayerKey.fajr, PrayerCompanionStatus.confirmed),
      );
      await repository.save(
        recordFor(PrayerKey.dhuhr, PrayerCompanionStatus.notYet),
      );
      final summary = await summaryAt(at1505);
      expect(summary.confirmedCount, 1);
      expect(
        summary.statusByPrayer[PrayerKey.fajr],
        PrayerCompanionStatus.confirmed,
      );
      expect(
        summary.statusByPrayer[PrayerKey.dhuhr],
        PrayerCompanionStatus.notYet,
      );
    });

    test('unanswered occurrences derive as unconfirmed', () async {
      final summary = await summaryAt(at1505);
      expect(summary.statusByPrayer.length, 5);
      expect(
        summary.statusByPrayer.values.every(
          (status) => status == PrayerCompanionStatus.unconfirmed,
        ),
        isTrue,
      );
      expect(summary.confirmedCount, 0);
    });

    test('actionable occurrence is the current prayer in its window', () async {
      // 15:05 — asr (15:00) has passed, maghrib (18:30) has not.
      final summary = await summaryAt(at1505);
      expect(summary.actionableOccurrence?.prayerKey, PrayerKey.asr);
    });

    test('confirmed current prayer is no longer actionable', () async {
      await repository.save(
        recordFor(PrayerKey.asr, PrayerCompanionStatus.confirmed),
      );
      final summary = await summaryAt(at1505);
      expect(summary.actionableOccurrence, isNull);
    });

    test('no actionable occurrence before the first prayer', () async {
      final summary = await summaryAt(DateTime(2026, 9, 16, 4));
      expect(summary.actionableOccurrence, isNull);
    });

    test('isha stays actionable until the end of the day', () async {
      final summary = await summaryAt(DateTime(2026, 9, 16, 23));
      expect(summary.actionableOccurrence?.prayerKey, PrayerKey.isha);
    });

    test('isha remains actionable at 23:30 with no record '
        '(civil-date rollover is the intentional V1 cap, spec §4.3)', () async {
      // Isha at 21:00, no record, now 23:30: the Isha window is capped
      // only by the civil-date boundary in V1, so Isha is still actionable.
      final times = <({PrayerKey key, DateTime time})>[
        (key: PrayerKey.fajr, time: DateTime(2026, 9, 16, 5)),
        (key: PrayerKey.dhuhr, time: DateTime(2026, 9, 16, 12)),
        (key: PrayerKey.asr, time: DateTime(2026, 9, 16, 15)),
        (key: PrayerKey.maghrib, time: DateTime(2026, 9, 16, 18, 30)),
        (key: PrayerKey.isha, time: DateTime(2026, 9, 16, 21)),
      ];
      final summary = await useCase(
        localDate: day,
        prayerTimes: times,
        now: DateTime(2026, 9, 16, 23, 30),
      );
      expect(summary.actionableOccurrence?.prayerKey, PrayerKey.isha);
    });
  });
}
