import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

void main() {
  late MemorizationPlusLocalDatasourceImpl datasource;
  late MemorizationPlusRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    datasource = MemorizationPlusLocalDatasourceImpl(prefs);
    repository = MemorizationPlusRepositoryImpl(
      datasource,
      _UnusedQuranRepository(),
      _ZeroStreakReader(),
      ProgressEventsBus(),
      prefs,
    );
  });

  Future<String> addReward() async {
    final saved = await repository.saveParentReward('نزهة');
    return saved.getOrElse(() => throw StateError('save failed')).single.id;
  }

  ParentReward single(Either<Failure, List<ParentReward>> result) =>
      result.getOrElse(() => throw StateError('$result')).single;

  void expectUnavailable(Either<Failure, List<ParentReward>> result) {
    expect(
      result.fold((f) => f.message, (_) => null),
      CubitMessageCodes.parentRewardUnavailable,
    );
  }

  test('a gift goes locked, unlocked, requested, then claimed', () async {
    final id = await addReward();

    final unlocked = single(await repository.unlockParentReward(id));
    expect(unlocked.status, ParentRewardStatus.unlocked);
    expect(unlocked.unlockedAt, isNotNull);

    final requested = single(await repository.requestParentReward(id));
    expect(requested.status, ParentRewardStatus.requested);
    expect(requested.requestedAt, isNotNull);
    expect(requested.claimedAt, isNull);

    final claimed = single(await repository.approveParentReward(id));
    expect(claimed.status, ParentRewardStatus.claimed);
    expect(claimed.claimedAt, isNotNull);

    final stored = (await datasource.getParentRewards()).single;
    expect(stored.status, ParentRewardStatus.claimed);
    expect(stored.requestedAt, requested.requestedAt);
  });

  test('the child cannot request a gift that is still locked', () async {
    final id = await addReward();

    expectUnavailable(await repository.requestParentReward(id));
    expect(
      (await datasource.getParentRewards()).single.status,
      ParentRewardStatus.locked,
    );
  });

  test('the guardian cannot approve a gift nobody requested', () async {
    final id = await addReward();
    await repository.unlockParentReward(id);

    expectUnavailable(await repository.approveParentReward(id));
    expect(
      (await datasource.getParentRewards()).single.status,
      ParentRewardStatus.unlocked,
    );
  });

  test('the old claim entry point only files a request', () async {
    final id = await addReward();
    await repository.unlockParentReward(id);

    final result = single(await repository.claimParentReward(id));

    expect(result.status, ParentRewardStatus.requested);
    expect(result.claimedAt, isNull);
  });

  test('repeating a finished step is a no-op that succeeds', () async {
    final id = await addReward();
    await repository.unlockParentReward(id);
    final first = single(await repository.requestParentReward(id));

    final again = single(await repository.requestParentReward(id));
    final reUnlock = single(await repository.unlockParentReward(id));

    expect(again.status, ParentRewardStatus.requested);
    expect(again.requestedAt, first.requestedAt);
    expect(reUnlock.status, ParentRewardStatus.requested);
  });

  test('an unknown gift id is reported as unavailable', () async {
    await addReward();

    expectUnavailable(await repository.unlockParentReward('missing'));
  });

  group('ParentRewardModel', () {
    test('keeps stored status indexes stable', () {
      expect(ParentRewardStatus.locked.index, 0);
      expect(ParentRewardStatus.unlocked.index, 1);
      expect(ParentRewardStatus.claimed.index, 2);
      expect(ParentRewardStatus.requested.index, 3);
    });

    test('round-trips a requested gift', () {
      final at = DateTime.utc(2026, 10, 5, 9);
      final model = ParentRewardModel(
        id: 'g1',
        title: 'نزهة',
        status: ParentRewardStatus.requested,
        createdAt: at,
        unlockedAt: at,
        requestedAt: at,
      );

      final back = ParentRewardModel.fromJson(model.toJson());

      expect(back.status, ParentRewardStatus.requested);
      expect(back.requestedAt, at);
    });

    test('reads an unknown status index as locked', () {
      final json = ParentRewardModel(
        id: 'g1',
        title: 'نزهة',
        status: ParentRewardStatus.locked,
        createdAt: DateTime.utc(2026),
      ).toJson()..['status'] = 99;

      expect(
        ParentRewardModel.fromJson(json).status,
        ParentRewardStatus.locked,
      );
    });
  });
}

class _ZeroStreakReader implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}

class _UnusedQuranRepository implements QuranRepository {
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
