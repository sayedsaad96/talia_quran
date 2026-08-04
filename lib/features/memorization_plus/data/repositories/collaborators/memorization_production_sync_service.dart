import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/error/app_failure.dart';
import '../../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../../core/memorization/review_record_cloud_merge.dart';
import '../../../../certificate/domain/entities/certificate_award.dart';
import '../../../domain/entities/memorization_entities.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import '../../models/memorization_models.dart';
import 'memorization_cloud_gateway.dart';
import 'memorization_cloud_mappers.dart';

/// Production-mode cloud sync: pull production review records + daily plan
/// from Supabase, resync dirty local rows back up, push certificates and
/// answer "is there pending cloud work" for the auth gate.
class MemorizationProductionSyncService {
  MemorizationProductionSyncService(
    this._datasource,
    this._prefs,
    this._gateway,
    this._mappers,
  );

  final MemorizationPlusLocalDatasource _datasource;
  final SharedPreferences _prefs;
  final MemorizationCloudGateway _gateway;
  final MemorizationCloudMappers _mappers;

  /// Daily-plan dirty flag is also written by the facade's `saveDailyPlan`.
  static const dailyPlanCloudDirtyKey = 'daily_plan_cloud_dirty';

  static const _reviewPullCursorKey = 'ayah_review_pull_cursor';
  static const _syncedCertificateIdsKey = 'synced_certificate_ids';
  static const _pullCursorStaleAfter = Duration(hours: 24);

  bool get _isSupabaseReady => _gateway.isSupabaseReady;

  bool get _cloudPullEnabled => _gateway.cloudPullEnabled;

  SupabaseClient get _supabase => _gateway.supabase;

  bool _isProductionReviewRecord(AyahReviewRecord record) =>
      record.createdByMode == ReviewRecordCreatedByMode.v2Session ||
      record.createdByMode == ReviewRecordCreatedByMode.kidsMode ||
      record.createdByMode == ReviewRecordCreatedByMode.hifz;

  Future<Either<Failure, void>> pullProductionDataFromCloud() async {
    try {
      if (!_isSupabaseReady || !_cloudPullEnabled) return const Right(null);
      final client = _supabase;
      final user = client.auth.currentUser;
      if (user == null) return const Right(null);

      var cursor = _readReviewPullCursor();
      var pages = 0;
      const maxPages = 20;

      while (pages < maxPages) {
        pages += 1;
        List<dynamic> rows;
        try {
          rows = await client.rpc(
            'pull_ayah_review_records_since',
            params: {
              'p_cursor': cursor.toUtc().toIso8601String(),
              'p_limit': 500,
            },
          ) as List<dynamic>? ??
              const [];
        } on PostgrestException catch (e) {
          if (!_gateway.isMissingRpc(e, 'pull_ayah_review_records_since')) {
            rethrow;
          }
          // Legacy fallback: one full pull, then stop.
          rows =
              await client.rpc('pull_ayah_review_records') as List<dynamic>? ??
                  const [];
          await _applyCloudReviewRows(rows.cast<Map<String, dynamic>>());
          await _mergeDailyPlanFromCloud(client, user.id);
          await _markReviewPullCompleted();
          return const Right(null);
        }

        final cloudRows = rows.cast<Map<String, dynamic>>();
        if (cloudRows.isEmpty) break;

        await _applyCloudReviewRows(cloudRows);

        DateTime? newest;
        for (final row in cloudRows) {
          final updatedRaw = row['updated_at'] as String?;
          if (updatedRaw == null) continue;
          final updated = DateTime.parse(updatedRaw).toUtc();
          if (newest == null || updated.isAfter(newest)) newest = updated;
        }
        if (newest != null) {
          cursor = newest;
          await _prefs.setString(
            _reviewPullCursorKey,
            cursor.toIso8601String(),
          );
        }
        if (cloudRows.length < 500) break;
      }

      await _mergeDailyPlanFromCloud(client, user.id);
      await _markReviewPullCompleted();
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  DateTime _readReviewPullCursor() {
    final raw = _prefs.getString(_reviewPullCursorKey);
    if (raw == null || raw.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    try {
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
  }

  bool isReviewPullCursorStale() {
    final lastPullRaw = _prefs.getString('${_reviewPullCursorKey}_pulled_at');
    if (lastPullRaw == null) return true;
    try {
      final lastPull = DateTime.parse(lastPullRaw).toUtc();
      return DateTime.now().toUtc().difference(lastPull) > _pullCursorStaleAfter;
    } catch (_) {
      return true;
    }
  }

  Future<void> _markReviewPullCompleted() async {
    await _prefs.setString(
      '${_reviewPullCursorKey}_pulled_at',
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<void> _applyCloudReviewRows(
    List<Map<String, dynamic>> cloudRows,
  ) async {
    for (final row in cloudRows) {
      final cloudRecord = _mappers.reviewRecordFromCloud(row);
      if (!_isProductionReviewRecord(cloudRecord)) continue;

      final readScope = ReviewRecordAudienceScope.scopeForWriteMode(
        cloudRecord.createdByMode,
      );
      final localModel = await _datasource.getReviewRecord(
        cloudRecord.surahId,
        cloudRecord.ayahNumber,
        scope: readScope,
      );
      final merged = ReviewRecordCloudMerge.merge(
        local: localModel,
        remote: cloudRecord,
      );
      final mergedModel = AyahReviewRecordModel.fromEntity(merged);
      if (localModel == null || localModel != mergedModel) {
        await _datasource.saveReviewRecord(
          mergedModel,
          markCloudDirty: false,
        );
      }
    }
  }

  Future<bool> _mergeDailyPlanFromCloud(
    SupabaseClient client,
    String userId,
  ) async {
    final rows = await client
        .from('daily_plans_cloud')
        .select()
        .eq('user_id', userId);
    if (rows.isEmpty) return false;

    final row = rows.first;
    final cloudGeneratedAt = DateTime.parse(row['generated_at'] as String);
    final local = await _datasource.getCachedDailyPlan();
    if (local != null && !cloudGeneratedAt.isAfter(local.generatedAt.toUtc())) {
      return false;
    }

    final payload = row['payload'];
    if (payload is! Map<String, dynamic>) return false;

    try {
      await _datasource.saveDailyPlan(DailyPlanModel.fromJson(payload));
      await _prefs.setBool(dailyPlanCloudDirtyKey, false);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Either<Failure, void>> resyncProductionDataToCloud() async {
    try {
      if (!_isSupabaseReady) return const Right(null);
      final client = _supabase;
      final user = client.auth.currentUser;
      if (user == null) return const Right(null);

      final dirtyRecords = await _datasource.getCloudDirtyReviewRecords(
        includeAllAudiences: true,
      );
      final productionRecords = dirtyRecords
          .where(_isProductionReviewRecord)
          .toList();
      if (productionRecords.isNotEmpty) {
        await _pushReviewRecordsBatch(client, productionRecords);
        await _datasource.markReviewRecordsCloudSynced(
          productionRecords.map(_reviewRecordStorageKey),
        );
      }

      if (_prefs.getBool(dailyPlanCloudDirtyKey) ?? false) {
        final cachedPlan = await _datasource.getCachedDailyPlan();
        if (cachedPlan != null) {
          await _upsertDailyPlanRow(client, user.id, cachedPlan);
          await _prefs.setBool(dailyPlanCloudDirtyKey, false);
        }
      }

      return const Right(null);
    } catch (e) {
      // Best-effort resync: local state remains authoritative. The next
      // resume/login retry will pick up anything that failed here.
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> pushCertificatesToCloud(
    List<CertificateAward> certificates,
  ) async {
    final unsynced = certificates
        .where((c) => !_syncedCertificateIds().contains(c.id))
        .toList();
    if (unsynced.isEmpty) return const Right(null);
    try {
      if (!_isSupabaseReady) return const Right(null);
      final client = _supabase;
      final user = client.auth.currentUser;
      if (user == null) return const Right(null);

      final rows = unsynced
          .map(
            (c) => {
              'user_id': user.id,
              'cert_id': c.id,
              'title_ar': c.titleAr,
              'cert_type': c.type.name,
              'earned_at': c.earnedAt.toUtc().toIso8601String(),
            },
          )
          .toList();

      // ignoreDuplicates → ON CONFLICT DO NOTHING: certificates are
      // immutable once earned, and the RLS policy only grants INSERT+SELECT.
      await client
          .from('certificate_awards_cloud')
          .upsert(rows, onConflict: 'user_id,cert_id', ignoreDuplicates: true);
      await _markCertificatesSynced(unsynced.map((c) => c.id));
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Set<String> _syncedCertificateIds() {
    final raw = _prefs.getStringList(_syncedCertificateIdsKey);
    return raw == null ? <String>{} : raw.toSet();
  }

  Future<void> _markCertificatesSynced(Iterable<String> ids) async {
    final merged = _syncedCertificateIds()..addAll(ids);
    await _prefs.setStringList(_syncedCertificateIdsKey, merged.toList());
  }

  Future<bool> hasPendingCloudWork() async {
    final dirtyRecords = await _datasource.getCloudDirtyReviewRecords(
      includeAllAudiences: true,
    );
    if (dirtyRecords.any(_isProductionReviewRecord)) return true;
    if (_prefs.getBool(dailyPlanCloudDirtyKey) ?? false) return true;

    final logs = await _datasource.getKidsSessionLogs();
    if (logs.any((log) => !log.isSynced)) return true;

    return isReviewPullCursorStale();
  }

  String _reviewRecordStorageKey(AyahReviewRecord record) =>
      ReviewRecordAudienceScope.storageKey(
        surahId: record.surahId,
        ayahNumber: record.ayahNumber,
        mode: record.createdByMode,
        scoped: ReviewRecordAudienceScope.isEnabled(
          readBool: (key) => _prefs.getBool(key) ?? false,
        ),
      );

  Future<void> _pushReviewRecordsBatch(
    SupabaseClient client,
    List<AyahReviewRecord> records,
  ) async {
    if (records.isEmpty) return;
    const chunkSize = 500;
    for (var i = 0; i < records.length; i += chunkSize) {
      final end = min(i + chunkSize, records.length);
      final payload = records
          .sublist(i, end)
          .map(
            (r) => {
              'surah_id': r.surahId,
              'ayah_number': r.ayahNumber,
              'strength_level': r.strengthLevel,
              'interval_days': r.intervalDays,
              'last_reviewed_at': r.lastReviewedAt.toUtc().toIso8601String(),
              'next_review_date': r.nextReviewDate.toUtc().toIso8601String(),
              'total_reviews': r.totalReviews,
              'last_rating': r.lastRating?.name,
              'ease_factor': r.easeFactor,
              'lapses': r.lapses,
              'review_state': r.reviewState.name,
              'created_by_mode': r.createdByMode.name,
              'sync_version': r.lastReviewedAt.toUtc().millisecondsSinceEpoch,
              'difficulty': r.difficulty,
              'stability': r.stability,
            },
          )
          .toList();
      await client.rpc(
        'upsert_ayah_review_records',
        params: {'p_data': payload},
      );
    }
  }

  Future<void> _upsertDailyPlanRow(
    SupabaseClient client,
    String userId,
    DailyPlan plan,
  ) async {
    await client.from('daily_plans_cloud').upsert({
      'user_id': userId,
      'surah_id': plan.surahId,
      'generated_at': plan.generatedAt.toUtc().toIso8601String(),
      'total_items': plan.totalItems,
      'completed_count': plan.requiredCompletedCount,
      'payload': DailyPlanModel.fromEntity(plan).toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }
}
