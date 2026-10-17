import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/utils/talia_logger.dart';

/// Which «ما الجديد» items the guardian has already seen, per child.
/// Key `guardian_milestones_seen|<ownerId>|<childKey>` holds a JSON list of
/// ids. A missing key means the child was never looked at (the first-load
/// rule); a present key, even `[]`, means it was. The owner is read once per
/// call, so an account switch in the middle cannot split a write across two
/// owners. Cleared with the account data (`AccountDataReset`).
class GuardianMilestoneSeenStore {
  GuardianMilestoneSeenStore(this._prefs, this._owner);

  static const keyPrefix = 'guardian_milestones_seen';

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  static String _key(String ownerId, String childKey) =>
      '$keyPrefix|$ownerId|$childKey';

  /// True when [childKey] already has a seen record for the current owner.
  Future<bool> hasRecord(String childKey) async =>
      _prefs.containsKey(_key(_owner.currentOwnerId, childKey));

  Future<Set<String>> seen(String childKey) async =>
      _read(_key(_owner.currentOwnerId, childKey));

  /// Adds [ids] to the seen set. An empty [ids] still creates the record.
  Future<void> markSeen(String childKey, Iterable<String> ids) async {
    final key = _key(_owner.currentOwnerId, childKey);
    final additions = ids.toSet();
    try {
      await AccountDataBarrier.forPreferences(_prefs).run((lease) async {
        final next = {..._read(key), ...additions}.toList()..sort();
        final saved = await _prefs.setString(key, jsonEncode(next));
        lease.check();
        if (!saved) {
          TaliaLogger.w('Guardian milestones seen set not saved');
        }
      });
    } on AccountDataUnavailableException {
      return;
    } catch (error, stack) {
      TaliaLogger.w('Guardian milestones seen set not saved', error, stack);
    }
  }

  Set<String> _read(String key) {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return {
        for (final item in decoded)
          if (item is String) item,
      };
    } catch (_) {
      return <String>{};
    }
  }
}
