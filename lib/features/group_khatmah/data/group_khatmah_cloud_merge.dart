import '../domain/entities/group_khatmah.dart';
import 'group_khatmah_cache.dart';

/// Server revisions are authoritative; pending completion only decorates an
/// unchanged, confirmed claim held by the same membership epoch.
class GroupKhatmahCloudMerge {
  const GroupKhatmahCloudMerge();

  GroupKhatmah newer(GroupKhatmah? cached, GroupKhatmah server) {
    if (cached == null || server.version >= cached.version) return server;
    return cached;
  }

  GroupKhatmah overlay(
    GroupKhatmah group,
    List<GroupIntent> intents,
    String ownerId,
  ) {
    final completionIntents = intents.where(
      (intent) =>
          intent.action == 'complete_group_part' && intent.groupId == group.id,
    );
    final pendingJuz = <int>{};
    final failedJuz = <int>{};
    for (final intent in completionIntents) {
      final juz = intent.args['p_juz'];
      final expected = intent.args['p_expected_version'];
      final epoch = intent.args['p_membership_epoch'];
      final part = juz is int ? group.part(juz) : null;
      if (part?.status == GroupPartStatus.claimed &&
          part?.claimedBy == ownerId &&
          part?.claimEpoch == epoch &&
          part?.version == expected &&
          group.membershipEpoch == epoch) {
        if (intent.deadLetter) {
          failedJuz.add(juz as int);
        } else {
          pendingJuz.add(juz as int);
        }
      }
    }
    if (pendingJuz.isEmpty && failedJuz.isEmpty) return group;
    return group.copyWith(
      parts: [
        for (final part in group.parts)
          part.copyWith(
            isCompletionPending: pendingJuz.contains(part.juz),
            isCompletionFailed: failedJuz.contains(part.juz),
          ),
      ],
    );
  }

  bool completionStillValid(
    GroupIntent intent,
    GroupKhatmah? group,
    String ownerId,
  ) {
    if (group == null || group.status != GroupKhatmahStatus.active) {
      return false;
    }
    final juz = intent.args['p_juz'];
    final part = juz is int ? group.part(juz) : null;
    return part != null &&
        part.status == GroupPartStatus.claimed &&
        part.claimedBy == ownerId &&
        part.claimEpoch == intent.args['p_membership_epoch'] &&
        part.version == intent.args['p_expected_version'] &&
        group.membershipEpoch == intent.args['p_membership_epoch'];
  }
}
