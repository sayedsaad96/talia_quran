import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'record_owner_provider.dart';

class AccountDataUnavailableException implements Exception {
  const AccountDataUnavailableException();
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
  final _changes = StreamController<void>.broadcast(sync: true);
  Stream<void> get changes => _changes.stream;
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
    if (_preparingOwner == ownerId) return;
    _preparingOwner = ownerId;
    invalidate();
  }

  Future<void> markOwnerReady(String ownerId) async {
    if (_preparingOwner != ownerId ||
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
    if (_preparingOwner != ownerId ||
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
    _changes.add(null);
  }

  void notifyChanged() => _changes.add(null);

  Future<T> run<T>(
    Future<T> Function(AccountDataLease lease) work, {
    Object? authority,
  }) {
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

  Future<void> clear(Future<void> Function() clearStores) {
    invalidate();
    final generation = _generation;
    final result = _tail.then((_) async {
      await clearStores();
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
  const AccountDataLease._(this._barrier, this._generation);
  final AccountDataBarrier _barrier;
  final int _generation;
  void check() {
    _barrier._checkOwner();
    if (_barrier._blocked || _generation != _barrier._generation) {
      throw const AccountDataUnavailableException();
    }
  }
}
