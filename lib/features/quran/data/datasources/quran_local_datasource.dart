import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';

abstract class QuranLocalDatasource {
  Future<void> ensureLoaded();
  Future<List<SurahModel>> getSurahs();
  Future<List<AyahModel>> getAyahs(int surahId);
  Future<List<AyahModel>> getAyahsByPage(int pageNumber);
  Future<List<AyahModel>> searchAyahs(String query);
  Future<Map<int, List<AyahModel>>> getAyahsGroupedByJuz();
}

class QuranLocalDatasourceImpl implements QuranLocalDatasource {
  List<SurahModel>? _cachedSurahs;
  Map<int, List<AyahModel>>? _cachedAyahs;
  // BUG-007: Page index for O(1) lookup instead of O(n) iteration
  Map<int, List<AyahModel>>? _cachedByPage;

  @override
  Future<void> ensureLoaded() async {
    await getSurahs();
    if (_cachedAyahs == null) {
      await _loadQuranData();
    }
  }

  @override
  Future<List<SurahModel>> getSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/surahs.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _cachedSurahs = list
          .map((e) => SurahModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return _cachedSurahs!;
    } catch (e) {
      throw const CacheFailure('Failed to load surahs');
    }
  }

  @override
  Future<List<AyahModel>> getAyahs(int surahId) async {
    if (_cachedAyahs == null) {
      await _loadQuranData();
    }

    final ayahs = _cachedAyahs![surahId];
    if (ayahs != null) return ayahs;

    throw const NotFoundFailure();
  }

  @override
  Future<List<AyahModel>> getAyahsByPage(int pageNumber) async {
    if (_cachedByPage == null) {
      await _loadQuranData();
    }
    // BUG-007: O(1) lookup via pre-built page index
    final ayahs = _cachedByPage![pageNumber];
    if (ayahs == null || ayahs.isEmpty) throw const NotFoundFailure();
    return ayahs;
  }

  Future<void> _loadQuranData() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/quran.json');
      final surahs = await getSurahs();

      final result = await compute(QuranLocalDatasourceImpl.parseQuranData, {
        'jsonStr': jsonStr,
        'surahs': surahs,
      });

      _cachedAyahs = result.ayahs;
      _cachedByPage = result.byPage;
    } catch (e) {
      throw const CacheFailure(
        'Failed to load Quran text data (missing or invalid structural '
        'metadata fails closed)',
      );
    }
  }

  /// Parses the bundled corpus deterministically and FAILS CLOSED when any
  /// ayah record is missing required structural metadata (`global`, `page`,
  /// or `juz`). Guessed/fabricated metadata is never produced (V1-M1 gate).
  static QuranParseResult parseQuranData(Map<String, dynamic> params) {
    final String jsonStr = params['jsonStr'];
    final List<SurahModel> surahs = params['surahs'];

    final Map<String, dynamic> data = jsonDecode(jsonStr);
    final cachedAyahs = <int, List<AyahModel>>{};
    final cachedByPage = <int, List<AyahModel>>{};

    for (final surah in surahs) {
      final surahIdStr = surah.id.toString();
      final List<dynamic> verseList = data[surahIdStr] ?? [];

      final parsedAyahs = <AyahModel>[];
      for (int i = 0; i < verseList.length; i++) {
        final verseObj = verseList[i];
        final rawText = verseObj['text'].toString();
        final global = verseObj['global'];
        final juz = verseObj['juz'];
        final page = verseObj['page'];
        if (rawText.isEmpty || global is! int || juz is! int || page is! int) {
          throw StateError(
            'Surah ${surah.id} verse ${verseObj['verse']}: missing required '
            'structural metadata (text/global/page/juz)',
          );
        }
        final ayah = AyahModel(
          number: global,
          surahId: surah.id,
          text: rawText,
          numberInSurah: verseObj['verse'] as int,
          juz: juz,
          page: page,
        );
        parsedAyahs.add(ayah);

        cachedByPage.putIfAbsent(page, () => []).add(ayah);
      }

      cachedAyahs[surah.id] = parsedAyahs;
    }

    return QuranParseResult(cachedAyahs, cachedByPage);
  }

  @override
  Future<List<AyahModel>> searchAyahs(String query) async {
    if (query.trim().isEmpty) return [];
    if (_cachedAyahs == null) await _loadQuranData();

    final normalizedQuery = ArabicNormalizer.normalize(query);
    final results = <AyahModel>[];

    for (final ayahs in _cachedAyahs!.values) {
      for (final ayah in ayahs) {
        final normalizedText = ArabicNormalizer.normalize(ayah.text);
        if (normalizedText.contains(normalizedQuery)) {
          results.add(ayah);
          if (results.length >= 50) return results;
        }
      }
    }

    return results;
  }

  @override
  Future<Map<int, List<AyahModel>>> getAyahsGroupedByJuz() async {
    if (_cachedAyahs == null) await _loadQuranData();

    final grouped = <int, List<AyahModel>>{};
    for (final ayahs in _cachedAyahs!.values) {
      for (final ayah in ayahs) {
        final juz = ayah.juz ?? 1;
        grouped.putIfAbsent(juz, () => []).add(ayah);
      }
    }
    return grouped;
  }
}

class QuranParseResult {
  final Map<int, List<AyahModel>> ayahs;
  final Map<int, List<AyahModel>> byPage;
  const QuranParseResult(this.ayahs, this.byPage);
}
