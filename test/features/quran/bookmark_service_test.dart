import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/quran/data/datasources/bookmark_service.dart';

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
    });
  });
}
