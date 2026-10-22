import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/backup/backup_sections.dart';

void main() {
  const owner = 'restored-owner';
  Map<String, Object?> pair({Map<String, Object?>? changes}) => {
    'ownerId': kBackupOwnerToken,
    'audience': 'adult',
    'targetKey': '2:255',
    'otherKey': '3:2',
    'count': 1,
    'firstAt': '2026-01-01T00:00:00.000Z',
    'lastAt': '2026-01-02T00:00:00.000Z',
    ...?changes,
  };

  test('rebinds a valid adult directed pair to the restoring owner', () {
    final restored = ConfusionPairBackupMapper.fromJson(pair(), owner);

    expect(restored.ownerId, owner);
    expect(restored.audience, 'adult');
    expect(restored.targetKey, '2:255');
    expect(restored.otherKey, '3:2');
    expect(restored.firstAt.isUtc, isTrue);
  });

  test('rejects speech-shaped and unknown pair fields', () {
    expect(
      () => ConfusionPairBackupMapper.fromJson(
        pair(changes: {'spokenText': 'not permitted'}),
        owner,
      ),
      throwsA(isA<BackupSectionInvalid>()),
    );
  });

  test('rejects invalid audience, self pair, invalid IDs, and timestamps', () {
    for (final changes in [
      {'audience': 'kids'},
      {'otherKey': '2:255'},
      {'targetKey': '02:255'},
      {'targetKey': '+2:255'},
      {'targetKey': '2:0255'},
      {'targetKey': '115:1'},
      {'count': 0},
      {'lastAt': '2025-01-01T00:00:00.000Z'},
    ]) {
      expect(
        () => ConfusionPairBackupMapper.fromJson(pair(changes: changes), owner),
        throwsA(isA<BackupSectionInvalid>()),
      );
    }
  });
}
