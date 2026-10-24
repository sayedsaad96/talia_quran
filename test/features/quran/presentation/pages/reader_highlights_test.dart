import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/strength_band.dart';
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

  test('strength goes first so audio/selected/bookmark win for the same ayah', () {
    final highlights = readerHighlights(
      page: 2,
      accent: accent,
      bookmarks: [bookmark],
      selected: (surah: 2, ayah: 3),
      strengthBands: {
        (surah: 2, ayah: 5): StrengthBand.weak,
        (surah: 2, ayah: 3): StrengthBand.due,
        (surah: 2, ayah: 7): StrengthBand.solid,
      },
    );
    final order = highlights.map((h) => h.verseNumber).toList();
    expect(order.sublist(0, 3).toSet(), {5, 3, 7});
    expect(order.sublist(3), [5, 3]);
  });

  test('strength colours share one alpha', () {
    Color colorFor(StrengthBand band) => readerHighlights(
      page: 2,
      accent: accent,
      bookmarks: const [],
      strengthBands: {(surah: 2, ayah: 1): band},
    ).single.color;
    expect(colorFor(StrengthBand.due).a, closeTo(0.40, 0.01));
    expect(colorFor(StrengthBand.weak).a, closeTo(0.40, 0.01));
    expect(colorFor(StrengthBand.building).a, closeTo(0.40, 0.01));
    expect(colorFor(StrengthBand.solid).a, closeTo(0.40, 0.01));
  });

  test('strength tint stays within the spec range once qcf applies 0.4', () {
    // qcf paints highlight.color.withOpacity(0.4) over the page.
    double visible(Color band, Color page) {
      final c = strengthHighlightColor(band, page).withValues(alpha: 1);
      final painted = Color.lerp(page, c, 0.4)!;
      // Share of the band's distance from the page that remains visible.
      return (painted.r - page.r) / (band.r - page.r);
    }

    const lightPage = Color(0xFFFFF8E7);
    const darkPage = Color(0xFF1A1A1A);
    const band = Color(0xFFE53935);
    expect(visible(band, lightPage), inInclusiveRange(0.15, 0.22));
    expect(visible(band, darkPage), inInclusiveRange(0.15, 0.22));
    expect(strengthHighlightColor(band, lightPage).a, closeTo(0.40, 0.01));
  });

  test('empty strengthBands equals the previous output', () {
    List<(int, int, Color)> view(List<dynamic> hs) =>
        [for (final h in hs) (h.surah as int, h.verseNumber as int, h.color as Color)];
    final before = readerHighlights(
      page: 2,
      accent: accent,
      bookmarks: [bookmark],
    );
    final after = readerHighlights(
      page: 2,
      accent: accent,
      bookmarks: [bookmark],
      strengthBands: const {},
    );
    expect(view(after), view(before));
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
