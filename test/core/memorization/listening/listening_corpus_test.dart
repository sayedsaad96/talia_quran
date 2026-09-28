import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/listening/listening_corpus.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';

// Synthetic texts: the tests exercise the ambiguity rules, not real ayahs.
ListeningCorpus _corpus() => ListeningCorpus.fromTexts({
  1: ['alpha one', 'alpha two', 'alpha three'],
  2: [
    'beta one',
    'shared line',
    'beta three',
    'refrain',
    'beta five',
    'refrain',
    'beta seven',
  ],
  3: ['gamma one', 'shared line', 'gamma three'],
});

void main() {
  group('canAskWhichSurah', () {
    test('allows an ayah whose text is unique across surahs', () {
      expect(_corpus().canAskWhichSurah(const ListeningAyahRef(1, 2)), isTrue);
    });

    test('rejects an ayah whose text also appears in another surah', () {
      final corpus = _corpus();
      expect(corpus.canAskWhichSurah(const ListeningAyahRef(2, 2)), isFalse);
      expect(corpus.canAskWhichSurah(const ListeningAyahRef(3, 2)), isFalse);
    });

    test('allows an intra-surah refrain (the surah is still unique)', () {
      expect(_corpus().canAskWhichSurah(const ListeningAyahRef(2, 4)), isTrue);
    });

    test('rejects refs outside the corpus', () {
      final corpus = _corpus();
      expect(corpus.canAskWhichSurah(const ListeningAyahRef(9, 1)), isFalse);
      expect(corpus.canAskWhichSurah(const ListeningAyahRef(1, 0)), isFalse);
      expect(corpus.canAskWhichSurah(const ListeningAyahRef(1, 4)), isFalse);
    });
  });

  group('canAskNextAyah', () {
    test('allows a unique ayah that has a successor in the same surah', () {
      expect(_corpus().canAskNextAyah(const ListeningAyahRef(1, 1)), isTrue);
    });

    test('rejects the last ayah of a surah', () {
      expect(_corpus().canAskNextAyah(const ListeningAyahRef(1, 3)), isFalse);
    });

    test('rejects an ayah repeated inside its surah', () {
      final corpus = _corpus();
      expect(corpus.canAskNextAyah(const ListeningAyahRef(2, 4)), isFalse);
      expect(corpus.canAskNextAyah(const ListeningAyahRef(2, 6)), isFalse);
    });

    test('rejects an ayah whose text also appears in another surah', () {
      expect(_corpus().canAskNextAyah(const ListeningAyahRef(2, 2)), isFalse);
    });
  });

  test('normalizedKey ignores diacritics, BOM and extra whitespace', () {
    expect(
      ListeningCorpus.normalizedKey('﻿بِسْمِ  ٱللَّهِ '),
      ListeningCorpus.normalizedKey('بسم الله'),
    );
  });

  test('textOf returns the canonical text unchanged', () {
    expect(_corpus().textOf(const ListeningAyahRef(2, 3)), 'beta three');
  });
}
