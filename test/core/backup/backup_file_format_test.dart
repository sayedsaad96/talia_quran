import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/backup/backup_file_format.dart';

List<int> _pack(Map<String, Object?> envelope) =>
    gzip.encode(utf8.encode(jsonEncode(envelope)));

Map<String, Object?> _unpack(List<int> bytes) =>
    jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, Object?>;

BackupPayload _sample() => BackupPayload(
  schemaVersion: kBackupSchemaVersion,
  createdAt: DateTime.utc(2026, 10, 17, 8, 30, 15),
  sections: {
    'b': {
      'z': 1,
      'a': [1, 2.5, null, true, 'نص'],
    },
    'a': 'x',
  },
);

void main() {
  test('round trip preserves sections and createdAt', () {
    final p = _sample();
    final r = decodeBackup(encodeBackup(p));
    expect(r.error, isNull);
    expect(r.payload, p);
    expect(r.payload!.createdAt.isUtc, isTrue);
  });

  test('local createdAt is stored as UTC and round-trips as same instant', () {
    final local = DateTime(2026, 10, 17, 8, 30);
    final p = BackupPayload(
      schemaVersion: 1,
      createdAt: local,
      sections: const {},
    );
    final env = _unpack(encodeBackup(p));
    expect((env['createdAt'] as String).endsWith('Z'), isTrue);
    final r = decodeBackup(encodeBackup(p));
    expect(r.payload!.createdAt.isAtSameMomentAs(local), isTrue);
  });

  test('canonical json is key-order independent', () {
    final a = BackupPayload(
      schemaVersion: 1,
      createdAt: DateTime.utc(2026),
      sections: {
        'x': {'b': 1, 'a': 2},
        'y': 3,
      },
    );
    final b = BackupPayload(
      schemaVersion: 1,
      createdAt: DateTime.utc(2026),
      sections: {
        'y': 3,
        'x': {'a': 2, 'b': 1},
      },
    );
    expect(
      _unpack(encodeBackup(a))['sha256'],
      _unpack(encodeBackup(b))['sha256'],
    );
  });

  test('encode rejects non-finite numbers and non JSON-safe values', () {
    BackupPayload w(Object? v) => BackupPayload(
      schemaVersion: 1,
      createdAt: DateTime.utc(2026),
      sections: {'k': v},
    );
    expect(() => encodeBackup(w(double.nan)), throwsArgumentError);
    expect(() => encodeBackup(w(double.infinity)), throwsArgumentError);
    expect(() => encodeBackup(w(DateTime.utc(2026))), throwsArgumentError);
    expect(() => encodeBackup(w({1: 2})), throwsArgumentError);
  });

  group('schema versions', () {
    test('the current layout is v5 and v1-v4 files still decode', () {
      expect(kBackupSchemaVersion, 5);
      for (var version = 1; version <= 5; version++) {
        final payload = BackupPayload(
          schemaVersion: version,
          createdAt: DateTime.utc(2026),
          sections: const {'k': 1},
        );
        final decoded = decodeBackup(encodeBackup(payload));
        expect(decoded.error, isNull, reason: 'v$version');
        expect(decoded.payload!.schemaVersion, version);
      }
    });

    test('a file newer than v5 is refused, not partially read', () {
      final env = _unpack(encodeBackup(_sample()))..['schemaVersion'] = 6;
      final decoded = decodeBackup(_pack(env));
      expect(decoded.payload, isNull);
      expect(decoded.error, BackupDecodeError.newerVersion);
    });

    test('the 50 MiB payload limit is unchanged', () {
      expect(kBackupMaxBytes, 50 * 1024 * 1024);
      final oversized = List<int>.filled(kBackupMaxBytes + 1, 0)
        ..[0] = 0x1f
        ..[1] = 0x8b;
      expect(decodeBackup(oversized).error, BackupDecodeError.notGzip);
    });
  });

  group('decode errors', () {
    test('notGzip', () {
      expect(
        decodeBackup(utf8.encode('hello')).error,
        BackupDecodeError.notGzip,
      );
      expect(decodeBackup(const []).error, BackupDecodeError.notGzip);
    });

    test('notJson', () {
      expect(
        decodeBackup(gzip.encode(utf8.encode('{nope'))).error,
        BackupDecodeError.notJson,
      );
      expect(
        decodeBackup(gzip.encode([0xff, 0xfe, 0x00])).error,
        BackupDecodeError.notJson,
      );
    });

    test('wrongFormat', () {
      final env = _unpack(encodeBackup(_sample()))..['format'] = 'other';
      expect(decodeBackup(_pack(env)).error, BackupDecodeError.wrongFormat);
      expect(decodeBackup(_pack({})).error, BackupDecodeError.wrongFormat);
      expect(
        decodeBackup(gzip.encode(utf8.encode('[1]'))).error,
        BackupDecodeError.wrongFormat,
      );
    });

    test('newerVersion', () {
      final env = _unpack(encodeBackup(_sample()))
        ..['schemaVersion'] = kBackupSchemaVersion + 1;
      expect(decodeBackup(_pack(env)).error, BackupDecodeError.newerVersion);
    });

    test('invalid schemaVersion is malformedSections', () {
      for (final v in <Object?>[0, -1, '1', null, 1.5]) {
        final env = _unpack(encodeBackup(_sample()))..['schemaVersion'] = v;
        expect(
          decodeBackup(_pack(env)).error,
          BackupDecodeError.malformedSections,
          reason: '$v',
        );
      }
    });

    test('checksumMismatch when sections tampered or hash altered', () {
      final env = _unpack(encodeBackup(_sample()));
      (env['sections']! as Map)['a'] = 'y';
      expect(
        decodeBackup(_pack(env)).error,
        BackupDecodeError.checksumMismatch,
      );
      final env2 = _unpack(encodeBackup(_sample()))..['sha256'] = 'abc';
      expect(
        decodeBackup(_pack(env2)).error,
        BackupDecodeError.checksumMismatch,
      );
    });

    test('flipping a byte never throws', () {
      final bytes = encodeBackup(_sample());
      for (var i = 0; i < bytes.length; i++) {
        final c = List<int>.of(bytes)..[i] ^= 0x01;
        final r = decodeBackup(c);
        expect(r.payload == null, r.error != null);
      }
    });

    test('malformedSections', () {
      final env = _unpack(encodeBackup(_sample()))..['sections'] = [1];
      expect(
        decodeBackup(_pack(env)).error,
        BackupDecodeError.malformedSections,
      );
      final env2 = _unpack(encodeBackup(_sample()))..['createdAt'] = 'nope';
      expect(
        decodeBackup(_pack(env2)).error,
        BackupDecodeError.malformedSections,
      );
      final env3 = _unpack(encodeBackup(_sample()))..remove('sha256');
      expect(
        decodeBackup(_pack(env3)).error,
        BackupDecodeError.malformedSections,
      );
    });

    test('oversized decompressed input is rejected', () {
      final big = gzip.encode(List<int>.filled(kBackupMaxBytes + 1, 0x20));
      expect(decodeBackup(big).error, BackupDecodeError.malformedSections);
    });
  });

  test('backupFileName format', () {
    expect(
      backupFileName(DateTime(2026, 3, 5, 7, 9)),
      'talia-backup-20260305-0709.talia',
    );
  });
}
