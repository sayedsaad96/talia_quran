import 'dart:async';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/group_khatmah/data/group_khatmah_remote.dart';
import 'package:talia_quran/features/group_khatmah/domain/entities/group_khatmah.dart';

const ownerA = '11111111-1111-4111-8111-111111111111';
const ownerB = '22222222-2222-4222-8222-222222222222';
const groupA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const groupB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const epochA = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const epochB = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const operation1 = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const operation2 = 'ffffffff-ffff-4fff-8fff-ffffffffffff';

class MutableOwner implements RecordOwnerProvider {
  MutableOwner(this.currentOwnerId);
  @override
  String currentOwnerId;
  @override
  bool get isSignedIn => currentOwnerId.isNotEmpty;
}

class MutableEnvironment implements GroupKhatmahEnvironment {
  final _changes = StreamController<void>.broadcast(sync: true);
  @override
  Stream<void> get changes => _changes.stream;
  @override
  bool featureEnabled = true;
  @override
  bool isAdult = true;
  @override
  bool isOnline = true;

  void setAdult(bool value) {
    isAdult = value;
    _changes.add(null);
  }

  void setFeatureEnabled(bool value) {
    featureEnabled = value;
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}

class FakeWake implements GroupKhatmahWakeScheduler {
  final pushes = <String>[];
  final pulls = <String>[];

  @override
  Future<void> reconcilePush({
    required String ownerId,
    required AccountDataLease lease,
    required DateTime? nextRetryAt,
  }) async {
    lease.checkOwner(ownerId);
    pushes.add(ownerId);
  }

  @override
  Future<void> requestPull({
    required String ownerId,
    required AccountDataLease lease,
  }) async {
    lease.checkOwner(ownerId);
    pulls.add(ownerId);
  }
}

class RpcCall {
  const RpcCall(this.function, this.args, this.ownerId);
  final String function;
  final Map<String, dynamic> args;
  final String ownerId;
}

class FakeRemote implements GroupKhatmahRemote {
  final calls = <RpcCall>[];
  final groupLookups = <String>[];
  final groups = <String, GroupKhatmah>{};
  Future<Map<String, dynamic>> Function(RpcCall)? onRpc;
  Future<GroupKhatmahPage> Function(String ownerId, String? cursor)? onPage;
  Future<GroupKhatmah?> Function(String ownerId, String groupId)? onGroup;

  @override
  Future<Map<String, dynamic>> rpc(
    String function,
    Map<String, dynamic> args, {
    required String ownerId,
  }) async {
    final call = RpcCall(function, args, ownerId);
    calls.add(call);
    return onRpc?.call(call) ??
        {
          'applied': true,
          'code': 'completed',
          'operation_id': args['p_operation_id'],
          'group_id': args['p_group_id'],
          'part_version': 3,
          'group_version': 3,
        };
  }

  @override
  Future<GroupKhatmahPage> fetchMine({
    required String ownerId,
    String? cursor,
  }) async =>
      onPage?.call(ownerId, cursor) ??
      GroupKhatmahPage(groups: groups.values.toList(), nextCursor: null);

  @override
  Future<GroupKhatmah?> fetchGroup({
    required String ownerId,
    required String groupId,
  }) async {
    groupLookups.add(groupId);
    if (onGroup != null) return onGroup!(ownerId, groupId);
    return groups[groupId];
  }
}

GroupKhatmah fixture(
  String id,
  String owner,
  String epoch, {
  GroupPartStatus firstStatus = GroupPartStatus.claimed,
  int firstVersion = 2,
  String? firstClaimant,
  GroupPartStatus secondStatus = GroupPartStatus.open,
  int secondVersion = 1,
  int groupVersion = 2,
  String? groupOwner,
}) => GroupKhatmah(
  id: id,
  code: 'ABC234',
  title: 'Shared reading',
  ownerId: groupOwner ?? owner,
  maxMembers: 30,
  status: GroupKhatmahStatus.active,
  version: groupVersion,
  createdAt: DateTime.utc(2026, 10, 23),
  completedAt: null,
  membershipEpoch: epoch,
  members: [
    GroupMember(
      groupId: id,
      userId: owner,
      displayName: 'Reader',
      joinedAt: DateTime.utc(2026, 10, 23),
      leftAt: null,
      membershipEpoch: epoch,
    ),
  ],
  parts: [
    for (var juz = 1; juz <= 30; juz++)
      GroupPart(
        groupId: id,
        juz: juz,
        status: juz == 1
            ? firstStatus
            : juz == 2
            ? secondStatus
            : GroupPartStatus.open,
        claimedBy: juz == 1 && firstStatus != GroupPartStatus.open
            ? (firstClaimant ?? owner)
            : juz == 2 && secondStatus != GroupPartStatus.open
            ? owner
            : null,
        claimEpoch:
            (juz == 1 && firstStatus != GroupPartStatus.open) ||
                (juz == 2 && secondStatus != GroupPartStatus.open)
            ? epoch
            : null,
        version: juz == 1
            ? firstVersion
            : juz == 2
            ? secondVersion
            : 1,
        updatedAt: DateTime.utc(2026, 10, 23),
      ),
  ],
);
