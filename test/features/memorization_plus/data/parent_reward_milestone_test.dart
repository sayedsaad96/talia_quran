import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_cloud_mappers.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

Map<String, dynamic> _json({Object? milestone = _absent}) => {
  'id': 'g1',
  'title': 'نزهة',
  'status': 0,
  'createdAt': '2026-10-01T00:00:00.000Z',
  if (!identical(milestone, _absent)) 'milestoneSurahId': milestone,
};

const Object _absent = Object();

void main() {
  group('ParentRewardModel milestone', () {
    test('round-trips milestoneSurahId through local JSON', () {
      final model = ParentRewardModel.fromJson(_json(milestone: 78));
      expect(model.milestoneSurahId, 78);
      expect(model.toJson()['milestoneSurahId'], 78);
      expect(ParentRewardModel.fromJson(model.toJson()).milestoneSurahId, 78);
    });

    test('an old record without the field has no milestone', () {
      expect(ParentRewardModel.fromJson(_json()).milestoneSurahId, isNull);
    });

    test('an invalid stored value becomes null', () {
      for (final bad in <Object?>[0, -3, 115, 'x', 3.5, true, null]) {
        expect(
          ParentRewardModel.fromJson(_json(milestone: bad)).milestoneSurahId,
          isNull,
          reason: '$bad',
        );
      }
    });

    test('copyWith keeps the milestone and fromEntity copies it', () {
      final model = ParentRewardModel.fromJson(_json(milestone: 112));
      final next = model.copyWith(status: ParentRewardStatus.unlocked);
      expect(next.milestoneSurahId, 112);
      expect(ParentRewardModel.fromEntity(next).milestoneSurahId, 112);
    });
  });

  group('local save', () {
    late MemorizationPlusRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repository = MemorizationPlusRepositoryImpl(
        MemorizationPlusLocalDatasourceImpl(prefs),
        _UnusedQuranRepository(),
        _ZeroStreakReader(),
        ProgressEventsBus(),
        prefs,
      );
    });

    test('stores the chosen surah with the gift', () async {
      final saved = await repository.saveParentReward(
        'نزهة',
        milestoneSurahId: 112,
      );
      expect(saved.getOrElse(() => []).single.milestoneSurahId, 112);
      final read = await repository.getDeviceRewards();
      expect(read.getOrElse(() => []).single.milestoneSurahId, 112);
    });

    test('a gift without a condition has no milestone', () async {
      final saved = await repository.saveParentReward('نزهة');
      expect(saved.getOrElse(() => []).single.milestoneSurahId, isNull);
    });

    test('an unknown surah id is not stored', () async {
      final saved = await repository.saveParentReward(
        'نزهة',
        milestoneSurahId: 999,
      );
      expect(saved.getOrElse(() => []).single.milestoneSurahId, isNull);
    });

    test('the limit counts graphemes, so a vowelled title fits', () async {
      final title = 'بَ' * 80; // 160 code points, 80 graphemes
      final ok = await repository.saveParentReward(title);
      expect(ok.isRight(), isTrue);
    });

    test('the title is limited to 80 characters', () async {
      final ok = await repository.saveParentReward('ا' * 80);
      expect(ok.isRight(), isTrue);

      final tooLong = await repository.saveParentReward('ا' * 81);
      expect(
        tooLong.fold((f) => f.message, (_) => null),
        CubitMessageCodes.parentRewardTitleTooLong,
      );
      final all = await repository.getDeviceRewards();
      expect(all.getOrElse(() => []).length, 1);
    });
  });

  group('cloud milestone provenance', () {
    test('rewardFromCloud keeps a valid server milestone', () {
      final mapper = MemorizationCloudMappers(const ProgressMetricsService());
      final reward = mapper.rewardFromCloud({
        'id': 'r1',
        'title': 'نزهة',
        'status': 'locked',
        'created_at': '2026-10-01T00:00:00.000Z',
        'milestone_surah_id': 78,
        'milestoneSurahId': 78,
      });
      expect(reward.milestoneSurahId, 78);
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
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
