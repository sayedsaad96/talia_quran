import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';

const kBackupFormatId = 'talia-backup';
const kBackupSchemaVersion = 1;

/// Upper bound for both the compressed input and the decompressed JSON
/// (zip-bomb guard). Oversized compressed input maps to
/// [BackupDecodeError.notGzip]; oversized decompressed output maps to
/// [BackupDecodeError.malformedSections].
const kBackupMaxBytes = 50 * 1024 * 1024;

final class BackupPayload extends Equatable {
  const BackupPayload({
    required this.schemaVersion,
    required this.createdAt,
    required this.sections,
  });

  final int schemaVersion;
  final DateTime createdAt;

  /// JSON-safe values only: null, bool, num (finite), String, List,
  /// `Map<String, ...>`.
  final Map<String, Object?> sections;

  @override
  List<Object?> get props => [
    schemaVersion,
    createdAt.toUtc().microsecondsSinceEpoch,
    sections,
  ];
}

enum BackupDecodeError {
  notGzip,
  notJson,
  wrongFormat,
  newerVersion,
  checksumMismatch,
  malformedSections,
}

/// gzip(utf8(json({format, schemaVersion, createdAt, sha256, sections})))
/// where sha256 = hex(sha256(canonical json of sections)).
///
/// Throws [ArgumentError] for non JSON-safe values or non-finite numbers.
List<int> encodeBackup(BackupPayload p) {
  final canonical = _canonicalJson(p.sections);
  final envelope = <String, Object?>{
    'format': kBackupFormatId,
    'schemaVersion': p.schemaVersion,
    'createdAt': p.createdAt.toUtc().toIso8601String(),
    'sha256': sha256.convert(utf8.encode(canonical)).toString(),
    'sections': jsonDecode(canonical),
  };
  return gzip.encode(utf8.encode(jsonEncode(envelope)));
}

/// Never throws; every failure maps to a [BackupDecodeError].
///
/// A missing/non-int/`< 1` `schemaVersion` maps to
/// [BackupDecodeError.malformedSections].
({BackupPayload? payload, BackupDecodeError? error}) decodeBackup(
  List<int> bytes,
) {
  try {
    return _decode(bytes);
  } catch (_) {
    return (payload: null, error: BackupDecodeError.malformedSections);
  }
}

({BackupPayload? payload, BackupDecodeError? error}) _fail(
  BackupDecodeError e,
) => (payload: null, error: e);

({BackupPayload? payload, BackupDecodeError? error}) _decode(List<int> bytes) {
  if (bytes.length > kBackupMaxBytes ||
      bytes.length < 2 ||
      bytes[0] != 0x1f ||
      bytes[1] != 0x8b) {
    return _fail(BackupDecodeError.notGzip);
  }

  final out = BytesBuilder(copy: false);
  var tooBig = false;
  try {
    final sink = _LimitedSink(out);
    final conv = gzip.decoder.startChunkedConversion(sink);
    conv.add(bytes);
    conv.close();
  } on _TooLarge {
    tooBig = true;
  } catch (_) {
    return _fail(BackupDecodeError.notGzip);
  }
  if (tooBig) return _fail(BackupDecodeError.malformedSections);

  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(out.takeBytes()));
  } catch (_) {
    return _fail(BackupDecodeError.notJson);
  }

  if (decoded is! Map || decoded['format'] != kBackupFormatId) {
    return _fail(BackupDecodeError.wrongFormat);
  }
  final version = decoded['schemaVersion'];
  if (version is! int || version < 1) {
    return _fail(BackupDecodeError.malformedSections);
  }
  if (version > kBackupSchemaVersion) {
    return _fail(BackupDecodeError.newerVersion);
  }
  final createdRaw = decoded['createdAt'];
  final hash = decoded['sha256'];
  final sections = decoded['sections'];
  if (createdRaw is! String || hash is! String || sections is! Map) {
    return _fail(BackupDecodeError.malformedSections);
  }
  final created = DateTime.tryParse(createdRaw);
  if (created == null) return _fail(BackupDecodeError.malformedSections);

  final String canonical;
  try {
    canonical = _canonicalJson(sections);
  } on ArgumentError {
    return _fail(BackupDecodeError.malformedSections);
  }
  if (sha256.convert(utf8.encode(canonical)).toString() != hash) {
    return _fail(BackupDecodeError.checksumMismatch);
  }
  return (
    payload: BackupPayload(
      schemaVersion: version,
      createdAt: created.toUtc(),
      sections: Map<String, Object?>.from(sections),
    ),
    error: null,
  );
}

class _TooLarge implements Exception {}

class _LimitedSink implements Sink<List<int>> {
  _LimitedSink(this._out);
  final BytesBuilder _out;

  @override
  void add(List<int> data) {
    if (_out.length + data.length > kBackupMaxBytes) throw _TooLarge();
    _out.add(data);
  }

  @override
  void close() {}
}

String _canonicalJson(Object? value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? v) {
  if (v == null || v is bool || v is String) return v;
  if (v is num) {
    if (!v.isFinite) throw ArgumentError('Non-finite number in backup: $v');
    return v;
  }
  if (v is List) return [for (final e in v) _canonicalize(e)];
  if (v is Map) {
    final keys = <String>[];
    for (final k in v.keys) {
      if (k is! String) throw ArgumentError('Non-string map key: $k');
      keys.add(k);
    }
    keys.sort();
    return {for (final k in keys) k: _canonicalize(v[k])};
  }
  throw ArgumentError('Value not JSON-safe: ${v.runtimeType}');
}

String backupFileName(DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'talia-backup-${now.year.toString().padLeft(4, '0')}'
      '${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}.talia';
}
