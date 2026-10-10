import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_kids_local_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_house_review_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_daily_budget.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Owner implements RecordOwnerProvider {
  String id = 'local';
  @override
  String get currentOwnerId => id;
  @override
  bool get isSignedIn => id != 'local';
}

class _Streak implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}

class _PausedStorage extends MemorizationPlusLocalDatasourceImpl {
  _PausedStorage(super.prefs, {required super.owner, required this.blockOn});
  final int blockOn;
  final reached = Completer<void>();
  final release = Completer<void>();
  int reads = 0;
  @override
  Future<List<KidsSessionLogModel>> getKidsSessionLogs() async {
    final logs = await super.getKidsSessionLogs();
    if (++reads == blockOn) {
      reached.complete();
      await release.future;
    }
    return logs;
  }
}

class _Corpus implements QuranRepository {
  final failed = <int>{};
  final corpus =
      jsonDecode(File('assets/data/quran.json').readAsStringSync())
          as Map<String, dynamic>;
  final metadata =
      (jsonDecode(File('assets/data/surahs.json').readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int id) async {
    if (failed.contains(id)) return const Left(CacheFailure());
    final row = metadata.singleWhere((row) => row['id'] == id);
    return Right(
      SurahDetail(
        surah: Surah(
          id: id,
          nameAr: row['nameAr'] as String,
          nameEn: row['nameEn'] as String,
          ayahCount: row['ayahCount'] as int,
          juz: row['juz'] as int,
          type: row['type'] as String,
          page: row['page'] as int,
        ),
        ayahs: [
          for (final ayah in corpus['$id'] as List)
            Ayah(
              number: ayah['global'] as int,
              surahId: id,
              text: ayah['text'] as String,
              numberInSurah: ayah['verse'] as int,
              page: ayah['page'] as int,
              juz: ayah['juz'] as int,
            ),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late MemorizationPlusLocalDatasourceImpl storage;
  late MemorizationKidsLocalService service;
  late _Corpus quran;
  late _Owner owner;
  late ProgressEventsBus events;
  var sequence = 0;

  MemorizationKidsLocalService createService(
    MemorizationPlusLocalDatasourceImpl source,
  ) => MemorizationKidsLocalService(
    source,
    quran,
    _Streak(),
    events,
    null,
    owner: owner,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = _Owner();
    events = ProgressEventsBus();
    quran = _Corpus();
    storage = MemorizationPlusLocalDatasourceImpl(prefs, owner: owner);
    service = createService(storage);
    sequence = 0;
  });
  tearDown(() => events.dispose());

  Future<List<KidsJourneyStage>> journey([int surah = 1]) async =>
      (await service.getKidsJourney(
        surahId: surah,
      )).getOrElse(() => throw StateError('journey failed'));

  Future<void> pass(
    int ayah, {
    bool review = false,
    PerformanceRating rating = PerformanceRating.excellent,
    List<int> listedAyahs = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final id = 'fixture-${++sequence}';
    final outcome = await service.awardKidsPoints(
      completionAuthorized: true,
      sessionId: review ? KidsHouseReviewPolicy.proofId(1, ayah, id) : id,
      surahId: 1,
      ayahNumber: ayah,
      repeatsCompleted: 2,
      missionType: review
          ? KidsMissionType.linkedReview
          : KidsMissionType.newMemorization,
      masteryRating: rating,
      ayahNumbers: listedAyahs,
    );
    expect(outcome.isRight(), isTrue);
  }

  test(
    'last first-pass opens mandatory review only; every ayah must be recited',
    () async {
      expect((await service.setKidsAyahsPerHouse(2)).isRight(), isTrue);
      await pass(1);
      expect((await journey()).first.requiresHouseReview, isFalse);
      await pass(2);
      var stages = await journey();
      expect(stages.first.requiresHouseReview, isTrue);
      expect(stages.first.pendingHouseReviewAyahs, [1, 2]);
      expect(stages[1].isUnlocked, isFalse);
      await pass(1, review: true, listedAyahs: [1, 2]);
      stages = await journey();
      expect(stages.first.pendingHouseReviewAyahs, [
        2,
      ], reason: 'range metadata is not per-ayah evidence');
      expect(stages[1].isUnlocked, isFalse);
      await pass(2, review: true, rating: PerformanceRating.weak);
      expect((await journey())[1].isUnlocked, isFalse);
      await pass(2, review: true, rating: PerformanceRating.average);
      stages = await journey();
      expect(stages.first.requiresHouseReview, isFalse);
      expect(stages[1].status, KidsJourneyStageStatus.current);
      expect(
        (await service.getKidsProgress())
            .getOrElse(() => throw StateError('progress'))
            .ayahsCompleted,
        2,
      );
    },
  );

  test(
    'review done before the entire house is memorized is not final house review',
    () async {
      await service.setKidsAyahsPerHouse(2);
      await pass(1);
      await pass(1, review: true);
      await pass(2);
      expect((await journey()).first.pendingHouseReviewAyahs, [1, 2]);
    },
  );

  test(
    'frozen grouping survives preference edits, stale ordinary settings and restart',
    () async {
      await service.setKidsAyahsPerHouse(2);
      final original = await journey();
      expect(original.map((s) => s.totalAyahs), [2, 2, 2, 1]);
      final stale = (await service.getParentSettings()).getOrElse(
        () => throw StateError('settings'),
      );
      await pass(1);
      await service.setKidsAyahsPerHouse(4);
      await service.saveParentSettings(stale.copyWith(reminderHour: 12));
      service = createService(
        MemorizationPlusLocalDatasourceImpl(prefs, owner: owner),
      );
      expect((await journey()).map((s) => s.totalAyahs), [2, 2, 2, 1]);
      expect((await journey(114)).map((s) => s.totalAyahs), [4, 2]);
      final settings = (await service.getParentSettings()).getOrElse(
        () => throw StateError('settings'),
      );
      expect(settings.kidsAyahsPerHouse, 4);
      expect(settings.kidsHouseSizesBySurah[1], 2);
    },
  );

  test(
    'older progress stays credited and its previous age grouping is frozen',
    () async {
      await storage.saveKidsSessionLog(
        KidsSessionLogModel(
          id: 'legacy',
          surahId: 1,
          ayahNumber: 1,
          repeatsCompleted: 2,
          pointsEarned: 10,
          completedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await service.setKidsAyahsPerHouse(2);
      expect((await journey()).first.totalAyahs, 5);
      expect((await journey()).first.completedAyahs, [1]);
    },
  );

  test(
    'mandatory reviews bypass daily limits and continuation cannot skip them',
    () async {
      await service.setKidsAyahsPerHouse(2);
      await pass(1);
      await pass(2);
      final stages = await journey();
      final logs = await storage.getKidsSessionLogs();
      final budget = KidsDailyBudget.fromLogs(
        logs: logs,
        policy: KidsSessionPolicy.forAge(6),
        now: DateTime.now(),
      );
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 1,
        stages: stages,
        reviewRecords: const [],
        now: DateTime.now(),
        budget: budget,
      );
      expect(mission!.type, KidsMissionType.linkedReview);
      expect(mission.ayahNumbers, [1]);
      expect(
        await const KidsNextMissionResolver().findContinuation(
          activeSurahId: 1,
          stages: stages,
          loadStages: (_) async => await journey(114),
        ),
        isNull,
      );
      expect((await journey(114)).every((stage) => !stage.isUnlocked), isTrue);
    },
  );

  test(
    'account switches isolate preferred and frozen house sizes and evidence',
    () async {
      owner.id = 'account-a';
      await service.setKidsAyahsPerHouse(2);
      await pass(1);
      owner.id = 'account-b';
      final other = (await service.getParentSettings()).getOrElse(
        () => throw StateError('settings'),
      );
      expect(other.kidsAyahsPerHouse, isNull);
      expect(other.kidsHouseSizesBySurah, isEmpty);
      expect((await journey()).first.completedCount, 0);
      owner.id = 'account-a';
      expect((await journey()).first.totalAyahs, 2);
      expect((await journey()).first.completedAyahs, [1]);
    },
  );

  test('canonical load failure creates no invented houses', () async {
    quran.failed.add(1);
    expect((await service.getKidsJourney(surahId: 1)).isLeft(), isTrue);
    expect((await storage.getParentSettings()).kidsHouseSizesBySurah, isEmpty);
  });

  test(
    'house settings round trip and malformed additions preserve existing guardian settings',
    () {
      const saved = ParentSettingsModel(
        reminderHour: 12,
        kidsAyahsPerHouse: 4,
        kidsHouseSizesBySurah: {1: 2, 114: 3},
      );
      expect(ParentSettingsModel.fromJson(saved.toJson()), saved);
      final parsed = ParentSettingsModel.fromJson({
        ...saved.toJson(),
        'kidsAyahsPerHouse': 'invalid',
        'kidsHouseSizesBySurah': {'114': 2, '1': 0, '0': 1, 'bad': 3},
      });
      expect(parsed.kidsAyahsPerHouse, isNull);
      expect(parsed.kidsHouseSizesBySurah, {114: 2});
      expect(parsed.reminderHour, 12);
    },
  );

  test(
    'invalid old ayah numbers cannot substitute for missing earlier memorization',
    () async {
      for (var ayah = 90; ayah < 97; ayah++) {
        await storage.saveKidsSessionLog(
          KidsSessionLogModel(
            id: 'invalid-$ayah',
            surahId: 1,
            ayahNumber: ayah,
            repeatsCompleted: 0,
            pointsEarned: 10,
            completedAt: DateTime.utc(2026),
          ),
        );
      }
      expect((await journey(114)).every((stage) => !stage.isUnlocked), isTrue);
    },
  );

  test(
    'legacy later-surah frontier remains accessible without opening its successor',
    () async {
      await storage.saveKidsSessionLog(
        KidsSessionLogModel(
          id: 'legacy-later-start',
          surahId: 114,
          ayahNumber: 1,
          repeatsCompleted: 2,
          pointsEarned: 10,
          completedAt: DateTime.utc(2026),
        ),
      );
      final saved = await journey(114);
      expect(saved.first.isUnlocked, isTrue);
      expect(saved.first.completedAyahs, [1]);
      expect((await journey(113)).every((stage) => !stage.isUnlocked), isTrue);
    },
  );

  test(
    'a started later house never relocks behind a partially done earlier one',
    () async {
      await pass(1);
      await storage.saveKidsSessionLog(
        KidsSessionLogModel(
          id: 'legacy-partial-earlier',
          surahId: 114,
          ayahNumber: 1,
          repeatsCompleted: 2,
          pointsEarned: 10,
          completedAt: DateTime.utc(2026),
        ),
      );
      final started = await journey(114);
      expect(started.first.isUnlocked, isTrue);
      expect(started.first.completedAyahs, [1]);
      expect(
        (await journey(113)).every((stage) => !stage.isUnlocked),
        isTrue,
        reason: 'an unstarted house still waits for the earlier ones',
      );
    },
  );

  test(
    'direct later-surah link cannot bypass unstarted earlier houses',
    () async {
      expect((await journey(114)).every((stage) => !stage.isUnlocked), isTrue);
      await service.saveParentSettings(
        const ParentSettings(startingSurahId: 114),
      );
      expect(
        (await journey(114)).first.isUnlocked,
        isTrue,
        reason: 'the configured starting surah remains accessible',
      );
    },
  );

  test(
    'account switch while review evidence is being read cannot write into next account',
    () async {
      owner.id = 'account-a';
      final paused = _PausedStorage(prefs, owner: owner, blockOn: 2);
      service = createService(paused);
      final award = service.awardKidsPoints(
        surahId: 1,
        ayahNumber: 1,
        repeatsCompleted: 0,
        missionType: KidsMissionType.linkedReview,
        sessionId: KidsHouseReviewPolicy.proofId(1, 1, 'switch'),
      );
      await paused.reached.future;
      owner.id = 'account-b';
      paused.release.complete();
      expect((await award).isLeft(), isTrue);
      expect(await storage.getKidsSessionLogs(), isEmpty);
      owner.id = 'account-a';
      expect(await storage.getKidsSessionLogs(), isEmpty);
    },
  );

  test(
    'queued awards retain their original account after waiting for the lock',
    () async {
      owner.id = 'account-a';
      final paused = _PausedStorage(prefs, owner: owner, blockOn: 1);
      service = createService(paused);
      Future<Either<Failure, KidsCompletionResult>> award(String id) =>
          service.awardKidsPoints(
            surahId: 1,
            ayahNumber: 1,
            repeatsCompleted: 0,
            missionType: KidsMissionType.linkedReview,
            sessionId: KidsHouseReviewPolicy.proofId(1, 1, id),
          );
      final first = award('first');
      await paused.reached.future;
      final queued = award('queued');
      owner.id = 'account-b';
      paused.release.complete();
      expect((await first).isLeft(), isTrue);
      expect((await queued).isLeft(), isTrue);
      expect(await storage.getKidsSessionLogs(), isEmpty);
      owner.id = 'account-a';
      expect(await storage.getKidsSessionLogs(), isEmpty);
    },
  );
}
