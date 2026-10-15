import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_kids_local_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_house_review_policy.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

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

class _Corpus implements QuranRepository {
  final corpus =
      jsonDecode(File('assets/data/quran.json').readAsStringSync())
          as Map<String, dynamic>;
  final metadata =
      (jsonDecode(File('assets/data/surahs.json').readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int id) async {
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

  test('kids Quran journey end to end', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final owner = _Owner();
    final events = ProgressEventsBus();
    addTearDown(events.dispose);
    final storage = MemorizationPlusLocalDatasourceImpl(prefs, owner: owner);
    final service = MemorizationKidsLocalService(
      storage,
      _Corpus(),
      _Streak(),
      events,
      null,
      owner: owner,
      quranJourneyEnabled: () => true,
    );
    var sequence = 0;

    Future<void> award(
      int surah,
      int ayah, {
      bool review = false,
      PerformanceRating rating = PerformanceRating.excellent,
    }) async {
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final id = 'flow-${++sequence}';
      final outcome = await service.awardKidsPoints(
        completionAuthorized: true,
        sessionId: review ? KidsHouseReviewPolicy.proofId(surah, ayah, id) : id,
        surahId: surah,
        ayahNumber: ayah,
        repeatsCompleted: 2,
        missionType: review
            ? KidsMissionType.linkedReview
            : KidsMissionType.newMemorization,
        masteryRating: rating,
      );
      expect(outcome.isRight(), isTrue, reason: '$surah:$ayah review=$review');
    }

    Future<List<KidsJourneyStage>> journey(int surah) async =>
        (await service.getKidsJourney(
          surahId: surah,
        )).getOrElse(() => throw StateError('journey $surah failed'));

    Set<int> completed(List<KidsJourneyStage> stages) => {
      for (final s in stages) ...s.completedAyahs,
    };

    // 1. flag on; adventure by default; one reward log on 114:1.
    await award(114, 1);

    // 2. switch to the Quran journey.
    expect(
      (await service.setKidsJourneyPath(
        KidsJourneyPathId.quranFromNas,
      )).isRight(),
      isTrue,
    );
    final path = (await service.getKidsJourneyPath()).getOrElse(
      () => throw StateError('path'),
    );
    expect(path.isQuranJourney, isTrue);

    // 3. Al-Mulk is open (no lock) but cannot be split as a whole surah.
    final mulk = await journey(67);
    // Later stages of the same surah wait their turn; the surah itself is open.
    expect(mulk.first.status, KidsJourneyStageStatus.current);
    final whole67 = await service.setKidsSurahSplit(67, whole: true);
    expect(whole67.fold((f) => f, (_) => null), isA<ValidationFailure>());

    // 4. Stages of 5 ayahs -> 6 stages.
    expect(
      (await service.setKidsSurahSplit(
        67,
        whole: false,
        stageSize: 5,
      )).isRight(),
      isTrue,
    );
    expect((await journey(67)).length, 6);

    // 5. Memorize ayahs 1..5 then recite each for the house review.
    for (var ayah = 1; ayah <= 5; ayah++) {
      await award(67, ayah);
    }
    for (var ayah = 1; ayah <= 5; ayah++) {
      await award(67, ayah, review: true);
    }
    var stages = await journey(67);
    expect(stages.first.status, KidsJourneyStageStatus.completed);
    expect(completed(stages), {1, 2, 3, 4, 5});

    // 6. Re-splitting keeps the memorized ayahs.
    expect(
      (await service.setKidsSurahSplit(
        67,
        whole: false,
        stageSize: 3,
      )).isRight(),
      isTrue,
    );
    stages = await journey(67);
    expect(stages.first.endAyah, 3);
    expect(completed(stages), {1, 2, 3, 4, 5});

    // 7. Al-Asr as one whole stage.
    expect(
      (await service.setKidsSurahSplit(103, whole: true)).isRight(),
      isTrue,
    );
    final asr = await journey(103);
    expect(asr.length, 1);
    expect(asr.single.totalAyahs, 3);

    // 8. Switching back to the adventure loses nothing.
    expect(
      (await service.setKidsJourneyPath(
        KidsJourneyPathId.juzAmmaAdventure,
      )).isRight(),
      isTrue,
    );
    expect(completed(await journey(114)), contains(1));
    final logs = await storage.getKidsSessionLogs();
    for (var ayah = 1; ayah <= 5; ayah++) {
      expect(
        logs.any((l) => l.surahId == 67 && l.ayahNumber == ayah),
        isTrue,
        reason: '67:$ayah log kept',
      );
    }
    final mission = const KidsNextMissionResolver().resolve(
      activeSurahId: 67,
      stages: await journey(67),
      reviewRecords: [
        AyahReviewRecord(
          surahId: 67,
          ayahNumber: 1,
          strengthLevel: 1,
          intervalDays: 1,
          lastReviewedAt: DateTime.utc(2026, 10, 1),
          nextReviewDate: DateTime.utc(2026, 10, 2),
          totalReviews: 1,
          lastRating: PerformanceRating.average,
          createdByMode: ReviewRecordCreatedByMode.kidsMode,
        ),
      ],
      now: DateTime.utc(2026, 10, 16),
      path: (await service.getKidsJourneyPath()).getOrElse(
        () => throw StateError('path'),
      ),
    );
    expect(mission!.type, KidsMissionType.dueReview);
    expect(mission.surahId, 67);
    expect(mission.ayahNumbers, [1]);

    // 9. Another account sees none of it.
    owner.id = 'account-b';
    final other = (await service.getParentSettings()).getOrElse(
      () => throw StateError('settings'),
    );
    expect(other.kidsJourneyPathId, isNull);
    expect(other.kidsWholeSurahIds, isEmpty);
    owner.id = 'local';
  });
}
