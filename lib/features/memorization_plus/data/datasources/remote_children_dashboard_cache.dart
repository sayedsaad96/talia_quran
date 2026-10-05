import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The last `get_remote_children_dashboard` payload a guardian read, kept per
/// account so an offline dashboard can still show the linked children.
class RemoteChildrenDashboardCache {
  RemoteChildrenDashboardCache(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const _keyPrefix = 'family_remote_dashboard_cache_v1:';

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  Future<void> save(String ownerId, Object? payload) => _prefs.setString(
    '$_keyPrefix$ownerId',
    jsonEncode({
      'fetchedAt': _clock().toUtc().toIso8601String(),
      'payload': payload,
    }),
  );

  /// Null when nothing was cached for [ownerId] or the entry is unreadable.
  CachedRemoteDashboard? read(String ownerId) {
    final raw = _prefs.getString('$_keyPrefix$ownerId');
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final fetchedAt = DateTime.parse(json['fetchedAt'] as String);
      return CachedRemoteDashboard(fetchedAt, json['payload']);
    } catch (_) {
      return null;
    }
  }
}

class CachedRemoteDashboard {
  const CachedRemoteDashboard(this.fetchedAt, this.payload);

  final DateTime fetchedAt;
  final Object? payload;
}
