import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:talia_quran/core/memorization/similar_ayah/similar_ayah_index_generator.dart';

const _reviewRoot = 'docs/content/reviews/2026-10-30-tafsir-mutashabihat';
const _fixturePath = 'test/fixtures/similar_ayah_calibration_candidates.json';
const _corpusPath = 'assets/data/quran.json';

/// Emits the owner's approved browsing index to stdout without file writes.
/// The frozen fixture's mechanical measurements are retained, not relabelled
/// as detector calibration or an algorithmically accepted lexical relation.
void main() {
  final approval = _readJson('$_reviewRoot/owner-approval.json');
  if (approval['status'] != 'approved' ||
      approval['reviewAuthority'] != 'projectOwner' ||
      approval['fixturePath'] != _fixturePath ||
      approval['fixtureSha256'] != _hash(_fixturePath) ||
      approval['sourceCorpusSha256'] != _hash(_corpusPath)) {
    throw StateError('Approval does not match the frozen input files.');
  }
  final fixture = _readJson(_fixturePath);
  final candidates = fixture['candidatePairs'] as List<dynamic>;
  if (candidates.length != approval['approvedPairCount'] ||
      (fixture['rawBasmalahOnlyCandidates'] as List).length !=
          approval['excludedPairCount']) {
    throw StateError('Approval does not match the reviewed pair counts.');
  }
  final pairs =
      candidates.cast<Map<String, dynamic>>().map(_curatedPair).toList()
        ..sort(_comparePairs);
  if (pairs.map((pair) => '${pair['a']}|${pair['b']}').toSet().length !=
      pairs.length) {
    throw StateError('Duplicate approved references.');
  }
  final provenance = similarAyahProvenance(
    corpusBytes: File(_corpusPath).readAsBytesSync(),
    normalizerBytes: File(
      'lib/core/utils/arabic_normalizer.dart',
    ).readAsBytesSync(),
    splitterBytes: File('lib/core/quran/quran_basmalah.dart').readAsBytesSync(),
    recitablePredicateBytes: File(
      'lib/core/memorization/v2/recitation_word_diff.dart',
    ).readAsBytesSync(),
    surahMetadataBytes: File('assets/data/surahs.json').readAsBytesSync(),
    generatorBytes: File(Platform.script.toFilePath()).readAsBytesSync(),
  );
  provenance['reviewSetId'] = approval['reviewSetId'] as String;
  provenance['tokenPolicy'] = 'owner-curated-fixture-metrics-v1';
  provenance['approvalSha256'] = _hash('$_reviewRoot/owner-approval.json');
  provenance['fixtureSha256'] = _hash(_fixturePath);
  final index = {'version': 1, 'provenance': provenance, 'pairs': pairs};
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(index));
}

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

String _hash(String path) =>
    sha256.convert(File(path).readAsBytesSync()).toString();

Map<String, Object> _curatedPair(Map<String, dynamic> candidate) {
  final references = [
    for (final side in ['a', 'b'])
      '${candidate[side]['surah']}:${candidate[side]['ayah']}',
  ]..sort(_compareKeys);
  final metrics = candidate['runtimeMetrics'] as Map<String, dynamic>;
  return {
    'a': references.first,
    'b': references.last,
    'score': metrics['normalizedSimilarity'] as num,
    'sharedRun': metrics['sharedRunTokens'] as int,
    'kind': 'curated',
  };
}

int _comparePairs(Map<String, Object> left, Map<String, Object> right) {
  final first = _compareKeys(left['a'] as String, right['a'] as String);
  return first != 0
      ? first
      : _compareKeys(left['b'] as String, right['b'] as String);
}

int _compareKeys(String left, String right) {
  final a = left.split(':').map(int.parse).toList();
  final b = right.split(':').map(int.parse).toList();
  final surah = a.first.compareTo(b.first);
  return surah != 0 ? surah : a.last.compareTo(b.last);
}
