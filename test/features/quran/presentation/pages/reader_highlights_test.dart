import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/domain/entities/bookmark_entry.dart';
import 'package:talia_quran/features/quran/presentation/pages/quran_reader_page.dart';

/// N15: the ayah whose options are open was not marked on the page.
void main() {
  const accent = Color(0xFF0D5C55);
  final bookmark = BookmarkEntry(
    surahId: 2,
    surahName: 'البقرة',
    ayahNumber: 5,
    ayahText: 'x',
    savedAt: DateTime.utc(2026, 9, 1),
  );

  test('the selected ayah is highlighted above bookmarks', () {
    final highlights = readerHighlights(
      page: 2,
      accent: accent,
      bookmarks: [bookmark],
      selected: (surah: 2, ayah: 3),
    );

    expect(
      highlights.map((h) => (h.surah, h.verseNumber)),
      containsAll([(2, 3), (2, 5)]),
    );
    final selected = highlights.firstWhere((h) => h.verseNumber == 3);
    final marked = highlights.firstWhere((h) => h.verseNumber == 5);
    expect(selected.color.a, greaterThan(marked.color.a));
  });

  test('audio playback replaces bookmark marks but keeps the selection', () {
    final highlights = readerHighlights(
      page: 2,
      accent: accent,
      bookmarks: [bookmark],
      audio: (surah: 2, ayah: 4, page: 2),
      selected: (surah: 2, ayah: 3),
    );

    expect(highlights.map((h) => h.verseNumber), unorderedEquals([4, 3]));
  });

  test('without a selection only the usual marks show', () {
    final highlights = readerHighlights(
      page: 2,
      accent: accent,
      bookmarks: [bookmark],
    );

    expect(highlights.map((h) => h.verseNumber), [5]);
  });
}
