import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/parent_reward_cloud_merge.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

void main() {
  ParentRewardModel reward({
    required String id,
    required ParentRewardOrigin origin,
    String? ownerId,
    String? serverId,
  }) => ParentRewardModel(
    id: id,
    title: 'gift $id',
    status: ParentRewardStatus.locked,
    createdAt: DateTime.utc(2026, 10, 21),
    origin: origin,
    ownerId: ownerId,
    serverId: serverId,
  );

  test('legacy reward JSON is unknown and stays preserved', () {
    final legacy = ParentRewardModel.fromJson({
      'id': '123',
      'title': 'legacy',
      'status': 0,
      'createdAt': '2026-10-21T00:00:00.000Z',
    });

    expect(legacy.origin, ParentRewardOrigin.unknown);
    expect(legacy.serverId, isNull);
    expect(legacy.ownerId, isNull);
  });

  group('gifts stored before origins existed', () {
    Future<MemorizationPlusLocalDatasourceImpl> deviceWithLegacyGift({
      required bool linked,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final source = MemorizationPlusLocalDatasourceImpl(
        prefs,
        owner: const FixedRecordOwnerProvider('child-a'),
      );
      final now = DateTime.utc(2026, 10, 1);
      await source.saveMemorizationProfile(
        MemorizationProfileModel(
          schemaVersion: 1,
          selectedPath: MemorizationPath.child,
          guardianLinkStatus: linked
              ? GuardianLinkStatus.linked
              : GuardianLinkStatus.none,
          guardianOnboardingStatus: GuardianOnboardingStatus.completed,
          isParentGuardian: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
      // The pre-upgrade app wrote no origin, server id, or owner.
      await source.saveParentRewards([
        ParentRewardModel.fromJson({
          'id': '42',
          'title': 'old gift',
          'status': ParentRewardStatus.locked.index,
          'createdAt': '2026-10-01T00:00:00.000Z',
        }),
      ]);
      return source;
    }

    test('an unlinked device reads them as its own local gifts', () async {
      final source = await deviceWithLegacyGift(linked: false);

      final gift = (await source.getParentRewards()).single;

      expect(gift.origin, ParentRewardOrigin.local);
      expect(gift.ownerId, 'child-a');
      expect(gift.serverId, isNull);
    });

    test('a linked device reads them as cloud mirrors, and the next pull '
        'replaces them without a duplicate', () async {
      final source = await deviceWithLegacyGift(linked: true);

      final gift = (await source.getParentRewards()).single;
      expect(gift.origin, ParentRewardOrigin.cloud);
      expect(gift.serverId, '42');
      expect(gift.ownerId, 'child-a');

      await source.updateParentRewards(
        (current) async => ParentRewardCloudMerge.completeSnapshot(
          current: current,
          ownerId: 'child-a',
          cloudSnapshot: [
            reward(
              id: '42',
              origin: ParentRewardOrigin.cloud,
              serverId: '42',
              ownerId: 'child-a',
            ),
          ],
        ),
      );

      expect(await source.getParentRewards(), hasLength(1));
    });
  });

  test('provenance JSON round-trips server id and owner', () {
    final original = reward(
      id: '42',
      origin: ParentRewardOrigin.cloud,
      serverId: '42',
      ownerId: 'child-a',
    );

    expect(ParentRewardModel.fromJson(original.toJson()), original);
  });

  test('complete cloud snapshot preserves local and unknown id collisions', () {
    final merged = ParentRewardCloudMerge.completeSnapshot(
      ownerId: 'child-a',
      current: [
        reward(id: '42', origin: ParentRewardOrigin.local, ownerId: 'child-a'),
        reward(id: '42', origin: ParentRewardOrigin.unknown),
        reward(
          id: '42',
          origin: ParentRewardOrigin.cloud,
          serverId: '42',
          ownerId: 'child-a',
        ),
      ],
      cloudSnapshot: [
        reward(
          id: '42',
          origin: ParentRewardOrigin.cloud,
          serverId: '42',
          ownerId: 'child-a',
        ),
      ],
    );

    expect(merged, hasLength(3));
    expect(
      merged.map((item) => item.origin),
      containsAll([
        ParentRewardOrigin.local,
        ParentRewardOrigin.unknown,
        ParentRewardOrigin.cloud,
      ]),
    );
  });

  test('acknowledgement replaces only its full provenance identity', () {
    final local = reward(
      id: '42',
      origin: ParentRewardOrigin.local,
      ownerId: 'child-a',
    );
    final cloud = reward(
      id: '42',
      origin: ParentRewardOrigin.cloud,
      ownerId: 'child-a',
      serverId: '42',
    ).copyWith(status: ParentRewardStatus.unlocked);

    final merged = ParentRewardCloudMerge.mergeAcknowledged(
      current: [
        local,
        reward(
          id: '42',
          origin: ParentRewardOrigin.cloud,
          ownerId: 'child-a',
          serverId: '42',
        ),
      ],
      acknowledged: [cloud],
    );

    expect(merged, contains(local));
    expect(
      merged
          .singleWhere((item) => item.origin == ParentRewardOrigin.cloud)
          .status,
      ParentRewardStatus.unlocked,
    );
  });

  test(
    'serialized mutation re-reads and keeps a local reward created first',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final source = MemorizationPlusLocalDatasourceImpl(
        prefs,
        owner: const FixedRecordOwnerProvider('child-a'),
      );
      await source.updateParentRewards(
        (_) async => [
          reward(
            id: 'local',
            origin: ParentRewardOrigin.local,
            ownerId: 'child-a',
          ),
        ],
      );
      await source.updateParentRewards(
        (current) async => ParentRewardCloudMerge.completeSnapshot(
          current: current,
          ownerId: 'child-a',
          cloudSnapshot: [
            reward(
              id: '42',
              origin: ParentRewardOrigin.cloud,
              ownerId: 'child-a',
              serverId: '42',
            ),
          ],
        ),
      );

      expect(
        (await source.getParentRewards()).map((item) => item.id),
        containsAll(['local', '42']),
      );
    },
  );

  test('invalidated reward lease cannot commit a queued mutation', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const owner = FixedRecordOwnerProvider('child-a');
    final source = MemorizationPlusLocalDatasourceImpl(prefs, owner: owner);
    final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    final lease = source.captureParentRewardsLease();
    barrier.invalidate();

    await expectLater(
      source.updateParentRewards(
        (_) async => [
          reward(
            id: 'late',
            origin: ParentRewardOrigin.local,
            ownerId: 'child-a',
          ),
        ],
        authority: lease,
      ),
      throwsA(isA<AccountDataUnavailableException>()),
    );
    expect(await source.getParentRewards(), isEmpty);
  });

  test('a reward request begun before reset cannot mutate the replacement cache',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const owner = FixedRecordOwnerProvider('child-a');
    final source = _DelayedRewardDatasource(prefs, owner: owner);
    final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    final old = reward(
      id: 'same-id',
      origin: ParentRewardOrigin.local,
      ownerId: 'child-a',
    ).copyWith(status: ParentRewardStatus.unlocked);
    final replacement = reward(
      id: 'same-id',
      origin: ParentRewardOrigin.local,
      ownerId: 'child-a',
    ).copyWith(status: ParentRewardStatus.unlocked);
    await source.saveParentRewards([ParentRewardModel.fromEntity(old)]);
    final repository = MemorizationPlusRepositoryImpl(
      source,
      _NoQuran(),
      _NoStreak(),
      ProgressEventsBus(),
      prefs,
      owner: owner,
    );

    final request = repository.requestParentReward('same-id');
    await source.entered.future;
    await barrier.clear(() async {
      await prefs.clear();
      await source.saveParentRewards([ParentRewardModel.fromEntity(replacement)]);
    });
    source.release.complete();

    expect((await request).isLeft(), isTrue);
    expect((await source.getParentRewards()).single.status,
        ParentRewardStatus.unlocked);
  });
}

class _DelayedRewardDatasource extends MemorizationPlusLocalDatasourceImpl {
  _DelayedRewardDatasource(super.prefs, {required super.owner});

  final entered = Completer<void>();
  final release = Completer<void>();
  var _delayNextRead = true;

  @override
  Future<List<ParentRewardModel>> getParentRewards() async {
    final snapshot = await super.getParentRewards();
    if (_delayNextRead) {
      _delayNextRead = false;
      entered.complete();
      await release.future;
    }
    return snapshot;
  }
}

class _NoStreak implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}

class _NoQuran implements QuranRepository {
  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) =>
      throw UnimplementedError();
}
