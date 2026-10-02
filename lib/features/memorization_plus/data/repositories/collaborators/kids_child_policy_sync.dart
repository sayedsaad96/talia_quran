import 'package:dartz/dartz.dart';

import '../../../../../core/error/app_failure.dart';
import '../../../../../core/identity/record_owner_provider.dart';
import '../../../../../core/utils/talia_logger.dart';
import '../../../domain/entities/kids_child_policy.dart';
import '../../../domain/entities/parent_dashboard.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import '../../models/memorization_models.dart';

/// Calls `compare_and_swap_child_policy` with the given params and returns
/// its jsonb payload `{"applied": bool, "version": bigint, "policy": row|null}`.
typedef KidsPolicyCasRpc =
    Future<Object?> Function(Map<String, dynamic> params);

/// Kids child-policy sync (compare-and-swap against `kids_child_policies`).
///
/// Transport is injected so the merge/CAS logic is testable without a live
/// Supabase client. [onPolicyChanged] runs after every local policy write
/// (the app reloads `KidsPolicyController` there).
class KidsChildPolicySync {
  KidsChildPolicySync(
    this._datasource,
    this._owner, {
    void Function()? onPolicyChanged,
  }) : _onPolicyChanged = onPolicyChanged;

  final MemorizationPlusLocalDatasource _datasource;
  final RecordOwnerProvider _owner;
  final void Function()? _onPolicyChanged;

  /// Server error raised when the caller is the child but holds no active
  /// guardian link: the device is treated as unlinked (local-only edit).
  static const _childNotLinked = 'Child link is not active';

  /// Child device: replaces the local policy with the server row when the
  /// server version is newer. Never throws; a failure leaves local untouched.
  Future<void> pull({
    required String ownerId,
    required Future<Map<String, dynamic>?> Function() fetchRow,
  }) async {
    try {
      final remote = policyFromRow(await fetchRow());
      if (remote == null || _owner.currentOwnerId != ownerId) return;
      final local = await _datasource.getParentSettings();
      if (remote.version <= local.policyVersion) return;
      if (_owner.currentOwnerId != ownerId) return;
      await _store(local, remote);
    } catch (e) {
      TaliaLogger.w('Kids child policy pull skipped', e);
    }
  }

  /// Child device edit (already behind the guardian PIN).
  ///
  /// - [linkedChildUserId] null → local only, `policyVersion + 1`.
  /// - Linked → CAS with the LOCAL `policyVersion` as expected version.
  ///   Applied → the returned row is stored. Not applied →
  ///   `Left(PolicyConflictFailure)` and the local policy is refreshed from
  ///   the returned server row (the edit is dropped). When the server has no
  ///   row yet, the CAS is retried once as a create (expected version 0).
  /// - "Child link is not active" → treated as unlinked.
  /// - Any other error → `Left(NetworkFailure)`, local unchanged.
  Future<Either<Failure, KidsChildPolicy>> saveOnDevice({
    required KidsChildPolicy policy,
    required String? linkedChildUserId,
    required KidsPolicyCasRpc casRpc,
  }) async {
    final ParentSettings local;
    try {
      local = await _datasource.getParentSettings();
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
    final edit = policy.sanitized();

    if (linkedChildUserId != null) {
      final ownerId = _owner.currentOwnerId;
      try {
        var response = await casRpc(
          casParams(linkedChildUserId, edit, local.policyVersion),
        );
        var parsed = _CasResponse.parse(response);
        if (!parsed.applied &&
            parsed.policy == null &&
            local.policyVersion > 0) {
          // No server row yet (e.g. edits made before linking): create it.
          response = await casRpc(casParams(linkedChildUserId, edit, 0));
          parsed = _CasResponse.parse(response);
        }
        if (_owner.currentOwnerId != ownerId) {
          return const Left(NetworkFailure());
        }
        final serverPolicy = parsed.policy;
        if (parsed.applied) {
          final stored = serverPolicy ?? edit.copyWith(version: parsed.version);
          await _store(await _datasource.getParentSettings(), stored);
          return Right(stored);
        }
        if (serverPolicy != null) {
          await _store(await _datasource.getParentSettings(), serverPolicy);
        }
        return const Left(PolicyConflictFailure());
      } catch (e) {
        if (!e.toString().contains(_childNotLinked)) {
          return Left(NetworkFailure.from(e));
        }
        TaliaLogger.w('Kids child policy saved locally (no active link)', e);
      }
    }

    try {
      final fresh = await _datasource.getParentSettings();
      final stored = edit.copyWith(version: fresh.policyVersion + 1);
      await _store(fresh, stored);
      return Right(stored);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  /// Guardian edit of a linked child's policy. Never touches the local cache.
  Future<Either<Failure, KidsChildPolicy>> casRemote({
    required String childUserId,
    required KidsChildPolicy policy,
    required int expectedVersion,
    required KidsPolicyCasRpc casRpc,
  }) async {
    try {
      final edit = policy.sanitized();
      final parsed = _CasResponse.parse(
        await casRpc(
          casParams(childUserId, edit, clampKidsPolicyVersion(expectedVersion)),
        ),
      );
      if (!parsed.applied) return const Left(PolicyConflictFailure());
      return Right(parsed.policy ?? edit.copyWith(version: parsed.version));
    } catch (e) {
      return Left(NetworkFailure.from(e));
    }
  }

  static Map<String, dynamic> casParams(
    String childUserId,
    KidsChildPolicy policy,
    int expectedVersion,
  ) => {
    'p_child_user_id': childUserId,
    'p_expected_version': expectedVersion,
    'p_reduce_motion': policy.reduceMotion,
    'p_max_daily_suggestions': policy.maxDailySuggestions,
    'p_home_missions_enabled': policy.homeMissionsEnabled,
    'p_session_goal_minutes': policy.sessionGoalMinutes,
  };

  /// Maps a `kids_child_policies` row (type-tolerant) to a sanitized policy;
  /// null when [row] is not a map.
  static KidsChildPolicy? policyFromRow(Object? row) {
    if (row is! Map) return null;
    return KidsChildPolicy(
      reduceMotion: _bool(row['reduce_motion'], false),
      maxDailySuggestions:
          _int(row['max_daily_suggestions']) ?? kKidsDefaultDailySuggestions,
      homeMissionsEnabled: _bool(row['home_missions_enabled'], true),
      sessionGoalMinutes: _int(row['session_goal_minutes']),
      version: _int(row['version']) ?? 0,
    ).sanitized();
  }

  static bool _bool(Object? raw, bool fallback) => switch (raw) {
    final bool value => value,
    'true' => true,
    'false' => false,
    _ => fallback,
  };

  static int? _int(Object? raw) => switch (raw) {
    final num value when value.isFinite => value.toInt(),
    final String value => int.tryParse(value),
    _ => null,
  };

  Future<void> _store(ParentSettings base, KidsChildPolicy policy) async {
    final clean = policy.sanitized();
    await _datasource.saveParentSettings(
      ParentSettingsModel.fromEntity(
        base.copyWith(
          kidsReduceMotion: clean.reduceMotion,
          maxDailySuggestions: clean.maxDailySuggestions,
          homeMissionsEnabled: clean.homeMissionsEnabled,
          sessionGoalMinutes: clean.sessionGoalMinutes,
          clearSessionGoalMinutes: clean.sessionGoalMinutes == null,
          policyVersion: clean.version,
        ),
      ),
    );
    try {
      _onPolicyChanged?.call();
    } catch (e) {
      TaliaLogger.w('Kids policy change listener failed', e);
    }
  }
}

class _CasResponse {
  const _CasResponse(this.applied, this.version, this.policy);

  final bool applied;
  final int version;
  final KidsChildPolicy? policy;

  static _CasResponse parse(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('Unexpected child policy CAS response');
    }
    final policy = KidsChildPolicySync.policyFromRow(raw['policy']);
    final version = clampKidsPolicyVersion(
      KidsChildPolicySync._int(raw['version']) ?? policy?.version ?? 0,
    );
    return _CasResponse(
      raw['applied'] == true,
      version,
      policy?.copyWith(version: version),
    );
  }
}
