// ignore_for_file: avoid_print
//
// One-time deterministic correction of ayah-1 basmalah boundaries in
// `assets/data/quran.json` (release plan V1-M1).
//
// Rule applied:
//   - Al-Fatihah (1): ayah 1 IS the numbered basmalah — untouched.
//   - At-Tawbah (9): has no basmalah — untouched.
//   - All other surahs: the embedded basmalah prefix is removed from ayah 1
//     so the record contains only the approved numbered ayah text. The
//     Mushaf renders the basmalah structurally.
//
// The script is idempotent and fails closed: if any surah does not match the
// expected shape (basmalah present and exactly four words), it aborts without
// writing anything and exits non-zero.
import 'dart:convert';
import 'dart:io';

import 'package:talia_quran/core/utils/arabic_normalizer.dart';

void main() {
  final file = File('assets/data/quran.json');
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  final fatihahAyah1 = ((data['1'] as List)[0] as Map)['text'] as String;
  final basmalahNorm = ArabicNormalizer.normalize(fatihahAyah1);
  print('Approved basmalah (normalized): $basmalahNorm');

  final basmalahWords = ArabicNormalizer.normalize(fatihahAyah1).split(' ');
  if (basmalahWords.length != 4 || !basmalahNorm.startsWith('بسم')) {
    stderr.writeln(
      'FAIL: unexpected Al-Fatihah ayah-1 shape; refusing to proceed.',
    );
    exitCode = 1;
    return;
  }

  var changedSurahs = 0;
  var alreadyClean = 0;

  for (var surahId = 2; surahId <= 114; surahId++) {
    if (surahId == 9) continue;
    final ayahs = data[surahId.toString()] as List;
    final ayah1 = ayahs[0] as Map<String, dynamic>;
    final rawText = (ayah1['text'] as String).replaceAll('\uFEFF', '');

    if (!ArabicNormalizer.normalize(rawText).startsWith(basmalahNorm)) {
      // Verify the remaining text still does not embed the basmalah later on.
      if (ArabicNormalizer.normalize(rawText).contains(basmalahNorm)) {
        stderr.writeln(
          'FAIL: surah $surahId ayah 1 contains the basmalah in an '
          'unexpected position: $rawText',
        );
        exitCode = 1;
        return;
      }
      alreadyClean++;
      continue;
    }

    // The embedded basmalah is exactly four whitespace-separated words.
    final parts = rawText.split(' ');
    final candidate = parts.take(basmalahWords.length).join(' ');
    if (ArabicNormalizer.normalize(candidate) != basmalahNorm) {
      stderr.writeln(
        'FAIL: surah $surahId ayah 1 prefix does not normalize to the '
        'approved basmalah: "$candidate"',
      );
      exitCode = 1;
      return;
    }

    final remainder = parts.skip(basmalahWords.length).join(' ').trim();
    if (remainder.isEmpty) {
      stderr.writeln(
        'FAIL: surah $surahId ayah 1 would become empty after stripping '
        'the basmalah.',
      );
      exitCode = 1;
      return;
    }

    ayah1['text'] = remainder;
    changedSurahs++;
    print(
      'Surah $surahId ayah 1 corrected: "${remainder.substring(0, remainder.length > 40 ? 40 : remainder.length)}"',
    );
  }

  // At-Tawbah must never gain a basmalah.
  final tawbahAyah1 =
      ((data['9'] as List)[0] as Map<String, dynamic>)['text'] as String;
  if (ArabicNormalizer.normalize(tawbahAyah1).contains('بسم الله')) {
    stderr.writeln('FAIL: At-Tawbah unexpectedly contains the basmalah.');
    exitCode = 1;
    return;
  }

  if (changedSurahs + alreadyClean != 112) {
    stderr.writeln(
      'FAIL: expected to visit 112 surahs, visited '
      '${changedSurahs + alreadyClean} (changed=$changedSurahs, '
      'alreadyClean=$alreadyClean).',
    );
    exitCode = 1;
    return;
  }

  if (changedSurahs > 0) {
    file.writeAsStringSync(jsonEncode(data));
  }
  print('Done. Corrected=$changedSurahs, alreadyClean=$alreadyClean.');
}
