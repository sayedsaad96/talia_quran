import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/backup/backup_sections.dart';

void main() {
  Map<String, Object?> raw(String created, String updated) => {
    'ownerId': kBackupOwnerToken,
    'surahId': 1,
    'ayahNumber': 1,
    'body': 'note',
    'createdAt': created,
    'updatedAt': updated,
  };

  test('future timestamps are clamped to now and keep their order', () {
    final now = DateTime.utc(2026, 10, 21, 12);
    final note = AyahNoteBackupMapper.fromJson(
      raw('2030-01-01T00:00:00.000Z', '2031-01-01T00:00:00.000Z'),
      'owner-a',
      now: now,
    );
    expect(note.createdAt.toUtc(), now);
    expect(note.updatedAt.toUtc(), now);
    expect(note.updatedAt.isBefore(note.createdAt), isFalse);
  });

  test('past timestamps are untouched', () {
    final note = AyahNoteBackupMapper.fromJson(
      raw('2026-01-01T00:00:00.000Z', '2026-02-01T00:00:00.000Z'),
      'owner-a',
      now: DateTime.utc(2026, 10, 21),
    );
    expect(note.createdAt.toUtc(), DateTime.utc(2026, 1, 1));
    expect(note.updatedAt.toUtc(), DateTime.utc(2026, 2, 1));
  });
}
