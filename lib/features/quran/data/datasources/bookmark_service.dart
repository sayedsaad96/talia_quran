import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/identity/pending_bookmark_recovery_marker.dart';
import '../../../../core/security/encrypted_account_preferences_store.dart';
import '../../../../core/sync/cloud_sync_queue.dart';
import '../../domain/entities/bookmark_entry.dart';

typedef BookmarkCloudRpc =
    Future<dynamic> Function(String function, {Map<String, dynamic>? params});

class BookmarkService extends ChangeNotifier {
  BookmarkService(
    this._prefs, {
    RecordOwnerProvider owner = const SupabaseRecordOwnerProvider(),
    CloudSyncQueue? cloudSyncQueue,
    EncryptedAccountPreferencesStore? encryptedAccountPreferences,
    BookmarkCloudRpc? cloudRpc,
  }) : _owner = owner,
       _cloudSyncQueue = cloudSyncQueue,
       _encryptedAccountPreferences = encryptedAccountPreferences,
       _cloudRpc = cloudRpc;

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;
  final CloudSyncQueue? _cloudSyncQueue;
  final EncryptedAccountPreferencesStore? _encryptedAccountPreferences;
  final BookmarkCloudRpc? _cloudRpc;
  final Map<String, List<BookmarkEntry>> _recordsByOwner = {};
  final Set<String> _unreadableOwners = {};

  static final Map<String, Future<void>> _ownerOperationTails = {};

  static const _legacyStorageKey = 'quran_bookmarks';
  static const _storageKeyPrefix = 'quran_bookmarks_owner_';
  static const _encryptedStorageKey = 'quran_bookmarks';

  String _storageKeyFor(String ownerId) => '$_storageKeyPrefix$ownerId';

  bool get hasPendingCloudWork {
    final ownerId = _owner.currentOwnerId;
    return _hasPendingCloudWork(ownerId);
  }

  bool _hasPendingCloudWork(String ownerId) =>
      _unreadableOwners.contains(ownerId) ||
      _readRecords(ownerId).any((bookmark) => !bookmark.isSynced);

  Future<bool> hasPendingCloudWorkDurably() {
    final ownerId = _owner.currentOwnerId;
    return _serialize(ownerId, () async {
      await _loadRecords(ownerId, refresh: true);
      return _hasPendingCloudWork(ownerId);
    });
  }

  Future<void> preservePendingRecoveryIfNeeded() {
    final ownerId = _owner.currentOwnerId;
    return _serialize(ownerId, () async {
      await _loadRecords(ownerId, refresh: true);
      if (_hasPendingCloudWork(ownerId)) {
        await PendingBookmarkRecoveryMarker.mark(_prefs, ownerId);
      }
    });
  }

  List<BookmarkEntry> getAll() {
    final bookmarks = _readRecords(_owner.currentOwnerId);
    return bookmarks.where((bookmark) => !bookmark.isDeleted).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  List<BookmarkEntry> _readRecords(String ownerId) {
    final cached = _recordsByOwner[ownerId];
    if (cached != null) return List<BookmarkEntry>.from(cached);
    if (_encryptedAccountPreferences != null) return const [];
    final raw = _prefs.getString(_storageKeyFor(ownerId));
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => BookmarkEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  bool isBookmarked(int surahId, int ayahNumber) {
    return getAll().any(
      (b) => b.surahId == surahId && b.ayahNumber == ayahNumber,
    );
  }

  Future<void> toggle(BookmarkEntry entry) {
    final ownerId = _owner.currentOwnerId;
    return _serialize(ownerId, () => _toggle(ownerId, entry));
  }

  Future<void> _toggle(String ownerId, BookmarkEntry entry) async {
    _ensureActiveOwner(ownerId);
    await _loadRecords(ownerId, refresh: true);
    final records = await _recordsForMutation(ownerId);
    final existingIndex = records.indexWhere(
      (bookmark) => bookmark.key == entry.key,
    );
    final existing = existingIndex < 0 ? null : records[existingIndex];
    final revision = _nextRevision(existing?.revision ?? 0);
    final next = entry.copyWith(
      revision: revision,
      isDeleted: existing != null && !existing.isDeleted,
      isSynced: false,
    );
    if (existingIndex < 0) {
      records.add(next);
    } else {
      records[existingIndex] = next;
    }
    await _writeRecords(ownerId, records);
    await _finishLegacyMigration(ownerId);
    await _schedulePush(ownerId);
    notifyListeners();
  }

  Future<void> clear() {
    final ownerId = _owner.currentOwnerId;
    return _serialize(ownerId, () => _clear(ownerId));
  }

  Future<void> _clear(String ownerId) async {
    _ensureActiveOwner(ownerId);
    await _loadRecords(ownerId, refresh: true);
    final records = await _recordsForMutation(ownerId);
    final deleted = records
        .map(
          (bookmark) => bookmark.isDeleted
              ? bookmark
              : bookmark.copyWith(
                  revision: _nextRevision(bookmark.revision),
                  isDeleted: true,
                  isSynced: false,
                ),
        )
        .toList();
    await _writeRecords(ownerId, deleted);
    await _finishLegacyMigration(ownerId);
    await _schedulePush(ownerId);
    notifyListeners();
  }

  Future<void> pullFromCloud() {
    final ownerId = _owner.currentOwnerId;
    return _pullFromCloud(ownerId);
  }

  /// Claims the pre-account global bookmark blob exactly once for the active
  /// signed-in owner. It is deliberately not read by anonymous/other owners.
  Future<void> migrateLegacyForCurrentOwner() {
    final ownerId = _owner.currentOwnerId;
    return _serialize(ownerId, () => _migrateLegacyForCurrentOwner(ownerId));
  }

  Future<void> _migrateLegacyForCurrentOwner(String ownerId) async {
    _ensureActiveOwner(ownerId);
    await _loadRecords(ownerId, refresh: true);
    if (!_owner.isSignedIn ||
        _readRecords(ownerId).isNotEmpty ||
        _prefs.getString(_storageKeyFor(ownerId)) != null ||
        _prefs.getBool('${_storageKeyFor(ownerId)}_migrated') == true) {
      return;
    }
    final legacyRaw = _prefs.getString(_legacyStorageKey);
    if (legacyRaw == null) return;
    await _writeRecords(ownerId, _decodeLegacy(legacyRaw));
    await _finishLegacyMigration(ownerId);
    await _schedulePush(ownerId);
  }

  Future<void> _pullFromCloud(String ownerId) async {
    final readable = await _serialize(ownerId, () async {
      _ensureActiveOwner(ownerId);
      await _loadRecords(ownerId, refresh: true);
      return !_unreadableOwners.contains(ownerId);
    });
    if (!readable) return;
    final response = await _invokeCloudRpc(ownerId, 'pull_quran_bookmarks');
    if (response == null) return;
    final remoteRecords = (response as List<dynamic>)
        .whereType<Map>()
        .map((row) => _fromCloudRow(Map<String, dynamic>.from(row)))
        .toList();
    await _serialize(ownerId, () async {
      if (!_isActiveOwner(ownerId)) return;
      await _loadRecords(ownerId, refresh: true);
      if (_unreadableOwners.contains(ownerId)) return;
      final localByKey = {
        for (final bookmark in _readRecords(ownerId)) bookmark.key: bookmark,
      };
      for (final remote in remoteRecords) {
        final local = localByKey[remote.key];
        if (local == null ||
            remote.revision > local.revision ||
            local.isSynced) {
          localByKey[remote.key] = remote;
        }
      }
      await _writeRecords(ownerId, localByKey.values.toList());
      if (!_hasPendingCloudWork(ownerId)) {
        await PendingBookmarkRecoveryMarker.clear(_prefs, ownerId);
      }
      notifyListeners();
    });
  }

  Future<void> _pushToCloud(String ownerId) async {
    final pending = await _serialize(ownerId, () async {
      _ensureActiveOwner(ownerId);
      await _loadRecords(ownerId, refresh: true);
      if (_unreadableOwners.contains(ownerId)) {
        return <BookmarkEntry>[];
      }
      return _readRecords(
        ownerId,
      ).where((bookmark) => !bookmark.isSynced).toList();
    });
    for (final bookmark in pending) {
      final response = await _invokeCloudRpc(
        ownerId,
        'upsert_quran_bookmark',
        params: {
          'p_surah_id': bookmark.surahId,
          'p_ayah_number': bookmark.ayahNumber,
          'p_payload': bookmark.toJson(),
          'p_revision': bookmark.revision,
          'p_is_deleted': bookmark.isDeleted,
        },
      );
      if (response == null) return;
      final acknowledged = (response as List<dynamic>).whereType<Map>().any(
        (row) =>
            row['surah_id'] == bookmark.surahId &&
            row['ayah_number'] == bookmark.ayahNumber &&
            row['revision'] == bookmark.revision,
      );
      if (acknowledged) {
        await _serialize(
          ownerId,
          () => _markSyncedAtVersion(ownerId, bookmark),
        );
      }
    }
  }

  Future<void> pushToCloud() {
    final ownerId = _owner.currentOwnerId;
    return _pushToCloud(ownerId);
  }

  SupabaseClient? _clientOrNull(String ownerId) {
    try {
      final client = Supabase.instance.client;
      return client.auth.currentUser?.id == ownerId ? client : null;
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _invokeCloudRpc(
    String ownerId,
    String function, {
    Map<String, dynamic>? params,
  }) async {
    if (!_isActiveOwner(ownerId)) return null;
    final cloudRpc = _cloudRpc;
    final result = cloudRpc != null
        ? await cloudRpc(function, params: params)
        : await _clientOrNull(ownerId)?.rpc(function, params: params);
    if (!_isActiveOwner(ownerId)) return null;
    return result;
  }

  Future<List<BookmarkEntry>> _recordsForMutation(String ownerId) async {
    await _loadRecords(ownerId);
    if (_unreadableOwners.contains(ownerId)) {
      throw StateError('Encrypted bookmark records are unreadable');
    }
    final current = _readRecords(ownerId);
    if (current.isNotEmpty ||
        _prefs.getBool('${_storageKeyFor(ownerId)}_migrated') == true) {
      return current;
    }
    final legacyRaw = _prefs.getString(_legacyStorageKey);
    if (legacyRaw == null) return current;
    return _decodeLegacy(legacyRaw);
  }

  List<BookmarkEntry> _decodeLegacy(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((entry) => BookmarkEntry.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _loadRecords(String ownerId, {bool refresh = false}) async {
    if (!refresh && _recordsByOwner.containsKey(ownerId)) return;
    try {
      final encrypted = _encryptedAccountPreferences;
      String? raw;
      if (encrypted == null) {
        raw = _prefs.getString(_storageKeyFor(ownerId));
      } else {
        raw = await encrypted.read(ownerId, _encryptedStorageKey);
        if (raw == null) {
          raw = await encrypted.read(ownerId, _storageKeyFor(ownerId));
          if (raw != null) {
            await encrypted.write(ownerId, _encryptedStorageKey, raw);
            await encrypted.delete(ownerId, _storageKeyFor(ownerId));
          }
        }
      }
      _recordsByOwner[ownerId] = raw == null
          ? <BookmarkEntry>[]
          : _decodeRecords(raw);
      _unreadableOwners.remove(ownerId);
    } catch (_) {
      _recordsByOwner[ownerId] = <BookmarkEntry>[];
      _unreadableOwners.add(ownerId);
    }
  }

  List<BookmarkEntry> _decodeRecords(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((entry) => BookmarkEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeRecords(
    String ownerId,
    List<BookmarkEntry> records,
  ) async {
    final encoded = jsonEncode(
      records.map((bookmark) => bookmark.toJson()).toList(),
    );
    final encrypted = _encryptedAccountPreferences;
    if (encrypted == null) {
      await _prefs.setString(_storageKeyFor(ownerId), encoded);
    } else {
      await encrypted.write(ownerId, _encryptedStorageKey, encoded);
      await _prefs.remove(_storageKeyFor(ownerId));
    }
    _recordsByOwner[ownerId] = List<BookmarkEntry>.from(records);
    _unreadableOwners.remove(ownerId);
  }

  Future<void> _finishLegacyMigration(String ownerId) async {
    final migratedKey = '${_storageKeyFor(ownerId)}_migrated';
    if (_prefs.getBool(migratedKey) == true ||
        _prefs.getString(_legacyStorageKey) == null) {
      return;
    }
    await _prefs.setBool(migratedKey, true);
    await _prefs.remove(_legacyStorageKey);
  }

  int _nextRevision(int previous) =>
      DateTime.now().toUtc().millisecondsSinceEpoch > previous
      ? DateTime.now().toUtc().millisecondsSinceEpoch
      : previous + 1;

  BookmarkEntry _fromCloudRow(Map<String, dynamic> row) {
    final payload = Map<String, dynamic>.from(row['payload'] as Map);
    return BookmarkEntry.fromJson({
      ...payload,
      'revision': (row['revision'] as num).toInt(),
      'isDeleted': row['is_deleted'] as bool? ?? false,
      'isSynced': true,
    });
  }

  Future<void> _markSyncedAtVersion(
    String ownerId,
    BookmarkEntry acknowledged,
  ) async {
    if (!_isActiveOwner(ownerId)) return;
    await _loadRecords(ownerId, refresh: true);
    if (_unreadableOwners.contains(ownerId)) return;
    final records = _readRecords(ownerId);
    final index = records.indexWhere(
      (bookmark) => bookmark.key == acknowledged.key,
    );
    if (index < 0 || records[index].revision != acknowledged.revision) return;
    records[index] = records[index].copyWith(isSynced: true);
    await _writeRecords(ownerId, records);
    if (!_hasPendingCloudWork(ownerId)) {
      await PendingBookmarkRecoveryMarker.clear(_prefs, ownerId);
    }
  }

  Future<void> _schedulePush(String ownerId) async {
    _ensureActiveOwner(ownerId);
    await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.bookmarkPush);
  }

  bool _isActiveOwner(String ownerId) => _owner.currentOwnerId == ownerId;

  void _ensureActiveOwner(String ownerId) {
    if (!_isActiveOwner(ownerId)) {
      throw StateError('Bookmark owner changed during operation');
    }
  }

  Future<T> _serialize<T>(String ownerId, Future<T> Function() operation) {
    final previous = _ownerOperationTails[ownerId] ?? Future.value();
    final queued = previous.then((_) => operation());
    late final Future<void> tail;
    tail = queued.then<void>((_) {}, onError: (_, _) {}).whenComplete(() {
      if (identical(_ownerOperationTails[ownerId], tail)) {
        _ownerOperationTails.remove(ownerId);
      }
    });
    _ownerOperationTails[ownerId] = tail;
    return queued;
  }
}
