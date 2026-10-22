import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/similar_ayah/similar_ayah_index_generator.dart';
import 'package:talia_quran/core/quran/quran_basmalah.dart';
import 'package:talia_quran/core/utils/arabic_normalizer.dart';
import 'package:talia_quran/features/quran/data/datasources/quran_local_datasource.dart';
import 'package:talia_quran/features/quran/data/models/surah_model.dart';

import '../../tool/build_similar_ayah_index.dart' as tool;

void main() {
  group('Similar ayah index generator', () {
    test('retains identical short token sequences through exact buckets', () {
      final index = _index([
        _verse(2, 1, 'red blue green'),
        _verse(2, 2, 'red blue green'),
      ]);

      expect(index.pairs, hasLength(1));
      expect(index.pairs.single.toJson(), {
        'a': '2:1',
        'b': '2:2',
        'score': 1.0,
        'sharedRun': 3,
        'kind': 'identical',
      });
    });

    test(
      'finds a four-token run and gives its numeric canonical pair order',
      () {
        final index = _index([
          _verse(10, 1, 'first a b c d last'),
          _verse(2, 9, 'other a b c d end'),
        ]);

        expect(index.pairs.single.a, '2:9');
        expect(index.pairs.single.b, '10:1');
        expect(index.pairs.single.sharedRun, 4);
        expect(index.pairs.single.kind, 'partial');
      },
    );

    test(
      'uses the exact short similarity boundary without rounding admission',
      () {
        final index = _index([
          _verse(2, 1, 'one two three four'),
          _verse(2, 2, 'one two three changed'),
          _verse(2, 3, 'one two changed altered'),
        ]);

        expect(index.pairs.map((pair) => '${pair.a}|${pair.b}'), ['2:1|2:2']);
        expect(index.pairs.single.scoreMicros, 750000);
      },
    );

    test('rounds serialized score only after accepting a long common run', () {
      final index = _index([
        _verse(2, 1, 'one two three four left right'),
        _verse(2, 2, 'one two three four up down'),
      ]);

      expect(index.pairs.single.sharedRun, 4);
      expect(index.pairs.single.scoreMicros, 666667);
      expect(index.pairs.single.toJson()['score'], 0.666667);
    });

    test('matches an exhaustive small oracle after indexed pruning', () {
      final sequences = _allSequences(const ['a', 'b', 'c'], 4);
      final index = _index([
        for (var index = 0; index < sequences.length; index++)
          _verse(2, index + 1, sequences[index].join(' ')),
      ]);
      final actual = index.pairs.map((pair) => '${pair.a}|${pair.b}').toSet();
      final expected = <String>{};
      for (var a = 0; a < sequences.length; a++) {
        for (var b = a + 1; b < sequences.length; b++) {
          if (_oracleAccepts(sequences[a], sequences[b])) {
            expected.add('2:${a + 1}|2:${b + 1}');
          }
        }
      }

      expect(actual, expected);
    });

    test(
      'is deterministic, IDs-only, immutable, and offers adjacency lookup',
      () {
        final input = [
          _verse(2, 8, 'alpha beta gamma delta'),
          _verse(2, 9, 'alpha beta gamma delta'),
        ];
        final first = _index(input);
        final second = _index(input);

        expect(first.encode(), second.encode());
        expect(first.encode(), isNot(contains(RegExp(r'[\u0600-\u06ff]'))));
        expect(first.neighborsOf('2:8'), hasLength(1));
        expect(first.neighborsOf('2:999'), isEmpty);
        expect(
          () => first.pairs.add(first.pairs.single),
          throwsUnsupportedError,
        );
        expect(
          () => first.provenance['extra'] = 'value',
          throwsUnsupportedError,
        );
      },
    );

    test('reports candidate instrumentation without changing draft JSON', () {
      final index = _index([
        _verse(2, 1, 'same one two three four'),
        _verse(2, 2, 'same one two three four'),
        _verse(2, 3, 'same one two three four'),
      ]);

      expect(index.stats.maxBucketSize, greaterThanOrEqualTo(3));
      expect(index.stats.candidateCount, 3);
      expect(index.stats.dynamicProgramCount, 3);
      expect(index.encode(), isNot(contains('candidateCount')));
      expect(index.encode(), isNot(contains('elapsed')));
    });

    test('rejects duplicate IDs and missing canonical reference', () {
      expect(
        () => buildSimilarAyahIndex(
          verses: [_verse(2, 1, 'one'), _verse(2, 1, 'two')],
          provenance: const {},
        ),
        throwsArgumentError,
      );
      expect(
        () => buildSimilarAyahIndex(
          verses: [_verse(1, 2, 'one')],
          provenance: const {},
        ),
        throwsArgumentError,
      );
      expect(
        () => buildSimilarAyahIndex(
          verses: [_verse(1, 1, 'reference'), _verse(1, 8, 'too far')],
          provenance: const {},
        ),
        throwsArgumentError,
      );
    });
  });

  group('read-only canonical corpus structure', () {
    test(
      'contains the complete, numbered source shape required by the tool',
      () {
        final decoded = jsonDecode(
          File('assets/data/quran.json').readAsStringSync(),
        );
        final corpus = decoded as Map<String, dynamic>;
        expect(corpus.keys, hasLength(114));
        final reference = ArabicNormalizer.normalize(
          ((corpus['1'] as List<dynamic>).first as Map<String, dynamic>)['text']
              as String,
        );

        var total = 0;
        for (var surah = 1; surah <= 114; surah++) {
          final verses = corpus['$surah'] as List<dynamic>;
          for (var index = 0; index < verses.length; index++) {
            final verse = verses[index] as Map<String, dynamic>;
            expect(verse['chapter'], surah);
            expect(verse['verse'], index + 1);
            expect(verse['text'], isA<String>());
            expect((verse['text'] as String).isNotEmpty, isTrue);
            expect(
              QuranBasmalah.split(
                surahId: surah,
                ayahNumber: index + 1,
                canonicalText: verse['text'] as String,
                normalizedReference: reference,
              ).body,
              isNotEmpty,
            );
            total++;
          }
        }
        expect(total, 6236);
      },
    );
  });

  test(
    'generator strips a corpus-derived basmalah before candidate matching',
    () {
      final corpus =
          jsonDecode(File('assets/data/quran.json').readAsStringSync())
              as Map<String, dynamic>;
      final reference =
          ((corpus['1'] as List<dynamic>).first as Map<String, dynamic>)['text']
              as String;
      final index = buildSimilarAyahIndex(
        verses: [
          _verse(1, 1, reference),
          _verse(2, 1, '$reference north east south west'),
          _verse(3, 1, '$reference copper silver gold bronze'),
        ],
        provenance: const {},
      );

      expect(index.pairs, isEmpty);
    },
  );

  test(
    'generator body derivation matches the runtime datasource for all ayahs',
    () {
      final jsonText = File('assets/data/quran.json').readAsStringSync();
      final corpus = jsonDecode(jsonText) as Map<String, dynamic>;
      final surahs =
          (jsonDecode(File('assets/data/surahs.json').readAsStringSync())
                  as List<dynamic>)
              .map(
                (value) => SurahModel.fromJson(value as Map<String, dynamic>),
              )
              .toList(growable: false);
      final parsed = QuranLocalDatasourceImpl.parseQuranData({
        'jsonStr': jsonText,
        'surahs': surahs,
      });
      final reference = ArabicNormalizer.normalize(
        ((corpus['1'] as List<dynamic>).first as Map<String, dynamic>)['text']
            as String,
      );

      var splitCount = 0;
      for (var surah = 1; surah <= 114; surah++) {
        final rawVerses = corpus['$surah'] as List<dynamic>;
        final runtimeVerses = parsed.ayahs[surah]!;
        expect(runtimeVerses, hasLength(rawVerses.length));
        for (var index = 0; index < rawVerses.length; index++) {
          final raw = rawVerses[index] as Map<String, dynamic>;
          final runtime = runtimeVerses[index];
          final parts = QuranBasmalah.split(
            surahId: surah,
            ayahNumber: index + 1,
            canonicalText: raw['text'] as String,
            normalizedReference: reference,
          );
          expect(runtime.text, parts.body);
          expect(runtime.canonicalText, raw['text']);
          expect(runtime.leadingBasmalah, parts.basmalah);
          if (parts.basmalah != null) splitCount++;
        }
      }
      expect(splitCount, 112);
      expect(parsed.ayahs[1]!.first.leadingBasmalah, isNull);
      expect(parsed.ayahs[9]!.first.leadingBasmalah, isNull);
    },
  );

  group('draft CLI contract', () {
    test(
      'requires one explicit output outside protected source directories',
      () {
        expect(
          () => tool.parseSimilarAyahDraftOutput(const []),
          throwsArgumentError,
        );
        expect(
          () => tool.parseSimilarAyahDraftOutput(['--output']),
          throwsArgumentError,
        );
        expect(
          () => tool.parseSimilarAyahDraftOutput([
            '--output',
            'assets/data/../data/similar_ayah_index.json',
          ]),
          throwsArgumentError,
        );
        expect(
          () => tool.parseSimilarAyahDraftOutput([
            '--output',
            'lib/../lib/generated_draft.json',
          ]),
          throwsArgumentError,
        );
        expect(
          tool.parseSimilarAyahDraftOutput([
            '--output',
            'build/similar_ayah_drafts/similar_ayah_candidates.json',
          ]),
          'build/similar_ayah_drafts/similar_ayah_candidates.json',
        );
      },
    );

    test('fails closed when the corpus input has an unexpected shape', () {
      expect(
        () => tool.decodeSimilarAyahCorpus(
          utf8.encode('{"1":[]}'),
          utf8.encode('[]'),
        ),
        throwsFormatException,
      );
    });
  });
}

SimilarAyahIndex _index(List<SimilarAyahSourceVerse> verses) =>
    buildSimilarAyahIndex(
      verses: [_verse(1, 1, 'reference'), ...verses],
      provenance: const {'generatorSha256': 'test', 'tokenPolicy': 'test'},
    );

SimilarAyahSourceVerse _verse(int surah, int ayah, String text) =>
    SimilarAyahSourceVerse(
      surahId: surah,
      ayahNumber: ayah,
      canonicalText: text,
    );

List<List<String>> _allSequences(List<String> alphabet, int length) {
  if (length == 0) return [[]];
  return [
    for (final prefix in _allSequences(alphabet, length - 1))
      for (final token in alphabet) [...prefix, token],
  ];
}

bool _oracleAccepts(List<String> a, List<String> b) {
  final distance = _oracleDistance(a, b);
  final run = _oracleLongestRun(a, b);
  return distance == 0 || run >= 4 || 4 * distance <= 4;
}

int _oracleDistance(List<String> a, List<String> b) {
  var previous = List<int>.generate(b.length + 1, (index) => index);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      current[j] = a[i - 1] == b[j - 1]
          ? previous[j - 1]
          : 1 + _oracleMin(previous[j], current[j - 1], previous[j - 1]);
    }
    previous = current;
  }
  return previous.last;
}

int _oracleLongestRun(List<String> a, List<String> b) {
  var best = 0;
  for (var startA = 0; startA < a.length; startA++) {
    for (var startB = 0; startB < b.length; startB++) {
      var length = 0;
      while (startA + length < a.length &&
          startB + length < b.length &&
          a[startA + length] == b[startB + length]) {
        length++;
      }
      if (length > best) best = length;
    }
  }
  return best;
}

int _oracleMin(int a, int b, int c) =>
    a < b ? (a < c ? a : c) : (b < c ? b : c);
