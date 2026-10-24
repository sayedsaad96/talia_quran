import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'record_owner_provider.dart';

class AccountDataUnavailableException implements Exception {
  const AccountDataUnavailableException();
}

/// Thrown by a store wipe that completed everything except a native
/// projection (e.g. the home widget). The barrier stays blocked but may retry
/// just the projection later ([AccountDataBarrier.retryFailedClear]). It is
/// unwrapped before reaching callers.
class AccountProjectionClearFailure implements Exception {
  const AccountProjectionClearFailure(this.cause, this.stackTrace);
  final Object cause;
  final StackTrace stackTrace;
}

/// Local account authority shared by reset and account-owned writers.
/// Invalidation is synchronous; clearing is serialized after accepted I/O.
class AccountDataBarrier {
  AccountDataBarrier._(this._prefs);
  static final _instances = Expando<AccountDataBarrier>();
  static AccountDataBarrier forPreferences(SharedPreferences prefs) =>
      _instances[prefs] ??= AccountDataBarrier._(prefs);
  final SharedPreferences _prefs;
  RecordOwnerProvider? owner;
  String? _readyOwner;
  int _generation = 0;
  bool _blocked = false;
  String? _preparingOwner;
  Future<void> _tail = Future.value();
  final _invalidationParticipants = <Future<void> Function()>{};
  Future<void> _invalidation = Future.value();
  bool _invalidationFailed = false;
  bool _clearFailed = false;
  bool _retryingClear = false;

  /// Native projections must clear before an account becomes locally ready.
  void Function() addInvalidationParticipant(Future<void> Function() clear) {
    _invalidationParticipants.add(clear);
    return () => _invalidationParticipants.remove(clear);
  }
  final _changes = StreamController<void>.broadcast(sync: true);
  Stream<void> get changes => _changes.stream;

  /// Bumps on every invalidation; read-only, for change detection.
  int get generation => _generation;
  AccountDataLease get snapshot {
    _checkOwner();
    return AccountDataLease._(this, _generation);
  }

  void _checkOwner() {
    final current = owner?.currentOwnerId;
    if (current == null) return;
    final hasKhatmahData =
        _prefs.containsKey('khatmah_active_plan') ||
        _prefs.containsKey('khatmah_history');
    _readyOwner ??= hasKhatmahData
        ? (_prefs.getString('khatmah_owner') ??
              _prefs.getString('auth_last_signed_in_user_id') ??
              current)
        : current;
    if (current != _readyOwner && !_blocked) invalidate();
  }

  bool get isReady {
    _checkOwner();
    return !_blocked;
  }

  void prepareOwner(String ownerId) {
    if (_preparingOwner == ownerId && !_invalidationFailed) return;
    _preparingOwner = ownerId;
    invalidate();
  }

  Future<void> markOwnerReady(String ownerId) async {
    final generation = _generation;
    await _invalidation;
    if (generation != _generation || _preparingOwner != ownerId ||
        (owner != null && owner!.currentOwnerId != ownerId)) {
      throw const AccountDataUnavailableException();
    }
    // This marker prevents preserved account-owned Khatmah data appearing as
    // guest data after a forced sign-out and process restart.
    if (_prefs.containsKey('khatmah_active_plan') ||
        _prefs.containsKey('khatmah_history')) {
      if (!await _prefs.setString('khatmah_owner', ownerId)) {
        await _prefs.reload();
        throw const AccountDataUnavailableException();
      }
    }
    if (generation != _generation || _preparingOwner != ownerId ||
        (owner != null && owner!.currentOwnerId != ownerId)) {
      throw const AccountDataUnavailableException();
    }
    _readyOwner = ownerId;
    _preparingOwner = null;
    _blocked = false;
    notifyChanged();
  }

  Future<void> stampOwner(AccountDataLease lease) async {
    lease.check();
    final current = owner?.currentOwnerId;
    if (current != null && _prefs.getString('khatmah_owner') != current) {
      if (!await _prefs.setString('khatmah_owner', current)) {
        await _prefs.reload();
        throw const AccountDataUnavailableException();
      }
      lease.check();
    }
  }

  AccountDataLease capture() {
    _checkOwner();
    if (_blocked) throw const AccountDataUnavailableException();
    return AccountDataLease._(this, _generation);
  }

  void invalidate() {
    _generation++;
    _blocked = true;
    _invalidationFailed = false;
    _clearFailed = false;
    final generation = _generation;
    _invalidation = Future.wait<void>([
      for (final clear in _invalidationParticipants.toList()) Future<void>.sync(clear),
    ]).then<void>((_) {});
    unawaited(_invalidation.then<void>((_) {}, onError: (Object _, StackTrace _) {
      if (generation == _generation) _invalidationFailed = true;
    }));
    _changes.add(null);
  }

  void notifyChanged() => _changes.add(null);

  Future<T> run<T>(
    Future<T> Function(AccountDataLease lease) work, {
    Object? authority,
  }) {
    if (authority is AccountDataLease &&
        !identical(authority._barrier, this)) {
      throw const AccountDataUnavailableException();
    }
    final lease = authority is AccountDataLease ? authority : capture();
    final result = _tail.then((_) async {
      lease.check();
      final value = await work(lease);
      lease.check();
      return value;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  /// Bounded recovery after a [clear] that wiped the stores but failed to clear
  /// a native projection. Re-runs the projections once; only a fully
  /// successful run unblocks (fail closed otherwise). Any newer invalidation
  /// supersedes it. Returns whether the barrier was unblocked.
  Future<bool> retryFailedClear({Future<void> Function()? projection}) async {
    if (!_clearFailed || _retryingClear) return false;
    _retryingClear = true;
    final generation = _generation;
    try {
      await _tail;
      if (generation != _generation || !_clearFailed) return false;
      await Future.wait<void>([
        for (final clear in _invalidationParticipants.toList())
          Future<void>.sync(clear),
        if (projection != null) Future<void>.sync(projection),
      ]);
      if (generation != _generation) return false;
      _clearFailed = false;
      _invalidationFailed = false;
      _readyOwner = owner?.currentOwnerId;
      _blocked = _preparingOwner != null;
      notifyChanged();
      return true;
    } catch (_) {
      return false;
    } finally {
      _retryingClear = false;
    }
  }

  Future<void> clear(Future<void> Function() clearStores) {
    invalidate();
    final generation = _generation;
    final invalidation = _invalidation;
    final result = _tail.then((_) async {
      // A failed invalidation participant (for example a native projection)
      // must not keep stale account data on disk: always wipe the stores, then
      // surface the failure and stay blocked so nothing is published or
      // activated for the next owner (fail closed).
      Object? invalidationError;
      StackTrace? invalidationStack;
      try {
        await invalidation;
      } catch (error, stack) {
        invalidationError = error;
        invalidationStack = stack;
      }
      AccountProjectionClearFailure? projectionFailure;
      try {
        await clearStores();
      } on AccountProjectionClearFailure catch (failure) {
        projectionFailure = failure;
      }
      if (invalidationError != null) {
        if (generation == _generation) _clearFailed = true;
        Error.throwWithStackTrace(invalidationError, invalidationStack!);
      }
      if (projectionFailure != null) {
        if (generation == _generation) _clearFailed = true;
        Error.throwWithStackTrace(
          projectionFailure.cause,
          projectionFailure.stackTrace,
        );
      }
      if (generation == _generation) {
        _readyOwner = owner?.currentOwnerId;
        _blocked = _preparingOwner != null;
        notifyChanged();
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

class AccountDataLease {
  AccountDataLease._(this._barrier, this._generation)
    : _ownerId = _barrier.owner?.currentOwnerId;
  final AccountDataBarrier _barrier;
  final int _generation;
  final String? _ownerId;
  Stream<void> get changes => _barrier.changes;

  /// Binds an account-owned write to the owner governing this lease.
  /// An unbound barrier cannot authorize an owner-scoped write.
  void checkOwner(String ownerId) {
    check();
    if (ownerId.isEmpty || _ownerId != ownerId ||
        _barrier.owner?.currentOwnerId != ownerId) {
      throw const AccountDataUnavailableException();
    }
  }

  void check() {
    _barrier._checkOwner();
    if (_barrier._blocked || _generation != _barrier._generation) {
      throw const AccountDataUnavailableException();
    }
  }
}
