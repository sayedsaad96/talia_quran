import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';

abstract class QuranLocalDatasource {
  Future<List<SurahModel>> getSurahs();
  Future<List<AyahModel>> getAyahs(int surahId);
  Future<List<AyahModel>> getAyahsByPage(int pageNumber);
  Future<List<AyahModel>> searchAyahs(String query);
}

class QuranLocalDatasourceImpl implements QuranLocalDatasource {
  List<SurahModel>? _cachedSurahs;
  Map<int, List<AyahModel>>? _cachedAyahs;
  // BUG-007: Page index for O(1) lookup instead of O(n) iteration
  Map<int, List<AyahModel>>? _cachedByPage;

  @override
  Future<List<SurahModel>> getSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/surahs.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _cachedSurahs =
          list.map((e) => SurahModel.fromJson(e as Map<String, dynamic>)).toList();
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
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final surahs = await getSurahs();
      
      _cachedAyahs = {};
      _cachedByPage = {}; // BUG-007: Initialize page index
      int globalOffset = 0;
      
      for (final surah in surahs) {
        final surahIdStr = surah.id.toString();
        final List<dynamic> verseList = data[surahIdStr] ?? [];
        
        final parsedAyahs = <AyahModel>[];
        for (int i = 0; i < verseList.length; i++) {
          final verseObj = verseList[i];
          // BUG-001: Remove BOM character (\uFEFF) from ayah text
          final rawText = verseObj['text'].toString().replaceAll('\uFEFF', '');
          final ayah = AyahModel(
             number: verseObj['global'] ?? (globalOffset + i + 1),
             surahId: surah.id,
             text: rawText,
             numberInSurah: verseObj['verse'] as int,
             juz: verseObj['juz'] as int? ?? surah.juz,
             page: verseObj['page'] as int? ?? (surah.page + (i ~/ 15)),
          );
          parsedAyahs.add(ayah);
          
          // BUG-007: Build page index during load
          final pageNum = ayah.page ?? 1;
          _cachedByPage!.putIfAbsent(pageNum, () => []).add(ayah);
        }
        
        _cachedAyahs![surah.id] = parsedAyahs;
        globalOffset += surah.ayahCount;
      }
    } catch (e) {
      throw const CacheFailure('Failed to load Quran text data');
    }
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
}
