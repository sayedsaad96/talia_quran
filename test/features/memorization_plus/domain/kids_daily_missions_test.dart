import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_home_mission.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_daily_missions.dart';

void main() {
  final now = DateTime(2026, 10, 2, 10);
  const learning = KidsNextMission(
    type: KidsMissionType.newMemorization,
    surahId: 114,
    ayahNumbers: [1],
  );
  KidsHomeMission home(
    String id, {
    KidsHomeMissionStatus status = KidsHomeMissionStatus.assigned,
    DateTime? reportedAt,
  }) => KidsHomeMission(
    id: id,
    title: 'Task $id',
    status: status,
    createdAt: DateTime(2026, 10, int.parse(id)),
    reportedAt: reportedAt,
  );
  KidsSessionLog log({
    DateTime? at,
    int points = 10,
    int repeats = 2,
    KidsMissionType type = KidsMissionType.newMemorization,
    int hints = 0,
  }) => KidsSessionLog(
    id: 'log',
    surahId: 114,
    ayahNumber: 1,
    repeatsCompleted: repeats,
    pointsEarned: points,
    completedAt: at ?? now,
    missionType: type,
    hintCount: hints,
  );
  List<KidsDailyMission> resolve({
    DateTime? at,
    KidsNextMission? mission = learning,
    List<KidsHomeMission> homes = const [],
    List<KidsSessionLog> logs = const [],
    Set<int> pages = const {},
    int readingDays = 0,
    int cap = 3,
    bool reading = true,
  }) => resolveKidsDailyMissions(
    now: at ?? now,
    learning: mission,
    dayGoalReached: mission == null,
    logs: logs,
    pagesReadToday: pages,
    homeMissions: homes,
    recentReadingDays: readingDays,
    maxMissions: cap,
    readingAvailable: reading,
  );

  test('guardian assignments replace suggestions and are oldest first', () {
    final cards = resolve(homes: [home('3'), home('1'), home('2')]);
    expect(cards.map((m) => m.homeMissionId), ['1', '2', '3']);
    expect(cards.every((m) => m.kind == KidsDailyMissionKind.home), isTrue);
    expect(
      cards.every((m) => m.status == KidsDailyMissionStatus.available),
      isTrue,
    );
  });
  test('suggestion cap never hides an explicit guardian assignment', () {
    for (final cap in [0, 1, 2]) {
      expect(
        resolve(homes: [home('1'), home('2'), home('3')], cap: cap),
        hasLength(3),
      );
    }
  });
  test(
    'reported today remains done beside pending assignments without duplicates',
    () {
      final done = home(
        '1',
        status: KidsHomeMissionStatus.acknowledged,
        reportedAt: now,
      );
      final cards = resolve(homes: [done, home('2'), done]);
      expect(cards.map((m) => m.homeMissionId), ['2', '1']);
      expect(cards.last.status, KidsDailyMissionStatus.completed);
      expect(cards.last.homeMissionTitle, 'Task 1');
    },
  );
  test('old completed guardian tasks allow daily suggestions', () {
    final cards = resolve(
      homes: [
        home(
          '1',
          status: KidsHomeMissionStatus.reported,
          reportedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
    );
    expect(cards.any((m) => m.kind == KidsDailyMissionKind.home), isFalse);
    expect(cards, hasLength(2));
  });
  test('suggestions are stable within the day and change on the next day', () {
    final first = resolve();
    expect(resolve(at: DateTime(2026, 10, 2, 23, 59)), first);
    final next = resolve(at: now.add(const Duration(days: 1)));
    expect(
      first.map((m) => m.suggestion).toList(),
      isNot(next.map((m) => m.suggestion).toList()),
    );
    expect(
      first.map((m) => m.kind),
      unorderedEquals([
        KidsDailyMissionKind.reading,
        KidsDailyMissionKind.practice,
      ]),
    );
  });
  test('a new reader always receives a gentle one-page goal', () {
    for (var offset = 0; offset < 7; offset++) {
      final card = resolve(
        at: now.add(Duration(days: offset)),
      ).singleWhere((m) => m.kind == KidsDailyMissionKind.reading);
      expect(card.targetCount, 1);
    }
  });
  test(
    'recent confirmed reading adapts goals; two pages need two distinct receipts',
    () {
      final days = [now, now.add(const Duration(days: 1))];
      final day = days.firstWhere(
        (day) =>
            resolve(at: day, readingDays: 3).any((m) => m.targetCount == 2),
      );
      KidsDailyMission card(Set<int> pages) => resolve(
        at: day,
        readingDays: 3,
        pages: pages,
      ).singleWhere((m) => m.kind == KidsDailyMissionKind.reading);
      expect(card({5}).status, KidsDailyMissionStatus.available);
      expect(card({5, 6}).status, KidsDailyMissionStatus.completed);
      expect(card({0, 605}).status, KidsDailyMissionStatus.available);
    },
  );
  test('opening or zero-point/yesterday logs cannot complete a task', () {
    final cards = resolve(
      logs: [
        log(points: 0),
        log(at: now.subtract(const Duration(days: 1))),
      ],
    );
    expect(
      cards.every((m) => m.status == KidsDailyMissionStatus.available),
      isTrue,
    );
  });
  test('listening task needs completed recitation with listening evidence', () {
    final day = [now, now.add(const Duration(days: 1))].firstWhere(
      (day) => resolve(
        at: day,
      ).any((m) => m.suggestion == KidsDailySuggestion.listenAndRecite),
    );
    final completed = resolve(
      at: day,
      logs: [log(at: day, repeats: 2)],
    ).singleWhere((m) => m.kind == KidsDailyMissionKind.practice);
    expect(completed.suggestion, KidsDailySuggestion.listenAndRecite);
    expect(completed.status, KidsDailyMissionStatus.completed);
    expect(completed.learning, learning);
    final pending = resolve(
      at: day,
      logs: [log(at: day, repeats: 1)],
    ).singleWhere((m) => m.kind == KidsDailyMissionKind.practice);
    expect(pending.status, KidsDailyMissionStatus.available);
  });
  test(
    'review suggestions use the authorized review and require review evidence',
    () {
      const review = KidsNextMission(
        type: KidsMissionType.linkedReview,
        surahId: 1,
        ayahNumbers: [2],
      );
      final pending = resolve(
        mission: review,
      ).singleWhere((m) => m.kind == KidsDailyMissionKind.practice);
      expect(pending.suggestion, KidsDailySuggestion.reviewAyah);
      expect(pending.learning, review);
      expect(pending.status, KidsDailyMissionStatus.available);
      final done = resolve(
        mission: review,
        logs: [log(type: KidsMissionType.linkedReview)],
      ).singleWhere((m) => m.kind == KidsDailyMissionKind.practice);
      expect(done.status, KidsDailyMissionStatus.completed);
    },
  );
  test('no authorized work does not invent another session', () {
    expect(resolve(mission: null).map((m) => m.kind), [
      KidsDailyMissionKind.reading,
    ]);
    expect(resolve(mission: null, reading: false), isEmpty);
  });
  test('caps and unavailable reading sources apply to suggestions', () {
    expect(resolve(cap: 0), isEmpty);
    expect(resolve(cap: -1), isEmpty);
    expect(resolve(cap: 1), hasLength(1));
    expect(resolve(cap: 100), hasLength(2));
    expect(resolve(reading: false).map((m) => m.kind), [
      KidsDailyMissionKind.practice,
    ]);
  });
  test('UTC input uses the same local calendar and IDs', () {
    expect(resolve(at: now.toUtc()), resolve(at: now));
    expect(resolve().every((m) => m.id.startsWith('2026-10-02:')), isTrue);
  });
}
