import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_home_mission.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_daily_missions.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

import 'kids_journey_cubit_test.mocks.dart';

const _surahId = 1;
const _stages = <KidsJourneyStage>[
  KidsJourneyStage(
    stageNumber: 1,
    surahId: _surahId,
    startAyah: 1,
    endAyah: 3,
    completedAyahs: [],
    status: KidsJourneyStageStatus.current,
  ),
];
const _surah = Surah(
  id: _surahId,
  nameAr: 'الفاتحة',
  nameEn: 'Al-Fatihah',
  ayahCount: 7,
  juz: 1,
  type: 'meccan',
  page: 1,
);

final _guardianMission = KidsHomeMission(
  id: 'from-guardian',
  title: 'mission',
  status: KidsHomeMissionStatus.assigned,
  createdAt: DateTime(2026, 10, 5),
);

void main() {
  late MockGetKidsJourneyUsecase getJourney;
  late MockGetKidsProgressUsecase getProgress;
  late MockQuranRepository quran;
  late List<KidsHomeMission> localMissions;
  late List<bool> refreshCalls;
  late bool pullLands;
  late KidsJourneyCubit cubit;

  setUp(() {
    getJourney = MockGetKidsJourneyUsecase();
    getProgress = MockGetKidsProgressUsecase();
    quran = MockQuranRepository();
    when(getJourney(any)).thenAnswer((_) async => const Right(_stages));
    when(
      getProgress(),
    ).thenAnswer((_) async => const Right(KidsProgress.initial()));
    when(quran.getSurahDetail(_surahId)).thenAnswer(
      (_) async => const Right(SurahDetail(surah: _surah, ayahs: [])),
    );
    localMissions = [];
    refreshCalls = [];
    pullLands = true;
    cubit = KidsJourneyCubit(
      getJourney,
      getProgress,
      quran,
      homeMissionsLoader: () async => localMissions,
      inboundRefresh: ({bool force = false}) async {
        refreshCalls.add(force);
        if (pullLands) localMissions = [_guardianMission];
        return pullLands;
      },
    );
  });

  tearDown(() => cubit.close());

  bool hasHomeCard(KidsJourneyState state) =>
      state is KidsJourneyLoaded &&
      state.dailyMissions.any((m) => m.kind == KidsDailyMissionKind.home);

  test('a pulled guardian mission appears without a loading flash', () async {
    await cubit.load(surahId: _surahId, followFrontier: true);
    expect(hasHomeCard(cubit.state), isFalse);
    final states = <KidsJourneyState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.refreshFromGuardian(surahId: _surahId, force: true);
    await sub.cancel();

    expect(refreshCalls, [true]);
    expect(states, isNot(contains(isA<KidsJourneyLoading>())));
    expect(hasHomeCard(cubit.state), isTrue);
  });

  test('a pull that did not land does not reload', () async {
    pullLands = false;
    await cubit.load(surahId: _surahId, followFrontier: true);
    clearInteractions(getJourney);

    await cubit.refreshFromGuardian(surahId: _surahId);

    expect(refreshCalls, [false]);
    verifyNever(getJourney(any));
  });

  test('pull-to-refresh forces the pull and reloads even offline', () async {
    pullLands = false;
    await cubit.load(surahId: _surahId, followFrontier: true);
    clearInteractions(getJourney);

    await cubit.refresh(surahId: _surahId);

    expect(refreshCalls, [true]);
    verify(getJourney(any)).called(greaterThan(0));
    expect(cubit.state, isA<KidsJourneyLoaded>());
  });

  test('a slower earlier load never overwrites a newer one', () async {
    final firstProgress = Completer<void>();
    var calls = 0;
    when(getProgress()).thenAnswer((_) async {
      calls++;
      if (calls == 1) await firstProgress.future;
      return const Right(KidsProgress.initial());
    });

    final first = cubit.load(surahId: _surahId, followFrontier: true);
    await cubit.refreshFromGuardian(surahId: _surahId, force: true);
    expect(hasHomeCard(cubit.state), isTrue);

    localMissions = [];
    firstProgress.complete();
    await first;

    expect(hasHomeCard(cubit.state), isTrue);
  });

  test('a throwing refresh keeps the current state', () async {
    final throwing = KidsJourneyCubit(
      getJourney,
      getProgress,
      quran,
      inboundRefresh: ({bool force = false}) async => throw StateError('net'),
    );
    addTearDown(throwing.close);
    await throwing.load(surahId: _surahId, followFrontier: true);
    final before = throwing.state;

    await throwing.refreshFromGuardian(surahId: _surahId, force: true);

    expect(throwing.state, same(before));
  });
}
