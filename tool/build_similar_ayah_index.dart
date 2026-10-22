import 'dart:convert';
import 'dart:io';

import 'package:talia_quran/core/memorization/similar_ayah/similar_ayah_index_generator.dart';
import 'similar_ayah_draft_output.dart';

export 'similar_ayah_draft_output.dart' show parseSimilarAyahDraftOutput;

const _corpusPath = 'assets/data/quran.json';
const _surahsPath = 'assets/data/surahs.json';
const _normalizerPath = 'lib/core/utils/arabic_normalizer.dart';
const _splitterPath = 'lib/core/quran/quran_basmalah.dart';
const _recitablePredicatePath =
    'lib/core/memorization/v2/recitation_word_diff.dart';
const _generatorPath =
    'lib/core/memorization/similar_ayah/similar_ayah_index_generator.dart';
const _surahBoundsPath = 'lib/core/constants/surah_names.dart';
const _draftOutputPath = 'tool/similar_ayah_draft_output.dart';

Future<void> main(List<String> arguments) async {
  final outputPath = parseSimilarAyahDraftOutput(arguments);
  final corpusBytes = await File(_corpusPath).readAsBytes();
  final surahBytes = await File(_surahsPath).readAsBytes();
  final verses = decodeSimilarAyahCorpus(corpusBytes, surahBytes);
  final index = buildSimilarAyahIndex(
    verses: verses,
    provenance: similarAyahProvenance(
      corpusBytes: corpusBytes,
      normalizerBytes: await File(_normalizerPath).readAsBytes(),
      splitterBytes: await File(_splitterPath).readAsBytes(),
      recitablePredicateBytes: await File(
        _recitablePredicatePath,
      ).readAsBytes(),
      surahMetadataBytes: surahBytes,
      generatorBytes: await _generatorSourceBytes(),
    ),
  );
  final encoded = utf8.encode(index.encode());
  await writeNewSimilarAyahDraft(outputPath: outputPath, bytes: encoded);
  stdout.writeln(
    'Draft written: pairs=${index.pairs.length}, bytes=${encoded.length}, '
    'candidates=${index.stats.candidateCount}, maxBucket=${index.stats.maxBucketSize}, '
    'dp=${index.stats.dynamicProgramCount}, elapsedMs=${index.stats.elapsed.inMilliseconds}',
  );
}

List<SimilarAyahSourceVerse> decodeSimilarAyahCorpus(
  List<int> corpusBytes,
  List<int> surahBytes,
) {
  final corpus = jsonDecode(utf8.decode(corpusBytes));
  final surahs = jsonDecode(utf8.decode(surahBytes));
  if (corpus is! Map<String, dynamic> || surahs is! List<dynamic>) {
    throw const FormatException('Unexpected corpus structure.');
  }
  if (corpus.length != 114 || surahs.length != 114) {
    throw const FormatException('Corpus must contain 114 surahs.');
  }
  final verses = <SimilarAyahSourceVerse>[];
  var expectedGlobal = 1;
  for (var surahId = 1; surahId <= 114; surahId++) {
    final rawSurah = corpus['$surahId'];
    final metadata = surahs[surahId - 1];
    if (rawSurah is! List<dynamic> || metadata is! Map<String, dynamic>) {
      throw FormatException('Invalid surah structure at $surahId.');
    }
    final expectedCount = metadata['ayahCount'];
    if (metadata['id'] != surahId ||
        expectedCount is! int ||
        rawSurah.length != expectedCount) {
      throw FormatException('Invalid surah metadata at $surahId.');
    }
    _appendSurah(verses, rawSurah, surahId, expectedGlobal);
    expectedGlobal += rawSurah.length;
  }
  if (corpus.keys.any(
        (key) =>
            int.tryParse(key) == null ||
            int.parse(key) < 1 ||
            int.parse(key) > 114,
      ) ||
      verses.length != 6236 ||
      expectedGlobal != 6237) {
    throw const FormatException('Corpus identifiers are incomplete.');
  }
  return List.unmodifiable(verses);
}

void _appendSurah(
  List<SimilarAyahSourceVerse> verses,
  List<dynamic> rawSurah,
  int surahId,
  int expectedGlobal,
) {
  for (var index = 0; index < rawSurah.length; index++) {
    final record = rawSurah[index];
    if (record is! Map<String, dynamic> ||
        record['chapter'] != surahId ||
        record['verse'] != index + 1 ||
        record['global'] != expectedGlobal + index ||
        record['text'] is! String ||
        (record['text'] as String).isEmpty) {
      throw FormatException(
        'Invalid verse structure at $surahId:${index + 1}.',
      );
    }
    verses.add(
      SimilarAyahSourceVerse(
        surahId: surahId,
        ayahNumber: index + 1,
        canonicalText: record['text'] as String,
      ),
    );
  }
}

Future<List<int>> _generatorSourceBytes() async {
  final builder = await File(Platform.script.toFilePath()).readAsBytes();
  final helper = await File(_generatorPath).readAsBytes();
  final predicate = await File(_recitablePredicatePath).readAsBytes();
  final bounds = await File(_surahBoundsPath).readAsBytes();
  final output = await File(_draftOutputPath).readAsBytes();
  return [
    ...builder,
    0,
    ...helper,
    0,
    ...predicate,
    0,
    ...bounds,
    0,
    ...output,
  ];
}
