import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/prayer_companion/data/datasources/prayer_companion_preferences.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_companion/domain/repositories/prayer_companion_repository.dart';
import 'package:talia_quran/features/prayer_companion/domain/services/prayer_companion_scheduler_planner.dart';

class MockPrayerTimesService extends Mock implements PrayerTimesService {}

class InMemoryPrayerCompanionRepository implements PrayerCompanionRepository {
  final Map<String, PrayerCompanionRecord> records = {};
  var saveCalls = 0;

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
    saveCalls++;
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

  const defaultTimes = <PrayerKey, (int, int)>{
    PrayerKey.fajr: (5, 0),
    PrayerKey.dhuhr: (12, 0),
    PrayerKey.asr: (15, 30),
    PrayerKey.maghrib: (18, 30),
    PrayerKey.isha: (20, 0),
  };

  List<({String key, String nameAr, String nameEn, DateTime time})> timesFor(
    DateTime date,
  ) {
    final d = DateTime(date.year, date.month, date.day);
    return [
      for (final key in PrayerKey.values)
        (
          key: key.name,
          nameAr: key.name,
          nameEn: key.name,
          time: DateTime(
            d.year,
            d.month,
            d.day,
            defaultTimes[key]!.$1,
            defaultTimes[key]!.$2,
          ),
        ),
    ];
  }

  PrayerCompanionRecord recordFor(
    PrayerKey prayerKey,
    PrayerCompanionStatus status, {
    DateTime? localDate,
    DateTime? followUpAt,
    int followUpCount = 0,
  }) {
    final date = localDate ?? day;
    final time = DateTime(
      date.year,
      date.month,
      date.day,
      defaultTimes[prayerKey]!.$1,
      defaultTimes[prayerKey]!.$2,
    );
    final now = DateTime(2026, 9, 16, 9);
    return PrayerCompanionRecord(
      occurrence: PrayerOccurrence(
        ownerId: ownerId,
        localDate: date,
        prayerKey: prayerKey,
        scheduledAt: time,
      ),
      status: status,
      statusUpdatedAt: now,
      followUpAt: followUpAt,
      followUpCount: followUpCount,
      createdAt: now,
      updatedAt: now,
    );
  }

  late MockPrayerTimesService prayerTimes;
  late InMemoryPrayerCompanionRepository repository;
  late SharedPreferences prefs;
  late PrayerCompanionPreferences preferences;

  setUpAll(() {
    registerFallbackValue(DateTime(2000));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prayerTimes = MockPrayerTimesService();
    repository = InMemoryPrayerCompanionRepository();
    prefs = await SharedPreferences.getInstance();
    preferences = PrayerCompanionPreferences(prefs);
    when(() => prayerTimes.timesForDate(any())).thenAnswer(
      (invocation) async =>
          timesFor(invocation.positionalArguments.first as DateTime),
    );
  });

  Future<void> enableCompanion({
    int preparationMinutes = 10,
    bool checkInEnabled = true,
    bool followUpEnabled = true,
  }) {
    return preferences.write(
      PrayerCompanionSettings(
        enabled: true,
        preparationMinutes: preparationMinutes,
        checkInEnabled: checkInEnabled,
        followUpEnabled: followUpEnabled,
      ),
    );
  }

  PrayerCompanionPlanner buildPlanner() => PrayerCompanionPlanner(
    prayerTimesService: prayerTimes,
    preferences: preferences,
    repository: repository,
    prefs: Future.value(prefs),
    owner: const FixedRecordOwnerProvider(ownerId),
  );

  group('PrayerCompanionPlanner.plan', () {
    test(
      'two-day plan has preparation and check-in for every enabled prayer',
      () async {
        await enableCompanion();
        final plan = await buildPlanner().plan(now: DateTime(2026, 9, 16, 4));
        expect(
          plan.where(
            (e) => e.kind == PrayerCompanionNotificationKind.preparation,
          ),
          hasLength(10),
        );
        expect(
          plan.where((e) => e.kind == PrayerCompanionNotificationKind.checkIn),
          hasLength(10),
        );
      },
    );

    test('companion disabled yields an empty plan', () async {
      // Default preferences: Companion off.
      expect(await buildPlanner().plan(now: DateTime(2026, 9, 16, 4)), isEmpty);
    });

    test('preparation disabled produces no preparation events', () async {
      await enableCompanion(preparationMinutes: 0);
      final plan = await buildPlanner().plan(now: DateTime(2026, 9, 16, 4));
      expect(
        plan.where(
          (e) => e.kind == PrayerCompanionNotificationKind.preparation,
        ),
        isEmpty,
      );
      expect(
        plan.where((e) => e.kind == PrayerCompanionNotificationKind.checkIn),
        hasLength(10),
      );
    });

    test('check-in disabled produces no check-in events', () async {
      await enableCompanion(checkInEnabled: false);
      final plan = await buildPlanner().plan(now: DateTime(2026, 9, 16, 4));
      expect(
        plan.where((e) => e.kind == PrayerCompanionNotificationKind.checkIn),
        isEmpty,
      );
      expect(
        plan.where(
          (e) => e.kind == PrayerCompanionNotificationKind.preparation,
        ),
        hasLength(10),
      );
    });

    test(
      'disabled prayer with a pending follow-up has no event at all',
      () async {
        await prefs.setBool(TaliaNotificationService.prayerAsrKey, false);
        await enableCompanion();
        await repository.save(
          recordFor(
            PrayerKey.asr,
            PrayerCompanionStatus.remindLater,
            followUpAt: DateTime(2026, 9, 16, 15, 45),
            followUpCount: 1,
          ),
        );
        final plan = await buildPlanner().plan(
          now: DateTime(2026, 9, 16, 15, 31),
        );
        // The per-prayer skip suppresses prep, check-in, AND follow-up.
        expect(
          plan.where((e) => e.occurrence.prayerKey == PrayerKey.asr),
          isEmpty,
        );
      },
    );

    test('individually disabled prayer is excluded from the plan', () async {
      await prefs.setBool(TaliaNotificationService.prayerAsrKey, false);
      await enableCompanion();
      final plan = await buildPlanner().plan(now: DateTime(2026, 9, 16, 4));
      expect(
        plan.where((e) => e.occurrence.prayerKey == PrayerKey.asr),
        isEmpty,
      );
      expect(
        plan.where(
          (e) => e.kind == PrayerCompanionNotificationKind.preparation,
        ),
        hasLength(8),
      );
    });

    test('confirmed occurrence has no Companion event', () async {
      await enableCompanion();
      final asr = recordFor(PrayerKey.asr, PrayerCompanionStatus.confirmed);
      await repository.save(asr);
      final plan = await buildPlanner().plan(now: DateTime(2026, 9, 16, 4));
      expect(
        plan.where(
          (e) => e.occurrence.occurrenceKey == asr.occurrence.occurrenceKey,
        ),
        isEmpty,
      );
      expect(
        plan.where(
          (e) => e.kind == PrayerCompanionNotificationKind.preparation,
        ),
        hasLength(9),
      );
    });

    test('non-confirmed records still get planned events', () async {
      await enableCompanion();
      await repository.save(
        recordFor(PrayerKey.dhuhr, PrayerCompanionStatus.notYet),
      );
      final plan = await buildPlanner().plan(now: DateTime(2026, 9, 16, 4));
      expect(
        plan.where(
          (e) =>
              e.occurrence.prayerKey == PrayerKey.dhuhr &&
              e.occurrence.localDate.day == 17,
        ),
        hasLength(2),
      );
    });

    test('elapsed events are skipped', () async {
      await enableCompanion();
      final now = DateTime(2026, 9, 16, 16, 10);
      final plan = await buildPlanner().plan(now: now);
      // Today's fajr and dhuhr events plus asr's preparation (15:20) and
      // check-in (15:50) have elapsed; maghrib and isha remain.
      expect(
        plan.where(
          (e) => e.kind == PrayerCompanionNotificationKind.preparation,
        ),
        hasLength(7),
      );
      expect(
        plan.where((e) => e.kind == PrayerCompanionNotificationKind.checkIn),
        hasLength(7),
      );
      expect(plan.every((e) => e.scheduledAt.isAfter(now)), isTrue);
    });

    test(
      'planned IDs follow the documented formula and times are derived',
      () async {
        await enableCompanion();
        final plan = await buildPlanner().plan(now: DateTime(2026, 9, 16, 4));
        final fajrPrepToday = plan.singleWhere(
          (e) =>
              e.occurrence.prayerKey == PrayerKey.fajr &&
              e.occurrence.localDate.day == 16 &&
              e.kind == PrayerCompanionNotificationKind.preparation,
        );
        expect(fajrPrepToday.id, 2100);
        expect(fajrPrepToday.scheduledAt, DateTime(2026, 9, 16, 4, 50));
        final ishaCheckInTomorrow = plan.singleWhere(
          (e) =>
              e.occurrence.prayerKey == PrayerKey.isha &&
              e.occurrence.localDate.day == 17 &&
              e.kind == PrayerCompanionNotificationKind.checkIn,
        );
        expect(ishaCheckInTomorrow.id, 2119);
        expect(ishaCheckInTomorrow.scheduledAt, DateTime(2026, 9, 17, 20, 20));
        // Plan-wide uniqueness guard against future ID collisions.
        expect(plan.map((e) => e.id).toSet().length, plan.length);
      },
    );

    test('persisted follow-up appears once within the window', () async {
      await enableCompanion();
      await repository.save(
        recordFor(
          PrayerKey.asr,
          PrayerCompanionStatus.remindLater,
          followUpAt: DateTime(2026, 9, 16, 15, 45),
          followUpCount: 1,
        ),
      );
      final plan = await buildPlanner().plan(
        now: DateTime(2026, 9, 16, 15, 31),
      );
      final followUps = plan
          .where((e) => e.kind == PrayerCompanionNotificationKind.followUp)
          .toList();
      expect(followUps, hasLength(1));
      final followUp = followUps.single;
      expect(followUp.scheduledAt, DateTime(2026, 9, 16, 15, 45));
      // Follow-up ID: 2120 + dayOffset * 5 + prayerIndex (asr = 2).
      expect(followUp.id, 2122);
      expect(followUp.occurrence.prayerKey, PrayerKey.asr);
    });

    test('elapsed follow-up is skipped', () async {
      await enableCompanion();
      await repository.save(
        recordFor(
          PrayerKey.asr,
          PrayerCompanionStatus.remindLater,
          followUpAt: DateTime(2026, 9, 16, 15, 45),
          followUpCount: 1,
        ),
      );
      final plan = await buildPlanner().plan(
        now: DateTime(2026, 9, 16, 15, 46),
      );
      expect(
        plan.where((e) => e.kind == PrayerCompanionNotificationKind.followUp),
        isEmpty,
      );
    });

    test(
      'follow-up at or after the next obligatory prayer is skipped',
      () async {
        await enableCompanion();
        await repository.save(
          recordFor(
            PrayerKey.asr,
            PrayerCompanionStatus.remindLater,
            // Maghrib is at 18:30 â€” a 18:30 follow-up is not strictly before.
            followUpAt: DateTime(2026, 9, 16, 18, 30),
            followUpCount: 1,
          ),
        );
        final plan = await buildPlanner().plan(now: DateTime(2026, 9, 16, 16));
        expect(
          plan.where((e) => e.kind == PrayerCompanionNotificationKind.followUp),
          isEmpty,
        );
      },
    );

    test('follow-up beyond the two-day window is skipped', () async {
      await enableCompanion();
      await repository.save(
        recordFor(
          PrayerKey.fajr,
          PrayerCompanionStatus.prayNow,
          localDate: DateTime(2026, 9, 18),
          followUpAt: DateTime(2026, 9, 18, 6),
          followUpCount: 1,
        ),
      );
      final plan = await buildPlanner().plan(now: DateTime(2026, 9, 16, 4));
      expect(
        plan.where((e) => e.kind == PrayerCompanionNotificationKind.followUp),
        isEmpty,
      );
    });

    test('follow-up disabled produces no follow-up events', () async {
      await enableCompanion(followUpEnabled: false);
      await repository.save(
        recordFor(
          PrayerKey.asr,
          PrayerCompanionStatus.remindLater,
          followUpAt: DateTime(2026, 9, 16, 15, 45),
          followUpCount: 1,
        ),
      );
      final plan = await buildPlanner().plan(
        now: DateTime(2026, 9, 16, 15, 31),
      );
      expect(
        plan.where((e) => e.kind == PrayerCompanionNotificationKind.followUp),
        isEmpty,
      );
    });

    test('planner reads records but never writes them', () async {
      await enableCompanion();
      await buildPlanner().plan(now: DateTime(2026, 9, 16, 4));
      expect(repository.saveCalls, 0);
      expect(repository.records, isEmpty);
    });
  });
}
