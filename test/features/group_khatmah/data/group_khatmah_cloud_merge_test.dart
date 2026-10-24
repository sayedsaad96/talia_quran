import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/group_khatmah/data/group_khatmah_cache.dart';
import 'package:talia_quran/features/group_khatmah/data/group_khatmah_cloud_merge.dart';
import 'package:talia_quran/features/group_khatmah/domain/entities/group_khatmah.dart';

import 'group_khatmah_test_support.dart';

void main() {
  const merge = GroupKhatmahCloudMerge();

  GroupIntent completion({
    int juz = 1,
    int expectedVersion = 2,
    String epoch = epochA,
    bool deadLetter = false,
    String groupId = groupA,
  }) => GroupIntent(
    operationId: operation1,
    action: 'complete_group_part',
    args: {
      'p_group_id': groupId,
      'p_juz': juz,
      'p_expected_version': expectedVersion,
      'p_membership_epoch': epoch,
      'p_operation_id': operation1,
    },
    groupId: groupId,
    createdAt: DateTime.utc(2026, 10, 23),
    deadLetter: deadLetter,
  );

  group('newer', () {
    test('first server row is accepted', () {
      final server = fixture(groupA, ownerA, epochA);
      expect(merge.newer(null, server), same(server));
    });

    test('server row with a higher or equal version wins', () {
      final cached = fixture(groupA, ownerA, epochA, groupVersion: 2);
      final higher = fixture(groupA, ownerA, epochA, groupVersion: 3);
      final equal = fixture(groupA, ownerA, epochA, groupVersion: 2);
      expect(merge.newer(cached, higher), same(higher));
      expect(merge.newer(cached, equal), same(equal));
    });

    test('stale server row never replaces a newer cached row', () {
      final cached = fixture(groupA, ownerA, epochA, groupVersion: 5);
      final stale = fixture(groupA, ownerA, epochA, groupVersion: 4);
      expect(merge.newer(cached, stale), same(cached));
    });
  });

  group('overlay', () {
    test('marks a matching unacknowledged completion as pending', () {
      final group = fixture(groupA, ownerA, epochA);
      final merged = merge.overlay(group, [completion()], ownerA);
      expect(merged.part(1)!.isCompletionPending, isTrue);
      expect(merged.part(1)!.isCompletionFailed, isFalse);
      expect(merged.part(2)!.isCompletionPending, isFalse);
    });

    test('dead letter is shown as failed, not pending', () {
      final group = fixture(groupA, ownerA, epochA);
      final merged = merge.overlay(group, [
        completion(deadLetter: true),
      ], ownerA);
      expect(merged.part(1)!.isCompletionFailed, isTrue);
      expect(merged.part(1)!.isCompletionPending, isFalse);
    });

    test('server state that moved on yields: no decoration', () {
      final intents = [completion()];
      final cases = <String, GroupKhatmah>{
        'part version moved': fixture(groupA, ownerA, epochA, firstVersion: 3),
        'part completed': fixture(
          groupA,
          ownerA,
          epochA,
          firstStatus: GroupPartStatus.completed,
        ),
        'claimed by another member': fixture(
          groupA,
          ownerA,
          epochA,
          firstClaimant: ownerB,
        ),
        'new membership epoch': fixture(groupA, ownerA, epochB),
      };
      cases.forEach((name, group) {
        final merged = merge.overlay(group, intents, ownerA);
        expect(merged.part(1)!.isCompletionPending, isFalse, reason: name);
        expect(merged.part(1)!.isCompletionFailed, isFalse, reason: name);
      });
    });

    test('intents of another group or another owner are ignored', () {
      final group = fixture(groupA, ownerA, epochA);
      expect(
        merge
            .overlay(group, [completion(groupId: groupB)], ownerA)
            .part(1)!
            .isCompletionPending,
        isFalse,
      );
      expect(
        merge
            .overlay(group, [completion()], ownerB)
            .part(1)!
            .isCompletionPending,
        isFalse,
      );
    });
  });

  group('completionStillValid', () {
    test('accepts only the exact confirmed claim', () {
      final intent = completion();
      expect(
        merge.completionStillValid(
          intent,
          fixture(groupA, ownerA, epochA),
          ownerA,
        ),
        isTrue,
      );
      expect(merge.completionStillValid(intent, null, ownerA), isFalse);
      expect(
        merge.completionStillValid(
          intent,
          fixture(groupA, ownerA, epochA, firstVersion: 3),
          ownerA,
        ),
        isFalse,
      );
      expect(
        merge.completionStillValid(
          intent,
          fixture(
            groupA,
            ownerA,
            epochA,
          ).copyWith(status: GroupKhatmahStatus.completed),
          ownerA,
        ),
        isFalse,
      );
    });
  });
}
