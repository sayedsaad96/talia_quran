import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/security/encrypted_account_preferences_store.dart';
import '../../../../core/sync/cloud_sync_queue.dart';
import '../../domain/entities/bookmark_entry.dart';

class BookmarkService extends ChangeNotifier {
  BookmarkService(
    this._prefs, {
    RecordOwnerProvider owner = const SupabaseRecordOwnerProvider(),
    CloudSyncQueue? cloudSyncQueue,
    EncryptedAccountPreferencesStore? encryptedAccountPreferences,
  }) : _owner = owner,
       _cloudSyncQueue = cloudSyncQueue,
       _encryptedAccountPreferences = encryptedAccountPreferences;

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;
  final CloudSyncQueue? _cloudSyncQueue;
  final EncryptedAccountPreferencesStore? _encryptedAccountPreferences;
  Future<void> _operationTail = Future.value();
  final Map<String, List<BookmarkEntry>> _recordsByOwner = {};

  static const _legacyStorageKey = 'quran_bookmarks';
  static const _storageKeyPrefix = 'quran_bookmarks_owner_';

  String get _storageKey => '$_storageKeyPrefix${_owner.currentOwnerId}';

  bool get hasPendingCloudWork =>
      _readRecords().any((bookmark) => !bookmark.isSynced);

  List<BookmarkEntry> getAll() {
    final bookmarks = _readRecords();
    return bookmarks.where((bookmark) => !bookmark.isDeleted).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  List<BookmarkEntry> _readRecords() {
    final cached = _recordsByOwner[_owner.currentOwnerId];
    if (cached != null) return List<BookmarkEntry>.from(cached);
    if (_encryptedAccountPreferences != null) return const [];
    final raw = _prefs.getString(_storageKey);
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

  Future<void> toggle(BookmarkEntry entry) =>
      _serialize(() => _toggle(entry));

  Future<void> _toggle(BookmarkEntry entry) async {
    await _loadRecords();
    final records = await _recordsForMutation();
    final existingIndex = records.indexWhere((bookmark) => bookmark.key == entry.key);
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
    await _writeRecords(records);
    await _finishLegacyMigration();
    await _schedulePush();
    notifyListeners();
  }

  Future<void> clear() => _serialize(_clear);

  Future<void> _clear() async {
    await _loadRecords();
    final records = await _recordsForMutation();
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
    await _writeRecords(deleted);
    await _finishLegacyMigration();
    await _schedulePush();
    notifyListeners();
  }

  Future<void> pullFromCloud() => _serialize(_pullFromCloud);

  /// Claims the pre-account global bookmark blob exactly once for the active
  /// signed-in owner. It is deliberately not read by anonymous/other owners.
  Future<void> migrateLegacyForCurrentOwner() =>
      _serialize(_migrateLegacyForCurrentOwner);

  Future<void> _migrateLegacyForCurrentOwner() async {
    await _loadRecords();
    if (!_owner.isSignedIn ||
        _readRecords().isNotEmpty ||
        _prefs.getString(_storageKey) != null ||
        _prefs.getBool('${_storageKey}_migrated') == true) {
      return;
    }
    final legacyRaw = _prefs.getString(_legacyStorageKey);
    if (legacyRaw == null) return;
    await _writeRecords(_decodeLegacy(legacyRaw));
    await _finishLegacyMigration();
    await _schedulePush();
  }

  Future<void> _pullFromCloud() async {
    await _loadRecords();
    final client = _clientOrNull();
    if (client == null) return;
    final response = await client.rpc('pull_quran_bookmarks');
    final remoteRecords = (response as List<dynamic>)
        .whereType<Map>()
        .map((row) => _fromCloudRow(Map<String, dynamic>.from(row)))
        .toList();
    final localByKey = {for (final bookmark in _readRecords()) bookmark.key: bookmark};
    for (final remote in remoteRecords) {
      final local = localByKey[remote.key];
      if (local == null || remote.revision > local.revision || local.isSynced) {
        localByKey[remote.key] = remote;
      }
    }
    await _writeRecords(localByKey.values.toList());
    notifyListeners();
  }

  Future<void> pushToCloud() => _serialize(_pushToCloud);

  Future<void> _pushToCloud() async {
    await _loadRecords();
    final client = _clientOrNull();
    if (client == null) return;
    final pending = _readRecords().where((bookmark) => !bookmark.isSynced).toList();
    for (final bookmark in pending) {
      final response = await client.rpc(
        'upsert_quran_bookmark',
        params: {
          'p_surah_id': bookmark.surahId,
          'p_ayah_number': bookmark.ayahNumber,
          'p_payload': bookmark.toJson(),
          'p_revision': bookmark.revision,
          'p_is_deleted': bookmark.isDeleted,
        },
      );
      final acknowledged = (response as List<dynamic>)
          .whereType<Map>()
          .any(
            (row) =>
                row['surah_id'] == bookmark.surahId &&
                row['ayah_number'] == bookmark.ayahNumber &&
                row['revision'] == bookmark.revision,
          );
      if (acknowledged) await _markSyncedAtVersion(bookmark);
    }
  }

  SupabaseClient? _clientOrNull() {
    try {
      final client = Supabase.instance.client;
      return client.auth.currentUser?.id == _owner.currentOwnerId ? client : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<BookmarkEntry>> _recordsForMutation() async {
    await _loadRecords();
    final current = _readRecords();
    if (current.isNotEmpty || _prefs.getBool('${_storageKey}_migrated') == true) {
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

  Future<void> _loadRecords() async {
    final ownerId = _owner.currentOwnerId;
    if (_recordsByOwner.containsKey(ownerId)) return;
    final encrypted = _encryptedAccountPreferences;
    final raw = encrypted == null
        ? _prefs.getString(_storageKey)
        : await encrypted.read(ownerId, _storageKey);
    _recordsByOwner[ownerId] = raw == null ? <BookmarkEntry>[] : _decodeLegacy(raw);
  }

  Future<void> _writeRecords(List<BookmarkEntry> records) async {
    final ownerId = _owner.currentOwnerId;
    final encoded = jsonEncode(records.map((bookmark) => bookmark.toJson()).toList());
    _recordsByOwner[ownerId] = List<BookmarkEntry>.from(records);
    final encrypted = _encryptedAccountPreferences;
    if (encrypted == null) {
      await _prefs.setString(_storageKey, encoded);
      return;
    }
    await encrypted.write(ownerId, _storageKey, encoded);
    await _prefs.remove(_storageKey);
  }

  Future<void> _finishLegacyMigration() async {
    final migratedKey = '${_storageKey}_migrated';
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

  Future<void> _markSyncedAtVersion(BookmarkEntry acknowledged) async {
    final records = _readRecords();
    final index = records.indexWhere((bookmark) => bookmark.key == acknowledged.key);
    if (index < 0 || records[index].revision != acknowledged.revision) return;
    records[index] = records[index].copyWith(isSynced: true);
    await _writeRecords(records);
  }

  Future<void> _schedulePush() async {
    await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.bookmarkPush);
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final queued = _operationTail.then((_) => operation());
    _operationTail = queued.then<void>(
      (_) {},
      onError: (_, _) {},
    );
    return queued;
  }
}
