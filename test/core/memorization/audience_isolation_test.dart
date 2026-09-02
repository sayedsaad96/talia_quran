import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/v2/ayah_failure_tracker.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/session_adapters.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

bool _isarCoreInitialized = false;

Future<void> _initializeIsarCoreForTests() async {
  if (_isarCoreInitialized) return;

  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final dllPath =
          '$localAppData\\Pub\\Cache\\hosted\\pub.dev\\'
          'isar_flutter_libs-3.1.0+1\\windows\\isar.dll';
      if (File(dllPath).existsSync()) {
        await Isar.initializeIsarCore(libraries: {Abi.current(): dllPath});
        _isarCoreInitialized = true;
        return;
      }
    }
  }

  await Isar.initializeIsarCore();
  _isarCoreInitialized = true;
}

void main() {
  group('audience isolation (B4)', () {
    late Isar isar;
    late MemorizationPlusLocalDatasourceImpl datasource;
    late MemorizationPlusRepositoryImpl repository;
    late V2SessionReviewAdapter reviewAdapter;
    late ProgressEventsBus progressEvents;

    setUp(() async {
      await _initializeIsarCoreForTests();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dir = await Directory.systemTemp.createTemp('talia_audience_b4_');
      isar = await Isar.open(
        [IsarAyahReviewRecordSchema],
        directory: dir.path,
        name: 'audience_isolation_${DateTime.now().microsecondsSinceEpoch}',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });

      datasource = MemorizationPlusLocalDatasourceImpl(
        prefs,
        isar: isar,
        owner: const FixedRecordOwnerProvider('user-a'),
      );
      progressEvents = ProgressEventsBus();
      repository = MemorizationPlusRepositoryImpl(
        datasource,
        _UnusedQuranRepository(),
        _FakeStreakReader(),
        progressEvents,
        prefs,
      );
      reviewAdapter = V2SessionReviewAdapter(
        repository: repository,
        scheduler: const ScheduleNextReviewUsecase(),
      );
    });

    tearDown(() {
      progressEvents.dispose();
    });

    test('kids pass does not overwrite adult record on same ayah', () async {
      const surahId = 67;
      const ayahNumber = 3;
      final now = DateTime.utc(2026, 7, 8);

      final adultRecord = AyahReviewRecordModel(
        surahId: surahId,
        ayahNumber: ayahNumber,
        strengthLevel: 5,
        intervalDays: 14,
        lastReviewedAt: now,
        nextReviewDate: now.add(const Duration(days: 14)),
        totalReviews: 8,
        lastRating: PerformanceRating.excellent,
        createdByMode: ReviewRecordCreatedByMode.v2Session,
      );
      await datasource.saveReviewRecord(adultRecord);

      await reviewAdapter.recordPass(
        surahId: surahId,
        ayahNumber: ayahNumber,
        hintLevel: V2HintLevel.none,
        createdByMode: ReviewRecordCreatedByMode.kidsMode,
      );

      final adultAfter = await datasource.getReviewRecord(
        surahId,
        ayahNumber,
        scope: ReviewRecordReadScope.adult,
      );
      final kidsAfter = await datasource.getReviewRecord(
        surahId,
        ayahNumber,
        scope: ReviewRecordReadScope.kids,
      );

      expect(adultAfter, isNotNull);
      expect(adultAfter!.strengthLevel, 5);
      expect(adultAfter.totalReviews, 8);
      expect(adultAfter.createdByMode, ReviewRecordCreatedByMode.v2Session);

      expect(kidsAfter, isNotNull);
      expect(kidsAfter!.createdByMode, ReviewRecordCreatedByMode.kidsMode);
      expect(kidsAfter.totalReviews, 1);
    });

    test('kids weak ayah signal is stored only in kids records', () async {
      var tracker = const V2AyahFailureTracker();
      for (var attempt = 0; attempt < 3; attempt++) {
        tracker = tracker.recordFailure(surahId: 114, ayahNumber: 2);
      }

      await reviewAdapter.recordWeakAyahs(
        tracker,
        passedAyahNumbers: const {},
        createdByMode: ReviewRecordCreatedByMode.kidsMode,
      );

      final kids = await datasource.getReviewRecord(
        114,
        2,
        scope: ReviewRecordReadScope.kids,
      );
      final adult = await datasource.getReviewRecord(
        114,
        2,
        scope: ReviewRecordReadScope.adult,
      );
      expect(kids?.lastRating, PerformanceRating.weak);
      expect(kids?.createdByMode, ReviewRecordCreatedByMode.kidsMode);
      expect(adult, isNull);
    });
    test('adult pass does not overwrite kids record on same ayah', () async {
      const surahId = 114;
      const ayahNumber = 1;
      final now = DateTime.utc(2026, 7, 8);

      final kidsRecord = AyahReviewRecordModel(
        surahId: surahId,
        ayahNumber: ayahNumber,
        strengthLevel: 3,
        intervalDays: 7,
        lastReviewedAt: now,
        nextReviewDate: now.add(const Duration(days: 7)),
        totalReviews: 4,
        lastRating: PerformanceRating.average,
        createdByMode: ReviewRecordCreatedByMode.kidsMode,
      );
      await datasource.saveReviewRecord(kidsRecord);

      await reviewAdapter.recordPass(
        surahId: surahId,
        ayahNumber: ayahNumber,
        hintLevel: V2HintLevel.none,
        createdByMode: ReviewRecordCreatedByMode.v2Session,
      );

      final kidsAfter = await datasource.getReviewRecord(
        surahId,
        ayahNumber,
        scope: ReviewRecordReadScope.kids,
      );
      final adultAfter = await datasource.getReviewRecord(
        surahId,
        ayahNumber,
        scope: ReviewRecordReadScope.adult,
      );

      expect(kidsAfter, isNotNull);
      expect(kidsAfter!.strengthLevel, 3);
      expect(kidsAfter.totalReviews, 4);
      expect(kidsAfter.createdByMode, ReviewRecordCreatedByMode.kidsMode);

      expect(adultAfter, isNotNull);
      expect(adultAfter!.createdByMode, ReviewRecordCreatedByMode.v2Session);
      expect(adultAfter.totalReviews, 1);
    });
  });
}

class _UnusedQuranRepository implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeStreakReader implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}
