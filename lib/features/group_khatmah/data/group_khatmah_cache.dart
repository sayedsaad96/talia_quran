import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../domain/entities/group_khatmah.dart';

class GroupIntent {
  const GroupIntent({
    required this.operationId,
    required this.action,
    required this.args,
    required this.groupId,
    required this.createdAt,
    this.attemptCount = 0,
    this.nextRetryAt,
    this.deadLetter = false,
  });

  final String operationId;
  final String action;
  final Map<String, dynamic> args;
  final String? groupId;
  final DateTime createdAt;
  final int attemptCount;
  final DateTime? nextRetryAt;
  final bool deadLetter;

  GroupIntent failed(DateTime now) {
    final attempts = attemptCount + 1;
    final seconds = 30 * (1 << (attempts - 1).clamp(0, 7).toInt());
    return GroupIntent(
      operationId: operationId,
      action: action,
      args: args,
      groupId: groupId,
      createdAt: createdAt,
      attemptCount: attempts,
      nextRetryAt: now.add(Duration(seconds: seconds.clamp(30, 3600).toInt())),
      deadLetter: attempts >= 8,
    );
  }

  GroupIntent deferred(DateTime now) => GroupIntent(
    operationId: operationId,
    action: action,
    args: args,
    groupId: groupId,
    createdAt: createdAt,
    attemptCount: attemptCount,
    nextRetryAt: now.add(const Duration(seconds: 30)),
    deadLetter: deadLetter,
  );

  GroupIntent reactivated() => GroupIntent(
    operationId: operationId,
    action: action,
    args: args,
    groupId: groupId,
    createdAt: createdAt,
  );

  bool due(DateTime now) =>
      !deadLetter && (nextRetryAt == null || !nextRetryAt!.isAfter(now));

  factory GroupIntent.fromJson(Map<String, dynamic> json) => GroupIntent(
    operationId: json['operationId'] as String,
    action: json['action'] as String,
    args: Map<String, dynamic>.from(json['args'] as Map),
    groupId: json['groupId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
    nextRetryAt: json['nextRetryAt'] == null
        ? null
        : DateTime.parse(json['nextRetryAt'] as String).toUtc(),
    deadLetter: json['deadLetter'] == true,
  );

  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'action': action,
    'args': args,
    'groupId': groupId,
    'createdAt': createdAt.toIso8601String(),
    'attemptCount': attemptCount,
    'nextRetryAt': nextRetryAt?.toIso8601String(),
    'deadLetter': deadLetter,
  };
}

class GroupCacheState {
  const GroupCacheState({this.groups = const {}, this.intents = const []});
  final Map<String, GroupKhatmah> groups;
  final List<GroupIntent> intents;

  GroupCacheState copyWith({
    Map<String, GroupKhatmah>? groups,
    List<GroupIntent>? intents,
  }) => GroupCacheState(
    groups: Map.unmodifiable(groups ?? this.groups),
    intents: List.unmodifiable(intents ?? this.intents),
  );

  factory GroupCacheState.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) throw const FormatException('schema');
    final groups = <String, GroupKhatmah>{};
    for (final row in json['groups'] as List<dynamic>) {
      final group = GroupKhatmah.fromJson(
        Map<String, dynamic>.from(row as Map),
      );
      groups[group.id] = group;
    }
    return GroupCacheState(
      groups: Map.unmodifiable(groups),
      intents: List.unmodifiable(
        (json['intents'] as List<dynamic>).map(
          (e) => GroupIntent.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'groups': groups.values.map((g) => g.toJson()).toList(),
    'intents': intents.map((i) => i.toJson()).toList(),
  };
}

class GroupKhatmahCache {
  GroupKhatmahCache(this._prefs, this._barrier);
  final SharedPreferences _prefs;
  final AccountDataBarrier _barrier;

  static String keyFor(String ownerId) =>
      'group_khatmah_cache_v1|${Uri.encodeComponent(ownerId)}';

  GroupCacheState read(String ownerId) {
    final raw = _prefs.getString(keyFor(ownerId));
    if (raw == null) return const GroupCacheState();
    return GroupCacheState.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  Future<GroupCacheState> update(
    String ownerId,
    AccountDataLease lease,
    GroupCacheState Function(GroupCacheState state) change,
  ) => _barrier.run((active) async {
    active.checkOwner(ownerId);
    final before = read(ownerId);
    final after = change(before);
    if (!await _prefs.setString(keyFor(ownerId), jsonEncode(after.toJson()))) {
      throw const AccountDataUnavailableException();
    }
    active.checkOwner(ownerId);
    _barrier.notifyChanged();
    return after;
  }, authority: lease);
}
