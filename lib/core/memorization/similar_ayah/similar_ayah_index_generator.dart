import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../constants/surah_names.dart';
import '../../quran/quran_basmalah.dart';
import '../../utils/arabic_normalizer.dart';
import '../v2/recitation_word_diff.dart';

const similarAyahIndexVersion = 1;

/// A canonical corpus record used only while producing an IDs-only draft.
final class SimilarAyahSourceVerse {
  const SimilarAyahSourceVerse({
    required this.surahId,
    required this.ayahNumber,
    required this.canonicalText,
  });

  final int surahId;
  final int ayahNumber;
  final String canonicalText;
}

/// One symmetric lexical relation, represented by canonical `surah:ayah` IDs.
final class SimilarAyahPair {
  const SimilarAyahPair({
    required this.a,
    required this.b,
    required this.scoreMicros,
    required this.sharedRun,
    required this.kind,
  });

  final String a;
  final String b;
  final int scoreMicros;
  final int sharedRun;
  final String kind;

  Map<String, Object> toJson() => {
    'a': a,
    'b': b,
    'score': scoreMicros / 1000000,
    'sharedRun': sharedRun,
    'kind': kind,
  };
}

/// Non-persisted instrumentation for calibration and candidate-cost review.
final class SimilarAyahGenerationStats {
  const SimilarAyahGenerationStats({
    required this.maxBucketSize,
    required this.candidateCount,
    required this.dynamicProgramCount,
    required this.elapsed,
  });

  final int maxBucketSize;
  final int candidateCount;
  final int dynamicProgramCount;
  final Duration elapsed;
}

/// Immutable draft index with an efficient symmetric adjacency lookup.
final class SimilarAyahIndex {
  SimilarAyahIndex({
    required Map<String, String> provenance,
    required List<SimilarAyahPair> pairs,
    required this.stats,
  }) : provenance = Map.unmodifiable(_sortedMap(provenance)),
       pairs = List.unmodifiable(pairs),
       _adjacency = _buildAdjacency(pairs) {
    _validateDraftOutput(this.provenance, this.pairs);
  }

  final Map<String, String> provenance;
  final List<SimilarAyahPair> pairs;
  final SimilarAyahGenerationStats stats;
  final Map<String, List<SimilarAyahPair>> _adjacency;

  List<SimilarAyahPair> neighborsOf(String canonicalKey) =>
      _adjacency[canonicalKey] ?? const [];

  String encode() =>
      '${const JsonEncoder.withIndent('  ').convert({'version': similarAyahIndexVersion, 'provenance': provenance, 'pairs': pairs.map((pair) => pair.toJson()).toList(growable: false)})}\n';

  static Map<String, String> _sortedMap(Map<String, String> source) {
    final keys = source.keys.toList()..sort();
    return {for (final key in keys) key: source[key]!};
  }

  static Map<String, List<SimilarAyahPair>> _buildAdjacency(
    List<SimilarAyahPair> pairs,
  ) {
    final entries = <String, List<SimilarAyahPair>>{};
    for (final pair in pairs) {
      entries.putIfAbsent(pair.a, () => []).add(pair);
      entries.putIfAbsent(pair.b, () => []).add(pair);
    }
    return UnmodifiableMapView({
      for (final entry in entries.entries)
        entry.key: List.unmodifiable(entry.value),
    });
  }
}

void _validateDraftOutput(
  Map<String, String> provenance,
  List<SimilarAyahPair> pairs,
) {
  if (provenance.entries.any(
    (entry) => !_isAscii(entry.key) || !_isAscii(entry.value),
  )) {
    throw ArgumentError('Draft provenance must be ASCII-only.');
  }
  for (final pair in pairs) {
    if (!_isCanonicalKey(pair.a) ||
        !_isCanonicalKey(pair.b) ||
        _compareKey(pair.a, pair.b) >= 0 ||
        pair.scoreMicros < 0 ||
        pair.scoreMicros > 1000000 ||
        pair.sharedRun < 0 ||
        !const {
          'identical',
          'prefix',
          'suffix',
          'partial',
        }.contains(pair.kind)) {
      throw ArgumentError('Invalid IDs-only draft pair.');
    }
  }
}

bool _isAscii(String value) => value.codeUnits.every((unit) => unit <= 0x7f);

bool _isCanonicalKey(String value) =>
    RegExp(r'^[1-9]\d*:[1-9]\d*$').hasMatch(value);

/// Builds deterministic IDs-only lexical browsing candidates.
SimilarAyahIndex buildSimilarAyahIndex({
  required List<SimilarAyahSourceVerse> verses,
  required Map<String, String> provenance,
}) {
  final stopwatch = Stopwatch()..start();
  final prepared = _prepare(verses);
  final instrumentation = _Instrumentation();
  final candidates = <_PairKey>{
    ..._fourGramPairs(prepared, instrumentation),
    ..._exactSequencePairs(prepared, instrumentation),
    ..._shortPairs(prepared, instrumentation),
  };
  final accepted = <SimilarAyahPair>[];
  for (final pair in candidates) {
    final result = _compare(
      prepared[pair.a],
      prepared[pair.b],
      instrumentation,
    );
    if (result != null) accepted.add(result);
  }
  accepted.sort(_comparePairs);
  stopwatch.stop();
  return SimilarAyahIndex(
    provenance: provenance,
    pairs: accepted,
    stats: SimilarAyahGenerationStats(
      maxBucketSize: instrumentation.maxBucketSize,
      candidateCount: candidates.length,
      dynamicProgramCount: instrumentation.dynamicProgramCount,
      elapsed: stopwatch.elapsed,
    ),
  );
}

Map<String, String> similarAyahProvenance({
  required List<int> corpusBytes,
  required List<int> normalizerBytes,
  required List<int> splitterBytes,
  required List<int> recitablePredicateBytes,
  required List<int> surahMetadataBytes,
  required List<int> generatorBytes,
}) => {
  'corpusSha256': sha256.convert(corpusBytes).toString(),
  'generatorSha256': sha256.convert(generatorBytes).toString(),
  'normalizerSha256': sha256.convert(normalizerBytes).toString(),
  'recitablePredicateSha256': sha256
      .convert(recitablePredicateBytes)
      .toString(),
  'splitterSha256': sha256.convert(splitterBytes).toString(),
  'surahMetadataSha256': sha256.convert(surahMetadataBytes).toString(),
  'tokenPolicy': 'normalized-recitable-whitespace-v1',
};

List<_Verse> _prepare(List<SimilarAyahSourceVerse> source) {
  final ids = <String>{};
  final reference = _referenceFor(source);
  final result = <_Verse>[];
  for (final verse in source) {
    _validateSourceVerse(verse, ids);
    final body = QuranBasmalah.split(
      surahId: verse.surahId,
      ayahNumber: verse.ayahNumber,
      canonicalText: verse.canonicalText,
      normalizedReference: reference,
    ).body;
    result.add(_Verse(verse.surahId, verse.ayahNumber, _tokens(body)));
  }
  result.sort(_compareVerse);
  return result;
}

String _referenceFor(List<SimilarAyahSourceVerse> source) {
  for (final verse in source) {
    if (verse.surahId == 1 && verse.ayahNumber == 1) {
      return ArabicNormalizer.normalize(verse.canonicalText);
    }
  }
  throw ArgumentError('Missing canonical 1:1 reference');
}

void _validateSourceVerse(SimilarAyahSourceVerse verse, Set<String> ids) {
  if (verse.surahId < 1 ||
      verse.surahId > 114 ||
      verse.ayahNumber < 1 ||
      verse.ayahNumber > SurahNames.ayahCount(verse.surahId)) {
    throw ArgumentError('Invalid verse identifier');
  }
  if (verse.canonicalText.isEmpty) throw ArgumentError('Empty canonical text');
  if (!ids.add('${verse.surahId}:${verse.ayahNumber}')) {
    throw ArgumentError('Duplicate verse identifier');
  }
}

List<String> _tokens(String body) => ArabicNormalizer.normalize(body)
    .split(' ')
    .where(RecitationWordDiffer.isRecitableWord)
    .toList(growable: false);

Set<_PairKey> _fourGramPairs(List<_Verse> verses, _Instrumentation stats) {
  final buckets = <(String, String, String, String), Set<int>>{};
  for (var index = 0; index < verses.length; index++) {
    final tokens = verses[index].tokens;
    for (var start = 0; start + 4 <= tokens.length; start++) {
      final key = (
        tokens[start],
        tokens[start + 1],
        tokens[start + 2],
        tokens[start + 3],
      );
      buckets.putIfAbsent(key, () => {}).add(index);
    }
  }
  return _pairsFromBuckets(buckets.values, stats);
}

Set<_PairKey> _exactSequencePairs(List<_Verse> verses, _Instrumentation stats) {
  final buckets = <_TokenSequence, Set<int>>{};
  for (var index = 0; index < verses.length; index++) {
    final tokens = verses[index].tokens;
    if (tokens.isNotEmpty) {
      buckets.putIfAbsent(_TokenSequence(tokens), () => {}).add(index);
    }
  }
  return _pairsFromBuckets(buckets.values, stats);
}

Set<_PairKey> _shortPairs(List<_Verse> verses, _Instrumentation stats) {
  final words = <String, Set<int>>{};
  for (var index = 0; index < verses.length; index++) {
    final tokens = verses[index].tokens;
    if (tokens.length < 4 || tokens.length > 8) continue;
    for (final token in tokens.toSet()) {
      words.putIfAbsent(token, () => {}).add(index);
    }
  }
  return _pairsFromBuckets(words.values, stats).where((pair) {
    final a = verses[pair.a].tokens;
    final b = verses[pair.b].tokens;
    final min = a.length < b.length ? a.length : b.length;
    final max = a.length > b.length ? a.length : b.length;
    return 4 * min >= 3 * max && 4 * _multisetOverlap(a, b) >= 3 * max;
  }).toSet();
}

Set<_PairKey> _pairsFromBuckets(
  Iterable<Set<int>> buckets,
  _Instrumentation stats,
) {
  final result = <_PairKey>{};
  for (final bucket in buckets) {
    stats.maxBucketSize = _max(stats.maxBucketSize, bucket.length);
    final sorted = bucket.toList()..sort();
    for (var i = 0; i < sorted.length; i++) {
      for (var j = i + 1; j < sorted.length; j++) {
        result.add(_PairKey(sorted[i], sorted[j]));
      }
    }
  }
  return result;
}

SimilarAyahPair? _compare(_Verse a, _Verse b, _Instrumentation stats) {
  if (a.tokens.isEmpty || b.tokens.isEmpty) return null;
  final run = _longestRun(a.tokens, b.tokens);
  stats.dynamicProgramCount++;
  final distance = _distance(a.tokens, b.tokens);
  final max = _max(a.tokens.length, b.tokens.length);
  final identical = distance == 0;
  final short = _isShort(a.tokens) && _isShort(b.tokens);
  if (!identical && run.length < 4 && (!short || 4 * distance > max)) {
    return null;
  }
  return SimilarAyahPair(
    a: a.key,
    b: b.key,
    scoreMicros: _roundRatio(max - distance, max),
    sharedRun: run.length,
    kind: _kindFor(identical, run, a.tokens.length, b.tokens.length),
  );
}

bool _isShort(List<String> tokens) => tokens.length >= 4 && tokens.length <= 8;

String _kindFor(bool identical, _Run run, int aLength, int bLength) {
  if (identical) return 'identical';
  if (run.a == 0 && run.b == 0) return 'prefix';
  if (run.a + run.length == aLength && run.b + run.length == bLength) {
    return 'suffix';
  }
  return 'partial';
}

int _distance(List<String> a, List<String> b) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      current[j] = a[i - 1] == b[j - 1]
          ? previous[j - 1]
          : 1 + _min3(previous[j], current[j - 1], previous[j - 1]);
    }
    previous = current;
  }
  return previous.last;
}

_Run _longestRun(List<String> a, List<String> b) {
  var best = const _Run(0, 0, 0);
  var previous = List<_Run>.filled(b.length + 1, const _Run(0, 0, 0));
  for (var i = 1; i <= a.length; i++) {
    final current = List<_Run>.filled(b.length + 1, const _Run(0, 0, 0));
    for (var j = 1; j <= b.length; j++) {
      if (a[i - 1] == b[j - 1]) {
        final prior = previous[j - 1];
        final run = _Run(
          i - 1 - prior.length,
          j - 1 - prior.length,
          prior.length + 1,
        );
        current[j] = run;
        if (_isPreferredRun(run, best)) best = run;
      }
    }
    previous = current;
  }
  return best;
}

bool _isPreferredRun(_Run candidate, _Run current) =>
    candidate.length > current.length ||
    (candidate.length == current.length &&
        (candidate.a < current.a ||
            (candidate.a == current.a && candidate.b < current.b)));

int _multisetOverlap(List<String> a, List<String> b) {
  final counts = <String, int>{};
  for (final word in a) {
    counts[word] = (counts[word] ?? 0) + 1;
  }
  var result = 0;
  for (final word in b) {
    final count = counts[word] ?? 0;
    if (count > 0) {
      counts[word] = count - 1;
      result++;
    }
  }
  return result;
}

int _compareVerse(_Verse a, _Verse b) =>
    a.surah != b.surah ? a.surah - b.surah : a.ayah - b.ayah;

int _comparePairs(SimilarAyahPair a, SimilarAyahPair b) {
  final first = _compareKey(a.a, b.a);
  return first != 0 ? first : _compareKey(a.b, b.b);
}

int _compareKey(String a, String b) {
  final aParts = a.split(':');
  final bParts = b.split(':');
  final surahOrder = int.parse(aParts.first).compareTo(int.parse(bParts.first));
  return surahOrder != 0
      ? surahOrder
      : int.parse(aParts.last).compareTo(int.parse(bParts.last));
}

int _min3(int a, int b, int c) => _min(a, _min(b, c));
int _min(int a, int b) => a < b ? a : b;
int _max(int a, int b) => a > b ? a : b;
int _roundRatio(int numerator, int denominator) =>
    (numerator * 1000000 * 2 + denominator) ~/ (denominator * 2);

final class _Verse {
  const _Verse(this.surah, this.ayah, this.tokens);

  final int surah;
  final int ayah;
  final List<String> tokens;

  String get key => '$surah:$ayah';
}

final class _PairKey {
  const _PairKey(this.a, this.b);

  final int a;
  final int b;

  @override
  bool operator ==(Object other) =>
      other is _PairKey && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash(a, b);
}

final class _Run {
  const _Run(this.a, this.b, this.length);

  final int a;
  final int b;
  final int length;
}

final class _TokenSequence {
  _TokenSequence(List<String> tokens) : _tokens = List.unmodifiable(tokens);

  final List<String> _tokens;

  @override
  bool operator ==(Object other) =>
      other is _TokenSequence && _sameTokens(_tokens, other._tokens);

  @override
  int get hashCode => Object.hashAll(_tokens);
}

bool _sameTokens(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

final class _Instrumentation {
  int maxBucketSize = 0;
  int dynamicProgramCount = 0;
}
