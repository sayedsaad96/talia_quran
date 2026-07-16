import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/services/hifz_migration_service.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/hifz/domain/entities/hifz_entities.dart';
import 'package:talia_quran/features/hifz/domain/repositories/hifz_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';

void main() {
  group('HifzMigrationService', () {
    test('migrates legacy Hifz as hifz source with memorized strength 6', () async {
      final memPlus = _InMemoryMemPlusRepository();
      final service = await _buildService(
        memPlus: memPlus,
        hifzProgress: [
          _legacyProgress(status: AyahStatus.memorized, repetitions: 8),
        ],
      );

      await service.runIfNeeded();

      expect(memPlus.records, hasLength(1));
      final record = memPlus.records.first;
      expect(record.createdByMode, ReviewRecordCreatedByMode.hifz);
      expect(record.strengthLevel, 6);
      expect(record.lastRating, isNull);
      expect(service.isMigrationDone, isTrue);
      expect(service.isRepairDone, isTrue);
    });

    test('repair retags explicit migrated keys from v2Session to hifz', () async {
      SharedPreferences.setMockInitialValues({
        'hifz_v2_migration_done_v1': true,
        'hifz_migration_migrated_keys_v1': ['1_1'],
      });
      final prefs = await SharedPreferences.getInstance();
      final memPlus = _InMemoryMemPlusRepository(
        initialRecords: [
          _reviewRecord(
            strengthLevel: 3,
            mode: ReviewRecordCreatedByMode.v2Session,
          ),
        ],
      );
      final service = HifzMigrationService(
        hifzRepository: _EmptyHifzRepository(),
        memPlusRepository: memPlus,
        prefs: prefs,
      );

      await service.runRepairIfNeeded();

      expect(memPlus.records.first.createdByMode, ReviewRecordCreatedByMode.hifz);
      expect(memPlus.records.first.strengthLevel, 3);
      expect(service.isRepairDone, isTrue);
    });

    test('repair lifts legacy memorized strength 5 to 6', () async {
      SharedPreferences.setMockInitialValues({
        'hifz_v2_migration_done_v1': true,
        'hifz_migration_migrated_keys_v1': ['1_1'],
      });
      final prefs = await SharedPreferences.getInstance();
      final memPlus = _InMemoryMemPlusRepository(
        initialRecords: [
          _reviewRecord(
            strengthLevel: 5,
            mode: ReviewRecordCreatedByMode.v2Session,
          ),
        ],
      );
      final service = HifzMigrationService(
        hifzRepository: _EmptyHifzRepository(),
        memPlusRepository: memPlus,
        prefs: prefs,
      );

      await service.runRepairIfNeeded();

      final record = memPlus.records.first;
      expect(record.createdByMode, ReviewRecordCreatedByMode.hifz);
      expect(record.strengthLevel, 6);
    });

    test('repair heuristic skips genuine v2Session records with ratings', () async {
      SharedPreferences.setMockInitialValues({
        'hifz_v2_migration_done_v1': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final original = _reviewRecord(
        strengthLevel: 4,
        mode: ReviewRecordCreatedByMode.v2Session,
        lastRating: PerformanceRating.excellent,
      );
      final memPlus = _InMemoryMemPlusRepository(initialRecords: [original]);
      final service = HifzMigrationService(
        hifzRepository: _EmptyHifzRepository(),
        memPlusRepository: memPlus,
        prefs: prefs,
      );

      await service.runRepairIfNeeded();

      expect(memPlus.records.first, original);
    });

    test('repair is idempotent on second run', () async {
      SharedPreferences.setMockInitialValues({
        'hifz_v2_migration_done_v1': true,
        'hifz_migration_migrated_keys_v1': ['1_1'],
      });
      final prefs = await SharedPreferences.getInstance();
      final memPlus = _InMemoryMemPlusRepository(
        initialRecords: [
          _reviewRecord(
            strengthLevel: 5,
            mode: ReviewRecordCreatedByMode.v2Session,
          ),
        ],
      );
      final service = HifzMigrationService(
        hifzRepository: _EmptyHifzRepository(),
        memPlusRepository: memPlus,
        prefs: prefs,
      );

      await service.runRepairIfNeeded();
      final afterFirst = memPlus.records.first;

      await service.runRepairIfNeeded();

      expect(memPlus.records.first, afterFirst);
    });
  });
}

Future<HifzMigrationService> _buildService({
  required _InMemoryMemPlusRepository memPlus,
  required List<AyahProgress> hifzProgress,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return HifzMigrationService(
    hifzRepository: _FakeHifzRepository(hifzProgress),
    memPlusRepository: memPlus,
    prefs: prefs,
  );
}

AyahProgress _legacyProgress({
  required AyahStatus status,
  required int repetitions,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return AyahProgress(
    surahId: 1,
    ayahNumber: 1,
    status: status,
    repetitions: repetitions,
    nextReviewDate: now.add(const Duration(days: 30)),
    lastReviewDate: now,
  );
}

AyahReviewRecord _reviewRecord({
  required int strengthLevel,
  required ReviewRecordCreatedByMode mode,
  PerformanceRating? lastRating,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return AyahReviewRecord(
    surahId: 1,
    ayahNumber: 1,
    strengthLevel: strengthLevel,
    intervalDays: 7,
    lastReviewedAt: now,
    nextReviewDate: now.add(const Duration(days: 7)),
    totalReviews: 4,
    lastRating: lastRating,
    createdByMode: mode,
  );
}

class _FakeHifzRepository implements HifzRepository {
  _FakeHifzRepository(this.progress);

  final List<AyahProgress> progress;

  @override
  Future<Either<Failure, List<SurahHifzProgress>>> getAllSurahProgress() async {
    if (progress.isEmpty) return const Right([]);
    return Right([
      SurahHifzProgress(
        surahId: progress.first.surahId,
        totalAyahs: progress.length,
        memorizedCount: progress.length,
        reviewCount: 0,
        learningCount: 0,
      ),
    ]);
  }

  @override
  Future<Either<Failure, List<AyahProgress>>> getProgressForSurah(
    int surahId,
  ) async {
    return Right(progress.where((p) => p.surahId == surahId).toList());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyHifzRepository implements HifzRepository {
  @override
  Future<Either<Failure, List<SurahHifzProgress>>> getAllSurahProgress() async =>
      const Right([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InMemoryMemPlusRepository implements MemorizationPlusRepository {
  _InMemoryMemPlusRepository({List<AyahReviewRecord>? initialRecords})
    : records = List<AyahReviewRecord>.from(initialRecords ?? const []);

  final List<AyahReviewRecord> records;

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async =>
      Right(List<AyahReviewRecord>.from(records));

  @override
  Future<Either<Failure, AyahReviewRecord?>> getReviewRecord(
    int surahId,
    int ayahNumber, {
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async {
    for (final record in records) {
      if (record.surahId == surahId && record.ayahNumber == ayahNumber) {
        return Right(record);
      }
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveReviewRecord(
    AyahReviewRecord record,
  ) async {
    final index = records.indexWhere(
      (r) => r.surahId == record.surahId && r.ayahNumber == record.ayahNumber,
    );
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> hasPendingCloudWork() async => false;
}
