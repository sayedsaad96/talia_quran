import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/quran/data/datasources/bookmark_service.dart';
import '../../features/quran/domain/entities/bookmark_entry.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../services/app_session_service.dart';
import 'portable_reading_backup_adapter.dart';
import 'portable_reading_data.dart';
import 'restore_operation_gate.dart';
import 'backup_file_format.dart';
import 'backup_sections.dart';

class StalePortableImportException implements Exception {
  const StalePortableImportException();
}

sealed class PortableImportResult {
  const PortableImportResult(this.bookmarksAdded);
  final int bookmarksAdded;
}

class PortableImportCompleted extends PortableImportResult {
  const PortableImportCompleted(
    super.bookmarksAdded, {
    required this.checkpointImported,
  });
  final bool checkpointImported;
}

class BookmarksOnlyCheckpointFailed extends PortableImportResult {
  const BookmarksOnlyCheckpointFailed(super.bookmarksAdded);
}

class BookmarkImportPreview {
  BookmarkImportPreview._({
    required this.owner,
    required this.lease,
    required this.fingerprint,
    required List<PortableBookmark> additions,
    required List<PortableBookmark> existing,
    required List<PortableBookmark> deletedConflicts,
    required List<PortableBookmark> invalid,
    required this.checkpoint,
    required this.currentCheckpoint,
  }) : additions = List.unmodifiable(additions),
       existing = List.unmodifiable(existing),
       deletedConflicts = List.unmodifiable(deletedConflicts),
       invalid = List.unmodifiable(invalid);
  final String owner, fingerprint;
  final AccountDataLease lease;
  final List<PortableBookmark> additions, existing, deletedConflicts, invalid;
  final QuranReadingCheckpoint? checkpoint, currentCheckpoint;
}

/// Imports only canonical reading references after an explicit preview.
class PortableSignedInImporter {
  PortableSignedInImporter({
    required this.prefs,
    required this.owner,
    required this.barrier,
    required this.bookmarks,
    required this.resolve,
    required this.gate,
    this.readCheckpoint,
    this.writeCheckpoint,
  }) {
    if ((readCheckpoint == null) != (writeCheckpoint == null)) {
      throw ArgumentError(
        'Checkpoint reader and writer must be provided together',
      );
    }
  }
  final SharedPreferences prefs;
  final RecordOwnerProvider owner;
  final AccountDataBarrier barrier;
  final BookmarkService bookmarks;
  final BookmarkEntryResolver resolve;
  final RestoreOperationGate gate;
  final Future<QuranReadingCheckpoint?> Function(String, AccountDataLease)?
  readCheckpoint;
  final Future<void> Function(String, int, AccountDataLease)? writeCheckpoint;

  Future<BookmarkImportPreview> previewFile(List<int> bytes) {
    final payload = decodeBackup(bytes).payload;
    if (payload == null || payload.schemaVersion < 5) {
      throw const FormatException('A valid v5 portable backup is required');
    }
    final raw = payload.sections[BackupSections.bookmarks];
    if (raw is! List) throw const FormatException('Missing portable bookmarks');
    final references = raw
        .map(
          (value) => PortableBookmark.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();
    final checkpointJson = payload.sections[BackupSections.readingCheckpoint];
    final checkpoint = checkpointJson == null
        ? null
        : QuranReadingCheckpoint.fromJson(
            Map<String, dynamic>.from(checkpointJson as Map),
          );
    return preview(references, checkpoint: checkpoint);
  }

  Future<BookmarkImportPreview> preview(
    List<PortableBookmark> entries, {
    QuranReadingCheckpoint? checkpoint,
  }) async {
    if (!owner.isSignedIn) {
      throw const PortableReadingDataException('Sign-in required');
    }
    final ownerId = owner.currentOwnerId;
    final lease = barrier.capture();
    lease.checkOwner(ownerId);
    final resolved = <String, PortableBookmark>{};
    final invalid = <PortableBookmark>[];
    for (final reference in entries) {
      final value = await resolve(reference);
      lease.checkOwner(ownerId);
      if (value == null ||
          value.surahId != reference.surahId ||
          value.ayahNumber != reference.ayahNumber) {
        invalid.add(reference);
      } else {
        resolved.putIfAbsent(
          '${reference.surahId}_${reference.ayahNumber}',
          () => reference,
        );
      }
    }
    return barrier.run((authority) async {
      authority.checkOwner(ownerId);
      return bookmarks.runRestoreExclusive(
        expectedOwnerId: ownerId,
        body: (access) async {
          final snapshot = await access.capture();
          await prefs.reload();
          authority.checkOwner(ownerId);
          final current = await _readCheckpoint(ownerId, authority);
          final records = (jsonDecode(snapshot) as List).map(
            (e) => BookmarkEntry.fromJson(Map<String, dynamic>.from(e as Map)),
          );
          final byKey = {for (final record in records) record.key: record};
          final additions = <PortableBookmark>[],
              existing = <PortableBookmark>[],
              deleted = <PortableBookmark>[];
          for (final item in resolved.entries) {
            final record = byKey[item.key];
            if (record == null) {
              additions.add(item.value);
            } else if (record.isDeleted) {
              deleted.add(item.value);
            } else {
              existing.add(item.value);
            }
          }
          return BookmarkImportPreview._(
            owner: ownerId,
            lease: lease,
            fingerprint: _fingerprint(snapshot, current),
            additions: additions,
            existing: existing,
            deletedConflicts: deleted,
            invalid: invalid,
            checkpoint: checkpoint,
            currentCheckpoint: current,
          );
        },
      );
    }, authority: lease);
  }

  Future<PortableImportResult> apply(
    BookmarkImportPreview preview, {
    bool importCheckpoint = false,
  }) async {
    if (!owner.isSignedIn || owner.currentOwnerId != preview.owner) {
      throw const StalePortableImportException();
    }
    try {
      preview.lease.checkOwner(preview.owner);
    } catch (_) {
      throw const StalePortableImportException();
    }
    final resolved = <BookmarkEntry>[];
    for (final reference in preview.additions) {
      final entry = await resolve(reference);
      if (entry == null ||
          entry.surahId != reference.surahId ||
          entry.ayahNumber != reference.ayahNumber) {
        throw const StalePortableImportException();
      }
      resolved.add(entry);
    }
    return gate.run(
      expectedOwnerId: preview.owner,
      operation: () => barrier.run((lease) async {
        lease.checkOwner(preview.owner);
        return bookmarks.runRestoreExclusive(
          expectedOwnerId: preview.owner,
          body: (access) async {
            final snapshot = await access.capture();
            await prefs.reload();
            lease.checkOwner(preview.owner);
            final checkpoint = await _readCheckpoint(preview.owner, lease);
            lease.checkOwner(preview.owner);
            if (_fingerprint(snapshot, checkpoint) != preview.fingerprint) {
              throw const StalePortableImportException();
            }
            final added = await access.addMissing(resolved);
            lease.checkOwner(preview.owner);
            if (importCheckpoint && preview.checkpoint != null) {
              var written = false;
              try {
                final writer = writeCheckpoint;
                if (writer != null) {
                  await writer(
                    preview.owner,
                    preview.checkpoint!.pageNumber,
                    lease,
                  );
                  written = true;
                } else {
                  written = await prefs.setInt(
                    AppSessionService.quranCheckpointKeyFor(preview.owner),
                    preview.checkpoint!.pageNumber,
                  );
                }
              } catch (_) {
                lease.checkOwner(preview.owner);
              }
              lease.checkOwner(preview.owner);
              if (!written) {
                await prefs.reload();
                lease.checkOwner(preview.owner);
                return BookmarksOnlyCheckpointFailed(added);
              }
              return PortableImportCompleted(added, checkpointImported: true);
            }
            return PortableImportCompleted(added, checkpointImported: false);
          },
        );
      }, authority: preview.lease),
    );
  }

  Future<QuranReadingCheckpoint?> _readCheckpoint(
    String ownerId,
    AccountDataLease lease,
  ) async {
    lease.checkOwner(ownerId);
    final reader = readCheckpoint;
    if (reader != null) {
      final value = await reader(ownerId, lease);
      lease.checkOwner(ownerId);
      return value;
    }
    return _checkpoint(ownerId);
  }

  QuranReadingCheckpoint? _checkpoint(String ownerId) {
    final value = prefs.get(AppSessionService.quranCheckpointKeyFor(ownerId));
    if (value == null) return null;
    if (value is! int) {
      throw const PortableReadingDataException('Unreadable checkpoint');
    }
    return QuranReadingCheckpoint(pageNumber: value);
  }

  String _fingerprint(String snapshot, QuranReadingCheckpoint? checkpoint) =>
      sha256
          .convert(utf8.encode(jsonEncode([snapshot, checkpoint?.pageNumber])))
          .toString();
}
