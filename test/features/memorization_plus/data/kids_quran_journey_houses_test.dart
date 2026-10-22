import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_kids_local_service.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/kids_legacy_resume_recovery_probe.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_remote_plan.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

class _FakeQuranRepository implements QuranRepository {
  static const _counts = {1: 7, 103: 3, 67: 30, 113: 5};

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async {
    final count = _counts[surahId];
    if (count == null) return const Left(CacheFailure());
    return Right(
      SurahDetail(
        surah: Surah(
          id: surahId,
          nameAr: 'سورة',
          nameEn: 'Surah',
          ayahCount: count,
          juz: 1,
          type: 'meccan',
          page: 1,
        ),
        ayahs: [
          for (var n = 1; n <= count; n++)
            Ayah(number: n, surahId: surahId, text: 'x', numberInSurah: n),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStreakReader implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}

class _FakeProgressEventsBus implements ProgressEventsBus {
  @override
  void notify(ProgressChangedReason reason) {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingHouseSettingsDatasource
    extends MemorizationPlusLocalDatasourceImpl {
  _FailingHouseSettingsDatasource(super.prefs, {required super.owner});

  @override
  Future<ParentSettingsModel> updateKidsHouseSettings(
    ParentSettings Function(ParentSettings current) mutate,
  ) async => throw StateError('settings write failed');
}

class _Probe implements KidsLegacyResumeProbe {
  _Probe(this.result);

  final KidsLegacyResumeProbeResult result;
  AccountDataLease? receivedLease;
  int calls = 0;

  @override
  Future<KidsLegacyResumeProbeResult> inspect({
    required int surahId,
    required AccountDataLease lease,
  }) async {
    calls++;
    receivedLease = lease;
    return result;
  }
}

void main() {
  late SharedPreferences prefs;
  late MemorizationPlusLocalDatasource datasource;
  late AccountDataBarrier barrier;
  const owner = FixedRecordOwnerProvider('a');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  MemorizationKidsLocalService serviceFor({
    bool journeyEnabled = true,
    bool remotePlanEnabled = false,
    bool Function()? remotePlanGate,
    KidsLegacyResumeProbe? legacyResumeProbe,
    Future<void> Function(int)? remoteMilestoneUnlock,
    MemorizationPlusLocalDatasource? storage,
  }) {
    datasource =
        storage ?? MemorizationPlusLocalDatasourceImpl(prefs, owner: owner);
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    return MemorizationKidsLocalService(
      datasource,
      _FakeQuranRepository(),
      _FakeStreakReader(),
      _FakeProgressEventsBus(),
      null,
      owner: owner,
      quranJourneyEnabled: () => journeyEnabled,
      remotePlanEnabled: remotePlanGate ?? () => remotePlanEnabled,
      barrier: barrier,
      legacyResumeProbe: legacyResumeProbe,
      remoteMilestoneUnlock: remoteMilestoneUnlock,
      remoteMilestoneEnabled: () => remoteMilestoneUnlock != null,
    );
  }

  Future<List<KidsJourneyStage>> journey(
    MemorizationKidsLocalService service,
    int surahId, {
    bool freezeForSession = false,
  }) async => (await service.getKidsJourney(
    surahId: surahId,
    freezeForSession: freezeForSession,
  )).fold((f) => fail('expected Right, got $f'), (v) => v);

  Future<void> seedRewards(int surahId, Iterable<int> ayahs) =>
      datasource.saveKidsSessionLogs([
        for (final ayah in ayahs)
          KidsSessionLogModel(
            id: 'reward_${surahId}_$ayah',
            surahId: surahId,
            ayahNumber: ayah,
            repeatsCompleted: 3,
            pointsEarned: 10,
            completedAt: DateTime.now().subtract(const Duration(days: 30)),
          ),
      ]);

  test('whole surah 103 is one stage of 3 ayahs', () async {
    final service = serviceFor();
    await service.setKidsAyahsPerHouse(2);
    await service.setKidsSurahSplit(103, whole: true);

    final stages = await journey(service, 103);
    expect(stages.length, 1);
    expect(stages.single.startAyah, 1);
    expect(stages.single.endAyah, 3);
  });

  test('whole is ignored for a 30-ayah surah stored as whole', () async {
    final service = serviceFor();
    await datasource.updateKidsHouseSettings(
      (current) => current.copyWith(kidsWholeSurahIds: {67}),
    );

    final stages = await journey(service, 67);
    final defaultSize = KidsSessionPolicy.forChildAge(null).journeyStageSize;
    expect(stages.length, greaterThan(1));
    expect(stages.first.endAyah - stages.first.startAyah + 1, defaultSize);
  });

  test('whole wins over a stray house size key for the same surah', () async {
    final service = serviceFor();
    await datasource.updateKidsHouseSettings(
      (current) => current.copyWith(
        kidsWholeSurahIds: {103},
        kidsHouseSizesBySurah: {103: 1},
      ),
    );

    final stages = await journey(service, 103);
    expect(stages.length, 1);
    expect(stages.single.endAyah, 3);
  });

  test('re-splitting a started surah keeps completed ayahs', () async {
    final service = serviceFor();
    await service.setKidsSurahSplit(67, whole: false, stageSize: 5);
    await seedRewards(67, [1, 2, 3, 4, 5]);

    await service.setKidsSurahSplit(67, whole: false, stageSize: 3);
    final stages = await journey(service, 67);

    expect(stages[0].startAyah, 1);
    expect(stages[0].endAyah, 3);
    expect(stages[1].startAyah, 4);
    expect(stages[1].endAyah, 6);
    final completed = {for (final s in stages) ...s.completedAyahs};
    expect(completed, {1, 2, 3, 4, 5});
    expect(stages[0].status, KidsJourneyStageStatus.needsReview);
    expect(stages[1].status, KidsJourneyStageStatus.locked);
  });

  test('quran journey never locks a later surah', () async {
    final service = serviceFor();
    await service.setKidsJourneyPath(KidsJourneyPathId.quranFromNas);

    final stages = await journey(service, 113);
    expect(stages.first.status, KidsJourneyStageStatus.current);
  });

  test('adventure still locks a later surah (unchanged)', () async {
    final service = serviceFor();
    await service.setKidsJourneyPath(KidsJourneyPathId.juzAmmaAdventure);

    final stages = await journey(service, 113);
    expect(stages.first.status, KidsJourneyStageStatus.locked);
  });

  test('session start freezes the local fallback while the remote flag is off', () async {
    final service = serviceFor();
    await service.setKidsAyahsPerHouse(2);

    final started = await journey(service, 67, freezeForSession: true);
    await service.setKidsAyahsPerHouse(3);
    final preview = await journey(service, 67);
    final settings = await datasource.getParentSettings();

    expect(started.first.endAyah, 2);
    expect(preview.first.endAyah, 2);
    expect(settings.kidsHouseSizesBySurah[67], 2);
  });

  test('enabled remote house size freezes at session start', () async {
    final service = serviceFor(remotePlanEnabled: true);
    await datasource.updateKidsHouseSettings(
      (current) => current.copyWith(
        remotePlan: const KidsRemotePlan(ayahsPerSession: 3),
      ),
    );

    final stages = await journey(service, 67, freezeForSession: true);
    final settings = await datasource.getParentSettings();

    expect(stages.first.endAyah, 3);
    expect(settings.kidsHouseSizesBySurah[67], 3);
  });

  test('current whole-surah choice wins over a remote house size', () async {
    final service = serviceFor(remotePlanEnabled: true);
    await datasource.updateKidsHouseSettings(
      (current) => current.copyWith(
        kidsWholeSurahIds: {103},
        remotePlan: const KidsRemotePlan(ayahsPerSession: 2),
      ),
    );

    final stages = await journey(service, 103, freezeForSession: true);
    final settings = await datasource.getParentSettings();

    expect(stages, hasLength(1));
    expect(stages.single.endAyah, 3);
    expect(settings.kidsHouseSizesBySurah.containsKey(103), isFalse);
  });

  test('legacy frozen house size wins over a changed remote policy', () async {
    final service = serviceFor(remotePlanEnabled: true);
    await datasource.updateKidsHouseSettings(
      (current) => current.copyWith(
        kidsHouseSizesBySurah: {67: 5},
        remotePlan: const KidsRemotePlan(ayahsPerSession: 2),
      ),
    );

    final stages = await journey(service, 67, freezeForSession: true);

    expect(stages.first.endAyah, 5);
  });

  test('failed freeze does not launch a session or persist a house size', () async {
    final failing = _FailingHouseSettingsDatasource(prefs, owner: owner);
    final service = serviceFor(storage: failing);

    final outcome = await service.getKidsJourney(
      surahId: 67,
      freezeForSession: true,
    );
    final settings = await datasource.getParentSettings();

    expect(outcome.isLeft(), isTrue);
    expect(settings.kidsHouseSizesBySurah, isEmpty);
  });

  test('invalidated account authority prevents a session freeze', () async {
    final service = serviceFor();
    barrier.invalidate();

    final outcome = await service.getKidsJourney(
      surahId: 67,
      freezeForSession: true,
    );

    expect(outcome.isLeft(), isTrue);
    expect(
      (await datasource.getParentSettings()).kidsHouseSizesBySurah,
      isEmpty,
    );
  });

  test('concurrent session starts retain one frozen house size', () async {
    var remoteReadCount = 0;
    final service = serviceFor(
      remotePlanGate: () => remoteReadCount++ == 0,
    );
    await datasource.updateKidsHouseSettings(
      (current) => current.copyWith(
        remotePlan: const KidsRemotePlan(ayahsPerSession: 3),
        kidsAyahsPerHouse: 2,
      ),
    );

    final results = await Future.wait([
      journey(service, 67, freezeForSession: true),
      journey(service, 67, freezeForSession: true),
    ]);
    final settings = await datasource.getParentSettings();

    expect(results.map((stages) => stages.first.endAyah).toSet(), {3});
    expect(settings.kidsHouseSizesBySurah, {67: 3});
  });

  for (final remoteEnabled in [false, true]) {
  test('unknown legacy resume blocks freezing with remote=$remoteEnabled without a split choice', () async {
    final probe = _Probe(
      const KidsLegacyResumeProbeResult.choiceRequired(checkpointAyah: 3),
    );
    final service = serviceFor(
      remotePlanEnabled: remoteEnabled,
      legacyResumeProbe: probe,
    );
    await datasource.updateKidsHouseSettings(
      (current) => current.copyWith(
        remotePlan: const KidsRemotePlan(ayahsPerSession: 7),
      ),
    );

    final outcome = await service.getKidsJourney(
      surahId: 67,
      freezeForSession: true,
    );

    expect(outcome.isLeft(), isTrue);
    expect(probe.receivedLease, isNotNull);
    expect((await datasource.getParentSettings()).kidsHouseSizesBySurah,
        isEmpty);
    final preview = await journey(service, 67);
    expect(preview.first.endAyah, KidsSessionPolicy.forChildAge(null).journeyStageSize);
    expect((await datasource.getParentSettings()).kidsHouseSizesBySurah, isEmpty);
  });
  }

  test('an unreadable legacy checkpoint never blocks the session start', () async {
    final probe = _Probe(const KidsLegacyResumeProbeResult.unavailable());
    final service = serviceFor(legacyResumeProbe: probe);
    await service.setKidsAyahsPerHouse(2);

    final stages = await journey(service, 67, freezeForSession: true);

    expect(probe.calls, 1);
    expect(stages.first.endAyah, 2);
    // The safe default is used unfrozen, as before the probe existed.
    expect(
      (await datasource.getParentSettings()).kidsHouseSizesBySurah,
      isEmpty,
    );
  });

  test('established whole, frozen, and canonical history bypass the probe',
      () async {
    final probe = _Probe(
      const KidsLegacyResumeProbeResult.choiceRequired(checkpointAyah: 3),
    );
    final service = serviceFor(legacyResumeProbe: probe);
    await datasource.updateKidsHouseSettings(
      (current) => current.copyWith(kidsWholeSurahIds: {103}),
    );

    await journey(service, 103, freezeForSession: true);
    expect(probe.calls, 0);

    await datasource.updateKidsHouseSettings(
      (current) => current.copyWith(kidsHouseSizesBySurah: {67: 4}),
    );
    await journey(service, 67, freezeForSession: true);
    expect(probe.calls, 0);

    await seedRewards(113, [1]);
    await journey(service, 113, freezeForSession: true);
    expect(probe.calls, 0);
  });

  test('out-of-range log counts cannot attest complete canonical surah coverage', () async {
    final opened = <int>[];
    final service = serviceFor(remoteMilestoneUnlock: (id) async => opened.add(id));
    await seedRewards(67, List.generate(30, (index) => index + 100));
    final result = await service.awardKidsPoints(completionAuthorized: true,
      surahId: 67, ayahNumber: 1, repeatsCompleted: 3);
    await Future<void>.delayed(Duration.zero);
    expect(result.isRight(), isTrue);
    expect(opened, isEmpty);
  });

  test('an unavailable milestone side effect cannot fail a committed completion', () async {
    final service = serviceFor(remoteMilestoneUnlock: (_) async => throw StateError('offline'));
    await seedRewards(103, [1, 2]);
    final result = await service.awardKidsPoints(completionAuthorized: true,
      surahId: 103, ayahNumber: 3, repeatsCompleted: 3);
    await Future<void>.delayed(Duration.zero);
    expect(result.isRight(), isTrue);
    expect((await datasource.getKidsSessionLogs()).any((log) =>
      log.surahId == 103 && log.ayahNumber == 3), isTrue);
  });
}
