import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
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

    test('stores signed-in owner bookmarks in encrypted account storage', () async {
      final prefs = await SharedPreferences.getInstance();
      const encrypted = _MemoryEncryptedAccountPreferencesStore();
      const owner = FixedRecordOwnerProvider('owner-a');
      final first = BookmarkService(
        prefs,
        owner: owner,
        encryptedAccountPreferences: encrypted,
      );

      await first.toggle(createEntry(surahId: 36, ayahNumber: 1));

      expect(
        prefs.getString('quran_bookmarks_owner_owner-a'),
        isNull,
      );
      final restored = BookmarkService(
        prefs,
        owner: owner,
        encryptedAccountPreferences: encrypted,
      );
      await restored.migrateLegacyForCurrentOwner();
      expect(restored.isBookmarked(36, 1), isTrue);
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
  const _MemoryEncryptedAccountPreferencesStore();

  static final Map<String, String> _values = {};

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
