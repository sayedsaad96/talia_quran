part of 'restore_recovery_journal.dart';

/// Chunking and (de)serialisation of the journal's keys.
extension _JournalFormat on RestoreRecoveryJournal {
  // ─── encoding helpers ─────────────────────────────────────────────────

  String _chunkKey(String restoreId, String part, int index) =>
      'part.$restoreId.$part.$index';

  /// Splits at UTF-8 code point boundaries so every chunk is valid text of at
  /// most [maxChunkBytes] bytes.
  List<String> _split(List<int> bytes) {
    if (bytes.isEmpty) return const [''];
    final chunks = <String>[];
    var start = 0;
    while (start < bytes.length) {
      var end = min(start + maxChunkBytes, bytes.length);
      if (end < bytes.length) {
        while (end > start && (bytes[end] & 0xC0) == 0x80) {
          end--;
        }
      }
      if (end == start) {
        throw const RestoreJournalRejected(
          RestoreJournalRejection.storage,
          'chunk size too small',
        );
      }
      chunks.add(utf8.decode(bytes.sublist(start, end)));
      start = end;
    }
    return chunks;
  }

  String _stateValue(String restoreId, String state) =>
      jsonEncode({'id': restoreId, 's': state});

  ({String id, String state})? _parseState(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is Map && json['id'] is String && json['s'] is String) {
        return (id: json['id'] as String, state: json['s'] as String);
      }
    } on FormatException {
      // fall through
    }
    return null;
  }

  ({String id, Map<String, int> parts})? _parseIntent(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is Map && json['id'] is String && json['parts'] is Map) {
        final parts = <String, int>{};
        for (final entry in (json['parts'] as Map).entries) {
          final key = entry.key;
          final count = entry.value;
          if (key is! String ||
              !RestoreRecoveryJournal._partName.hasMatch(key) ||
              count is! int) {
            return null;
          }
          parts[key] = count;
        }
        return (id: json['id'] as String, parts: parts);
      }
    } on FormatException {
      // fall through
    }
    return null;
  }

  _Manifest? _parseManifest(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map ||
          json['v'] != 1 ||
          json['id'] is! String ||
          json['owner'] is! String ||
          json['parts'] is! List) {
        return null;
      }
      final parts = <_PartInfo>[];
      for (final part in json['parts'] as List) {
        if (part is! Map ||
            part['name'] is! String ||
            !RestoreRecoveryJournal._partName.hasMatch(
              part['name'] as String,
            ) ||
            part['chunks'] is! int ||
            part['bytes'] is! int ||
            part['sha256'] is! String) {
          return null;
        }
        parts.add(
          _PartInfo(
            part['name'] as String,
            part['chunks'] as int,
            part['bytes'] as int,
            part['sha256'] as String,
          ),
        );
      }
      return _Manifest(json['id'] as String, json['owner'] as String, parts);
    } on FormatException {
      return null;
    }
  }
}

class _Manifest {
  const _Manifest(this.id, this.owner, this.parts);
  final String id;
  final String owner;
  final List<_PartInfo> parts;
}

class _PartInfo {
  const _PartInfo(this.name, this.chunks, this.bytes, this.sha256);
  final String name;
  final int chunks;
  final int bytes;
  final String sha256;
}

class _JournalStoreException implements Exception {
  const _JournalStoreException();
}
