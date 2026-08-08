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
//   —                               → AyahReviewRecord.createdByMode     = hifz
//   —                               → AyahReviewRecord.lastRating        = null

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/hifz/domain/entities/hifz_entities.dart';
import '../../features/hifz/domain/repositories/hifz_repository.dart';
import '../../features/memorization_plus/domain/entities/memorization_entities.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../memorization/review_record_audience_scope.dart';
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
  static const String _repairKey = 'hifz_migration_repair_v1';
  static const String _migratedKeysKey = 'hifz_migration_migrated_keys_v1';
  static const String _backupFileName = 'hifz_migration_backup.json';

  /// Returns true if the migration has already been completed.
  bool get isMigrationDone => _prefs.getBool(_migrationKey) ?? false;

  /// Returns true if the one-time repair pass has already completed.
  bool get isRepairDone => _prefs.getBool(_repairKey) ?? false;

  /// Runs the migration if it has not already been done, then the repair pass.
  ///
  /// Safe to call at every app start — both steps are no-ops when already done.
  Future<void> runIfNeeded() async {
    if (!isMigrationDone) {
      TaliaLogger.i('HifzMigration: Starting one-time migration...');
      try {
        await _run();
        await _prefs.setBool(_migrationKey, true);
        TaliaLogger.i('HifzMigration: Completed successfully.');
      } catch (e, stack) {
        TaliaLogger.e(
          'HifzMigration: Failed — will retry on next launch.',
          e,
          stack,
        );
        return;
      }
    }

    await runRepairIfNeeded();
  }

  /// Repairs legacy imports that were incorrectly tagged as [v2Session].
  ///
  /// Uses the explicit migrated-key list when available; otherwise falls back
  /// to a conservative heuristic (`v2Session`, `lastRating == null`,
  /// `totalReviews > 0`) for installs migrated before key tracking existed.
  Future<void> runRepairIfNeeded() async {
    if (isRepairDone) return;

    TaliaLogger.i('HifzMigration: Starting one-time repair pass...');
    try {
      await _runRepair();
      await _prefs.setBool(_repairKey, true);
      TaliaLogger.i('HifzMigration: Repair pass completed.');
    } catch (e, stack) {
      TaliaLogger.e(
        'HifzMigration: Repair failed — will retry on next launch.',
        e,
        stack,
      );
    }
  }

  Future<void> _run() async {
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
      'HifzMigration: Found ${allProgress.length} records to migrate.',
    );

    await _writeBackup(allProgress);

    final migratedKeys = <String>[];
    var migrated = 0;
    var skipped = 0;

    for (final progress in allProgress) {
      try {
        final existingResult = await _memPlusRepo.getReviewRecord(
          progress.surahId,
          progress.ayahNumber,
          scope: ReviewRecordReadScope.adult,
        );

        final alreadyExists = existingResult.fold(
          (_) => false,
          (record) => record != null,
        );

        if (alreadyExists) {
          skipped++;
          continue;
        }

        final record = _toReviewRecord(progress);
        await _memPlusRepo.saveReviewRecord(record);
        migratedKeys.add(record.key);
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

    if (migratedKeys.isNotEmpty) {
      await _prefs.setStringList(_migratedKeysKey, migratedKeys);
    }

    TaliaLogger.i(
      'HifzMigration: $migrated migrated, $skipped already existed.',
    );
  }

  Future<void> _runRepair() async {
    final recordsResult = await _memPlusRepo.getAllReviewRecords(
      scope: ReviewRecordReadScope.adult,
    );
    final records = recordsResult.fold((_) => <AyahReviewRecord>[], (r) => r);
    if (records.isEmpty) return;

    final explicitKeys = _prefs.getStringList(_migratedKeysKey)?.toSet() ?? {};
    final useExplicitKeys = explicitKeys.isNotEmpty;

    var repaired = 0;
    for (final record in records) {
      if (!_shouldRepairRecord(
        record,
        explicitKeys,
        useExplicitKeys: useExplicitKeys,
      )) {
        continue;
      }

      final fixed = _repairRecord(record);
      if (fixed == record) continue;

      await _memPlusRepo.saveReviewRecord(fixed);
      repaired++;
    }

    TaliaLogger.i('HifzMigration: Repaired $repaired review records.');
  }

  /// Maps an [AyahProgress] (legacy Hifz) to an [AyahReviewRecord].
  AyahReviewRecord _toReviewRecord(AyahProgress progress) {
    return AyahReviewRecord(
      surahId: progress.surahId,
      ayahNumber: progress.ayahNumber,
      strengthLevel: _statusToStrengthLevel(progress.status),
      intervalDays: _repetitionsToIntervalDays(progress.repetitions),
      nextReviewDate: progress.nextReviewDate,
      lastReviewedAt: progress.lastReviewDate,
      totalReviews: progress.repetitions,
      lastRating: null,
      createdByMode: ReviewRecordCreatedByMode.hifz,
    );
  }

  /// Maps legacy [AyahStatus] to SRS strength level (0-6).
  ///
  /// Mapping rationale:
  ///   notStarted → 0 (never reviewed)
  ///   learning   → 1 (early stage)
  ///   review     → 3 (mid stage — confirmed known but needs review)
  ///   memorized  → 6 (fully memorized — matches [ReviewRecordFilters.isMemorized])
  int _statusToStrengthLevel(AyahStatus status) {
    return switch (status) {
      AyahStatus.notStarted => 0,
      AyahStatus.learning => 1,
      AyahStatus.review => 3,
      AyahStatus.memorized => 6,
    };
  }

  bool _shouldRepairRecord(
    AyahReviewRecord record,
    Set<String> explicitKeys, {
    required bool useExplicitKeys,
  }) {
    if (record.createdByMode == ReviewRecordCreatedByMode.hifz) {
      return record.strengthLevel == 5 && record.lastRating == null;
    }

    if (record.createdByMode != ReviewRecordCreatedByMode.v2Session) {
      return false;
    }

    if (useExplicitKeys) {
      return explicitKeys.contains(record.key);
    }

    return record.lastRating == null && record.totalReviews > 0;
  }

  AyahReviewRecord _repairRecord(AyahReviewRecord record) {
    final needsTag = record.createdByMode == ReviewRecordCreatedByMode.v2Session;
    final needsStrengthLift =
        record.strengthLevel == 5 && record.lastRating == null;

    if (!needsTag && !needsStrengthLift) return record;

    return record.copyWith(
      createdByMode: needsTag
          ? ReviewRecordCreatedByMode.hifz
          : record.createdByMode,
      strengthLevel: needsStrengthLift ? 6 : record.strengthLevel,
    );
  }

  int _repetitionsToIntervalDays(int repetitions) {
    const intervals = [1, 3, 7, 14, 30, 60, 120];
    if (repetitions <= 0) return 1;
    final index = (repetitions - 1).clamp(0, intervals.length - 1);
    return intervals[index];
  }

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
        'HifzMigration: Backup written to ${file.path} (${records.length} records).',
      );
    } catch (e, stack) {
      TaliaLogger.w('HifzMigration: Backup write failed (non-fatal).', e, stack);
    }
  }
}
