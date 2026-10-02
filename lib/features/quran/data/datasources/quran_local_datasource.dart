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
  QuranLocalDatasourceImpl({Future<String> Function(String path)? loadAsset})
    : _loadAsset = loadAsset ?? rootBundle.loadString;

  final Future<String> Function(String path) _loadAsset;
  List<SurahModel>? _cachedSurahs;
  Map<int, List<AyahModel>>? _cachedAyahs;

  /// Every ayah with its search-normalized text, built once off the UI
  /// isolate: normalizing all 6,236 ayahs per query took ~250 ms (desktop
  /// JIT) on the UI thread. Display text is never altered.
  Future<List<(AyahModel, String)>>? _searchIndex;
  // BUG-007: Page index for O(1) lookup instead of O(n) iteration
  Map<int, List<AyahModel>>? _cachedByPage;
  Map<int, List<AyahModel>>? _cachedByJuz;

  // In-flight loads. The first home load asks for progress, the daily wird
  // page and the ayah of the day at the same time; without sharing one
  // future each caller decoded and parsed the whole corpus separately.
  Future<List<SurahModel>>? _surahsLoad;
  Future<void>? _quranLoad;

  @override
  Future<void> ensureLoaded() async {
    await getSurahs();
    if (_cachedAyahs == null) {
      await _loadQuranData();
    }
  }

  @override
  Future<List<SurahModel>> getSurahs() {
    final cached = _cachedSurahs;
    if (cached != null) return Future.value(cached);
    return _surahsLoad ??= _readSurahs().whenComplete(() => _surahsLoad = null);
  }

  Future<List<SurahModel>> _readSurahs() async {
    try {
      final jsonStr = await _loadAsset('assets/data/surahs.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return _cachedSurahs = list
          .map((e) => SurahModel.fromJson(e as Map<String, dynamic>))
          .toList();
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

  Future<void> _loadQuranData() {
    if (_cachedAyahs != null) return Future.value();
    return _quranLoad ??= _readQuranData().whenComplete(
      () => _quranLoad = null,
    );
  }

  Future<void> _readQuranData() async {
    try {
      final jsonStr = await _loadAsset('assets/data/quran.json');
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

    for (final (ayah, normalizedText) in await _buildSearchIndex()) {
      if (normalizedText.contains(normalizedQuery)) {
        results.add(ayah);
        if (results.length >= 50) return results;
      }
    }

    return results;
  }

  Future<List<(AyahModel, String)>> _buildSearchIndex() {
    final existing = _searchIndex;
    if (existing != null) return existing;
    final ayahs = [for (final list in _cachedAyahs!.values) ...list];
    final index = compute(_normalizeAll, [for (final a in ayahs) a.text]).then(
      (normalized) => [
        for (var i = 0; i < ayahs.length; i++) (ayahs[i], normalized[i]),
      ],
    );
    _searchIndex = index;
    // A failed build is retried on the next search.
    index.catchError((Object _) {
      if (identical(_searchIndex, index)) _searchIndex = null;
      return const <(AyahModel, String)>[];
    });
    return index;
  }

  @override
  Future<Map<int, List<AyahModel>>> getAyahsGroupedByJuz() async {
    final cached = _cachedByJuz;
    if (cached != null) return cached;
    if (_cachedAyahs == null) await _loadQuranData();

    final grouped = <int, List<AyahModel>>{};
    for (final ayahs in _cachedAyahs!.values) {
      for (final ayah in ayahs) {
        final juz = ayah.juz ?? 1;
        grouped.putIfAbsent(juz, () => []).add(ayah);
      }
    }
    return _cachedByJuz = grouped;
  }
}

class QuranParseResult {
  final Map<int, List<AyahModel>> ayahs;
  final Map<int, List<AyahModel>> byPage;
  const QuranParseResult(this.ayahs, this.byPage);
}

List<String> _normalizeAll(List<String> texts) =>
    [for (final text in texts) ArabicNormalizer.normalize(text)];
