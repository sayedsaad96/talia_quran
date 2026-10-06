import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/quran/quran_basmalah.dart';
import 'package:talia_quran/core/utils/arabic_normalizer.dart';

void main() {
  final corpus =
      jsonDecode(File('assets/data/quran.json').readAsStringSync())
          as Map<String, dynamic>;
  String canonical(int surah, int ayah) =>
      ((corpus['$surah'] as List)[ayah - 1] as Map)['text'] as String;
  final reference = ArabicNormalizer.normalize(canonical(1, 1));

  AyahTextParts split(int surah, int ayah) => QuranBasmalah.split(
    surahId: surah,
    ayahNumber: ayah,
    canonicalText: canonical(surah, ayah),
    normalizedReference: reference,
  );

  test('Al-Fatihah ayah 1 is the numbered basmalah and is never split', () {
    final parts = split(1, 1);
    expect(parts.basmalah, isNull);
    expect(parts.body, canonical(1, 1));
  });

  test('At-Tawbah has no basmalah to separate', () {
    final parts = split(9, 1);
    expect(parts.basmalah, isNull);
    expect(parts.body, canonical(9, 1));
  });

  test('every other surah separates a verbatim basmalah from ayah 1', () {
    for (var surah = 2; surah <= 114; surah++) {
      if (surah == 9) continue;
      final text = canonical(surah, 1);
      final parts = split(surah, 1);
      expect(parts.basmalah, isNotNull, reason: 'surah $surah');
      expect(parts.body, isNotEmpty, reason: 'surah $surah');
      // Verbatim: both parts are exact substrings of the canonical text.
      expect(text.startsWith(parts.basmalah!), isTrue, reason: 'surah $surah');
      expect(text.endsWith(parts.body), isTrue, reason: 'surah $surah');
      expect(
        ArabicNormalizer.normalize(parts.basmalah!),
        reference,
        reason: 'surah $surah',
      );
    }
  });

  test('keeps non-identical basmalah spellings exactly as written', () {
    final spellings = {
      for (var surah = 2; surah <= 114; surah++)
        if (surah != 9) split(surah, 1).basmalah!,
    };
    // The Tanzil text spells some basmalahs differently (e.g. a shadda on the
    // first letter); none may be rewritten to a single form.
    for (final surah in [95, 97]) {
      expect(spellings, contains(split(surah, 1).basmalah));
    }
    expect(spellings.length, greaterThan(1));
  });

  test('later ayahs are never split', () {
    final parts = split(27, 30);
    expect(parts.basmalah, isNull);
    expect(parts.body, canonical(27, 30));
  });

  test('fails safe: an unexpected prefix hides nothing', () {
    final parts = QuranBasmalah.split(
      surahId: 2,
      ayahNumber: 1,
      canonicalText: 'نص لا يبدأ بالبسملة هنا',
      normalizedReference: reference,
    );
    expect(parts.basmalah, isNull);
    expect(parts.body, 'نص لا يبدأ بالبسملة هنا');
  });

  test('fails safe without a reference basmalah', () {
    final parts = QuranBasmalah.split(
      surahId: 2,
      ayahNumber: 1,
      canonicalText: canonical(2, 1),
      normalizedReference: null,
    );
    expect(parts.basmalah, isNull);
    expect(parts.body, canonical(2, 1));
  });
}
