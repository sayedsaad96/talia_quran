import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_house_review_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_surah_house_summary_builder.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

final _now = DateTime.utc(2026, 10, 16, 12);

const _counts = <int, int>{1: 7, 2: 286, 103: 3, 110: 3, 112: 4, 114: 6};

List<Surah> _surahs() => [
  for (var id = 1; id <= 114; id++)
    Surah(
      id: id,
      nameAr: 's$id',
      nameEn: 's$id',
      ayahCount: _counts[id] ?? 10,
      juz: 1 + (id % 30),
      type: 'meccan',
      page: id,
    ),
];

KidsSessionLog _log(
  int surah,
  int ayah, {
  KidsMissionType type = KidsMissionType.newMemorization,
  int points = 10,
  DateTime? at,
  String? id,
}) => KidsSessionLog(
  id: id ?? 'l_${surah}_${ayah}_${type.name}',
  surahId: surah,
  ayahNumber: ayah,
  repeatsCompleted: 3,
  pointsEarned: points,
  completedAt: at ?? DateTime.utc(2026, 10, 1),
  missionType: type,
);

KidsSessionLog _houseReview(int surah, int ayah, DateTime at) => _log(
  surah,
  ayah,
  type: KidsMissionType.linkedReview,
  points: 5,
  at: at,
  id: KidsHouseReviewPolicy.proofId(surah, ayah, 's'),
);

AyahReviewRecord _record(int surah, int ayah, {required DateTime next}) =>
    AyahReviewRecord(
      surahId: surah,
      ayahNumber: ayah,
      strengthLevel: 3,
      intervalDays: 1,
      lastReviewedAt: DateTime.utc(2026, 10, 1),
      nextReviewDate: next,
      totalReviews: 1,
      lastRating: PerformanceRating.excellent,
      createdByMode: ReviewRecordCreatedByMode.kidsMode,
    );

List<KidsSurahHouse> _build({
  KidsJourneyPathDefinition? path,
  List<KidsSessionLog> logs = const [],
  List<AyahReviewRecord> records = const [],
  Map<int, int> frozen = const {},
  Set<int> whole = const {},
  int defaultSize = 3,
}) => buildKidsSurahHouses(
  path: path ?? KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas),
  surahs: _surahs(),
  logs: logs,
  kidsRecords: records,
  frozenSizes: frozen,
  wholeSurahIds: whole,
  defaultStageSize: defaultSize,
  now: _now,
);

KidsSurahHouse _house(List<KidsSurahHouse> houses, int id) =>
    houses.firstWhere((h) => h.surahId == id);

void main() {
  test('returns 114 houses in quranFromNas order with juz from surahs', () {
    final houses = _build();
    expect(houses.length, 114);
    expect(
      houses.map((h) => h.surahId).toList(),
      KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas).surahIds,
    );
    expect(houses.first.surahId, 1);
    expect(houses[1].surahId, 114);
    expect(_house(houses, 114).juz, 1 + (114 % 30));
    expect(_house(houses, 114).ayahCount, 6);
    expect(
      houses.every((h) => h.status == KidsSurahHouseStatus.notStarted),
      isTrue,
    );
  });

  test('notStarted / inProgress / completed from canonical reward logs', () {
    final houses = _build(
      defaultSize: 6,
      logs: [
        _log(114, 1),
        _log(114, 2),
        for (var a = 1; a <= 3; a++) _log(110, a),
        _houseReview(110, 1, DateTime.utc(2026, 10, 2)),
        _houseReview(110, 2, DateTime.utc(2026, 10, 2)),
        _houseReview(110, 3, DateTime.utc(2026, 10, 2)),
      ],
    );
    expect(_house(houses, 112).status, KidsSurahHouseStatus.notStarted);
    final inProgress = _house(houses, 114);
    expect(inProgress.status, KidsSurahHouseStatus.inProgress);
    expect(inProgress.completedCount, 2);
    expect(inProgress.progress, closeTo(2 / 6, 1e-9));
    final done = _house(houses, 110);
    expect(done.status, KidsSurahHouseStatus.completed);
    expect(done.progress, 1.0);
  });

  test('needsReview when a finished stage has a pending house review', () {
    final houses = _build(
      defaultSize: 3,
      logs: [for (var a = 1; a <= 3; a++) _log(114, a)],
    );
    final house = _house(houses, 114);
    expect(house.status, KidsSurahHouseStatus.needsReview);
    expect(house.completedCount, 3);
  });

  test('needsReview when a kids record of the surah is due', () {
    final logs = [
      for (var a = 1; a <= 3; a++) _log(114, a),
      for (var a = 1; a <= 3; a++)
        _houseReview(114, a, DateTime.utc(2026, 10, 2)),
    ];
    final fresh = _build(
      defaultSize: 3,
      logs: logs,
      records: [_record(114, 2, next: DateTime.utc(2026, 11, 1))],
    );
    expect(_house(fresh, 114).status, KidsSurahHouseStatus.inProgress);

    final due = _build(
      defaultSize: 3,
      logs: logs,
      records: [_record(114, 2, next: DateTime.utc(2026, 10, 10))],
    );
    expect(_house(due, 114).status, KidsSurahHouseStatus.needsReview);
  });

  test('needsReview when a due record is in an unfinished stage', () {
    final houses = _build(
      defaultSize: 3,
      logs: [
        for (var a = 1; a <= 3; a++) _log(114, a),
        for (var a = 1; a <= 3; a++)
          _houseReview(114, a, DateTime.utc(2026, 10, 2)),
      ],
      records: [_record(114, 5, next: DateTime.utc(2026, 10, 10))],
    );
    expect(_house(houses, 114).status, KidsSurahHouseStatus.needsReview);
  });

  test('whole 103 is completed after its 3 ayahs plus their house review', () {
    final base = [for (var a = 1; a <= 3; a++) _log(103, a)];
    final pending = _build(
      whole: {103},
      defaultSize: 1,
      frozen: const {103: 1},
      logs: base,
    );
    expect(_house(pending, 103).status, KidsSurahHouseStatus.needsReview);

    final reviewed = _build(
      whole: {103},
      defaultSize: 1,
      frozen: const {103: 1},
      logs: [
        ...base,
        for (var a = 1; a <= 3; a++)
          _houseReview(103, a, DateTime.utc(2026, 10, 2)),
      ],
    );
    expect(_house(reviewed, 103).status, KidsSurahHouseStatus.completed);
  });

  test('review-only logs do not count as completion', () {
    final houses = _build(
      logs: [
        _log(114, 1, type: KidsMissionType.linkedReview, points: 5),
        _log(114, 2, type: KidsMissionType.dueReview, points: 5),
        _log(112, 1, points: 0),
      ],
    );
    expect(_house(houses, 114).status, KidsSurahHouseStatus.notStarted);
    expect(_house(houses, 114).completedCount, 0);
    expect(_house(houses, 112).status, KidsSurahHouseStatus.notStarted);
  });

  group('currentKidsSurahHouse', () {
    test('first with no logs', () {
      final houses = _build();
      expect(currentKidsSurahHouse(houses, const []), 1);
    });

    test('the guardian starting surah with no logs', () {
      final houses = _build(
        path: KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas),
      );
      expect(
        currentKidsSurahHouse(houses, const [], startingSurahId: 67),
        67,
      );
    });

    test('a starting surah off the houses falls back to the first', () {
      final houses = _build(path: KidsJourneyPathDefinition.adventure);
      expect(
        currentKidsSurahHouse(houses, const [], startingSurahId: 67),
        1,
      );
    });

    test('last started when not completed', () {
      final logs = [
        _log(114, 1, at: DateTime.utc(2026, 10, 1)),
        _log(112, 1, at: DateTime.utc(2026, 10, 5)),
      ];
      final houses = _build(logs: logs);
      expect(currentKidsSurahHouse(houses, logs), 112);
    });

    test('next non-completed after a completed one', () {
      final logs = [
        for (var a = 1; a <= 6; a++)
          _log(114, a, at: DateTime.utc(2026, 10, 1)),
        for (var a = 1; a <= 6; a++)
          _houseReview(114, a, DateTime.utc(2026, 10, 2)),
      ];
      final houses = _build(defaultSize: 6, logs: logs);
      expect(_house(houses, 114).status, KidsSurahHouseStatus.completed);
      // Path order: 1, 114, 113, ...
      expect(currentKidsSurahHouse(houses, logs), 113);
    });

    test('needsReview house is the current house', () {
      final logs = [for (var a = 1; a <= 3; a++) _log(114, a)];
      final houses = _build(defaultSize: 3, logs: logs);
      expect(currentKidsSurahHouse(houses, logs), 114);
    });
  });

  test('adventure path returns its 38 houses only', () {
    final houses = _build(path: KidsJourneyPathDefinition.adventure);
    expect(houses.length, 38);
    expect(
      houses.map((h) => h.surahId).toList(),
      KidsJourneyPathDefinition.adventure.surahIds,
    );
  });
}
