// lib/core/services/hifz_migration_service.dart
//
// One-time migration from legacy Hifz AyahProgress records → AyahReviewRecord.
//
// Safety guarantees:
//   - Source (IsarAyahProgress) is never deleted or modified.
//   - Only writes a new AyahReviewRecord if none already exists for that ayah.
//   - Writes a JSON backup of all source records to app storage before migrating.
//   - Runs exactly once per installation (guarded by SharedPreferences flag).
//   - All writes are wrapped in a try/catch; any failure is logged, not rethrown.
//
// Field mapping:
//   AyahProgress.surahId            → AyahReviewRecord.surahId          ✅
//   AyahProgress.ayahNumber         → AyahReviewRecord.ayahNumber        ✅
//   AyahProgress.repetitions        → AyahReviewRecord.totalReviews      ✅
//   AyahProgress.nextReviewDate     → AyahReviewRecord.nextReviewDate    ✅
//   AyahProgress.lastReviewDate     → AyahReviewRecord.lastReviewedAt    ✅
//   AyahProgress.status             → AyahReviewRecord.strengthLevel     (mapped)
//   —                               → AyahReviewRecord.intervalDays      (derived)
//   —                               → AyahReviewRecord.createdByMode     = migration
//   —                               → AyahReviewRecord.lastRating        = null

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/hifz/domain/entities/hifz_entities.dart';
import '../../features/hifz/domain/repositories/hifz_repository.dart';
import '../../features/memorization_plus/domain/entities/memorization_entities.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../utils/talia_logger.dart';

/// Service that runs the one-time migration of Hifz data into MemorizationPlus.
final class HifzMigrationService {
  HifzMigrationService({
    required HifzRepository hifzRepository,
    required MemorizationPlusRepository memPlusRepository,
    required SharedPreferences prefs,
  })  : _hifzRepo = hifzRepository,
        _memPlusRepo = memPlusRepository,
        _prefs = prefs;

  final HifzRepository _hifzRepo;
  final MemorizationPlusRepository _memPlusRepo;
  final SharedPreferences _prefs;

  static const String _migrationKey = 'hifz_v2_migration_done_v1';
  static const String _backupFileName = 'hifz_migration_backup.json';

  /// Returns true if the migration has already been completed.
  bool get isMigrationDone => _prefs.getBool(_migrationKey) ?? false;

  /// Runs the migration if it has not already been done.
  ///
  /// Safe to call at every app start — it is a no-op if already done.
  Future<void> runIfNeeded() async {
    if (isMigrationDone) return;

    TaliaLogger.i('HifzMigration: Starting one-time migration...');
    try {
      await _run();
      await _prefs.setBool(_migrationKey, true);
      TaliaLogger.i('HifzMigration: Completed successfully.');
    } catch (e, stack) {
      // Never crash the app due to migration failure.
      // The flag is NOT set so it will be retried on next launch.
      TaliaLogger.e('HifzMigration: Failed — will retry on next launch.', e,
          stack);
    }
  }

  Future<void> _run() async {
    // 1. Load all legacy Hifz progress records via per-surah queries.
    // HifzRepository has no getAllProgress — we use getDueReviews() + getAllSurahProgress()
    // to discover which surahs have data, then load per-surah.
    final allProgress = <AyahProgress>[];

    final surahProgressResult = await _hifzRepo.getAllSurahProgress();
    final surahIds = surahProgressResult.fold(
      (_) => <int>[],
      (list) => list.map((s) => s.surahId).toList(),
    );

    for (final surahId in surahIds) {
      final result = await _hifzRepo.getProgressForSurah(surahId);
      result.fold(
        (failure) => TaliaLogger.w(
          'HifzMigration: Failed to load surah $surahId: ${failure.message}',
        ),
        allProgress.addAll,
      );
    }

    if (allProgress.isEmpty) {
      TaliaLogger.i('HifzMigration: No Hifz records found — nothing to do.');
      return;
    }

    TaliaLogger.i(
        'HifzMigration: Found ${allProgress.length} records to migrate.');

    // 2. Write backup JSON before touching anything.
    await _writeBackup(allProgress);

    // 3. For each AyahProgress, create a matching AyahReviewRecord if none exists.
    int migrated = 0;
    int skipped = 0;

    for (final progress in allProgress) {
      try {
        // Check if a record already exists to avoid duplication.
        final existingResult = await _memPlusRepo.getReviewRecord(
          progress.surahId,
          progress.ayahNumber,
        );

        final alreadyExists = existingResult.fold(
          (_) => false,
          (record) => record != null,
        );

        if (alreadyExists) {
          skipped++;
          continue;
        }

        // Map AyahProgress → AyahReviewRecord.
        final record = _toReviewRecord(progress);
        await _memPlusRepo.saveReviewRecord(record);
        migrated++;
      } catch (e, stack) {
        TaliaLogger.w(
          'HifzMigration: Skipped ayah '
          '${progress.surahId}:${progress.ayahNumber} due to error.',
          e,
          stack,
        );
      }
    }

    TaliaLogger.i(
      'HifzMigration: $migrated migrated, $skipped already existed.',
    );
  }

  /// Maps an [AyahProgress] (legacy Hifz) to an [AyahReviewRecord] (V2/MemPlus).
  AyahReviewRecord _toReviewRecord(AyahProgress progress) {
    return AyahReviewRecord(
      surahId: progress.surahId,
      ayahNumber: progress.ayahNumber,
      strengthLevel: _statusToStrengthLevel(progress.status),
      intervalDays: _repetitionsToIntervalDays(progress.repetitions),
      nextReviewDate: progress.nextReviewDate,
      lastReviewedAt: progress.lastReviewDate,
      totalReviews: progress.repetitions,
      lastRating: null, // No rating data in legacy Hifz
      createdByMode: ReviewRecordCreatedByMode.migration,
    );
  }

  /// Maps legacy [AyahStatus] to V2 strength level (0-6).
  ///
  /// Mapping rationale:
  ///   notStarted → 0 (never reviewed)
  ///   learning   → 1 (early stage)
  ///   review     → 3 (mid stage — confirmed known but needs review)
  ///   memorized  → 5 (strong — close to fully memorized)
  int _statusToStrengthLevel(AyahStatus status) {
    return switch (status) {
      AyahStatus.notStarted => 0,
      AyahStatus.learning => 1,
      AyahStatus.review => 3,
      AyahStatus.memorized => 5,
    };
  }

  /// Derives a reasonable SM-2 interval from the repetition count.
  ///
  /// Uses the classic SM-2 approximate intervals: 1, 3, 7, 14, 30, 60...
  int _repetitionsToIntervalDays(int repetitions) {
    const intervals = [1, 3, 7, 14, 30, 60, 120];
    if (repetitions <= 0) return 1;
    final index = (repetitions - 1).clamp(0, intervals.length - 1);
    return intervals[index];
  }

  /// Writes a JSON backup of all source records to app storage.
  ///
  /// The backup is kept indefinitely and can be used for rollback by support.
  Future<void> _writeBackup(List<AyahProgress> records) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_backupFileName');
      final json = records
          .map(
            (p) => {
              'surahId': p.surahId,
              'ayahNumber': p.ayahNumber,
              'status': p.status.name,
              'repetitions': p.repetitions,
              'nextReviewDate': p.nextReviewDate.toIso8601String(),
              'lastReviewDate': p.lastReviewDate.toIso8601String(),
            },
          )
          .toList();
      await file.writeAsString(jsonEncode(json));
      TaliaLogger.i(
          'HifzMigration: Backup written to ${file.path} (${records.length} records).');
    } catch (e, stack) {
      // Backup failure is non-fatal — log and continue.
      TaliaLogger.w('HifzMigration: Backup write failed (non-fatal).', e,
          stack);
    }
  }
}
