import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/share_good_local_store.dart';
import '../share_good_config.dart';
import 'install_referrer_channel.dart';

/// Captures links immediately and persists validated tokens before delivery.
class IncomingInviteLinkService {
  IncomingInviteLinkService({
    required this._appLinks,
    required this._referrer,
    required this._store,
    required this._preferences,
    required this._links,
    required this._isEnabled,
    bool? isAndroid,
  }) : _isAndroid = isAndroid ?? Platform.isAndroid {
    if (_isAndroid) {
      _subscription = _appLinks.stringLinkStream.listen(
        _onLink,
        onError: (Object _) {},
      );
    }
  }

  static const _checkedKey = 'share_good_referrer_checked';
  final AppLinks _appLinks;
  final InstallReferrerChannel _referrer;
  final ShareGoodLocalStore _store;
  final SharedPreferences _preferences;
  final ShareGoodLinks _links;
  final bool Function() _isEnabled;
  final bool _isAndroid;
  final _controller = StreamController<String>.broadcast();
  final _seen = <String>{};
  StreamSubscription<String>? _subscription;
  Future<void> _tail = Future.value();
  Future<String?>? _initial;
  bool _receivedWarmLink = false;

  Stream<String> get tokens => _controller.stream;

  void _onLink(String raw) {
    if (!_isEnabled()) return;
    final token = _links.parseRaw(raw);
    if (token == null || !_seen.add(token)) return;
    _receivedWarmLink = true;
    _enqueue(() async {
      if (!await _persist(token)) {
        _seen.remove(token);
        return;
      }
      if (!_controller.isClosed && _isEnabled()) _controller.add(token);
    });
  }

  void _enqueue(Future<void> Function() operation) {
    _tail = _tail.then((_) => operation());
  }

  Future<String?> initialToken() => _initial ??= _loadSafely();

  Future<String?> _loadSafely() async {
    try {
      return await _loadInitial();
    } catch (_) {
      // A secure-store failure must not strand ordinary app startup.
      return null;
    }
  }

  Future<String?> _loadInitial() async {
    if (!_isAndroid || !_isEnabled()) return null;
    String? token;
    try {
      final raw = await _appLinks.getInitialLinkString().timeout(
        const Duration(seconds: 1),
      );
      if (raw != null) token = _links.parseRaw(raw);
    } catch (_) {
      // A missing platform implementation must not block startup.
    }
    final hadPending = await _store.pendingIncomingToken() != null;
    final checkReferrer =
        token == null &&
        !hadPending &&
        !_receivedWarmLink &&
        !(_preferences.getBool(_checkedKey) ?? false);
    if (checkReferrer) {
      final raw = await _referrer.readOnce();
      if (raw != null) token = _links.parseReferrer(raw);
    }
    final value = token;
    if (value != null && !_receivedWarmLink && _seen.add(value)) {
      var saved = false;
      _enqueue(() async {
        if (!_receivedWarmLink) saved = await _persist(value);
        if (!saved) _seen.remove(value);
      });
      await _tail;
      if (checkReferrer && saved) await _preferences.setBool(_checkedKey, true);
    } else if (checkReferrer && value == null && !_receivedWarmLink) {
      await _preferences.setBool(_checkedKey, true);
    }
    await _tail;
    if (!_isEnabled()) return null;
    final pending = await _store.pendingIncomingToken();
    if (pending == null || _links.parseReferrer('inv=$pending') == null) {
      return null;
    }
    _seen.add(pending);
    return pending;
  }

  Future<bool> _persist(String token) async {
    try {
      await _store.setPendingIncomingToken(token);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _tail;
    await _controller.close();
  }
}
