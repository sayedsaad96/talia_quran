import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/identity/account_data_barrier.dart';
import '../../../core/identity/record_owner_provider.dart';
import '../domain/entities/kids_encouragement.dart';
import '../domain/repositories/kids_encouragement_repository.dart';
import 'kids_encouragement_cloud_codec.dart';

typedef KidsEncouragementRpc =
    Future<Object?> Function(String function, Map<String, dynamic> parameters);
typedef KidsEncouragementSelectForChild =
    Future<List<Map<String, dynamic>>> Function(String childUserId);
typedef KidsEncouragementSelectSeen =
    Future<List<Map<String, dynamic>>> Function(List<int> ids);

/// Account-scoped client for the fixed-key encouragement RPCs.
final class KidsEncouragementRepositoryImpl
    implements KidsEncouragementRepository {
  KidsEncouragementRepositoryImpl({
    required this._prefs,
    required this._owner,
    required this._barrier,
    required this._isEnabled,
    required this._rpc,
    required this._selectForChild,
    required this._selectSeen,
  });

  static const _pendingPrefix = 'kids_encouragement_pending_seen_v1_';
  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;
  final AccountDataBarrier _barrier;
  final bool Function() _isEnabled;
  final KidsEncouragementRpc _rpc;
  final KidsEncouragementSelectForChild _selectForChild;
  final KidsEncouragementSelectSeen _selectSeen;
  final Map<String, List<KidsEncouragement>> _cache = {};

  @override
  Future<KidsEncouragementSendResult> send({
    required String childUserId,
    required KidsEncouragementMessage message,
    required KidsEncouragementSticker sticker,
    required String clientRequestId,
  }) async {
    if (!_isEnabled()) return const KidsEncouragementSendDisabled();
    _checkIdentity(childUserId);
    if (!KidsEncouragementCloudCodec.isUuid(clientRequestId)) {
      throw const FormatException('Invalid encouragement request id');
    }
    final authority = _captureAuthority();
    final raw = await _rpc('send_kids_encouragement', {
      'p_child_user_id': childUserId,
      'p_message_key': message.serverKey,
      'p_sticker_key': sticker.serverKey,
      'p_client_request_id': clientRequestId,
    });
    authority.check(_owner);
    final rows = KidsEncouragementCloudCodec.decodeRows(raw);
    if (rows.length != 1 ||
        !_matchesRequest(
          rows.single,
          authority.ownerId,
          childUserId,
          message,
          sticker,
          clientRequestId,
        )) {
      throw const FormatException('Unexpected encouragement response');
    }
    await _barrier.run((lease) async {
      _check(authority.ownerId, lease);
      _put(authority.ownerId, childUserId, rows.single);
      _check(authority.ownerId, lease);
    }, authority: authority.lease);
    return KidsEncouragementSendSuccess(rows.single);
  }

  @override
  Future<List<KidsEncouragement>> refresh({required String childUserId}) async {
    if (!_isEnabled()) return const [];
    _checkIdentity(childUserId);
    final authority = _captureAuthority();
    final raw = await _selectForChild(childUserId);
    authority.check(_owner);
    final rows = KidsEncouragementCloudCodec.decodeRows(raw);
    if (rows.any((row) => row.childUserId != childUserId)) {
      throw const FormatException('Foreign encouragement row');
    }
    await _barrier.run((lease) async {
      _check(authority.ownerId, lease);
      _cache[_cacheKey(authority.ownerId, childUserId)] = rows;
      _check(authority.ownerId, lease);
    }, authority: authority.lease);
    return rows;
  }

  @override
  List<KidsEncouragement> cached({required String childUserId}) {
    if (!_isEnabled()) return const [];
    try {
      final authority = _captureAuthority();
      return List.unmodifiable(
        _cache[_cacheKey(authority.ownerId, childUserId)] ?? const [],
      );
    } on AccountDataUnavailableException {
      return const [];
    }
  }

  @override
  Future<int> markSeen(List<int> ids) => _markSeen(ids);

  @override
  Future<int> retryPendingSeen() async {
    if (!_isEnabled()) return 0;
    final authority = _captureAuthority();
    final pending = await _barrier.run(
      (_) => _readPending(authority),
      authority: authority.lease,
    );
    var updated = 0;
    // A revoked batch must not starve later active receipts. Process one
    // finite snapshot, keeping each request within the server's 100-id cap.
    for (var start = 0; start < pending.length; start += 100) {
      authority.check(_owner);
      final end = start + 100 < pending.length ? start + 100 : pending.length;
      updated += await _markSeen(
        pending.sublist(start, end),
        originalAuthority: authority,
      );
    }
    return updated;
  }

  @override
  Future<List<int>> pendingSeenIds() async {
    if (!_isEnabled()) return const [];
    final authority = _captureAuthority();
    return _barrier.run((lease) async {
      _check(authority.ownerId, lease);
      final value = _prefs.getString(_pendingKey(authority.ownerId));
      final decoded = value == null ? const <dynamic>[] : jsonDecode(value);
      if (decoded is! List || decoded.any((id) => id is! int || id <= 0)) {
        throw const FormatException('Invalid pending encouragement receipt');
      }
      _check(authority.ownerId, lease);
      return List<int>.unmodifiable(_capPending(decoded.cast<int>()));
    }, authority: authority.lease);
  }

  Future<int> _markSeen(List<int> ids, {_Authority? originalAuthority}) async {
    if (!_isEnabled() || ids.isEmpty) return 0;
    if (ids.length > 100) throw RangeError.range(ids.length, 0, 100, 'ids');
    final unique = ids.toSet().toList()..sort();
    if (unique.any((id) => id <= 0)) {
      throw const FormatException('Invalid encouragement id');
    }
    final authority = originalAuthority ?? _captureAuthority();
    authority.check(_owner);
    await _mergePending(authority, unique);
    final value = await _rpc('mark_kids_encouragements_seen', {
      'p_ids': unique,
    });
    authority.check(_owner);
    if (value is! int || value < 0 || value > unique.length) {
      throw const FormatException('Invalid seen response');
    }
    final confirmed = value == unique.length
        ? unique
        : await _confirmedSeen(authority, unique);
    authority.check(_owner);
    await _removePending(authority, confirmed);
    return value;
  }

  Future<List<int>> _confirmedSeen(
    _Authority authority,
    List<int> submitted,
  ) async {
    final rows = await _selectSeen(submitted);
    authority.check(_owner);
    final confirmed = <int>{};
    for (final row in rows) {
      final id = row['id'];
      final seenAt = row['seen_at'];
      if (id is! int ||
          !submitted.contains(id) ||
          row['child_user_id'] != authority.ownerId ||
          seenAt is! String ||
          DateTime.tryParse(seenAt) == null) {
        throw const FormatException('Invalid seen acknowledgement');
      }
      confirmed.add(id);
    }
    return confirmed.toList();
  }

  _Authority _captureAuthority() {
    final authority = _Authority(_owner.currentOwnerId, _barrier.capture());
    authority.check(_owner);
    return authority;
  }

  Future<void> _mergePending(_Authority authority, List<int> ids) async {
    await _barrier.run((lease) async {
      _check(authority.ownerId, lease);
      final current = await _readPending(authority);
      final merged = {...current, ...ids}.toList()..sort();
      await _writePending(authority, merged);
      _check(authority.ownerId, lease);
    }, authority: authority.lease);
  }

  Future<void> _removePending(_Authority authority, List<int> ids) =>
      _barrier.run((lease) async {
        _check(authority.ownerId, lease);
        final current = await _readPending(authority);
        await _writePending(
          authority,
          current.where((id) => !ids.contains(id)).toList(),
        );
        _check(authority.ownerId, lease);
      }, authority: authority.lease);

  Future<List<int>> _readPending(_Authority authority) async {
    authority.check(_owner);
    final raw = _prefs.getString(_pendingKey(authority.ownerId));
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.any((id) => id is! int || id <= 0)) {
      throw const FormatException('Invalid pending encouragement receipt');
    }
    authority.check(_owner);
    return _capPending(decoded.cast<int>());
  }

  /// Receipts that never confirm (hidden or revoked links) would otherwise
  /// accumulate forever; ids are serial, so keep only the newest ones.
  static const _maxPending = 200;
  static List<int> _capPending(List<int> ids) {
    if (ids.length <= _maxPending) return ids;
    final sorted = [...ids]..sort();
    return sorted.sublist(sorted.length - _maxPending);
  }

  Future<void> _writePending(_Authority authority, List<int> ids) async {
    authority.check(_owner);
    final ok = await _prefs.setString(
      _pendingKey(authority.ownerId),
      jsonEncode(_capPending(ids)),
    );
    authority.check(_owner);
    if (!ok) throw StateError('Unable to persist seen receipt');
  }

  void _put(String ownerId, String childId, KidsEncouragement row) {
    final key = _cacheKey(ownerId, childId);
    final existing = _cache[key] ?? const [];
    _cache[key] = [...existing.where((item) => item.id != row.id), row]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static bool _matchesRequest(
    KidsEncouragement row,
    String parentId,
    String childId,
    KidsEncouragementMessage message,
    KidsEncouragementSticker sticker,
    String requestId,
  ) =>
      row.parentUserId == parentId &&
      row.childUserId == childId &&
      row.message == message &&
      row.sticker == sticker &&
      row.clientRequestId == requestId;
  static String _cacheKey(String ownerId, String childId) =>
      '$ownerId\u0000$childId';
  static String _pendingKey(String ownerId) =>
      '$_pendingPrefix${Uri.encodeComponent(ownerId)}';
  static void _checkIdentity(String value) {
    if (value.isEmpty) throw const FormatException('Invalid child id');
  }

  static void _check(String ownerId, AccountDataLease lease) =>
      lease.checkOwner(ownerId);
}

final class _Authority {
  const _Authority(this.ownerId, this.lease);
  final String ownerId;
  final AccountDataLease lease;
  void check(RecordOwnerProvider owner) {
    lease.checkOwner(ownerId);
    if (owner.currentOwnerId != ownerId) {
      throw const AccountDataUnavailableException();
    }
  }
}
