import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/data/datasources/bookmark_service.dart';
import 'package:talia_quran/features/quran/domain/bookmark_reader_location.dart';

void main() {
  test('opens the mushaf page of the bookmarked ayah, not the surah start', () {
    final ayatAlKursi = BookmarkEntry(
      surahId: 2,
      surahName: 'البقرة',
      ayahNumber: 255,
      ayahText: 'الله لا إله إلا هو',
      savedAt: DateTime.utc(2026, 1, 1),
    );

    expect(bookmarkReaderLocation(ayatAlKursi), '/quran/page/42');
  });
}
