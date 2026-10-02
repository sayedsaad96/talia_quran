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
    ayahNumbers: [1, 2],
  );

  KidsSessionLog log(DateTime localAt, {int points = 10}) => KidsSessionLog(
    id: 'l-${localAt.microsecondsSinceEpoch}',
    surahId: 114,
    ayahNumber: 1,
    repeatsCompleted: 3,
    pointsEarned: points,
    completedAt: localAt.toUtc(),
  );

  List<KidsDailyMission> resolve({
    KidsNextMission? learningMission = learning,
    bool dayGoalReached = false,
    List<KidsSessionLog> logs = const [],
    Set<int> pages = const {},
    int max = kKidsMaxDailyMissions,
    KidsHomeMission? home,
    DateTime? at,
  }) => resolveKidsDailyMissions(
    now: at ?? now,
    learning: learningMission,
    dayGoalReached: dayGoalReached,
    logs: logs,
    pagesReadToday: pages,
    maxMissions: max,
    homeMission: home,
  );

  test('learning card first, reading second', () {
    final r = resolve();
    expect(r.map((m) => m.kind), [
      KidsDailyMissionKind.learning,
      KidsDailyMissionKind.reading,
    ]);
    expect(
      r.every((m) => m.status == KidsDailyMissionStatus.available),
      isTrue,
    );
  });

  test('learning completes after any positive log today', () {
    final r = resolve(logs: [log(DateTime(2026, 10, 2, 8))]);
    expect(r.first.status, KidsDailyMissionStatus.completed);
    expect(r.first.learning, learning);
  });

  test("yesterday's log does not complete today", () {
    final r = resolve(logs: [log(DateTime(2026, 10, 1, 23, 59))]);
    expect(r.first.status, KidsDailyMissionStatus.available);
  });

  test('zero-point log does not complete', () {
    final r = resolve(logs: [log(DateTime(2026, 10, 2, 8), points: 0)]);
    expect(r.first.status, KidsDailyMissionStatus.available);
  });

  test('reading completes with one confirmed page', () {
    final r = resolve(pages: {5});
    expect(r[1].status, KidsDailyMissionStatus.completed);
  });

  test('day goal reached and no learning mission', () {
    final done = resolve(
      learningMission: null,
      dayGoalReached: true,
      logs: [log(DateTime(2026, 10, 2, 8))],
    );
    expect(done.map((m) => m.kind), [
      KidsDailyMissionKind.learning,
      KidsDailyMissionKind.reading,
    ]);
    expect(done.first.status, KidsDailyMissionStatus.completed);
    expect(done.first.learning, isNull);

    final none = resolve(learningMission: null, dayGoalReached: true);
    expect(none.map((m) => m.kind), [KidsDailyMissionKind.reading]);
  });

  test('maxMissions limits the list', () {
    expect(resolve(max: 1).map((m) => m.kind), [KidsDailyMissionKind.learning]);
    expect(resolve(max: 0), isEmpty);
  });

  test('ids are stable per day', () {
    expect(resolve().map((m) => m.id), [
      '2026-10-02:learning',
      '2026-10-02:reading',
    ]);
    expect(kidsDayKey(DateTime(2026, 1, 5)), '2026-01-05');
  });

  group('home mission card', () {
    KidsHomeMission mission(
      KidsHomeMissionStatus status, {
      String id = '12',
    }) => KidsHomeMission(
      id: id,
      title: 'رتّب غرفتك',
      status: status,
      createdAt: DateTime(2026, 10, 1),
    );

    test('assigned mission adds a third card after learning and reading', () {
      final r = resolve(home: mission(KidsHomeMissionStatus.assigned));
      expect(r.map((m) => m.kind), [
        KidsDailyMissionKind.learning,
        KidsDailyMissionKind.reading,
        KidsDailyMissionKind.home,
      ]);
      final home = r.last;
      expect(home.id, '2026-10-02:home:12');
      expect(home.homeMissionId, '12');
      expect(home.homeMissionTitle, 'رتّب غرفتك');
      expect(home.status, KidsDailyMissionStatus.available);
    });

    test('reported and acknowledged missions are completed', () {
      for (final status in [
        KidsHomeMissionStatus.reported,
        KidsHomeMissionStatus.acknowledged,
      ]) {
        expect(
          resolve(home: mission(status)).last.status,
          KidsDailyMissionStatus.completed,
        );
      }
    });

    test('maxMissions 2 leaves the home card out', () {
      final r = resolve(
        home: mission(KidsHomeMissionStatus.assigned),
        max: 2,
      );
      expect(r.map((m) => m.kind), [
        KidsDailyMissionKind.learning,
        KidsDailyMissionKind.reading,
      ]);
    });

    test('slots are positional: no learning card and max 2 gives no home', () {
      final home = mission(KidsHomeMissionStatus.assigned);
      final capped = resolve(learningMission: null, home: home, max: 2);
      expect(capped.map((m) => m.kind), [KidsDailyMissionKind.reading]);

      final full = resolve(learningMission: null, home: home, max: 3);
      expect(full.map((m) => m.kind), [
        KidsDailyMissionKind.reading,
        KidsDailyMissionKind.home,
      ]);
    });

    test('no home mission means no home card', () {
      expect(
        resolve().any((m) => m.kind == KidsDailyMissionKind.home),
        isFalse,
      );
    });
  });

  test('maxMissions above the cap is clamped to kKidsMaxDailyMissions', () {
    final r = resolve(
      max: 5,
      home: KidsHomeMission(
        id: '1',
        title: 't',
        status: KidsHomeMissionStatus.assigned,
        createdAt: DateTime(2026, 10, 1),
      ),
    );
    expect(r, hasLength(kKidsMaxDailyMissions));
    expect(resolve(max: -1), isEmpty);
  });

  test('a UTC now is normalised to the local day key', () {
    final local = DateTime(2026, 10, 2, 0, 30);
    final r = resolve(at: local.toUtc());
    expect(r.first.id, '${kidsDayKey(local)}:learning');
  });
}
