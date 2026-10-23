import 'dart:async';

import '../../../../core/identity/account_data_barrier.dart';
import '../domain/entities/group_khatmah.dart';

class GroupKhatmahPage {
  GroupKhatmahPage({
    required List<GroupKhatmah> groups,
    required this.nextCursor,
  }) : groups = List.unmodifiable(groups);

  final List<GroupKhatmah> groups;
  final String? nextCursor;
}

abstract interface class GroupKhatmahRemote {
  Future<Map<String, dynamic>> rpc(
    String function,
    Map<String, dynamic> args, {
    required String ownerId,
  });

  Future<GroupKhatmahPage> fetchMine({required String ownerId, String? cursor});

  Future<GroupKhatmah?> fetchGroup({
    required String ownerId,
    required String groupId,
  });
}

abstract interface class GroupKhatmahWakeScheduler {
  Future<void> reconcilePush({
    required String ownerId,
    required AccountDataLease lease,
    required DateTime? nextRetryAt,
  });

  Future<void> requestPull({
    required String ownerId,
    required AccountDataLease lease,
  });
}

/// Audience and network facts only. Account identity is RecordOwnerProvider.
abstract interface class GroupKhatmahEnvironment {
  bool get featureEnabled;
  bool get isAdult;
  bool get isOnline;
  Stream<void> get changes;
}
