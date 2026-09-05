import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/identity/pending_bookmark_recovery_marker.dart';
import 'package:talia_quran/core/security/encrypted_account_preferences_store.dart';
import 'package:talia_quran/features/quran/data/datasources/bookmark_service.dart';
import 'package:talia_quran/features/quran/domain/entities/bookmark_entry.dart';

void main() {
  late BookmarkService service;

  BookmarkEntry createEntry({
    int surahId = 1,
    int ayahNumber = 1,
    String surahName = 'الفاتحة',
    String ayahText = 'بسم الله الرحمن الرحيم',
  }) {
    return BookmarkEntry(
      surahId: surahId,
      surahName: surahName,
      ayahNumber: ayahNumber,
      ayahText: ayahText,
      savedAt: DateTime.now(),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = BookmarkService(prefs);
  });

  group('BookmarkService', () {
    test('getAll returns empty list initially', () {
      expect(service.getAll(), isEmpty);
    });

    test('toggle adds a new bookmark', () async {
      final entry = createEntry();
      await service.toggle(entry);
      expect(service.getAll(), hasLength(1));
    });

    test('toggle removes an existing bookmark', () async {
      final entry = createEntry();
      await service.toggle(entry); // add
      await service.toggle(entry); // remove
      expect(service.getAll(), isEmpty);
    });

    test('isBookmarked returns true for bookmarked ayah', () async {
      await service.toggle(createEntry(surahId: 2, ayahNumber: 255));
      expect(service.isBookmarked(2, 255), isTrue);
    });

    test('isBookmarked returns false for non-bookmarked ayah', () {
      expect(service.isBookmarked(2, 255), isFalse);
    });

    test('getAll returns bookmarks sorted by savedAt descending', () async {
      // Add entries with slight delay to ensure different timestamps
      await service.toggle(createEntry(surahId: 1, ayahNumber: 1));
      await Future.delayed(const Duration(milliseconds: 10));
      await service.toggle(createEntry(surahId: 2, ayahNumber: 1));
      await Future.delayed(const Duration(milliseconds: 10));
      await service.toggle(createEntry(surahId: 3, ayahNumber: 1));

      final all = service.getAll();
      expect(all, hasLength(3));
      // Most recent first
      expect(all[0].surahId, equals(3));
      expect(all[2].surahId, equals(1));
    });

    test('handles multiple bookmarks from same surah', () async {
      await service.toggle(createEntry(surahId: 2, ayahNumber: 1));
      await service.toggle(createEntry(surahId: 2, ayahNumber: 255));
      expect(service.getAll(), hasLength(2));
      expect(service.isBookmarked(2, 1), isTrue);
      expect(service.isBookmarked(2, 255), isTrue);
    });

    test('clear removes all bookmarks', () async {
      await service.toggle(createEntry(surahId: 1, ayahNumber: 1));
      await service.toggle(createEntry(surahId: 2, ayahNumber: 1));
      await service.clear();
      expect(service.getAll(), isEmpty);
    });

    test('persists across service instances', () async {
      await service.toggle(createEntry(surahId: 36, ayahNumber: 1));

      // Create a new service instance with the same SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final newService = BookmarkService(prefs);
      expect(newService.isBookmarked(36, 1), isTrue);
    });

    test('does not expose one owner bookmarks to another owner', () async {
      final prefs = await SharedPreferences.getInstance();
      final ownerA = BookmarkService(
        prefs,
        owner: const FixedRecordOwnerProvider('owner-a'),
      );
      final ownerB = BookmarkService(
        prefs,
        owner: const FixedRecordOwnerProvider('owner-b'),
      );

      await ownerA.toggle(createEntry(surahId: 36, ayahNumber: 1));

      expect(ownerA.isBookmarked(36, 1), isTrue);
      expect(ownerB.isBookmarked(36, 1), isFalse);
    });

    test(
      'stores signed-in owner bookmarks in encrypted account storage',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final encrypted = _MemoryEncryptedAccountPreferencesStore();
        const owner = FixedRecordOwnerProvider('owner-a');
        final first = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );

        await first.toggle(createEntry(surahId: 36, ayahNumber: 1));

        expect(prefs.getString('quran_bookmarks_owner_owner-a'), isNull);
        final restored = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );
        await restored.migrateLegacyForCurrentOwner();
        expect(restored.isBookmarked(36, 1), isTrue);
      },
    );

    test('encrypted bookmarks remain isolated to their owner', () async {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = _MemoryEncryptedAccountPreferencesStore();
      final ownerA = BookmarkService(
        prefs,
        owner: const FixedRecordOwnerProvider('secure-owner-a'),
        encryptedAccountPreferences: encrypted,
      );
      await ownerA.toggle(createEntry(surahId: 36, ayahNumber: 1));

      final ownerB = BookmarkService(
        prefs,
        owner: const FixedRecordOwnerProvider('secure-owner-b'),
        encryptedAccountPreferences: encrypted,
      );
      await ownerB.migrateLegacyForCurrentOwner();

      expect(ownerB.getAll(), isEmpty);
      final restoredOwnerA = BookmarkService(
        prefs,
        owner: const FixedRecordOwnerProvider('secure-owner-a'),
        encryptedAccountPreferences: encrypted,
      );
      await restoredOwnerA.migrateLegacyForCurrentOwner();
      expect(restoredOwnerA.isBookmarked(36, 1), isTrue);
    });

    test('migrates the previous encrypted owner-prefixed key', () async {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = _MemoryEncryptedAccountPreferencesStore();
      const ownerId = 'legacy-secure-owner';
      final entry = createEntry(
        surahId: 55,
        ayahNumber: 13,
      ).copyWith(revision: 7, isSynced: false);
      await encrypted.write(
        ownerId,
        'quran_bookmarks_owner_$ownerId',
        jsonEncode([entry.toJson()]),
      );

      final restored = BookmarkService(
        prefs,
        owner: const FixedRecordOwnerProvider(ownerId),
        encryptedAccountPreferences: encrypted,
      );

      expect(await restored.hasPendingCloudWorkDurably(), isTrue);
      expect(restored.isBookmarked(55, 13), isTrue);
      expect(
        await encrypted.read(ownerId, 'quran_bookmarks_owner_$ownerId'),
        isNull,
      );
      expect(await encrypted.read(ownerId, 'quran_bookmarks'), isNotNull);
    });

    test('pending check waits for an in-flight cold toggle', () async {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = _ColdReadRaceEncryptedStore(
        ownerId: 'race-owner',
        initialValue: '[]',
      );
      final raced = BookmarkService(
        prefs,
        owner: const FixedRecordOwnerProvider('race-owner'),
        encryptedAccountPreferences: encrypted,
      );

      final toggle = raced.toggle(createEntry(surahId: 67, ayahNumber: 1));
      await encrypted.firstReadStarted.future;
      final pending = raced.hasPendingCloudWorkDurably();
      await Future<void>.delayed(Duration.zero);
      encrypted.releaseFirstRead();

      await toggle;
      expect(await pending, isTrue);
    });

    test(
      'stale instance acknowledgement cannot overwrite a newer durable revision',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final encrypted = _MemoryEncryptedAccountPreferencesStore();
        const owner = FixedRecordOwnerProvider('ack-race-owner');
        final foreground = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );
        await foreground.toggle(createEntry(surahId: 2, ayahNumber: 255));

        final rpcStarted = Completer<Map<String, dynamic>>();
        final releaseAck = Completer<void>();
        final background = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
          cloudRpc: (String function, {Map<String, dynamic>? params}) async {
            final sent = Map<String, dynamic>.from(params!);
            rpcStarted.complete(sent);
            await releaseAck.future;
            return [
              {
                'surah_id': sent['p_surah_id'],
                'ayah_number': sent['p_ayah_number'],
                'revision': sent['p_revision'],
              },
            ];
          },
        );

        final backgroundPush = background.pushToCloud();
        final sent = await rpcStarted.future;
        final firstRevision = sent['p_revision'] as int;
        await foreground.toggle(createEntry(surahId: 2, ayahNumber: 255));
        releaseAck.complete();
        await backgroundPush;

        final raw = await encrypted.read('ack-race-owner', 'quran_bookmarks');
        final durable = (jsonDecode(raw!) as List<dynamic>).single as Map;
        expect(durable['revision'], greaterThan(firstRevision));
        expect(durable['isDeleted'], isTrue);
        expect(durable['isSynced'], isFalse);
      },
    );

    test(
      'same-owner reconnect uploads one bookmark once and persists acknowledgement',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final encrypted = _MemoryEncryptedAccountPreferencesStore();
        const owner = FixedRecordOwnerProvider('reconnect-owner');
        final writer = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );
        await writer.toggle(createEntry(surahId: 2, ayahNumber: 255));

        final cloudRows = <String, Map<String, dynamic>>{};
        var upsertCount = 0;
        Future<dynamic> cloudRpc(
          String function, {
          Map<String, dynamic>? params,
        }) async {
          if (function == 'pull_quran_bookmarks') {
            return cloudRows.values.toList();
          }
          if (function == 'upsert_quran_bookmark') {
            upsertCount += 1;
            final payload = Map<String, dynamic>.from(
              params!['p_payload'] as Map,
            );
            final row = <String, dynamic>{
              'surah_id': params['p_surah_id'],
              'ayah_number': params['p_ayah_number'],
              'payload': payload,
              'revision': params['p_revision'],
              'is_deleted': params['p_is_deleted'],
            };
            cloudRows['${row['surah_id']}_${row['ayah_number']}'] = row;
            return [row];
          }
          throw StateError('Unexpected RPC: $function');
        }

        final reconnect = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
          cloudRpc: cloudRpc,
        );
        await reconnect.pushToCloud();
        await reconnect.pushToCloud();

        expect(upsertCount, 1);
        expect(cloudRows, hasLength(1));
        expect(cloudRows['2_255']?['surah_id'], 2);
        expect(cloudRows['2_255']?['ayah_number'], 255);
        final restored = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );
        expect(await restored.hasPendingCloudWorkDurably(), isFalse);
        expect(restored.isBookmarked(2, 255), isTrue);
      },
    );

    test(
      'owner switch during pull never merges the old owner response',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final encrypted = _MemoryEncryptedAccountPreferencesStore();
        final owner = _MutableRecordOwnerProvider('owner-a');
        final rpcStarted = Completer<void>();
        final releaseRpc = Completer<void>();
        final pulling = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
          cloudRpc: (function, {params}) async {
            rpcStarted.complete();
            await releaseRpc.future;
            final entry = createEntry(
              surahId: 18,
              ayahNumber: 5,
            ).copyWith(revision: 9, isSynced: true);
            return [
              {
                'surah_id': 18,
                'ayah_number': 5,
                'payload': entry.toJson(),
                'revision': 9,
                'is_deleted': false,
              },
            ];
          },
        );

        final pull = pulling.pullFromCloud();
        await rpcStarted.future;
        owner.currentOwnerId = 'owner-b';
        releaseRpc.complete();
        await pull;

        final ownerB = BookmarkService(
          prefs,
          owner: const FixedRecordOwnerProvider('owner-b'),
          encryptedAccountPreferences: encrypted,
        );
        await ownerB.hasPendingCloudWorkDurably();
        expect(ownerB.getAll(), isEmpty);
      },
    );

    test(
      'owner switch during push leaves old owner pending and B untouched',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final encrypted = _MemoryEncryptedAccountPreferencesStore();
        final owner = _MutableRecordOwnerProvider('owner-a');
        final writer = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );
        await writer.toggle(createEntry(surahId: 2, ayahNumber: 255));
        final rpcStarted = Completer<void>();
        final releaseRpc = Completer<void>();
        final ownersAtRpc = <String>[];
        final pushing = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
          cloudRpc: (function, {params}) async {
            ownersAtRpc.add(owner.currentOwnerId);
            rpcStarted.complete();
            await releaseRpc.future;
            return [
              {
                'surah_id': params!['p_surah_id'],
                'ayah_number': params['p_ayah_number'],
                'revision': params['p_revision'],
              },
            ];
          },
        );

        final push = pushing.pushToCloud();
        await rpcStarted.future;
        owner.currentOwnerId = 'owner-b';
        releaseRpc.complete();
        await push;

        expect(ownersAtRpc, ['owner-a']);
        final restoredA = BookmarkService(
          prefs,
          owner: const FixedRecordOwnerProvider('owner-a'),
          encryptedAccountPreferences: encrypted,
        );
        expect(await restoredA.hasPendingCloudWorkDurably(), isTrue);
        final restoredB = BookmarkService(
          prefs,
          owner: const FixedRecordOwnerProvider('owner-b'),
          encryptedAccountPreferences: encrypted,
        );
        expect(await restoredB.hasPendingCloudWorkDurably(), isFalse);
        expect(restoredB.getAll(), isEmpty);
      },
    );

    test(
      'failed durable acknowledgement keeps cache dirty and marker',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final encrypted = _FailingWriteEncryptedStore();
        const ownerId = 'write-failure-owner';
        final bookmarked = BookmarkService(
          prefs,
          owner: const FixedRecordOwnerProvider(ownerId),
          encryptedAccountPreferences: encrypted,
          cloudRpc: (function, {params}) async => [
            {
              'surah_id': params!['p_surah_id'],
              'ayah_number': params['p_ayah_number'],
              'revision': params['p_revision'],
            },
          ],
        );
        await bookmarked.toggle(createEntry(surahId: 12, ayahNumber: 3));
        await bookmarked.preservePendingRecoveryIfNeeded();
        encrypted.failWrites = true;

        await expectLater(bookmarked.pushToCloud(), throwsException);

        expect(bookmarked.hasPendingCloudWork, isTrue);
        expect(PendingBookmarkRecoveryMarker.contains(prefs, ownerId), isTrue);
        encrypted.failWrites = false;
        final restored = BookmarkService(
          prefs,
          owner: const FixedRecordOwnerProvider(ownerId),
          encryptedAccountPreferences: encrypted,
        );
        expect(await restored.hasPendingCloudWorkDurably(), isTrue);
      },
    );

    test(
      'clean pull clears a stale recovery marker after durable write',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final encrypted = _MemoryEncryptedAccountPreferencesStore();
        const ownerId = 'pull-marker-owner';
        await PendingBookmarkRecoveryMarker.mark(prefs, ownerId);
        final entry = createEntry(
          surahId: 20,
          ayahNumber: 1,
        ).copyWith(revision: 4, isSynced: true);
        final pulling = BookmarkService(
          prefs,
          owner: const FixedRecordOwnerProvider(ownerId),
          encryptedAccountPreferences: encrypted,
          cloudRpc: (function, {params}) async => [
            {
              'surah_id': 20,
              'ayah_number': 1,
              'payload': entry.toJson(),
              'revision': 4,
              'is_deleted': false,
            },
          ],
        );

        await pulling.pullFromCloud();

        expect(await pulling.hasPendingCloudWorkDurably(), isFalse);
        expect(PendingBookmarkRecoveryMarker.contains(prefs, ownerId), isFalse);
      },
    );

    test('toggle returns true when added and false when removed', () async {
      final entry = createEntry(surahId: 1, ayahNumber: 1);
      final added = await service.toggle(entry);
      expect(added, isTrue);
      expect(service.isBookmarked(1, 1), isTrue);

      final removed = await service.toggle(entry);
      expect(removed, isFalse);
      expect(service.isBookmarked(1, 1), isFalse);
    });

    test('ensureLoaded loads bookmarks into memory for encrypted storage', () async {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = _MemoryEncryptedAccountPreferencesStore();
      const owner = FixedRecordOwnerProvider('user-loaded');
      final first = BookmarkService(
        prefs,
        owner: owner,
        encryptedAccountPreferences: encrypted,
      );
      await first.toggle(createEntry(surahId: 18, ayahNumber: 10));

      final second = BookmarkService(
        prefs,
        owner: owner,
        encryptedAccountPreferences: encrypted,
      );
      expect(second.isLoaded, isFalse);
      expect(second.getAll(), isEmpty);

      await second.ensureLoaded();
      expect(second.isLoaded, isTrue);
      expect(second.isBookmarked(18, 10), isTrue);
    });

    test('ensureLoaded migrates legacy SharedPreferences data if encrypted store was empty', () async {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = _MemoryEncryptedAccountPreferencesStore();
      const ownerId = 'migrated-user';
      final entry = createEntry(surahId: 2, ayahNumber: 255);
      await prefs.setString(
        'quran_bookmarks_owner_$ownerId',
        jsonEncode([entry.toJson()]),
      );

      final secondService = BookmarkService(
        prefs,
        owner: const FixedRecordOwnerProvider(ownerId),
        encryptedAccountPreferences: encrypted,
      );

      await secondService.ensureLoaded();
      expect(secondService.isBookmarked(2, 255), isTrue);
      expect(prefs.getString('quran_bookmarks_owner_$ownerId'), isNull);
      expect(await encrypted.read(ownerId, 'quran_bookmarks'), isNotNull);
    });
  });

  group('BookmarkEntry', () {
    test('key is formatted as surahId_ayahNumber', () {
      final entry = createEntry(surahId: 2, ayahNumber: 255);
      expect(entry.key, equals('2_255'));
    });

    test('JSON roundtrip preserves all fields', () {
      final original = createEntry(surahId: 55, ayahNumber: 13);
      final json = original.toJson();
      final restored = BookmarkEntry.fromJson(json);

      expect(restored.surahId, equals(original.surahId));
      expect(restored.surahName, equals(original.surahName));
      expect(restored.ayahNumber, equals(original.ayahNumber));
      expect(restored.ayahText, equals(original.ayahText));
      expect(restored.savedAt, equals(original.savedAt));
    });
  });
}

class _MemoryEncryptedAccountPreferencesStore
    implements EncryptedAccountPreferencesStore {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String ownerId, String key) async {
    _values.remove('$ownerId/$key');
  }

  @override
  Future<String?> read(String ownerId, String key) async =>
      _values['$ownerId/$key'];

  @override
  Future<void> write(String ownerId, String key, String value) async {
    _values['$ownerId/$key'] = value;
  }
}

class _ColdReadRaceEncryptedStore implements EncryptedAccountPreferencesStore {
  _ColdReadRaceEncryptedStore({
    required this.ownerId,
    required String initialValue,
  }) : _value = initialValue;

  final String ownerId;
  final firstReadStarted = Completer<void>();
  final _firstReadRelease = Completer<void>();
  String? _value;
  var _readCount = 0;

  void releaseFirstRead() => _firstReadRelease.complete();

  @override
  Future<void> delete(String ownerId, String key) async {
    _value = null;
  }

  @override
  Future<String?> read(String ownerId, String key) async {
    _readCount += 1;
    if (_readCount == 1) {
      final snapshot = _value;
      firstReadStarted.complete();
      await _firstReadRelease.future;
      return snapshot;
    }
    return _value;
  }

  @override
  Future<void> write(String ownerId, String key, String value) async {
    _value = value;
  }
}

class _MutableRecordOwnerProvider implements RecordOwnerProvider {
  _MutableRecordOwnerProvider(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => true;
}

class _FailingWriteEncryptedStore
    extends _MemoryEncryptedAccountPreferencesStore {
  bool failWrites = false;

  @override
  Future<void> write(String ownerId, String key, String value) async {
    if (failWrites) throw Exception('secure write failed');
    await super.write(ownerId, key, value);
  }
}
