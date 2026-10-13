import 'package:dartz/dartz.dart';

import '../../../../../core/error/app_failure.dart';
import '../../../../../core/identity/record_owner_provider.dart';
import '../../../../../core/utils/talia_logger.dart';
import '../../../domain/entities/kids_learning_support_profile.dart';
import '../../datasources/kids_support_profile_store.dart';

/// Reads one `kids_child_reading_support` row for a child; null when none.
typedef KidsReadingSupportFetch =
    Future<Map<String, dynamic>?> Function(String childUserId);

/// Calls `compare_and_swap_child_reading_support` and returns its jsonb
/// payload `{"applied": bool, "version": bigint, "support": row|null}`.
typedef KidsReadingSupportCas =
    Future<Object?> Function(Map<String, dynamic> params);

/// Roadmap T7 sync of the reading answer, separate from the child-policy
/// CAS so neither can disturb the other. Transport is injected for tests.
/// Every child-device method is best-effort and never throws: a server
/// without the table (not yet migrated) just leaves the local answer as is.
class KidsReadingSupportSync {
  KidsReadingSupportSync(this._store, this._owner);

  final KidsSupportProfileStore _store;
  final RecordOwnerProvider _owner;

  /// Child device: adopts a newer server answer.
  Future<void> pull({
    required String ownerId,
    required KidsReadingSupportFetch fetch,
  }) async {
    try {
      final remote = supportFromRow(await fetch(ownerId));
      if (remote == null || _owner.currentOwnerId != ownerId) return;
      await _store.applyServer(remote.profile, version: remote.version);
    } catch (e) {
      TaliaLogger.w('Kids reading support pull skipped', e);
    }
  }

  /// Child device: sends a local guardian edit the server has not
  /// acknowledged. Applied → acknowledged; conflict → the server answer is
  /// adopted; the row vanished → re-created next time; any error → pending.
  Future<void> pushPending({
    required String ownerId,
    required KidsReadingSupportCas cas,
  }) async {
    try {
      if (_owner.currentOwnerId != ownerId) return;
      final state = _store.syncState();
      if (!state.pending) return;
      final parsed = _CasResponse.parse(
        await cas(casParams(ownerId, state.profile, state.serverVersion)),
      );
      if (_owner.currentOwnerId != ownerId) return;
      if (parsed.applied) {
        await _store.markSynced(state.profile, version: parsed.version);
        return;
      }
      final server = parsed.support;
      if (server != null) {
        await _store.applyServer(server.profile, version: server.version);
      } else if (state.serverVersion > 0) {
        await _store.restartFromCreate();
      }
    } catch (e) {
      TaliaLogger.w('Kids reading support push pending', e);
    }
  }

  /// Guardian device: the linked child's current answer.
  Future<Either<Failure, KidsRemoteReadingSupport>> fetchRemote({
    required String childUserId,
    required KidsReadingSupportFetch fetch,
  }) async {
    try {
      return Right(
        supportFromRow(await fetch(childUserId)) ??
            const KidsRemoteReadingSupport(
              KidsLearningSupportProfile.unknown,
              0,
            ),
      );
    } catch (e) {
      return Left(NetworkFailure.from(e));
    }
  }

  /// Guardian device: CAS against the version it read. A conflict returns
  /// `Left(PolicyConflictFailure)`; the caller re-reads and retries.
  Future<Either<Failure, KidsRemoteReadingSupport>> casRemote({
    required String childUserId,
    required KidsLearningSupportProfile profile,
    required int expectedVersion,
    required KidsReadingSupportCas cas,
  }) async {
    try {
      final parsed = _CasResponse.parse(
        await cas(casParams(childUserId, profile, expectedVersion)),
      );
      if (!parsed.applied) return const Left(PolicyConflictFailure());
      return Right(
        parsed.support ?? KidsRemoteReadingSupport(profile, parsed.version),
      );
    } catch (e) {
      return Left(NetworkFailure.from(e));
    }
  }

  static Map<String, dynamic> casParams(
    String childUserId,
    KidsLearningSupportProfile profile,
    int expectedVersion,
  ) => {
    'p_child_user_id': childUserId,
    'p_expected_version': expectedVersion < 0 ? 0 : expectedVersion,
    'p_reading_ability': profile.reading == KidsReadingAbility.unknown
        ? null
        : profile.reading.name,
  };

  /// Type-tolerant row mapping; null when [row] is not a map. An unknown or
  /// missing reading value reads as "not answered".
  static KidsRemoteReadingSupport? supportFromRow(Object? row) {
    if (row is! Map) return null;
    final reading = KidsReadingAbility.values
        .where(
          (r) =>
              r != KidsReadingAbility.unknown &&
              r.name == row['reading_ability'],
        )
        .firstOrNull;
    final version = _int(row['version']) ?? 0;
    return KidsRemoteReadingSupport(
      KidsLearningSupportProfile(
        reading: reading ?? KidsReadingAbility.unknown,
      ),
      version < 0 ? 0 : version,
    );
  }

  static int? _int(Object? raw) => switch (raw) {
    final num value when value.isFinite => value.toInt(),
    final String value => int.tryParse(value),
    _ => null,
  };
}

class _CasResponse {
  const _CasResponse(this.applied, this.version, this.support);

  final bool applied;
  final int version;
  final KidsRemoteReadingSupport? support;

  static _CasResponse parse(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('Unexpected reading support CAS response');
    }
    final support = KidsReadingSupportSync.supportFromRow(raw['support']);
    final version =
        KidsReadingSupportSync._int(raw['version']) ?? support?.version ?? 0;
    return _CasResponse(
      raw['applied'] == true,
      version < 0 ? 0 : version,
      support == null
          ? null
          : KidsRemoteReadingSupport(support.profile, version),
    );
  }
}
