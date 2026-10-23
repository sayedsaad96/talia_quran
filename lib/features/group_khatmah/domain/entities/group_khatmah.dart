enum GroupKhatmahStatus { active, completed }

enum GroupPartStatus { open, claimed, completed }

DateTime _date(Object? value) =>
    value is DateTime ? value.toUtc() : DateTime.parse(value as String).toUtc();

class GroupMember {
  const GroupMember({
    required this.groupId,
    required this.userId,
    required this.displayName,
    required this.joinedAt,
    required this.leftAt,
    required this.membershipEpoch,
  });

  final String groupId;
  final String userId;
  final String displayName;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String membershipEpoch;

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
    groupId: (json['group_id'] ?? json['groupId']) as String,
    userId: (json['user_id'] ?? json['userId']) as String,
    displayName: (json['display_name'] ?? json['displayName']) as String,
    joinedAt: _date(json['joined_at'] ?? json['joinedAt']),
    leftAt: (json['left_at'] ?? json['leftAt']) == null
        ? null
        : _date(json['left_at'] ?? json['leftAt']),
    membershipEpoch:
        (json['membership_epoch'] ?? json['membershipEpoch']) as String,
  );

  Map<String, dynamic> toJson() => {
    'group_id': groupId,
    'user_id': userId,
    'display_name': displayName,
    'joined_at': joinedAt.toIso8601String(),
    'left_at': leftAt?.toIso8601String(),
    'membership_epoch': membershipEpoch,
  };
}

class GroupPart {
  const GroupPart({
    required this.groupId,
    required this.juz,
    required this.status,
    required this.claimedBy,
    required this.claimEpoch,
    required this.version,
    required this.updatedAt,
    this.isCompletionPending = false,
    this.isCompletionFailed = false,
  });

  final String groupId;
  final int juz;
  final GroupPartStatus status;
  final String? claimedBy;
  final String? claimEpoch;
  final int version;
  final DateTime updatedAt;
  final bool isCompletionPending;
  final bool isCompletionFailed;

  GroupPart copyWith({
    GroupPartStatus? status,
    Object? claimedBy = _unchanged,
    Object? claimEpoch = _unchanged,
    int? version,
    bool? isCompletionPending,
    bool? isCompletionFailed,
  }) => GroupPart(
    groupId: groupId,
    juz: juz,
    status: status ?? this.status,
    claimedBy: identical(claimedBy, _unchanged)
        ? this.claimedBy
        : claimedBy as String?,
    claimEpoch: identical(claimEpoch, _unchanged)
        ? this.claimEpoch
        : claimEpoch as String?,
    version: version ?? this.version,
    updatedAt: updatedAt,
    isCompletionPending: isCompletionPending ?? this.isCompletionPending,
    isCompletionFailed: isCompletionFailed ?? this.isCompletionFailed,
  );

  factory GroupPart.fromJson(Map<String, dynamic> json) => GroupPart(
    groupId: (json['group_id'] ?? json['groupId']) as String,
    juz: (json['juz'] as num).toInt(),
    status: GroupPartStatus.values.byName(json['status'] as String),
    claimedBy: (json['claimed_by'] ?? json['claimedBy']) as String?,
    claimEpoch: (json['claim_epoch'] ?? json['claimEpoch']) as String?,
    version: (json['version'] as num).toInt(),
    updatedAt: _date(json['updated_at'] ?? json['updatedAt']),
    isCompletionPending: json['isCompletionPending'] == true,
  );

  Map<String, dynamic> toJson() => {
    'group_id': groupId,
    'juz': juz,
    'status': status.name,
    'claimed_by': claimedBy,
    'claim_epoch': claimEpoch,
    'version': version,
    'updated_at': updatedAt.toIso8601String(),
    'isCompletionPending': isCompletionPending,
  };
}

const Object _unchanged = Object();

class GroupKhatmah {
  GroupKhatmah({
    required this.id,
    required this.code,
    required this.title,
    required this.ownerId,
    required this.maxMembers,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.completedAt,
    required this.membershipEpoch,
    required List<GroupMember> members,
    required List<GroupPart> parts,
  }) : members = List.unmodifiable(members),
       parts = List.unmodifiable(parts);

  final String id;
  final String code;
  final String title;
  final String ownerId;
  final int maxMembers;
  final GroupKhatmahStatus status;
  final int version;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String membershipEpoch;
  final List<GroupMember> members;
  final List<GroupPart> parts;

  GroupPart? part(int juz) {
    for (final value in parts) {
      if (value.juz == juz) return value;
    }
    return null;
  }

  GroupKhatmah copyWith({
    int? version,
    GroupKhatmahStatus? status,
    Object? completedAt = _unchanged,
    String? membershipEpoch,
    List<GroupMember>? members,
    List<GroupPart>? parts,
  }) => GroupKhatmah(
    id: id,
    code: code,
    title: title,
    ownerId: ownerId,
    maxMembers: maxMembers,
    status: status ?? this.status,
    version: version ?? this.version,
    createdAt: createdAt,
    completedAt: identical(completedAt, _unchanged)
        ? this.completedAt
        : completedAt as DateTime?,
    membershipEpoch: membershipEpoch ?? this.membershipEpoch,
    members: members ?? this.members,
    parts: parts ?? this.parts,
  );

  factory GroupKhatmah.fromJson(Map<String, dynamic> json) => GroupKhatmah(
    id: json['id'] as String,
    code: json['code'] as String,
    title: json['title'] as String,
    ownerId: (json['owner_id'] ?? json['ownerId']) as String,
    maxMembers: ((json['max_members'] ?? json['maxMembers']) as num).toInt(),
    status: GroupKhatmahStatus.values.byName(json['status'] as String),
    version: (json['version'] as num).toInt(),
    createdAt: _date(json['created_at'] ?? json['createdAt']),
    completedAt: (json['completed_at'] ?? json['completedAt']) == null
        ? null
        : _date(json['completed_at'] ?? json['completedAt']),
    membershipEpoch:
        (json['membership_epoch'] ?? json['membershipEpoch']) as String,
    members: (json['members'] as List<dynamic>)
        .map((e) => GroupMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    parts: (json['parts'] as List<dynamic>)
        .map((e) => GroupPart.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'owner_id': ownerId,
    'max_members': maxMembers,
    'status': status.name,
    'version': version,
    'created_at': createdAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'membership_epoch': membershipEpoch,
    'members': members.map((e) => e.toJson()).toList(),
    'parts': parts.map((e) => e.toJson()).toList(),
  };
}
