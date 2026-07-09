import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/session_adapters.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

void main() {
  group('daily plan completion (B1)', () {
    late MemorizationPlusLocalDatasourceImpl datasource;
    late MemorizationPlusRepositoryImpl repository;
    late ProgressEventsBus progressEvents;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      datasource = MemorizationPlusLocalDatasourceImpl(prefs);
      progressEvents = ProgressEventsBus();
      repository = MemorizationPlusRepositoryImpl(
        datasource,
        _UnusedQuranRepository(),
        _FakeStreakReader(),
        progressEvents,
        prefs,
      );
    });

    tearDown(() {
      progressEvents.dispose();
    });

    test('markDailyPlanAyahCompleted persists ayah in cached plan', () async {
      final plan = DailyPlan(
        generatedAt: DateTime.utc(2026, 7, 8),
        surahId: 67,
        newAyahs: const [
          DailyPlanAyah(
            surahId: 67,
            ayahNumber: 3,
            ayahText: 'text',
            record: null,
          ),
        ],
        nearRevision: const [],
        farRevision: const [],
        completedAyahNums: const [1, 2],
      );
      await datasource.saveDailyPlan(DailyPlanModel.fromEntity(plan));

      final result = await repository.markDailyPlanAyahCompleted(
        surahId: 67,
        ayahNumber: 3,
      );

      expect(result, const Right(true));
      final cached = await datasource.getCachedDailyPlan();
      expect(cached?.completedAyahNums, contains(3));
    });

    test('markDailyPlanAyahCompleted is no-op when ayah not in plan', () async {
      final plan = DailyPlan(
        generatedAt: DateTime.utc(2026, 7, 8),
        surahId: 67,
        newAyahs: const [
          DailyPlanAyah(
            surahId: 67,
            ayahNumber: 3,
            ayahText: 'text',
            record: null,
          ),
        ],
        nearRevision: const [],
        farRevision: const [],
        completedAyahNums: const [],
      );
      await datasource.saveDailyPlan(DailyPlanModel.fromEntity(plan));

      final result = await repository.markDailyPlanAyahCompleted(
        surahId: 67,
        ayahNumber: 99,
      );

      expect(result, const Right(false));
      final cached = await datasource.getCachedDailyPlan();
      expect(cached?.completedAyahNums, isEmpty);
    });

    test('V2SessionReviewAdapter marks plan after recordPass', () async {
      final plan = DailyPlan(
        generatedAt: DateTime.utc(2026, 7, 8),
        surahId: 1,
        newAyahs: const [
          DailyPlanAyah(
            surahId: 1,
            ayahNumber: 2,
            ayahText: 'text',
            record: null,
          ),
        ],
        nearRevision: const [],
        farRevision: const [],
        completedAyahNums: const [1],
      );
      await datasource.saveDailyPlan(DailyPlanModel.fromEntity(plan));

      final adapter = V2SessionReviewAdapter(
        repository: repository,
        scheduler: const ScheduleNextReviewUsecase(),
        markDailyPlanCompleted: MarkDailyPlanAyahCompletedUsecase(repository),
      );

      final reasons = <ProgressChangedReason>[];
      progressEvents.changes.listen(reasons.add);

      await adapter.recordPass(
        surahId: 1,
        ayahNumber: 2,
        hintLevel: V2HintLevel.none,
      );

      final cached = await datasource.getCachedDailyPlan();
      expect(cached?.completedAyahNums, contains(2));
      expect(reasons, contains(ProgressChangedReason.dailyPlan));
      expect(reasons, contains(ProgressChangedReason.reviewRecord));
    });
  });
}

class _FakeStreakReader implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}

class _UnusedQuranRepository implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Not needed for daily plan tests');
}
