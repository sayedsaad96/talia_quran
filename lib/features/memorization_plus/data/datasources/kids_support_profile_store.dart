import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../domain/entities/kids_learning_support_profile.dart';
import '../../domain/repositories/kids_support_profile_repository.dart';

/// Sync bookkeeping next to the answer: the last server version this device
/// adopted or had acknowledged, and whether a local edit still waits for the
/// server.
class KidsSupportSyncState {
  const KidsSupportSyncState({
    required this.profile,
    required this.serverVersion,
    required this.pending,
  });

  final KidsLearningSupportProfile profile;
  final int serverVersion;
  final bool pending;
}

/// Owner-scoped, versioned record of the guardian's support answers for the
/// child on this device. Cleared with the rest of the account's data on an
/// account switch (`AccountDataReset`, prefix [keyPrefix]). Every write runs
/// under the account barrier, so nothing lands for another account.
class KidsSupportProfileStore implements KidsSupportProfileRepository {
  KidsSupportProfileStore(this._prefs, this._owner);

  static const keyPrefix = 'kids_support_profile_';

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  String get _key => '$keyPrefix${_owner.currentOwnerId}';

  @override
  KidsLearningSupportProfile read() => syncState().profile;

  KidsSupportSyncState syncState() => _readState(_key);

  KidsSupportSyncState _readState(String key) {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return _empty;
      final decoded = jsonDecode(raw);
      final serverVersion = decoded is Map ? decoded['serverVersion'] : null;
      return KidsSupportSyncState(
        profile: KidsLearningSupportProfile.fromJson(decoded),
        serverVersion: serverVersion is int && serverVersion > 0
            ? serverVersion
            : 0,
        pending: decoded is Map && decoded['pending'] == true,
      );
    } catch (_) {
      return _empty;
    }
  }

  static const _empty = KidsSupportSyncState(
    profile: KidsLearningSupportProfile.unknown,
    serverVersion: 0,
    pending: false,
  );

  /// A guardian edit on this device: kept, and marked pending for the server.
  @override
  Future<bool> save(KidsLearningSupportProfile profile) => _write(
    (current) => KidsSupportSyncState(
      profile: profile,
      serverVersion: current.serverVersion,
      pending: true,
    ),
  );

  /// Adopts a server row only when it is newer than what this device holds.
  /// The server (the guardian's latest answer) wins over a pending local
  /// edit, like the child policy.
  Future<bool> applyServer(
    KidsLearningSupportProfile profile, {
    required int version,
  }) => _write(
    (current) => version <= current.serverVersion
        ? null
        : KidsSupportSyncState(
            profile: profile,
            serverVersion: version,
            pending: false,
          ),
  );

  /// Records the server's acknowledgement of [pushed]. An answer edited
  /// again during the push stays pending for the next sync.
  Future<bool> markSynced(
    KidsLearningSupportProfile pushed, {
    required int version,
  }) => _write(
    (current) => KidsSupportSyncState(
      profile: current.profile,
      serverVersion: version,
      pending: current.profile != pushed,
    ),
  );

  /// The server row vanished: keep the answer pending so it is re-created.
  Future<bool> restartFromCreate() => _write(
    (current) => KidsSupportSyncState(
      profile: current.profile,
      serverVersion: 0,
      pending: true,
    ),
  );

  /// [next] returns null to leave the record untouched.
  Future<bool> _write(
    KidsSupportSyncState? Function(KidsSupportSyncState current) next,
  ) async {
    final key = _key;
    try {
      return await AccountDataBarrier.forPreferences(_prefs).run((lease) async {
        if (key != _key) return false;
        final state = next(_readState(key));
        if (state == null) return false;
        final saved = await _prefs.setString(
          key,
          jsonEncode({
            ...state.profile.toJson(),
            'serverVersion': state.serverVersion,
            'pending': state.pending,
          }),
        );
        lease.check();
        return saved;
      });
    } on AccountDataUnavailableException {
      return false;
    } catch (error, stack) {
      // A platform write failure is reported as "not saved", never thrown
      // into the guardian's editor.
      TaliaLogger.w('Kids support profile not saved', error, stack);
      return false;
    }
  }
}
