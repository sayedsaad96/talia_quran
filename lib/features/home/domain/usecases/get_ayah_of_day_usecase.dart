import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../quran/domain/repositories/quran_repository.dart';
import '../entities/ayah_of_day.dart';

class GetAyahOfDayUsecase {
  GetAyahOfDayUsecase(
    this._repository, {
    DateTime Function()? now,
    this.assetPath = 'assets/data/daily_ayahs.json',
  }) : _now = now ?? DateTime.now;

  final QuranRepository _repository;
  final DateTime Function() _now;
  final String assetPath;

  Future<AyahOfDay?> call() async {
    final refs = await _loadRefs();
    if (refs.isEmpty) return null;
    final ref = refs[_indexFor(_now(), refs.length)];
    final detail = await _repository.getSurahDetail(ref.surahId);
    return detail.fold((_) => null, (surah) {
      for (final ayah in surah.ayahs) {
        if (ayah.numberInSurah == ref.ayahNumber) {
          return AyahOfDay(
            surahId: ref.surahId,
            ayahNumber: ref.ayahNumber,
            text: ayah.text,
            surahNameAr: surah.surah.nameAr,
            surahNameEn: surah.surah.nameEn,
            pageNumber: ayah.page ?? surah.surah.page,
          );
        }
      }
      return null;
    });
  }

  /// Advances by exactly one reference per calendar day so the full list is
  /// visited before repeating. A millisecond seed would step by 86_400_000 and
  /// collapse the cycle to `length / gcd(86_400_000 % length, length)` entries.
  static int _indexFor(DateTime day, int length) {
    final ordinal = DateTime(day.year, day.month, day.day)
        .difference(DateTime(1970))
        .inDays;
    return ordinal.remainder(length).abs();
  }

  Future<List<DailyAyahRef>> _loadRefs() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>)
            DailyAyahRef(
              surahId: item['surahId'] as int,
              ayahNumber: item['ayahNumber'] as int,
            ),
      ];
    } catch (_) {
      return const [
        DailyAyahRef(surahId: 1, ayahNumber: 1),
        DailyAyahRef(surahId: 2, ayahNumber: 255),
        DailyAyahRef(surahId: 18, ayahNumber: 10),
        DailyAyahRef(surahId: 36, ayahNumber: 1),
        DailyAyahRef(surahId: 112, ayahNumber: 1),
      ];
    }
  }
}
