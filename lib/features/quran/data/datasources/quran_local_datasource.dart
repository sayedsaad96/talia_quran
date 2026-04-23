import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../../core/error/app_failure.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';

abstract class QuranLocalDatasource {
  Future<List<SurahModel>> getSurahs();
  Future<List<AyahModel>> getAyahs(int surahId);
  Future<List<AyahModel>> getAyahsByPage(int pageNumber);
}

class QuranLocalDatasourceImpl implements QuranLocalDatasource {
  List<SurahModel>? _cachedSurahs;
  Map<int, List<AyahModel>>? _cachedAyahs;

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
     if (_cachedAyahs == null) {
      await _loadQuranData();
    }
    final allAyahs = _cachedAyahs!.values.expand((element) => element).toList();
    final pageAyahs = allAyahs.where((a) => a.page == pageNumber).toList();
    if (pageAyahs.isEmpty) throw const NotFoundFailure();
    return pageAyahs;
  }

  Future<void> _loadQuranData() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/quran.json');
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final surahs = await getSurahs();
      
      _cachedAyahs = {};
      int globalOffset = 0;
      
      for (final surah in surahs) {
        final surahIdStr = surah.id.toString();
        final List<dynamic> verseList = data[surahIdStr] ?? [];
        
        final parsedAyahs = <AyahModel>[];
        for (int i = 0; i < verseList.length; i++) {
          final verseObj = verseList[i];
          parsedAyahs.add(
            AyahModel(
               number: verseObj['global'] ?? (globalOffset + i + 1),
               surahId: surah.id,
               text: verseObj['text'].toString(),
               numberInSurah: verseObj['verse'] as int,
               juz: verseObj['juz'] as int? ?? surah.juz,
               page: verseObj['page'] as int? ?? (surah.page + (i ~/ 15)),
            ),
          );
        }
        
        _cachedAyahs![surah.id] = parsedAyahs;
        globalOffset += surah.ayahCount;
      }
    } catch (e) {
      throw const CacheFailure('Failed to load Quran text data');
    }
  }
}
