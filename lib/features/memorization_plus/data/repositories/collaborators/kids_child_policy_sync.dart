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

  /// Child device: adopts the server row iff its version is newer than the
  /// last version the server acknowledged (`policySyncedVersion`). Adopting
  /// sets both versions to the server version and confirms the link.
  /// Never throws; a failure leaves local untouched.
  Future<void> pull({
    required String ownerId,
    required Future<Map<String, dynamic>?> Function() fetchRow,
  }) async {
    try {
      final remote = policyFromRow(await fetchRow());
      if (remote == null || _owner.currentOwnerId != ownerId) return;
      final local = await _datasource.getParentSettings();
      if (remote.version <= local.policySyncedVersion) return;
      if (_owner.currentOwnerId != ownerId) return;
      await _storeServer(local, remote);
    } catch (e) {
      TaliaLogger.w('Kids child policy pull skipped', e);
    }
  }

  /// Child device edit (already behind the guardian PIN).
  ///
  /// - [linkedChildUserId] null → local only, `policyVersion + 1`.
  /// - Signed in → CAS with `expected = policySyncedVersion` (0 = create).
  ///   Applied → the returned row is stored. Not applied →
  ///   `Left(PolicyConflictFailure)` and the local policy is refreshed from
  ///   the returned server row (the edit is dropped). Either way both
  ///   versions become the server version and the link is confirmed.
  /// - Not applied with no server row while `expected > 0` (the row
  ///   vanished) → the edit is kept pending (`policySyncedVersion = 0`) and
  ///   `Right` is returned; the next push recreates the row.
  /// - "Child link is not active" → local edit (+1), link unconfirmed.
  /// - Transport error → `Left(NetworkFailure)` (local unchanged) only when
  ///   the link is confirmed; otherwise the edit is kept locally (+1) and
  ///   pushed later by [pushPending].
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
    bool? linkConfirmed;

    if (linkedChildUserId != null) {
      final ownerId = _owner.currentOwnerId;
      try {
        final parsed = _CasResponse.parse(
          await casRpc(
            casParams(linkedChildUserId, edit, local.policySyncedVersion),
          ),
        );
        if (_owner.currentOwnerId != ownerId) {
          return const Left(NetworkFailure());
        }
        final fresh = await _datasource.getParentSettings();
        if (parsed.applied) {
          final stored =
              parsed.policy ?? edit.copyWith(version: parsed.version);
          await _storeServer(fresh, stored);
          return Right(stored);
        }
        if (parsed.policy == null && local.policySyncedVersion > 0) {
          // The row vanished (no conflict to show): keep the EDIT pending so
          // the next push recreates the row with expected = 0.
          final stored = edit.copyWith(version: fresh.policyVersion + 1);
          await _store(fresh, stored, syncedVersion: 0, linkConfirmed: true);
          return Right(stored);
        }
        await _storeServer(
          fresh,
          parsed.policy ??
              // The row vanished: keep local values, restart from a create.
              KidsChildPolicy.fromSettings(fresh).copyWith(version: 0),
        );
        return const Left(PolicyConflictFailure());
      } catch (e) {
        if (_isChildNotLinked(e)) {
          TaliaLogger.w('Kids child policy saved locally (no active link)', e);
          linkConfirmed = false;
        } else if (local.policyLinkConfirmed == true) {
          return Left(NetworkFailure.from(e));
        } else {
          TaliaLogger.w('Kids child policy saved locally (offline)', e);
        }
      }
    }

    try {
      final fresh = await _datasource.getParentSettings();
      final stored = edit.copyWith(version: fresh.policyVersion + 1);
      await _store(
        fresh,
        stored,
        syncedVersion: fresh.policySyncedVersion,
        linkConfirmed: linkConfirmed ?? fresh.policyLinkConfirmed,
      );
      return Right(stored);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  /// Pushes a local policy edit the server has not acknowledged yet
  /// (`policyVersion > policySyncedVersion`, e.g. edits made before linking)
  /// with `expected = policySyncedVersion`. Applied → stored; conflict → the
  /// server row is adopted (the guardian wins); "Child link is not active" →
  /// link unconfirmed; transport error → stays pending; the row vanished
  /// (not applied, no row, `expected > 0`) → local values stay pending with
  /// `policySyncedVersion = 0` so the next push recreates it.
  ///
  /// Upgrade from P2 (P3-R17): `policySyncedVersion == 0` with an unknown
  /// link state (`policyLinkConfirmed == null`) is also pending, so one create
  /// with `expected = 0` is sent; an existing row conflicts and is adopted
  /// (the guardian's choice wins). Never throws.
  Future<void> pushPending({
    required String ownerId,
    required String childUserId,
    required KidsPolicyCasRpc casRpc,
  }) async {
    try {
      if (_owner.currentOwnerId != ownerId) return;
      final local = await _datasource.getParentSettings();
      final upgradeFromP2 =
          local.policySyncedVersion == 0 && local.policyLinkConfirmed == null;
      if (local.policyVersion <= local.policySyncedVersion && !upgradeFromP2) {
        return;
      }
      final edit = KidsChildPolicy.fromSettings(local);
      final _CasResponse parsed;
      try {
        parsed = _CasResponse.parse(
          await casRpc(casParams(childUserId, edit, local.policySyncedVersion)),
        );
      } catch (e) {
        if (!_isChildNotLinked(e)) {
          TaliaLogger.w('Kids child policy push pending', e);
          return;
        }
        if (_owner.currentOwnerId != ownerId) return;
        final fresh = await _datasource.getParentSettings();
        await _datasource.saveParentSettings(
          ParentSettingsModel.fromEntity(
            fresh.copyWith(policyLinkConfirmed: false),
          ),
        );
        return;
      }
      if (_owner.currentOwnerId != ownerId) return;
      final fresh = await _datasource.getParentSettings();
      if (parsed.applied && fresh.policyVersion != local.policyVersion) {
        // Edited again during the call: record the acknowledgement only;
        // the newer edit stays pending for the next sync.
        await _datasource.saveParentSettings(
          ParentSettingsModel.fromEntity(
            fresh.copyWith(
              policySyncedVersion: parsed.version,
              policyLinkConfirmed: true,
            ),
          ),
        );
        return;
      }
      if (!parsed.applied &&
          parsed.policy == null &&
          local.policySyncedVersion > 0) {
        // The row vanished: keep the local values pending for a re-create.
        await _store(
          fresh,
          KidsChildPolicy.fromSettings(
            fresh,
          ).copyWith(version: fresh.policyVersion + 1),
          syncedVersion: 0,
          linkConfirmed: true,
        );
        return;
      }
      await _storeServer(
        fresh,
        parsed.policy ??
            (parsed.applied
                ? edit.copyWith(version: parsed.version)
                : edit.copyWith(version: 0)),
      );
    } catch (e) {
      TaliaLogger.w('Kids child policy push skipped', e);
    }
  }

  static bool _isChildNotLinked(Object error) =>
      error.toString().contains(_childNotLinked);

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

  /// Stores a server-acknowledged policy: both versions = its version, link
  /// confirmed.
  Future<void> _storeServer(ParentSettings base, KidsChildPolicy policy) =>
      _store(
        base,
        policy,
        syncedVersion: clampKidsPolicyVersion(policy.version),
        linkConfirmed: true,
      );

  Future<void> _store(
    ParentSettings base,
    KidsChildPolicy policy, {
    required int syncedVersion,
    required bool? linkConfirmed,
  }) async {
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
          policySyncedVersion: syncedVersion,
          policyLinkConfirmed: linkConfirmed,
          clearPolicyLinkConfirmed: linkConfirmed == null,
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
