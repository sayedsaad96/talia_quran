import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/approved_similar_ayah_candidate_source.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

void main() {
  late Map<String, Object?> index;
  late Map<String, Object?> entry;
  late _Quran quran;
  late List<String> reads;
  final corpusSha = 'a' * 64;
  setUp(() {
    quran = _Quran();
    reads = [];
    index = {
      'version': 1,
      'provenance': {
        for (final key in [
          'corpusSha256',
          'normalizerSha256',
          'splitterSha256',
          'generatorSha256',
          'recitablePredicateSha256',
          'surahMetadataSha256',
        ])
          key: corpusSha,
        'tokenPolicy': 'normalized-recitable-whitespace-v1',
      },
      'pairs': [pair('2:1', '2:2')],
    };
    entry = {
      'path': ApprovedSimilarAyahCandidateSource.indexPath,
      'role': 'derived',
      'reviewStatus': 'approved',
      'generatorVersion': 1,
      'sourceCorpusSha256': corpusSha,
      'reviewedBy': 'Reviewer - scholar',
      'reviewedAt': '2026-10-20',
      'reviewSetId': 'similar-v1-reviewed-1',
    };
  });

  ApprovedSimilarAyahCandidateSource source({
    bool badDigest = false,
  }) => ApprovedSimilarAyahCandidateSource(
    quran: quran,
    readBytes: (path) async {
      reads.add(path);
      final bytes = utf8.encode(jsonEncode(index));
      if (path == ApprovedSimilarAyahCandidateSource.indexPath) return bytes;
      return utf8.encode(
        jsonEncode({
          'items': [
            {'path': 'assets/data/quran.json', 'sha256': corpusSha},
            {
              ...entry,
              'sha256': badDigest ? '0' * 64 : sha256.convert(bytes).toString(),
            },
          ],
        }),
      );
    },
  );

  test('resolves all symmetric neighbors to original runtime bodies', () async {
    final loaded = source();
    final alternatives = await loaded.loadCandidates('2:1');
    expect(alternatives!.map((item) => item.key), ['2:2']);
    expect(alternatives.single.text, 'original body 2');
    expect((await loaded.loadCandidates('2:2'))!.single.key, '2:1');
    expect(
      reads.where(
        (path) => path == ApprovedSimilarAyahCandidateSource.indexPath,
      ),
      hasLength(1),
    );
    expect(() => alternatives.clear(), throwsUnsupportedError);
  });

  test('pending approval does not read an index or Quran bodies', () async {
    entry['reviewStatus'] = 'pending_human_review';
    expect(await source().loadCandidates('2:1'), isNull);
    expect(reads, [ApprovedSimilarAyahCandidateSource.manifestPath]);
    expect(quran.calls, 0);
  });

  test('approved status without complete review evidence fails closed', () async {
    final good = Map<String, Object?>.of(entry);
    for (final bad in <Map<String, Object?>>[
      {'reviewedBy': null},
      {'reviewedBy': '  '},
      {'reviewedAt': null},
      {'reviewedAt': 'yesterday'},
      {'reviewSetId': ''},
      {'reviewSetId': null},
    ]) {
      entry
        ..clear()
        ..addAll(good)
        ..addAll(bad);
      expect(await source().loadCandidates('2:1'), isNull, reason: '$bad');
    }
    expect(quran.calls, 0);
  });

  test('real bundled manifest leaves unapproved feature unavailable', () async {
    final loaded = ApprovedSimilarAyahCandidateSource(
      quran: quran,
      readBytes: (path) async {
        reads.add(path);
        return File(path).readAsBytes();
      },
    );
    expect(await loaded.loadCandidates('2:1'), isNull);
    expect(reads, [ApprovedSimilarAyahCandidateSource.manifestPath]);
    expect(quran.calls, 0);
  });

  test('digest and canonical source mismatch fail closed', () async {
    expect(await source(badDigest: true).loadCandidates('2:1'), isNull);
    entry['sourceCorpusSha256'] = 'b' * 64;
    expect(await source().loadCandidates('2:1'), isNull);
    expect(quran.calls, 0);
  });

  test(
    'invalid, duplicate, or text-bearing relations fail before corpus reads',
    () async {
      for (final relations in [
        [pair('2:1', '2:287')],
        [pair('2:1', '2:1')],
        [pair('02:1', '2:2')],
        [pair('2:1', '2:2'), pair('2:1', '2:2')],
        [
          {...pair('2:1', '2:2'), 'text': 'not allowed'},
        ],
        [
          {...pair('2:1', '2:2'), 'score': '1.000000'},
        ],
      ]) {
        index['pairs'] = relations;
        expect(await source().loadCandidates('2:1'), isNull);
      }
      expect(quran.calls, 0);
    },
  );

  test(
    'one missing neighbor discards every partially resolved candidate',
    () async {
      index['pairs'] = [pair('2:1', '2:2'), pair('2:1', '2:3')];
      quran.omitLast = true;
      expect(await source().loadCandidates('2:1'), isNull);
    },
  );
}

Map<String, Object> pair(String a, String b) => {
  'a': a,
  'b': b,
  'score': 1.0,
  'sharedRun': 4,
  'kind': 'identical',
};

final class _Quran implements QuranRepository {
  int calls = 0;
  bool omitLast = false;
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int id) async {
    calls++;
    return Right(
      SurahDetail(
        surah: Surah(
          id: id,
          nameAr: 'x',
          nameEn: 'x',
          ayahCount: 3,
          juz: 1,
          type: 'x',
          page: 1,
        ),
        ayahs: [
          for (var number = 1; number <= (omitLast ? 2 : 3); number++)
            Ayah(
              number: number,
              surahId: id,
              numberInSurah: number,
              text: 'original body $number',
            ),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
