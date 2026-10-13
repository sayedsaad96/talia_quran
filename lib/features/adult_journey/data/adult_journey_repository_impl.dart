import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/identity/account_data_barrier.dart';
import '../../../core/identity/record_owner_provider.dart';
import '../../../core/utils/talia_logger.dart';
import '../domain/entities/adult_journey_preferences.dart';
import '../domain/entities/adult_journey_update.dart';
import '../domain/repositories/adult_journey_repository.dart';
import '../domain/services/adult_journey_update_reducer.dart';
import 'adult_journey_preferences_codec.dart';

/// SharedPreferences record per owner under [keyPrefix] (spec §5).
///
/// Reads and writes run under [AccountDataBarrier.run] with the owner the
/// caller expected, checked before and after I/O. The record is account data:
/// [keyPrefix] is in `AccountDataReset.clearedPreferencePrefixes`.
///
/// SharedPreferences updates its cache before the platform write completes,
/// so a failed write can leave a value in memory that was never stored. After
/// such a failure the cache is reloaded; until a reload succeeds this
/// repository neither reads nor writes from the untrusted cache.
class AdultJourneyRepositoryImpl implements AdultJourneyRepository {
  AdultJourneyRepositoryImpl(
    this._prefs,
    this._owner, {
    AdultJourneyPreferencesCodec codec = const AdultJourneyPreferencesCodec(),
    AdultJourneyUpdateReducer reducer = const AdultJourneyUpdateReducer(),
  }) : _codec = codec,
       _reducer = reducer;

  static const keyPrefix = 'adult_journey_v1_';

  static String keyFor(String ownerId) =>
      '$keyPrefix${Uri.encodeComponent(ownerId)}';

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;
  final AdultJourneyPreferencesCodec _codec;
  final AdultJourneyUpdateReducer _reducer;
  bool _cacheUntrusted = false;

  // Synchronous so a cubit can tell its own save (still `isSaving`) apart.
  final _changes = StreamController<String>.broadcast(sync: true);

  @override
  Stream<String> get changes => _changes.stream;

  AccountDataBarrier get _barrier => AccountDataBarrier.forPreferences(_prefs);

  @override
  Future<AdultJourneyLoadResult> load({required String expectedOwnerId}) async {
    try {
      return await _barrier.run((lease) async {
        _checkOwner(expectedOwnerId);
        if (!await _ensureTrustedCache(lease)) {
          return AdultJourneyLoadResult.unavailable;
        }
        final result = _codec.decode(_prefs.getString(keyFor(expectedOwnerId)));
        _checkOwner(expectedOwnerId);
        return result;
      });
    } on AccountDataUnavailableException {
      return AdultJourneyLoadResult.unavailable;
    } catch (error, stack) {
      TaliaLogger.w('Adult journey preferences not read', error, stack);
      return AdultJourneyLoadResult.unavailable;
    }
  }

  @override
  Future<AdultJourneySaveResult> update({
    required String expectedOwnerId,
    required AdultJourneyUpdate command,
  }) async {
    try {
      return await _barrier.run((lease) async {
        _checkOwner(expectedOwnerId);
        if (!await _ensureTrustedCache(lease)) {
          return const AdultJourneySaveResult.failed(
            AdultJourneySaveFailure.storage,
          );
        }
        return _apply(lease, expectedOwnerId, command);
      });
    } on AccountDataUnavailableException {
      return const AdultJourneySaveResult.failed(
        AdultJourneySaveFailure.unavailable,
      );
    } catch (error, stack) {
      TaliaLogger.w('Adult journey preferences not saved', error, stack);
      return const AdultJourneySaveResult.failed(
        AdultJourneySaveFailure.storage,
      );
    }
  }

  Future<AdultJourneySaveResult> _apply(
    AccountDataLease lease,
    String ownerId,
    AdultJourneyUpdate command,
  ) async {
    final key = keyFor(ownerId);
    final loaded = _codec.decode(_prefs.getString(key));
    final AdultJourneyPreferences current;
    switch (loaded.status) {
      case AdultJourneyLoadStatus.unsupported:
        return const AdultJourneySaveResult.failed(
          AdultJourneySaveFailure.unsupportedRecord,
        );
      case AdultJourneyLoadStatus.corrupt:
        // Only an explicit user choice replaces an unreadable record.
        if (command.isAutomatic) {
          return const AdultJourneySaveResult.failed(
            AdultJourneySaveFailure.corruptRecord,
          );
        }
        current = AdultJourneyPreferences.empty;
      case AdultJourneyLoadStatus.ready:
      case AdultJourneyLoadStatus.missing:
      case AdultJourneyLoadStatus.unavailable:
        current = loaded.preferences;
    }
    final next = _reducer.reduce(current, command);
    if (next == null) return AdultJourneySaveResult.unchanged(current);

    final saved = await _write(key, _codec.encode(next));
    if (!saved) {
      await _reconcile(lease);
      return const AdultJourneySaveResult.failed(
        AdultJourneySaveFailure.storage,
      );
    }
    _checkOwner(ownerId);
    lease.check();
    _changes.add(ownerId);
    return AdultJourneySaveResult.saved(next);
  }

  Future<bool> _write(String key, String value) async {
    try {
      return await _prefs.setString(key, value);
    } catch (error, stack) {
      TaliaLogger.w('Adult journey preferences write failed', error, stack);
      return false;
    }
  }

  Future<bool> _ensureTrustedCache(AccountDataLease lease) async {
    if (!_cacheUntrusted) return true;
    await _reconcile(lease);
    return !_cacheUntrusted;
  }

  /// Drops the possibly-unsaved in-memory value by reloading from disk.
  Future<void> _reconcile(AccountDataLease lease) async {
    _cacheUntrusted = true;
    try {
      await _prefs.reload();
      _cacheUntrusted = false;
    } catch (error, stack) {
      TaliaLogger.w('Adult journey preferences reload failed', error, stack);
    }
    lease.check();
  }

  void _checkOwner(String expectedOwnerId) {
    if (_owner.currentOwnerId != expectedOwnerId) {
      throw const AccountDataUnavailableException();
    }
  }
}
