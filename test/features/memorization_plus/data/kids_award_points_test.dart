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

void main() {
  late MemorizationKidsLocalService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = MemorizationKidsLocalService(
      MemorizationPlusLocalDatasourceImpl(prefs),
      _UnusedQuranRepository(),
      _FakeStreakReader(),
      _FakeProgressEventsBus(),
      null,
    );
  });

  Future<int> award(
    int ayah, {
    KidsMissionType missionType = KidsMissionType.newMemorization,
    int attemptCount = 1,
    int hintCount = 0,
    PerformanceRating masteryRating = PerformanceRating.excellent,
  }) async {
    final result = await service.awardKidsPoints(
      completionAuthorized: true,
      sessionId: 'session-$ayah-${DateTime.now().microsecondsSinceEpoch}',
      surahId: 114,
      ayahNumber: ayah,
      repeatsCompleted: 2,
      missionType: missionType,
      durationSeconds: 60,
      attemptCount: attemptCount,
      hintCount: hintCount,
      masteryRating: masteryRating,
    );
    return result.fold((failure) => -1, (completion) => completion.pointsEarned);
  }

  test('a perfect first-try new ayah earns the excellence bonus', () async {
    final points = await award(1);

    expect(points, 15); // 10 base + 5 excellence bonus
  });

  test('an ayah that needed retries earns the base reward only', () async {
    final points = await award(
      2,
      attemptCount: 3,
      hintCount: 1,
      masteryRating: PerformanceRating.weak,
    );

    expect(points, 10);
  });

  test('a review pass earns the reduced review reward', () async {
    final reviewPoints = await award(
      1,
      missionType: KidsMissionType.dueReview,
      attemptCount: 2,
      masteryRating: PerformanceRating.average,
    );

    expect(reviewPoints, 5);
  });

  test('review points survive projection rebuilds but not star inflation', () async {
    await award(1); // canonical 15 points, 3 stars (excellent)
    final reviewPoints = await award(
      1,
      missionType: KidsMissionType.dueReview,
    );
    expect(reviewPoints, 5);

    final progressResult = await service.getKidsProgress();
    final progress = progressResult.getOrElse(() => throw StateError('fail'));
    // 15 + 5 review points rebuild from the evidence log; stars stay tied
    // to the canonical reward only.
    expect(progress.totalPoints, 20);
    expect(progress.starsEarned, 3);
    expect(progress.ayahsCompleted, 1);
  });

  test('fifty total points reach level 2 under the early curve', () async {
    // Two perfect ayahs (30) + one base ayah (10) + two reviews (10) = 50.
    await award(1);
    await award(2);
    await award(3, attemptCount: 2, masteryRating: PerformanceRating.average);
    await award(1, missionType: KidsMissionType.linkedReview);
    await award(2, missionType: KidsMissionType.dueReview);

    final progressResult = await service.getKidsProgress();
    final progress = progressResult.getOrElse(() => throw StateError('fail'));

    expect(progress.totalPoints, 50);
    expect(progress.currentLevel, 2);
  });

  test('a second canonical pass of the same ayah never double-awards', () async {
    final first = await award(4);
    final second = await award(
      4,
      attemptCount: 1,
      masteryRating: PerformanceRating.excellent,
    );

    expect(first, 15);
    expect(second, 0); // canonical guard: the ayah is already rewarded
  });
}
