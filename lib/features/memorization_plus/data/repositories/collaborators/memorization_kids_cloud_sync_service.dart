import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/error/app_failure.dart';
import '../../../../../core/memorization/kids_session_log_acknowledgement.dart';
import '../../../../../core/memorization/kids_progress_cloud_merge.dart';
import '../../../../../core/services/streak_reader.dart';
import '../../../domain/entities/memorization_entities.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import '../../models/memorization_models.dart';
import 'memorization_cloud_gateway.dart';
import 'memorization_cloud_mappers.dart';

/// Kids-mode cloud sync: pushes kids progress + session logs to Supabase and
/// reads the parent-facing remote children dashboard (with the legacy row-by-
/// row fallback when the RPC is not deployed).
class MemorizationKidsCloudSyncService {
  MemorizationKidsCloudSyncService(
    this._datasource,
    this._streakReader,
    this._gateway,
    this._mappers,
  );

  final MemorizationPlusLocalDatasource _datasource;
  final StreakReader _streakReader;
  final MemorizationCloudGateway _gateway;
  final MemorizationCloudMappers _mappers;

  Either<Failure, SupabaseClient> get _supabaseOrFailure =>
      _gateway.supabaseOrFailure();

  Future<Either<Failure, void>> pullKidsProgressFromCloud() async {
    try {
      final clientResult = _supabaseOrFailure;
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      final user = client.auth.currentUser;
      if (user == null) return const Right(null);

      final progressRows = await client
          .from('kids_progress_cloud')
          .select()
          .eq('child_user_id', user.id)
          .limit(1);
      final logRows = await client
          .from('kids_session_logs')
          .select()
          .eq('child_user_id', user.id)
          .order('completed_at', ascending: true);
      final rewardRows = await client
          .from('parent_rewards')
          .select()
          .eq('child_user_id', user.id)
          .order('created_at', ascending: false);

      final remote = _mappers.progressFromCloud(
        progressRows.isEmpty ? null : progressRows.first,
      );
      final local = await _datasource.getKidsProgress();
      final localLogs = await _datasource.getKidsSessionLogs();
      final remoteLogs = logRows
          .map((row) => _mappers.logFromCloud(Map<String, dynamic>.from(row)))
          .toList();
      final mergedLogs = KidsSessionLogsCloudMerge.merge(
        local: localLogs,
        remote: remoteLogs,
      );
      final mergedProgress = KidsProgressCloudMerge.merge(
        local: local,
        remote: remote,
      );
      final reconciledProgress = mergedProgress.copyWith(
        ayahsCompleted: KidsSessionLogsCloudMerge.completedAyahsCount(
          mergedLogs,
        ),
      );

      await _datasource.saveKidsProgress(
        KidsProgressModel.fromEntity(reconciledProgress),
      );
      await _datasource.saveKidsSessionLogs(
        mergedLogs.map(KidsSessionLogModel.fromEntity).toList(),
      );
      await _datasource.saveParentRewards(
        rewardRows
            .map(
              (row) => ParentRewardModel.fromEntity(
                _mappers.rewardFromCloud(Map<String, dynamic>.from(row)),
              ),
            )
            .toList(),
      );
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> syncKidsProgressToCloud() async {
    try {
      final clientResult = _supabaseOrFailure;
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      final user = client.auth.currentUser;
      if (user == null) return const Right(null);

      final progress = await _datasource.getKidsProgress();
      final streak = await _streakReader.getStreak();
      await client.rpc(
        'upsert_kids_progress_cloud',
        params: {
          'p_total_points': progress.totalPoints,
          'p_current_level': progress.currentLevel,
          'p_current_streak': streak.currentStreak,
          'p_stars_earned': progress.starsEarned,
          'p_ayahs_completed': progress.ayahsCompleted,
          'p_last_session_at': progress.lastSessionAt
              ?.toUtc()
              .toIso8601String(),
        },
      );

      final logs = await _datasource.getKidsSessionLogs();
      final pendingLogs = logs.where((log) => !log.isSynced).toList();
      if (pendingLogs.isNotEmpty) {
        final acceptedIds = await _pushKidsSessionLogs(client, pendingLogs);
        await _datasource.markKidsSessionLogsCloudSynced(acceptedIds);
      }
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<RemoteChildSummary>>> getRemoteChildren() async {
    try {
      final clientResult = _supabaseOrFailure;
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      final user = client.auth.currentUser;
      if (user == null) {
        return const Left(NetworkFailure('سجّل الدخول أولاً'));
      }

      try {
        final payload = await client.rpc('get_remote_children_dashboard');
        return Right(_mappers.parseRemoteChildrenDashboard(payload));
      } on PostgrestException catch (e) {
        if (!_gateway.isMissingRpc(e, 'get_remote_children_dashboard')) {
          rethrow;
        }
      }

      return Right(await _fetchRemoteChildrenLegacy(client, user.id));
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<List<RemoteChildSummary>> _fetchRemoteChildrenLegacy(
    SupabaseClient client,
    String parentUserId,
  ) async {
    final links = await client
        .from('parent_child_links')
        .select('child_user_id')
        .eq('parent_user_id', parentUserId)
        .eq('status', 'active');

    final children = <RemoteChildSummary>[];
    for (final link in links) {
      final childId = link['child_user_id'] as String;
      final profileRows = await client
          .from('profiles')
          .select('display_name')
          .eq('id', childId)
          .limit(1);
      final progressRows = await client
          .from('kids_progress_cloud')
          .select()
          .eq('child_user_id', childId)
          .limit(1);
      final logRows = await client
          .from('kids_session_logs')
          .select()
          .eq('child_user_id', childId)
          .order('completed_at', ascending: false)
          .limit(30);
      final rewardRows = await client
          .from('parent_rewards')
          .select()
          .eq('child_user_id', childId)
          .order('created_at', ascending: false);

      RemoteChildProductionSummary? production;
      try {
        final reviewRows = await client
            .from('ayah_review_records_cloud')
            .select()
            .eq('user_id', childId);
        final dailyPlanRows = await client
            .from('daily_plans_cloud')
            .select()
            .eq('user_id', childId)
            .limit(1);
        final certRows = await client
            .from('certificate_awards_cloud')
            .select()
            .eq('user_id', childId)
            .order('earned_at', ascending: false);
        final streakRows = await client
            .from('streaks')
            .select()
            .eq('user_id', childId)
            .limit(1);
        final activityRows = await client
            .from('daily_activities')
            .select('day_key, activity_count')
            .eq('user_id', childId)
            .order('day_key', ascending: false)
            .limit(31);

        production = _mappers.buildProductionSummary(
          reviewRows: List<Map<String, dynamic>>.from(reviewRows),
          dailyPlanRow: dailyPlanRows.isEmpty ? null : dailyPlanRows.first,
          certRows: List<Map<String, dynamic>>.from(certRows),
          streakRow: streakRows.isEmpty ? null : streakRows.first,
          activityRows: List<Map<String, dynamic>>.from(activityRows),
        );
      } catch (_) {
        production = null;
      }

      children.add(
        RemoteChildSummary(
          childUserId: childId,
          displayName: profileRows.isEmpty
              ? 'طفل تالية'
              : profileRows.first['display_name'] as String? ?? 'طفل تالية',
          progress: _mappers.progressFromCloud(
            progressRows.isEmpty ? null : progressRows.first,
          ),
          logs: logRows.map(_mappers.logFromCloud).toList(),
          rewards: rewardRows.map(_mappers.rewardFromCloud).toList(),
          production: production,
        ),
      );
    }
    return children;
  }

  Future<Either<Failure, List<ParentReward>>> saveRemoteParentReward({
    required String childUserId,
    required String title,
  }) async {
    try {
      final trimmed = title.trim();
      if (trimmed.isEmpty) {
        return const Left(CacheFailure('اكتب اسم المكافأة أولاً'));
      }
      final clientResult = _supabaseOrFailure;
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      final user = client.auth.currentUser;
      if (user == null) {
        return const Left(NetworkFailure('سجّل الدخول أولاً'));
      }
      await client.rpc(
        'create_parent_reward',
        params: {'p_child_user_id': childUserId, 'p_title': trimmed},
      );
      final rows = await client
          .from('parent_rewards')
          .select()
          .eq('child_user_id', childUserId)
          .order('created_at', ascending: false);
      return Right(rows.map(_mappers.rewardFromCloud).toList());
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<Set<String>> _pushKidsSessionLogs(
    SupabaseClient client,
    List<KidsSessionLog> logs,
  ) async {
    if (logs.isEmpty) return const <String>{};

    final payload = logs
        .map(
          (log) => {
            'local_id': log.id,
            'surah_id': log.surahId,
            'ayah_number': log.ayahNumber,
            'repeats_completed': log.repeatsCompleted,
            'points_earned': log.pointsEarned,
            'completed_at': log.completedAt.toUtc().toIso8601String(),
          },
        )
        .toList();

    try {
      final response = await client.rpc(
        'insert_kids_session_logs_batch',
        params: {'p_data': payload},
      );
      return KidsSessionLogAcknowledgement.acceptedIds(
        sentIds: logs.map((log) => log.id).toSet(),
        acknowledgedRows: (response as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row)),
      );
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (!message.contains('insert_kids_session_logs_batch') &&
          !message.contains('could not find the function')) {
        rethrow;
      }
    }

    for (final log in logs) {
      await client.rpc(
        'insert_kids_session_log',
        params: {
          'p_local_id': log.id,
          'p_surah_id': log.surahId,
          'p_ayah_number': log.ayahNumber,
          'p_repeats_completed': log.repeatsCompleted,
          'p_points_earned': log.pointsEarned,
          'p_completed_at': log.completedAt.toUtc().toIso8601String(),
        },
      );
    }
    // Legacy RPCs return void, so they cannot prove which mutations were
    // accepted. Keep every row dirty until the acknowledgement-capable RPC is
    // deployed rather than risking lost child history.
    return const <String>{};
  }

  /// Claims a server-owned reward only when the authenticated child is allowed
  /// to transition it from unlocked to claimed. The local cache changes only
  /// after the RPC returns that exact row.
  Future<Either<Failure, List<ParentReward>>> claimRemoteParentReward(
    String rewardId,
  ) => _transitionRemoteParentReward('claim_parent_reward', rewardId);

  /// Parent-only counterpart to [claimRemoteParentReward]. The database RPC
  /// enforces ownership and the locked-to-unlocked transition.
  Future<Either<Failure, List<ParentReward>>> unlockRemoteParentReward(
    String rewardId,
  ) => _transitionRemoteParentReward('unlock_parent_reward', rewardId);

  Future<Either<Failure, List<ParentReward>>> _transitionRemoteParentReward(
    String rpcName,
    String rewardId,
  ) async {
    try {
      final parsedId = int.tryParse(rewardId);
      if (parsedId == null) {
        return const Left(CacheFailure('معرّف المكافأة غير صالح'));
      }
      final clientResult = _supabaseOrFailure;
      final clientFailure = clientResult.fold((failure) => failure, (_) => null);
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(() => throw StateError('unreachable'));
      if (client.auth.currentUser == null) {
        return const Left(NetworkFailure('سجّل الدخول أولاً'));
      }

      final response = await client.rpc(
        rpcName,
        params: {'p_reward_id': parsedId},
      );
      final acknowledged = (response as List<dynamic>)
          .whereType<Map>()
          .map((row) => _mappers.rewardFromCloud(Map<String, dynamic>.from(row)))
          .toList();
      if (acknowledged.isEmpty) {
        return const Left(NetworkFailure('المكافأة ليست متاحة لهذا الإجراء'));
      }

      final local = await _datasource.getParentRewards();
      final byId = {for (final reward in local) reward.id: reward};
      for (final reward in acknowledged) {
        byId[reward.id] = ParentRewardModel.fromEntity(reward);
      }
      final merged = byId.values.toList();
      await _datasource.saveParentRewards(
        merged.map(ParentRewardModel.fromEntity).toList(),
      );
      return Right(merged);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}
