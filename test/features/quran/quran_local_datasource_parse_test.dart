import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/data/datasources/quran_local_datasource.dart';
import 'package:talia_quran/features/quran/data/models/surah_model.dart';

/// V1-M1 exactness + fail-closed gates for the deterministic corpus parser.
void main() {
  late final String jsonStr;
  late final List<dynamic> surahsJson;

  setUpAll(() {
    jsonStr = File('assets/data/quran.json').readAsStringSync();
    surahsJson =
        jsonDecode(File('assets/data/surahs.json').readAsStringSync())
            as List<dynamic>;
  });

  SurahModel surahModel(int id) {
    final json =
        surahsJson.singleWhere((s) => s['id'] == id) as Map<String, dynamic>;
    return SurahModel.fromJson(json);
  }

  group('parseQuranData — sacred-text exactness', () {
    test('surah 2, 9, 95 and 97 fallback fixtures are exact literals', () {
      const expectedAyah1 = <int, String>{
        2: 'الٓمٓ',
        9: 'بَرَآءَةٌۭ مِّنَ ٱللَّهِ وَرَسُولِهِۦٓ إِلَى ٱلَّذِينَ عَٰهَدتُّم مِّنَ ٱلْمُشْرِكِينَ',
        95: 'وَٱلتِّينِ وَٱلزَّيْتُونِ',
        97: 'إِنَّآ أَنزَلْنَٰهُ فِى لَيْلَةِ ٱلْقَدْرِ',
      };
      final result = QuranLocalDatasourceImpl.parseQuranData({
        'jsonStr': jsonStr,
        'surahs': expectedAyah1.keys.map(surahModel).toList(),
      });

      for (final entry in expectedAyah1.entries) {
        expect(
          result.ayahs[entry.key]!.first.text,
          entry.value,
          reason: 'Fallback corpus drifted at Surah ${entry.key}, ayah 1',
        );
      }
    });

    test('preserves every input code point including BOM and whitespace', () {
      const sacredInput = '\uFEFF  قُلْ\nهُوَ  ';
      final fixture = <String, dynamic>{
        '112': [
          {
            'chapter': 112,
            'verse': 1,
            'text': sacredInput,
            'global': 6222,
            'page': 604,
            'juz': 30,
          },
        ],
      };

      final result = QuranLocalDatasourceImpl.parseQuranData({
        'jsonStr': jsonEncode(fixture),
        'surahs': [surahModel(112)],
      });

      expect(result.ayahs[112]!.single.text, sacredInput);
    });

    test(
      'surah 2, 9, 95 and 97 texts pass through character-for-character',
      () {
        final result = QuranLocalDatasourceImpl.parseQuranData({
          'jsonStr': jsonStr,
          'surahs': [
            surahModel(2),
            surahModel(9),
            surahModel(95),
            surahModel(97),
          ],
        });

        for (final surahId in [2, 9, 95, 97]) {
          final rawAyahs = (jsonDecode(jsonStr)[surahId.toString()] as List)
              .cast<Map<String, dynamic>>();
          final parsed = result.ayahs[surahId]!;
          expect(parsed, hasLength(rawAyahs.length));
          for (var i = 0; i < rawAyahs.length; i++) {
            final expected = rawAyahs[i]['text']!.toString();
            expect(
              parsed[i].text,
              expected,
              reason: 'Surah $surahId ayah ${i + 1} mutated in parse',
            );
            expect(parsed[i].number, rawAyahs[i]['global']);
            expect(parsed[i].page, rawAyahs[i]['page']);
            expect(parsed[i].juz, rawAyahs[i]['juz']);
          }
        }
      },
    );
  });

  group('parseQuranData — fail-closed structural metadata', () {
    test('rejects a record missing the global number', () {
      final broken = <String, dynamic>{
        '112': [
          {'chapter': 112, 'verse': 1, 'text': 'قُلْ هُوَ ٱللَّهُ أَحَدٌ'},
        ],
      };
      expect(
        () => QuranLocalDatasourceImpl.parseQuranData({
          'jsonStr': jsonEncode(broken),
          'surahs': [surahModel(112)],
        }),
        throwsStateError,
      );
    });

    test('rejects a record missing the page number', () {
      final broken = <String, dynamic>{
        '112': [
          {
            'chapter': 112,
            'verse': 1,
            'text': 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
            'global': 6222,
            'juz': 30,
          },
        ],
      };
      expect(
        () => QuranLocalDatasourceImpl.parseQuranData({
          'jsonStr': jsonEncode(broken),
          'surahs': [surahModel(112)],
        }),
        throwsStateError,
      );
    });

    test('rejects a record missing the juz number', () {
      final broken = <String, dynamic>{
        '112': [
          {
            'chapter': 112,
            'verse': 1,
            'text': 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
            'global': 6222,
            'page': 604,
          },
        ],
      };
      expect(
        () => QuranLocalDatasourceImpl.parseQuranData({
          'jsonStr': jsonEncode(broken),
          'surahs': [surahModel(112)],
        }),
        throwsStateError,
      );
    });

    test('accepts complete records', () {
      final ok = <String, dynamic>{
        '112': [
          {
            'chapter': 112,
            'verse': 1,
            'text': 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
            'global': 6222,
            'page': 604,
            'juz': 30,
          },
        ],
      };
      final result = QuranLocalDatasourceImpl.parseQuranData({
        'jsonStr': jsonEncode(ok),
        'surahs': [surahModel(112)],
      });
      expect(result.ayahs[112]!.single.text, 'قُلْ هُوَ ٱللَّهُ أَحَدٌ');
      expect(result.byPage[604], hasLength(1));
    });
  });
}
