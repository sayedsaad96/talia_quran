import 'package:dartz/dartz.dart';
import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/error/app_failure.dart';
import '../../../../../core/l10n/cubit_message_codes.dart';
import '../../../../../core/identity/record_owner_provider.dart';
import '../../../../../core/memorization/kids_session_log_acknowledgement.dart';
import '../../../../../core/memorization/kids_progress_cloud_merge.dart';
import '../../../../../core/services/streak_reader.dart';
import '../../../../../core/utils/talia_logger.dart';
import '../../../domain/entities/kids_child_policy.dart';
import '../../../domain/entities/kids_home_mission.dart';
import '../../../domain/entities/memorization_entities.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import '../../datasources/remote_children_dashboard_cache.dart';
import '../../models/memorization_models.dart';
import 'family_activity_publisher.dart';
import 'memorization_cloud_gateway.dart';
import 'kids_child_policy_sync.dart';
import 'kids_home_mission_child_sync.dart';
import 'memorization_cloud_mappers.dart';

/// Kids-mode cloud sync: pushes kids progress + session logs to Supabase and
/// reads the parent-facing remote children dashboard (with the legacy row-by-
/// row fallback when the RPC is not deployed).
class MemorizationKidsCloudSyncService {
  MemorizationKidsCloudSyncService(
    this._datasource,
    this._streakReader,
    this._gateway,
    this._mappers, {
    RecordOwnerProvider owner = const SupabaseRecordOwnerProvider(),
    void Function()? onKidsPolicyChanged,
    FamilyActivityPublisher? activityPublisher,
    RemoteChildrenDashboardCache? dashboardCache,
  }) : _owner = owner,
       _onKidsPolicyChanged = onKidsPolicyChanged,
       _activityPublisher = activityPublisher,
       _dashboardCache = dashboardCache;

  final FamilyActivityPublisher? _activityPublisher;
  final RemoteChildrenDashboardCache? _dashboardCache;

  final MemorizationPlusLocalDatasource _datasource;
  final StreakReader _streakReader;
  final MemorizationCloudGateway _gateway;
  final MemorizationCloudMappers _mappers;
  final RecordOwnerProvider _owner;

  final void Function()? _onKidsPolicyChanged;

  late final KidsHomeMissionChildSync _homeMissionSync =
      KidsHomeMissionChildSync(_datasource, _mappers, _owner);

  late final KidsChildPolicySync _policySync = KidsChildPolicySync(
    _datasource,
    _owner,
    onPolicyChanged: _onKidsPolicyChanged,
  );

  Either<Failure, SupabaseClient> get _supabaseOrFailure =>
      _gateway.supabaseOrFailure().leftMap(
        (_) => const NetworkFailure(CubitMessageCodes.guardianCloudUnavailable),
      );

  /// Pulls the child's progress, then what the guardian sent. The inbound
  /// pull runs even when the progress pull fails.
  Future<Either<Failure, void>> pullKidsProgressFromCloud() =>
      _withSignedInClient((client, ownerId) async {
        final progress = await _guardCloud(
          () => _pullProgress(client, ownerId),
        );
        final inbound = await _guardCloud(() => _pullInbound(client, ownerId));
        return progress.isLeft() ? progress : inbound;
      });

  /// What the guardian sends the child: gifts, home missions and the policy.
  Future<Either<Failure, void>> pullKidsInboundFromCloud() =>
      _withSignedInClient(
        (client, ownerId) => _guardCloud(() => _pullInbound(client, ownerId)),
      );

  /// Signed out is a successful no-op; no cloud client is a failure.
  Future<Either<Failure, void>> _withSignedInClient(
    Future<Either<Failure, void>> Function(SupabaseClient, String) run,
  ) async {
    final SupabaseClient client;
    final String? ownerId;
    try {
      final clientResult = _supabaseOrFailure;
      final failure = clientResult.fold((failure) => failure, (_) => null);
      if (failure != null) return Left(failure);
      client = clientResult.getOrElse(() => throw StateError('unreachable'));
      ownerId = client.auth.currentUser?.id;
    } catch (e) {
      return Left(Failure.fromCloud(e));
    }
    if (ownerId == null) return const Right(null);
    return run(client, ownerId);
  }

  Future<Either<Failure, void>> _guardCloud(Future<void> Function() run) async {
    try {
      await run();
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromCloud(e));
    }
  }

  Future<void> _pullProgress(SupabaseClient client, String ownerId) async {
    _ensureOwner(ownerId);
    final progressRows = await client
        .from('kids_progress_cloud')
        .select()
        .eq('child_user_id', ownerId)
        .limit(1);
    final logRows = await client
        .from('kids_session_logs')
        .select()
        .eq('child_user_id', ownerId)
        .order('completed_at', ascending: true);
    _ensureOwner(ownerId);

    final remote = _mappers.progressFromCloud(
      progressRows.isEmpty ? null : progressRows.first,
    );
    final remoteLogs = logRows
        .map((row) => _mappers.logFromCloud(Map<String, dynamic>.from(row)))
        .toList();
    // Evidence is persisted before its projection. The merge runs as one
    // atomic read-modify-write so a concurrent award can never be dropped
    // between the local read and the merged write-back. If interrupted, the
    // next read/sync deterministically repairs the aggregate from these
    // logs.
    final mergedLogs = await _datasource.updateKidsSessionLogs(
      (localLogs) async => KidsSessionLogsCloudMerge.merge(
        local: localLogs,
        remote: remoteLogs,
      ).map(KidsSessionLogModel.fromEntity).toList(),
    );
    _ensureOwner(ownerId);
    final rebuilt = KidsSessionLogsCloudMerge.rebuildProjection(mergedLogs);
    // Preserve legacy remote aggregates that cannot yet be reconstructed
    // because the deployed log contract omits exact awarded stars. Local
    // stale caches are deliberately not merged back into the projection.
    final reconciledProgress = KidsProgressCloudMerge.merge(
      local: rebuilt,
      remote: remote,
    );
    await _datasource.saveKidsLegacyCloudFloor(
      KidsProgressModel.fromEntity(remote),
    );
    _ensureOwner(ownerId);
    await _datasource.saveKidsProgress(
      KidsProgressModel.fromEntity(reconciledProgress),
    );
  }

  Future<void> _pullInbound(SupabaseClient client, String ownerId) async {
    _ensureOwner(ownerId);
    // The gift list mirrors the server only while a guardian is linked. An
    // unlinked device keeps the gifts its guardian area made locally, and a
    // child can still read rows of a revoked link that can no longer move.
    if ((await _datasource.getMemorizationProfile()).isGuardianLinked) {
      final rewardRows = await client
          .from('parent_rewards')
          .select()
          .eq('child_user_id', ownerId)
          .order('created_at', ascending: false);
      _ensureOwner(ownerId);
      await _datasource.saveParentRewards(
        rewardRows
            .map(
              (row) => ParentRewardModel.fromEntity(
                _mappers.rewardFromCloud(Map<String, dynamic>.from(row)),
              ),
            )
            .toList(),
      );
      _ensureOwner(ownerId);
    }
    // Home missions never fail the pull (the table may be undeployed or the
    // link revoked); the local list is left untouched.
    await _homeMissionSync.pull(
      ownerId: ownerId,
      fetchRows: () async {
        final rows = await client
            .from('kids_home_missions')
            .select()
            .eq('child_user_id', ownerId)
            .order('created_at', ascending: true);
        return rows
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false);
      },
    );
    // Same best-effort rule for the guardian policy: a newer server
    // version replaces the local policy fields; errors are swallowed.
    await _policySync.pull(
      ownerId: ownerId,
      fetchRow: () async {
        final rows = await client
            .from('kids_child_policies')
            .select()
            .eq('child_user_id', ownerId)
            .limit(1);
        return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
      },
    );
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
      final ownerId = user.id;
      _ensureOwner(ownerId);

      final logs = await _datasource.getKidsSessionLogs();
      final pendingLogs = logs
          .where(
            (log) =>
                !log.isSynced &&
                KidsSessionLogsCloudMerge.isCanonicalRewardLog(log),
          )
          .toList();
      if (pendingLogs.isNotEmpty) {
        final acceptedIds = await _pushKidsSessionLogs(client, pendingLogs);
        _ensureOwner(ownerId);
        await _datasource.markKidsSessionLogsCloudSynced(acceptedIds);
      }

      // The cloud aggregate is uploaded only after its canonical evidence.
      final reconciledLogs = await _datasource.getKidsSessionLogs();
      final progress = KidsSessionLogsCloudMerge.rebuildProjection(
        reconciledLogs,
      );
      await _datasource.saveKidsProgress(
        KidsProgressModel.fromEntity(progress),
      );
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
      _ensureOwner(ownerId);

      // Home-mission reports go last so a slow or failing RPC can never
      // delay or lose the progress upload. A transient failure surfaces as a
      // retryable failure (the queue backs off and retries); terminal server
      // rejections are cleared inside the push.
      final hadTransientFailure = await _homeMissionSync.push(
        ownerId: ownerId,
        reportRpc: (missionId) async {
          await client.rpc(
            'report_kids_home_mission',
            params: {'p_mission_id': missionId},
          );
        },
      );
      // Policy edits the server has not acknowledged (e.g. made before
      // linking) go last, best-effort: pushPending never throws and a
      // transport error just leaves the edit pending for the next sync.
      await _policySync.pushPending(
        ownerId: ownerId,
        childUserId: user.id,
        casRpc: (params) =>
            client.rpc('compare_and_swap_child_policy', params: params),
      );
      final hadActivityFailure = await _publishFamilyActivity(client, ownerId);
      if (hadActivityFailure) {
        return const Left(
          NetworkFailure('Family activity snapshot is waiting to sync'),
        );
      }
      if (hadTransientFailure) {
        return const Left(
          NetworkFailure('Kids home mission report is waiting to sync'),
        );
      }
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromCloud(e));
    }
  }

  /// Child devices only: the server rejects other accounts. Returns true
  /// when the publish should be retried.
  Future<bool> _publishFamilyActivity(
    SupabaseClient client,
    String ownerId,
  ) async {
    final publisher = _activityPublisher;
    if (publisher == null) return false;
    final profile = await _datasource.getMemorizationProfile();
    if (!profile.isChild) return false;
    _ensureOwner(ownerId);
    return publisher.publish(
      (params) => client.rpc('publish_child_family_activity', params: params),
    );
  }

  void _ensureOwner(String ownerId) {
    if (_owner.currentOwnerId != ownerId) {
      throw StateError('Kids cloud sync owner changed during operation');
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
        return const Left(
          NetworkFailure(CubitMessageCodes.guardianSignInRequired),
        );
      }

      try {
        final payload = await client.rpc('get_remote_children_dashboard');
        final children = _mappers.parseRemoteChildrenDashboard(payload);
        await _cacheDashboard(user.id, payload);
        return Right(children);
      } on PostgrestException catch (e) {
        if (!_gateway.isMissingRpc(e, 'get_remote_children_dashboard')) {
          rethrow;
        }
      }

      return Right(await _fetchRemoteChildrenLegacy(client, user.id));
    } catch (e) {
      return Left(Failure.fromCloud(e));
    }
  }

  /// A cache write failure never fails a successful read.
  Future<void> _cacheDashboard(String ownerId, Object? payload) async {
    try {
      await _dashboardCache?.save(ownerId, payload);
    } catch (e) {
      TaliaLogger.w('[KidsCloudSync] dashboard cache write failed: $e');
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
      List<Map<String, dynamic>> profileRows;
      try {
        profileRows = await client
            .from('profiles')
            .select('display_name, child_nickname, age')
            .eq('id', childId)
            .limit(1);
      } on PostgrestException catch (e) {
        if (e.code != '42703') rethrow;
        profileRows = await client
            .from('profiles')
            .select('display_name, age')
            .eq('id', childId)
            .limit(1);
      }
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
          // Blank means unnamed; the UI shows its localized default.
          displayName: profileRows.isEmpty
              ? ''
              : [
                      profileRows.first['child_nickname'],
                      profileRows.first['display_name'],
                    ]
                    .whereType<String>()
                    .map((name) => name.trim())
                    .firstWhere((name) => name.isNotEmpty, orElse: () => ''),
          childAge: profileRows.isEmpty
              ? null
              : (profileRows.first['age'] as num?)?.toInt(),
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
        return const Left(
          CacheFailure(CubitMessageCodes.parentRewardTitleRequired),
        );
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
        return const Left(
          NetworkFailure(CubitMessageCodes.guardianSignInRequired),
        );
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
      return Left(NetworkFailure.from(e));
    }
  }

  /// Guardian assigns a home mission to a linked child. The server re-checks
  /// the active link; the cache is never touched (the guardian reads remotely).
  Future<Either<Failure, List<KidsHomeMission>>> createRemoteHomeMission({
    required String childUserId,
    required String title,
  }) async {
    try {
      final trimmed = title.trim();
      if (trimmed.isEmpty || trimmed.length > kHomeMissionTitleMaxLength) {
        return const Left(
          ValidationFailure(CubitMessageCodes.kidsHomeMissionInvalidTitle),
        );
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
      if (client.auth.currentUser == null) {
        return const Left(
          NetworkFailure(CubitMessageCodes.guardianSignInRequired),
        );
      }
      await client.rpc(
        'create_kids_home_mission',
        params: {'p_child_user_id': childUserId, 'p_title': trimmed},
      );
      return await _selectHomeMissions(client, childUserId);
    } catch (e) {
      return Left(NetworkFailure.from(e));
    }
  }

  /// Guardian marks a reported mission as seen. Returns the child's refreshed
  /// mission list (the child id comes from the row the RPC returns).
  Future<Either<Failure, List<KidsHomeMission>>> acknowledgeRemoteHomeMission(
    String missionId,
  ) async {
    try {
      final parsedId = int.tryParse(missionId);
      if (parsedId == null) {
        return const Left(
          CacheFailure(CubitMessageCodes.kidsHomeMissionUnavailable),
        );
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
      if (client.auth.currentUser == null) {
        return const Left(
          NetworkFailure(CubitMessageCodes.guardianSignInRequired),
        );
      }
      final response = await client.rpc(
        'acknowledge_kids_home_mission',
        params: {'p_mission_id': parsedId},
      );
      final rows = (response as List<dynamic>).whereType<Map>().toList();
      if (rows.isEmpty) {
        return const Left(
          NetworkFailure(CubitMessageCodes.kidsHomeMissionUnavailable),
        );
      }
      final childId = rows.first['child_user_id'] as String?;
      if (childId == null) {
        return Right(
          rows
              .map(
                (row) => _mappers.homeMissionFromCloud(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList(),
        );
      }
      return await _selectHomeMissions(client, childId);
    } catch (e) {
      return Left(acknowledgeFailure(e));
    }
  }

  /// Maps an `acknowledge_kids_home_mission` error to a message code; raw
  /// server text never reaches the UI.
  @visibleForTesting
  static Failure acknowledgeFailure(Object error) {
    final text = error.toString();
    if (text.contains('Child link is not active')) {
      TaliaLogger.w('Kids home mission acknowledge rejected', error);
      return const NetworkFailure(CubitMessageCodes.guardianChildNotLinked);
    }
    if (text.contains('Mission not found') ||
        text.contains('Invalid mission transition')) {
      TaliaLogger.w('Kids home mission acknowledge rejected', error);
      return const NetworkFailure(CubitMessageCodes.kidsHomeMissionUnavailable);
    }
    return NetworkFailure.from(error);
  }

  /// Reads a linked child's home missions (parent SELECT RLS), newest first.
  Future<Either<Failure, List<KidsHomeMission>>> getRemoteHomeMissions(
    String childUserId,
  ) async {
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
      return await _selectHomeMissions(client, childUserId);
    } catch (e) {
      return Left(NetworkFailure.from(e));
    }
  }

  static const kHomeMissionTitleMaxLength = 120;

  /// Child device policy edit (behind the PIN). Linked (a signed-in cloud
  /// user, the same gate home-mission reports use) → compare-and-swap with
  /// the local version; otherwise local only with `policyVersion + 1`.
  Future<Either<Failure, KidsChildPolicy>> saveLocalChildPolicy(
    KidsChildPolicy policy,
  ) async {
    SupabaseClient? client;
    String? childUserId;
    if (_gateway.hasSignedInCloudUser) {
      client = _gateway.supabaseOrFailure().fold((_) => null, (c) => c);
      childUserId = client?.auth.currentUser?.id;
    }
    return _policySync.saveOnDevice(
      policy: policy,
      linkedChildUserId: childUserId,
      casRpc: (params) async =>
          client!.rpc('compare_and_swap_child_policy', params: params),
    );
  }

  /// Guardian edit of a linked child's policy; [policy].version is the
  /// version the guardian last read (from [getRemoteChildPolicy]).
  Future<Either<Failure, KidsChildPolicy>> saveRemoteChildPolicy({
    required String childUserId,
    required KidsChildPolicy policy,
  }) async {
    final clientResult = _supabaseOrFailure;
    final clientFailure = clientResult.fold((failure) => failure, (_) => null);
    if (clientFailure != null) return Left(clientFailure);
    final client = clientResult.getOrElse(
      () => throw StateError('unreachable'),
    );
    if (client.auth.currentUser == null) {
      return const Left(
        NetworkFailure(CubitMessageCodes.guardianSignInRequired),
      );
    }
    return _policySync.casRemote(
      childUserId: childUserId,
      policy: policy,
      expectedVersion: policy.version,
      casRpc: (params) =>
          client.rpc('compare_and_swap_child_policy', params: params),
    );
  }

  /// Reads a linked child's policy row (parent SELECT RLS). Right(null) when
  /// the child has no row yet (defaults, version 0).
  Future<Either<Failure, KidsChildPolicy?>> getRemoteChildPolicy(
    String childUserId,
  ) async {
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
      final rows = await client
          .from('kids_child_policies')
          .select()
          .eq('child_user_id', childUserId)
          .limit(1);
      return Right(
        rows.isEmpty ? null : KidsChildPolicySync.policyFromRow(rows.first),
      );
    } catch (e) {
      return Left(NetworkFailure.from(e));
    }
  }

  Future<Either<Failure, List<KidsHomeMission>>> _selectHomeMissions(
    SupabaseClient client,
    String childUserId,
  ) async {
    final rows = await client
        .from('kids_home_missions')
        .select()
        .eq('child_user_id', childUserId)
        .order('created_at', ascending: false);
    return Right(rows.map(_mappers.homeMissionFromCloud).toList());
  }

  /// Guardian-side correction of a linked child's name and age. The server
  /// (`update_linked_child_identity`) re-checks the active link and limits.
  Future<Either<Failure, void>> updateLinkedChildIdentity({
    required String childUserId,
    required String nickname,
    required int age,
  }) async {
    final name = ChildIdentityPolicy.normalizeNickname(nickname);
    if (name == null) {
      return const Left(CacheFailure(CubitMessageCodes.childNicknameInvalid));
    }
    if (!ChildIdentityPolicy.isValidAge(age)) {
      return const Left(CacheFailure(CubitMessageCodes.childAgeInvalid));
    }
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
      if (client.auth.currentUser == null) {
        return const Left(
          NetworkFailure(CubitMessageCodes.guardianSignInRequired),
        );
      }
      await client.rpc(
        'update_linked_child_identity',
        params: {
          'p_child_user_id': childUserId,
          'p_nickname': name,
          'p_age': age,
        },
      );
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(childIdentityUpdateFailure(e));
    } catch (e) {
      return Left(Failure.fromCloud(e));
    }
  }

  /// Maps `update_linked_child_identity` exceptions
  /// (supabase/migrations/20260929195346_guardian_child_identity.sql) to
  /// message codes; a server without the function yet reports the edit as
  /// unavailable instead of a generic error.
  @visibleForTesting
  static Failure childIdentityUpdateFailure(PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = switch (message) {
      _
          when error.code == 'PGRST202' ||
              message.contains('update_linked_child_identity') ||
              message.contains('could not find the function') =>
        CubitMessageCodes.childIdentityUpdateUnavailable,
      _ when message.contains('no active guardian link') =>
        CubitMessageCodes.guardianChildNotLinked,
      _ when message.contains('invalid child nickname') =>
        CubitMessageCodes.childNicknameInvalid,
      _ when message.contains('invalid child age') =>
        CubitMessageCodes.childAgeInvalid,
      _ when message.contains('not authenticated') =>
        CubitMessageCodes.guardianSignInRequired,
      _ => null,
    };
    return code == null ? ServerFailure.from(error) : ServerFailure(code);
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

  /// Child: asks to receive an unlocked gift (unlocked → requested). The local
  /// cache changes only after the RPC returns that exact row.
  Future<Either<Failure, List<ParentReward>>> requestRemoteParentReward(
    String rewardId,
  ) => _transitionRemoteParentReward(
    'request_parent_reward',
    rewardId,
    cacheOnDevice: true,
  );

  /// Guardian: confirms the hand-over (requested → claimed).
  Future<Either<Failure, List<ParentReward>>> approveRemoteParentReward(
    String rewardId,
  ) => _transitionRemoteParentReward('approve_parent_reward', rewardId);

  /// Guardian: opens a locked gift (locked → unlocked).
  Future<Either<Failure, List<ParentReward>>> unlockRemoteParentReward(
    String rewardId,
  ) => _transitionRemoteParentReward('unlock_parent_reward', rewardId);

  /// The device's reward cache belongs to the child on this device, so only
  /// the child's own transitions ([cacheOnDevice]) are written to it.
  Future<Either<Failure, List<ParentReward>>> _transitionRemoteParentReward(
    String rpcName,
    String rewardId, {
    bool cacheOnDevice = false,
  }) async {
    try {
      final parsedId = int.tryParse(rewardId);
      if (parsedId == null) {
        return const Left(
          CacheFailure(CubitMessageCodes.parentRewardUnavailable),
        );
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
      if (client.auth.currentUser == null) {
        return const Left(
          NetworkFailure(CubitMessageCodes.guardianSignInRequired),
        );
      }

      final response = await client.rpc(
        rpcName,
        params: {'p_reward_id': parsedId},
      );
      final acknowledged = (response as List<dynamic>)
          .whereType<Map>()
          .map(
            (row) => _mappers.rewardFromCloud(Map<String, dynamic>.from(row)),
          )
          .toList();
      if (acknowledged.isEmpty) {
        return const Left(
          NetworkFailure(CubitMessageCodes.parentRewardUnavailable),
        );
      }
      if (!cacheOnDevice) return Right(acknowledged);

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
    } on PostgrestException catch (e) {
      if (e.message.contains('Invalid reward transition') ||
          e.message.contains('Reward not found')) {
        return const Left(
          NetworkFailure(CubitMessageCodes.parentRewardUnavailable),
        );
      }
      return Left(Failure.fromCloud(e));
    } catch (e) {
      return Left(Failure.fromCloud(e));
    }
  }
}
