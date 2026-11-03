import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/backup/portable_reading_data.dart';
import 'package:talia_quran/core/constants/surah_names.dart';
import 'package:talia_quran/features/quran/data/datasources/quran_local_datasource.dart';
import 'package:talia_quran/features/quran/data/models/ayah_model.dart';
import 'package:talia_quran/features/quran/data/models/surah_model.dart';
import 'package:talia_quran/features/quran/data/services/quran_corpus_bookmark_resolver.dart';

class _Corpus implements QuranLocalDatasource {
  _Corpus(this.ayahs, {this.fail = false});

  final Map<int, List<AyahModel>> ayahs;
  final bool fail;

  @override
  Future<List<AyahModel>> getAyahs(int surahId) async {
    if (fail) throw StateError('corpus unavailable');
    return ayahs[surahId] ?? (throw StateError('missing'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<SurahModel>> getSurahs() => throw UnimplementedError();
}

AyahModel _ayah(int surah, int number, String text) => AyahModel(
  number: surah * 1000 + number,
  surahId: surah,
  text: text,
  numberInSurah: number,
);

void main() {
  final reference = PortableBookmark(
    surahId: 2,
    ayahNumber: 255,
    savedAt: DateTime.utc(2026, 5, 6),
  );

  test(
    'takes name and text from the corpus, time from the reference',
    () async {
      final resolver = QuranCorpusBookmarkResolver(
        _Corpus({
          2: [_ayah(2, 254, 'other'), _ayah(2, 255, 'corpus text')],
        }),
      );

      final entry = await resolver(reference);

      expect(entry, isNotNull);
      expect(entry!.surahId, 2);
      expect(entry.ayahNumber, 255);
      expect(entry.ayahText, 'corpus text');
      expect(entry.surahName, SurahNames.nameAr(2));
      expect(entry.savedAt, DateTime.utc(2026, 5, 6));
      expect(entry.isSynced, isFalse);
    },
  );

  test('an ayah missing from the corpus resolves to null', () async {
    final resolver = QuranCorpusBookmarkResolver(
      _Corpus({
        2: [_ayah(2, 1, 'x')],
      }),
    );

    expect(await resolver(reference), isNull);
  });

  test('an unreadable corpus resolves to null instead of throwing', () async {
    final resolver = QuranCorpusBookmarkResolver(_Corpus(const {}, fail: true));

    expect(await resolver(reference), isNull);
  });
}
