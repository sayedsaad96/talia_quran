import 'dart:convert';
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/error/app_failure.dart';
import '../../../../../core/identity/record_owner_provider.dart';
import '../../../../../core/memorization/custom_plan_cloud_merge.dart';
import '../../../../../core/memorization/daily_plan_cloud_merge.dart';
import '../../../../../core/memorization/plan_cloud_dirty_keys.dart';
import '../../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../../core/memorization/review_record_cloud_merge.dart';
import '../../../../../core/memorization/review_record_cloud_push_acknowledgement.dart';
import '../../../../../core/memorization/review_record_identity.dart';
import '../../../../../core/memorization/review_record_pull_cursor.dart';
import '../../../../../core/sync/sync_result.dart';
import '../../../../certificate/domain/entities/certificate_award.dart';
import '../../../domain/entities/memorization_entities.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import '../../models/memorization_models.dart';
import 'memorization_cloud_gateway.dart';
import 'memorization_cloud_mappers.dart';

/// Production-mode cloud sync: pull production review records, daily plan,
/// and custom plan from Supabase; resync dirty local rows; push certificates;
/// answer "is there pending cloud work" for the auth gate.
class MemorizationProductionSyncService {
  MemorizationProductionSyncService(
    this._datasource,
    this._prefs,
    this._gateway,
    this._mappers, {
    RecordOwnerProvider owner = const SupabaseRecordOwnerProvider(),
  }) : _owner = owner;

  final MemorizationPlusLocalDatasource _datasource;
  final SharedPreferences _prefs;
  final MemorizationCloudGateway _gateway;
  final MemorizationCloudMappers _mappers;
  final RecordOwnerProvider _owner;

  /// Daily-plan dirty flag is also written by the facade's `saveDailyPlan`.
  static const dailyPlanCloudDirtyKey = PlanCloudDirtyKeys.dailyPlan;

  /// Custom-plan dirty flag — set on save/delete in [MemorizationCustomPlanService].
  static const customPlanCloudDirtyKey = PlanCloudDirtyKeys.customPlan;

  static const _reviewPullCursorKey = 'ayah_review_pull_cursor';
  static const _syncedCertificateIdsKey = 'synced_certificate_ids';
  static const _dailyPlanRevisionKey = 'daily_plan_cloud_revision';
  static const _customPlanRevisionKey = 'custom_plan_cloud_revision';
  static const _dailyPlanConflictKey = 'daily_plan_cloud_conflict';
  static const _customPlanConflictKey = 'custom_plan_cloud_conflict';
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
      final expectedOwner = user.id;
      if (_owner.currentOwnerId != expectedOwner) {
        return const Right(null);
      }

      var cursor = _readReviewPullCursor();
      var pages = 0;
      const maxPages = 20;

      while (pages < maxPages) {
        pages += 1;
        List<dynamic> rows;
        try {
          rows =
              await client.rpc(
                    'pull_ayah_review_records_since',
                    params: {
                      'p_cursor_updated_at': cursor.updatedAt
                          .toUtc()
                          .toIso8601String(),
                      'p_cursor_id': cursor.id,
                      'p_limit': 500,
                    },
                  )
                  as List<dynamic>? ??
              const [];
        } on PostgrestException catch (e) {
          if (!_gateway.isMissingRpc(e, 'pull_ayah_review_records_since')) {
            rethrow;
          }
          // Legacy fallback: one full pull, then stop.
          rows =
              await client.rpc('pull_ayah_review_records') as List<dynamic>? ??
              const [];
          await _applyCloudReviewRows(
            rows.cast<Map<String, dynamic>>(),
            expectedOwner: expectedOwner,
          );
          await _mergeDailyPlanFromCloud(client, user.id);
          await _mergeCustomPlanFromCloud(client, user.id);
          await _markReviewPullCompleted();
          return const Right(null);
        }

        final cloudRows = rows.cast<Map<String, dynamic>>();
        if (cloudRows.isEmpty) break;
        if (_owner.currentOwnerId != expectedOwner) {
          return const Right(null);
        }

        await _applyCloudReviewRows(cloudRows, expectedOwner: expectedOwner);

        ReviewRecordPullCursor? newest;
        for (final row in cloudRows) {
          try {
            final rowCursor = ReviewRecordPullCursor.fromCloudRow(row);
            if (newest == null || newest.isBefore(rowCursor)) {
              newest = rowCursor;
            }
          } on FormatException {
            // Invalid rows cannot advance the cursor and will be retried.
          }
        }
        if (newest != null) {
          cursor = newest;
          await _prefs.setString(_reviewPullCursorKey, cursor.toStorage());
        }
        if (cloudRows.length < 500) break;
      }

      await _mergeDailyPlanFromCloud(client, user.id);
      await _mergeCustomPlanFromCloud(client, user.id);
      await _markReviewPullCompleted();
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure.from(e));
    }
  }

  ReviewRecordPullCursor _readReviewPullCursor() =>
      ReviewRecordPullCursor.fromStorage(
        _prefs.getString(_reviewPullCursorKey),
      );

  bool isReviewPullCursorStale() {
    final lastPullRaw = _prefs.getString('${_reviewPullCursorKey}_pulled_at');
    if (lastPullRaw == null) return true;
    try {
      final lastPull = DateTime.parse(lastPullRaw).toUtc();
      return DateTime.now().toUtc().difference(lastPull) >
          _pullCursorStaleAfter;
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
    List<Map<String, dynamic>> cloudRows, {
    required String expectedOwner,
  }) async {
    for (final row in cloudRows) {
      final rowOwner = row['user_id'] as String?;
      if (rowOwner != null && rowOwner != expectedOwner) continue;
      if (_owner.currentOwnerId != expectedOwner) return;

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
        await _datasource.saveReviewRecord(mergedModel, markCloudDirty: false);
      }
    }
  }

  Future<bool> _mergeDailyPlanFromCloud(
    SupabaseClient client,
    String userId,
  ) async {
    final localDirty = _prefs.getBool(dailyPlanCloudDirtyKey) ?? false;
    final rows = await client
        .from('daily_plans_cloud')
        .select()
        .eq('user_id', userId);
    if (rows.isEmpty) return false;

    final row = rows.first;
    await _storeRevision(_dailyPlanRevisionKey, row['revision']);
    final cloudGeneratedAt = DateTime.parse(row['generated_at'] as String);
    final local = await _datasource.getCachedDailyPlan();
    if (!DailyPlanCloudMerge.shouldApplyRemote(
      localDirty: localDirty,
      localGeneratedAt: local?.generatedAt,
      remoteGeneratedAt: cloudGeneratedAt,
    )) {
      if (localDirty) {
        await _prefs.setString(_dailyPlanConflictKey, jsonEncode(row));
      }
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

  Future<bool> _mergeCustomPlanFromCloud(
    SupabaseClient client,
    String userId,
  ) async {
    final localDirty = _prefs.getBool(customPlanCloudDirtyKey) ?? false;

    final rows = await client
        .from('custom_plans_cloud')
        .select()
        .eq('user_id', userId);
    if (rows.isEmpty) return false;

    final row = rows.first;
    await _storeRevision(_customPlanRevisionKey, row['revision']);
    final updatedRaw = row['updated_at'];
    if (updatedRaw is! String) return false;
    final remoteUpdatedAt = DateTime.tryParse(updatedRaw);
    if (remoteUpdatedAt == null ||
        !CustomPlanCloudMerge.shouldApplyRemote(
          localDirty: localDirty,
          localUpdatedAt: _readCustomPlanLocalUpdatedAt(),
          remoteUpdatedAt: remoteUpdatedAt,
        )) {
      if (localDirty) {
        await _prefs.setString(_customPlanConflictKey, jsonEncode(row));
      }
      return false;
    }
    final deletedAt = row['deleted_at'];
    try {
      if (deletedAt != null) {
        await _datasource.deleteCustomPlan();
        await _prefs.setBool(customPlanCloudDirtyKey, false);
        await _writeCustomPlanLocalUpdatedAt(remoteUpdatedAt);
        return true;
      }
      final payload = row['payload'];
      if (payload is! Map<String, dynamic>) return false;
      await _datasource.saveCustomPlan(
        CustomMemorizationPlanModel.fromJson(payload),
      );
      await _prefs.setBool(customPlanCloudDirtyKey, false);
      await _writeCustomPlanLocalUpdatedAt(remoteUpdatedAt);
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
      if (_owner.currentOwnerId != user.id) return const Right(null);

      final dirtyRecords = await _datasource.getCloudDirtyReviewRecords(
        includeAllAudiences: true,
      );
      final productionRecords = dirtyRecords
          .where(_isProductionReviewRecord)
          .toList();
      if (productionRecords.isNotEmpty) {
        final acknowledgedVersions = await _pushReviewRecordsBatch(
          client,
          productionRecords,
        );
        await _datasource.markReviewRecordsCloudSyncedAtVersions(
          acknowledgedVersions,
        );
      }

      if (_prefs.getBool(dailyPlanCloudDirtyKey) ?? false) {
        final cachedPlan = await _datasource.getCachedDailyPlan();
        if (cachedPlan != null) {
          if (await _upsertDailyPlanRow(client, cachedPlan)) {
            await _prefs.setBool(dailyPlanCloudDirtyKey, false);
          }
        }
      }

      if (_prefs.getBool(customPlanCloudDirtyKey) ?? false) {
        if (await _upsertCustomPlanRow(client)) {
          await _writeCustomPlanLocalUpdatedAt(DateTime.now().toUtc());
          await _prefs.setBool(customPlanCloudDirtyKey, false);
        }
      }

      return const Right(null);
    } catch (e) {
      // Best-effort resync: local state remains authoritative. The next
      // resume/login retry will pick up anything that failed here.
      return Left(NetworkFailure.from(e));
    }
  }

  /// Pulls certificate awards for the signed-in user.
  ///
  /// Cloud rows have no audience column yet, so callers should merge into the
  /// adult list and recompute kids awards from local kids review records.
  Future<Either<Failure, List<CertificateAward>>>
  pullCertificatesFromCloud() async {
    try {
      if (!_isSupabaseReady) return const Right([]);
      final client = _supabase;
      final user = client.auth.currentUser;
      if (user == null) return const Right([]);
      if (_owner.currentOwnerId != user.id) return const Right([]);

      final rows = await client
          .from('certificate_awards_cloud')
          .select()
          .eq('user_id', user.id)
          .order('earned_at', ascending: false);
      final awards = rows
          .cast<Map<String, dynamic>>()
          .map(CertificateAward.fromCloudRow)
          .toList();
      if (awards.isNotEmpty) {
        await _markCertificatesSynced(awards.map((c) => c.id));
      }
      return Right(awards);
    } catch (e) {
      return Left(NetworkFailure.from(e));
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
      return Left(NetworkFailure.from(e));
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
    if (_prefs.getBool(customPlanCloudDirtyKey) ?? false) return true;
    if (_hasUnsyncedCertificates()) return true;

    final logs = await _datasource.getKidsSessionLogs();
    if (logs.any((log) => !log.isSynced)) return true;

    return isReviewPullCursorStale();
  }

  /// True when local earned certificates are missing from the synced-id set.
  ///
  /// Keys match [AchievementService] preference storage so resume/login keep
  /// pushing until the cloud mirror acknowledges every award.
  bool _hasUnsyncedCertificates() {
    final synced = _syncedCertificateIds();
    for (final key in const [
      'earned_certificates_v2',
      'earned_certificates_v2_kids',
    ]) {
      final raw = _prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) continue;
        for (final item in decoded) {
          if (item is! Map) continue;
          final id = item['id'];
          if (id is String && id.isNotEmpty && !synced.contains(id)) {
            return true;
          }
        }
      } catch (_) {
        // Corrupt local JSON must not block other pending work checks.
      }
    }
    return false;
  }

  Future<Map<String, int>> _pushReviewRecordsBatch(
    SupabaseClient client,
    List<AyahReviewRecord> records,
  ) async {
    if (records.isEmpty) return <String, int>{};
    const chunkSize = 500;
    final acknowledgedVersions = <String, int>{};
    for (var i = 0; i < records.length; i += chunkSize) {
      final end = min(i + chunkSize, records.length);
      final batch = records.sublist(i, end);
      final payload = batch
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
      try {
        final response = await client.rpc(
          'upsert_ayah_review_records_v2',
          params: {'p_data': payload},
        );
        if (response is List) {
          final acknowledgedKeys =
              ReviewRecordCloudPushAcknowledgement.storageKeys(
              ownerUserId: _owner.currentOwnerId,
              sentRecords: batch,
              acknowledgedRows: response.whereType<Map<String, dynamic>>(),
            );
          for (final record in batch) {
            final scope = ReviewRecordAudienceScope.scopeForWriteMode(
              record.createdByMode,
            );
            final storageKey = ReviewRecordIdentity(
              ownerUserId: _owner.currentOwnerId,
              audience: scope,
              surahId: record.surahId,
              ayahNumber: record.ayahNumber,
            ).storageKey;
            if (acknowledgedKeys.contains(storageKey)) {
              acknowledgedVersions[storageKey] =
                  record.lastReviewedAt.toUtc().millisecondsSinceEpoch;
            }
          }
        }
      } on PostgrestException catch (e) {
        if (!_gateway.isMissingRpc(e, 'upsert_ayah_review_records_v2')) {
          rethrow;
        }
        // Old servers do not report conflict-rejected rows. Push for backwards
        // compatibility but retain every dirty flag until the v2 RPC is live.
        await client.rpc(
          'upsert_ayah_review_records',
          params: {'p_data': payload},
        );
      }
    }
    return acknowledgedVersions;
  }

  Future<bool> _upsertDailyPlanRow(
    SupabaseClient client,
    DailyPlan plan,
  ) async {
    final response = await client.rpc(
      'compare_and_swap_daily_plan',
      params: {
        'p_expected_revision': _prefs.getInt(_dailyPlanRevisionKey) ?? 0,
        'p_surah_id': plan.surahId,
        'p_generated_at': plan.generatedAt.toUtc().toIso8601String(),
        'p_total_items': plan.totalItems,
        'p_completed_count': plan.requiredCompletedCount,
        'p_payload': DailyPlanModel.fromEntity(plan).toJson(),
      },
    );
    return _handlePlanMutationResponse(
      response,
      revisionKey: _dailyPlanRevisionKey,
      conflictKey: _dailyPlanConflictKey,
    );
  }

  Future<SyncConflict<DailyPlan>?> getDailyPlanConflict() async {
    final row = _readConflictRow(_dailyPlanConflictKey);
    if (row == null) return null;
    final local = await _datasource.getCachedDailyPlan();
    final payload = row['payload'];
    DailyPlan? cloud;
    if (payload is Map<String, dynamic>) {
      try {
        cloud = DailyPlanModel.fromJson(payload);
      } catch (_) {
        return null;
      }
    }
    return SyncConflict(
      local: local,
      cloud: cloud,
      cloudRevision: _revisionFromRow(row),
    );
  }

  Future<Either<Failure, void>> resolveDailyPlanConflict(
    SyncConflictResolution resolution,
  ) async {
    try {
      final conflict = await getDailyPlanConflict();
      if (conflict == null) {
        return const Left(CacheFailure('لا يوجد تعارض في الخطة اليومية'));
      }
      if (resolution == SyncConflictResolution.keepLocal) {
        if (conflict.local == null) {
          return const Left(CacheFailure('لا توجد نسخة محلية للاحتفاظ بها'));
        }
        await _prefs.setInt(_dailyPlanRevisionKey, conflict.cloudRevision);
        await _prefs.setBool(dailyPlanCloudDirtyKey, true);
      } else {
        if (conflict.cloud == null) {
          return const Left(CacheFailure('نسخة السحابة غير صالحة'));
        }
        await _datasource.saveDailyPlan(
          DailyPlanModel.fromEntity(conflict.cloud!),
        );
        await _prefs.setInt(_dailyPlanRevisionKey, conflict.cloudRevision);
        await _prefs.setBool(dailyPlanCloudDirtyKey, false);
      }
      await _prefs.remove(_dailyPlanConflictKey);
      return const Right(null);
    } catch (error) {
      return Left(CacheFailure.from(error));
    }
  }

  Future<SyncConflict<CustomMemorizationPlan>?> getCustomPlanConflict() async {
    final row = _readConflictRow(_customPlanConflictKey);
    if (row == null) return null;
    final local = await _datasource.getCustomPlan();
    final payload = row['payload'];
    CustomMemorizationPlan? cloud;
    if (row['deleted_at'] == null && payload is Map<String, dynamic>) {
      try {
        cloud = CustomMemorizationPlanModel.fromJson(payload);
      } catch (_) {
        return null;
      }
    }
    return SyncConflict(
      local: local,
      cloud: cloud,
      cloudRevision: _revisionFromRow(row),
    );
  }

  Future<Either<Failure, void>> resolveCustomPlanConflict(
    SyncConflictResolution resolution,
  ) async {
    try {
      final row = _readConflictRow(_customPlanConflictKey);
      final conflict = await getCustomPlanConflict();
      if (row == null || conflict == null) {
        return const Left(CacheFailure('لا يوجد تعارض في الخطة المخصصة'));
      }
      if (resolution == SyncConflictResolution.keepLocal) {
        await _prefs.setInt(_customPlanRevisionKey, conflict.cloudRevision);
        await _prefs.setBool(customPlanCloudDirtyKey, true);
      } else {
        if (row['deleted_at'] != null) {
          await _datasource.deleteCustomPlan();
        } else if (conflict.cloud != null) {
          await _datasource.saveCustomPlan(
            CustomMemorizationPlanModel.fromEntity(conflict.cloud!),
          );
        } else {
          return const Left(CacheFailure('نسخة السحابة غير صالحة'));
        }
        await _prefs.setInt(_customPlanRevisionKey, conflict.cloudRevision);
        await _prefs.setBool(customPlanCloudDirtyKey, false);
        await _writeCustomPlanLocalUpdatedAt(DateTime.now().toUtc());
      }
      await _prefs.remove(_customPlanConflictKey);
      return const Right(null);
    } catch (error) {
      return Left(CacheFailure.from(error));
    }
  }

  Map<String, dynamic>? _readConflictRow(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final row = map['row'];
      return row is Map ? Map<String, dynamic>.from(row) : map;
    } catch (_) {
      return null;
    }
  }

  int _revisionFromRow(Map<String, dynamic> row) {
    final revision = row['revision'];
    return revision is num && revision >= 0 ? revision.toInt() : 0;
  }

  Future<bool> _upsertCustomPlanRow(SupabaseClient client) async {
    final plan = await _datasource.getCustomPlan();
    final response = await client.rpc(
      'compare_and_swap_custom_plan',
      params: {
        'p_expected_revision': _prefs.getInt(_customPlanRevisionKey) ?? 0,
        'p_payload': plan == null
            ? <String, dynamic>{}
            : CustomMemorizationPlanModel.fromEntity(plan).toJson(),
        'p_is_deleted': plan == null,
      },
    );
    return _handlePlanMutationResponse(
      response,
      revisionKey: _customPlanRevisionKey,
      conflictKey: _customPlanConflictKey,
    );
  }

  Future<bool> _handlePlanMutationResponse(
    dynamic response, {
    required String revisionKey,
    required String conflictKey,
  }) async {
    if (response is! Map) return false;
    final result = Map<String, dynamic>.from(response);
    final row = result['row'];
    if (result['status'] == 'acknowledged' && row is Map) {
      await _storeRevision(revisionKey, row['revision']);
      await _prefs.remove(conflictKey);
      return true;
    }
    if (result['status'] == 'conflict') {
      await _prefs.setString(conflictKey, jsonEncode(result));
    }
    return false;
  }

  Future<void> _storeRevision(String key, dynamic rawRevision) async {
    if (rawRevision is num && rawRevision >= 0) {
      await _prefs.setInt(key, rawRevision.toInt());
    }
  }

  DateTime? _readCustomPlanLocalUpdatedAt() {
    final raw = _prefs.getString(PlanCloudDirtyKeys.customPlanLocalUpdatedAt);
    return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
  }

  Future<void> _writeCustomPlanLocalUpdatedAt(DateTime timestamp) =>
      _prefs.setString(
        PlanCloudDirtyKeys.customPlanLocalUpdatedAt,
        timestamp.toUtc().toIso8601String(),
      );
}
