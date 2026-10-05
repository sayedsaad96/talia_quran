import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_home_mission.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/parent_reward_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/kids_home_missions_usecase.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/parent_reward_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_treasures_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class _MockMemorizationRepo extends Mock
    implements MemorizationPlusRepository {}

class _MockQuranRepo extends Mock implements QuranRepository {}

Surah _surah(int id, int ayahCount) => Surah(
  id: id,
  nameAr: 's$id',
  nameEn: 's$id',
  ayahCount: ayahCount,
  juz: 30,
  type: 'meccan',
  page: 604,
);

KidsSessionLog _log(int surahId, int ayah) => KidsSessionLog(
  id: '$surahId-$ayah',
  surahId: surahId,
  ayahNumber: ayah,
  repeatsCompleted: 3,
  pointsEarned: 10,
  completedAt: DateTime(2026, 10, 1),
);

void main() {
  late _MockMemorizationRepo memRepo;
  late _MockQuranRepo quranRepo;

  setUp(() {
    memRepo = _MockMemorizationRepo();
    quranRepo = _MockQuranRepo();
  });

  KidsTreasuresCubit build(List<CertificateAward> certs) =>
      KidsTreasuresCubit(memRepo, quranRepo, certificatesLoader: () => certs);

  test('loads region progress and the kids certificates', () async {
    when(() => memRepo.getKidsSessionLogs()).thenAnswer(
      (_) async => Right([for (var a = 1; a <= 6; a++) _log(114, a)]),
    );
    when(
      () => quranRepo.getSurahs(),
    ).thenAnswer((_) async => Right([_surah(114, 6), _surah(113, 5)]));
    final cert = CertificateAward(
      id: 'c1',
      titleAr: 'شهادة',
      type: CertificateType.surah,
      earnedAt: DateTime(2026, 10, 1),
    );

    final cubit = build([cert]);
    addTearDown(cubit.close);
    await cubit.load();

    final state = cubit.state as KidsTreasuresLoaded;
    expect(state.regions[1].memorized, 1);
    expect(state.certificates.length, 1);
  });

  test('a surahs-load failure emits KidsTreasuresError', () async {
    when(
      () => memRepo.getKidsSessionLogs(),
    ).thenAnswer((_) async => const Right(<KidsSessionLog>[]));
    when(
      () => quranRepo.getSurahs(),
    ).thenAnswer((_) async => const Left(CacheFailure()));

    final cubit = build(const []);
    addTearDown(cubit.close);
    await cubit.load();

    expect(cubit.state, isA<KidsTreasuresError>());
    expect(
      (cubit.state as KidsTreasuresError).message,
      CubitMessageCodes.errorCache,
    );
  });

  test('a session-log failure emits KidsTreasuresError', () async {
    when(
      () => memRepo.getKidsSessionLogs(),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    when(
      () => quranRepo.getSurahs(),
    ).thenAnswer((_) async => Right([_surah(114, 6)]));

    final cubit = build(const []);
    addTearDown(cubit.close);
    await cubit.load();

    expect(cubit.state, isA<KidsTreasuresError>());
  });

  test('a throwing certificates loader emits KidsTreasuresError', () async {
    when(
      () => memRepo.getKidsSessionLogs(),
    ).thenAnswer((_) async => const Right(<KidsSessionLog>[]));
    when(
      () => quranRepo.getSurahs(),
    ).thenAnswer((_) async => Right([_surah(114, 6)]));

    final cubit = KidsTreasuresCubit(
      memRepo,
      quranRepo,
      certificatesLoader: () => throw StateError('boom'),
    );
    addTearDown(cubit.close);
    await cubit.load();

    expect(cubit.state, isA<KidsTreasuresError>());
  });

  group('gifts', () {
    late _FakeRewardRepo rewardRepo;

    setUp(() {
      rewardRepo = _FakeRewardRepo([_reward(ParentRewardStatus.unlocked)]);
      when(
        () => memRepo.getKidsSessionLogs(),
      ).thenAnswer((_) async => const Right(<KidsSessionLog>[]));
      when(
        () => quranRepo.getSurahs(),
      ).thenAnswer((_) async => Right([_surah(114, 6)]));
    });

    KidsTreasuresCubit buildWithGifts() => KidsTreasuresCubit(
      memRepo,
      quranRepo,
      certificatesLoader: () => const [],
      rewards: ParentRewardUsecase(rewardRepo),
    );

    test('load includes the device gifts', () async {
      final cubit = buildWithGifts();
      addTearDown(cubit.close);
      await cubit.load();

      final state = cubit.state as KidsTreasuresLoaded;
      expect(state.rewards.single.status, ParentRewardStatus.unlocked);
    });

    test('a failing gift read keeps the page and hides the gifts', () async {
      rewardRepo.readFailure = const CacheFailure();
      final cubit = buildWithGifts();
      addTearDown(cubit.close);
      await cubit.load();

      expect((cubit.state as KidsTreasuresLoaded).rewards, isEmpty);
    });

    test('requesting a gift reloads it as requested', () async {
      final cubit = buildWithGifts();
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.requestReward('g1');

      final state = cubit.state as KidsTreasuresLoaded;
      expect(state.rewards.single.status, ParentRewardStatus.requested);
      expect(state.rewardMessage, isNull);
    });

    test('a refused request surfaces a fresh message each time', () async {
      rewardRepo.requestFailure = const CacheFailure(
        CubitMessageCodes.parentRewardUnavailable,
      );
      final cubit = buildWithGifts();
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.requestReward('g1');
      final first = cubit.state as KidsTreasuresLoaded;
      await cubit.requestReward('g1');
      final second = cubit.state as KidsTreasuresLoaded;

      expect(first.rewardMessage, CubitMessageCodes.parentRewardUnavailable);
      expect(second.rewardMessageId, first.rewardMessageId + 1);
      expect(second.rewards.single.status, ParentRewardStatus.unlocked);
    });

    test('a double tap sends a single request', () async {
      final cubit = buildWithGifts();
      addTearDown(cubit.close);
      await cubit.load();

      await Future.wait([cubit.requestReward('g1'), cubit.requestReward('g1')]);

      expect(rewardRepo.requests, 1);
    });
  });

  group('home missions', () {
    var enabled = true;

    setUp(() {
      enabled = true;
      when(
        () => memRepo.getKidsSessionLogs(),
      ).thenAnswer((_) async => const Right(<KidsSessionLog>[]));
      when(
        () => quranRepo.getSurahs(),
      ).thenAnswer((_) async => Right([_surah(114, 6)]));
      when(() => memRepo.getHomeMissions()).thenAnswer(
        (_) async => Right([
          _mission('done', KidsHomeMissionStatus.acknowledged, 1),
          _mission('told', KidsHomeMissionStatus.reported, 2),
          _mission('new2', KidsHomeMissionStatus.assigned, 4),
          _mission('new1', KidsHomeMissionStatus.assigned, 3),
        ]),
      );
    });

    KidsTreasuresCubit buildWithMissions() => KidsTreasuresCubit(
      memRepo,
      quranRepo,
      certificatesLoader: () => const [],
      homeMissions: KidsHomeMissionsUsecase(memRepo),
      homeMissionsEnabled: () => enabled,
    );

    test('lists every open mission, new ones first, oldest first', () async {
      final cubit = buildWithMissions();
      addTearDown(cubit.close);
      await cubit.load();

      final state = cubit.state as KidsTreasuresLoaded;
      expect(state.homeMissions.map((m) => m.id), ['new1', 'new2', 'told']);
      expect(state.homeMissionsPaused, isFalse);
    });

    test('a paused policy hides the list and says why', () async {
      enabled = false;
      final cubit = buildWithMissions();
      addTearDown(cubit.close);
      await cubit.load();

      final state = cubit.state as KidsTreasuresLoaded;
      expect(state.homeMissions, isEmpty);
      expect(state.homeMissionsPaused, isTrue);
      verifyNever(() => memRepo.getHomeMissions());
    });

    test('a failing mission read keeps the page', () async {
      when(
        () => memRepo.getHomeMissions(),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      final cubit = buildWithMissions();
      addTearDown(cubit.close);
      await cubit.load();

      expect((cubit.state as KidsTreasuresLoaded).homeMissions, isEmpty);
    });

    test('reporting a mission refreshes the open list', () async {
      when(() => memRepo.reportHomeMission('new1')).thenAnswer(
        (_) async => Right([
          _mission('new1', KidsHomeMissionStatus.reported, 3),
          _mission('new2', KidsHomeMissionStatus.assigned, 4),
        ]),
      );
      final cubit = buildWithMissions();
      addTearDown(cubit.close);
      await cubit.load();

      await Future.wait([
        cubit.reportHomeMission('new1'),
        cubit.reportHomeMission('new1'),
      ]);

      final state = cubit.state as KidsTreasuresLoaded;
      expect(state.homeMissions.map((m) => m.id), ['new2', 'new1']);
      verify(() => memRepo.reportHomeMission('new1')).called(1);
    });

    test('a refused report surfaces a message', () async {
      when(() => memRepo.reportHomeMission('new1')).thenAnswer(
        (_) async => const Left(
          CacheFailure(CubitMessageCodes.kidsHomeMissionUnavailable),
        ),
      );
      final cubit = buildWithMissions();
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.reportHomeMission('new1');

      final state = cubit.state as KidsTreasuresLoaded;
      expect(state.rewardMessage, CubitMessageCodes.kidsHomeMissionUnavailable);
      expect(state.homeMissions.length, 3);
    });
  });
}

KidsHomeMission _mission(String id, KidsHomeMissionStatus status, int day) =>
    KidsHomeMission(
      id: id,
      title: 'مهمة $id',
      status: status,
      createdAt: DateTime.utc(2026, 10, day),
    );

ParentReward _reward(ParentRewardStatus status) => ParentReward(
  id: 'g1',
  title: 'نزهة',
  status: status,
  createdAt: DateTime.utc(2026, 10, 1),
);

class _FakeRewardRepo implements ParentRewardRepository {
  _FakeRewardRepo(this.rewards);

  List<ParentReward> rewards;
  Failure? readFailure;
  Failure? requestFailure;
  int requests = 0;

  @override
  Future<Either<Failure, List<ParentReward>>> getDeviceRewards() async =>
      readFailure == null ? Right(rewards) : Left(readFailure!);

  @override
  Future<Either<Failure, List<ParentReward>>> requestParentReward(
    String id,
  ) async {
    requests++;
    if (requestFailure != null) return Left(requestFailure!);
    rewards = [
      for (final r in rewards)
        r.id == id ? r.copyWith(status: ParentRewardStatus.requested) : r,
    ];
    return Right(rewards);
  }

  @override
  Future<Either<Failure, List<ParentReward>>> unlockParentReward(
    String id, {
    String? childUserId,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, List<ParentReward>>> approveParentReward(
    String id, {
    String? childUserId,
  }) => throw UnimplementedError();
}
