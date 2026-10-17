import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_kids_local_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

class _UnusedQuranRepository implements QuranRepository {
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

Future<MemorizationKidsLocalService> _service({required bool promiseOn}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return MemorizationKidsLocalService(
    MemorizationPlusLocalDatasourceImpl(prefs),
    _UnusedQuranRepository(),
    _FakeStreakReader(),
    _FakeProgressEventsBus(),
    null,
    promiseEnabled: () => promiseOn,
  );
}

/// Saves one milestone gift, reaches the weekly goal and returns the gift's
/// status afterwards.
Future<ParentRewardStatus> _statusAfterWeeklyGoal(
  MemorizationKidsLocalService service,
) async {
  await service.saveParentReward('نزهة', milestoneSurahId: 112);
  for (var ayah = 1; ayah <= 5; ayah++) {
    await service.awardKidsPoints(
      completionAuthorized: true,
      sessionId: 'session-$ayah',
      surahId: 114,
      ayahNumber: ayah,
      repeatsCompleted: 2,
      durationSeconds: 60,
    );
  }
  final rewards = (await service.getParentRewards()).getOrElse(() => []);
  return rewards.single.status;
}

void main() {
  test('with the promise feature on, a surah gift stays locked', () async {
    final service = await _service(promiseOn: true);

    expect(await _statusAfterWeeklyGoal(service), ParentRewardStatus.locked);
  });

  test('with the promise feature off, a surah gift is a plain gift', () async {
    final service = await _service(promiseOn: false);

    expect(await _statusAfterWeeklyGoal(service), ParentRewardStatus.unlocked);
  });
}
