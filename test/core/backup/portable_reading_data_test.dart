import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/backup/portable_reading_data.dart';
import 'package:talia_quran/core/constants/surah_names.dart';

void main() {
  group('PortableBookmark', () {
    test('accepts a reference that exists in the Quran corpus', () {
      final bookmark = PortableBookmark(
        surahId: 2,
        ayahNumber: 255,
        savedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
      );

      expect(bookmark.surahId, 2);
      expect(bookmark.ayahNumber, 255);
    });

    test('accepts the first and last ayah of a surah', () {
      expect(
        () => PortableBookmark(
          surahId: 114,
          ayahNumber: SurahNames.ayahCount(114),
          savedAt: DateTime.utc(2026),
        ),
        returnsNormally,
      );
      expect(
        () => PortableBookmark(
          surahId: 1,
          ayahNumber: 1,
          savedAt: DateTime.utc(2026),
        ),
        returnsNormally,
      );
    });

    test('rejects an ayah beyond the surah length', () {
      expect(
        () => PortableBookmark(
          surahId: 2,
          ayahNumber: 9999,
          savedAt: DateTime.utc(2026),
        ),
        throwsA(isA<PortableReadingDataException>()),
      );
      expect(
        () => PortableBookmark(
          surahId: 1,
          ayahNumber: SurahNames.ayahCount(1) + 1,
          savedAt: DateTime.utc(2026),
        ),
        throwsA(isA<PortableReadingDataException>()),
      );
    });

    test('rejects out-of-range surah and ayah numbers', () {
      for (final (surah, ayah) in [(0, 1), (115, 1), (2, 0), (2, -1)]) {
        expect(
          () => PortableBookmark(
            surahId: surah,
            ayahNumber: ayah,
            savedAt: DateTime.utc(2026),
          ),
          throwsA(isA<PortableReadingDataException>()),
          reason: '$surah:$ayah',
        );
      }
    });

    test('serialises only the reference and an UTC timestamp', () {
      final bookmark = PortableBookmark(
        surahId: 2,
        ayahNumber: 255,
        savedAt: DateTime.parse('2026-01-02T05:04:05+02:00'),
      );

      expect(bookmark.toJson(), {
        'surahId': 2,
        'ayahNumber': 255,
        'savedAt': '2026-01-02T03:04:05.000Z',
      });
    });

    test('round-trips through json', () {
      final original = PortableBookmark(
        surahId: 36,
        ayahNumber: 1,
        savedAt: DateTime.utc(2026, 5, 6, 7),
      );

      final decoded = PortableBookmark.fromJson(original.toJson());

      expect(decoded, original);
      expect(decoded.hashCode, original.hashCode);
    });

    test('decoding ignores display text a foreign file may carry', () {
      final decoded = PortableBookmark.fromJson({
        'surahId': 2,
        'ayahNumber': 255,
        'savedAt': '2026-01-02T03:04:05.000Z',
        'surahName': 'نص مزور',
        'ayahText': 'نص مزور',
        'isSynced': true,
        'ownerId': 'someone-else',
      });

      expect(decoded.toJson().keys, {'surahId', 'ayahNumber', 'savedAt'});
    });

    test('decoding rejects malformed or invalid entries', () {
      final invalid = <Map<String, dynamic>>[
        {'surahId': 2, 'ayahNumber': 9999, 'savedAt': '2026-01-01T00:00:00Z'},
        {'surahId': '2', 'ayahNumber': 255, 'savedAt': '2026-01-01T00:00:00Z'},
        {'surahId': 2, 'ayahNumber': 255, 'savedAt': 'not a date'},
        {'surahId': 2, 'ayahNumber': 255},
        {'surahId': 2, 'ayahNumber': 255, 'savedAt': 7},
      ];
      for (final json in invalid) {
        expect(
          () => PortableBookmark.fromJson(json),
          throwsA(isA<PortableReadingDataException>()),
          reason: '$json',
        );
      }
    });

    test('derives the display name from the reference, not from the file', () {
      final bookmark = PortableBookmark(
        surahId: 2,
        ayahNumber: 255,
        savedAt: DateTime.utc(2026),
      );

      expect(bookmark.surahNameAr, SurahNames.nameAr(2));
    });
  });

  group('QuranReadingCheckpoint', () {
    test('accepts pages 1 through 604', () {
      expect(QuranReadingCheckpoint(pageNumber: 1).pageNumber, 1);
      expect(QuranReadingCheckpoint(pageNumber: 604).pageNumber, 604);
    });

    test('rejects pages 0 and 605', () {
      for (final page in [0, 605, -1]) {
        expect(
          () => QuranReadingCheckpoint(pageNumber: page),
          throwsA(isA<PortableReadingDataException>()),
          reason: '$page',
        );
      }
    });

    test('round-trips through json and rejects bad payloads', () {
      final original = QuranReadingCheckpoint(pageNumber: 42);

      expect(QuranReadingCheckpoint.fromJson(original.toJson()), original);
      expect(
        () => QuranReadingCheckpoint.fromJson({'pageNumber': 605}),
        throwsA(isA<PortableReadingDataException>()),
      );
      expect(
        () => QuranReadingCheckpoint.fromJson({'pageNumber': '42'}),
        throwsA(isA<PortableReadingDataException>()),
      );
      expect(
        () => QuranReadingCheckpoint.fromJson(const {}),
        throwsA(isA<PortableReadingDataException>()),
      );
    });
  });
}
