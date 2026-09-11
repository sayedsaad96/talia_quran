import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../quran/domain/repositories/quran_repository.dart';
import '../entities/ayah_of_day.dart';
import '../services/daily_ayah_context_resolver.dart';

class GetAyahOfDayUsecase {
  GetAyahOfDayUsecase(
    this._repository, {
    DateTime Function()? now,
    this.assetPath = 'assets/data/daily_ayahs.json',
    DailyAyahContextResolver? contextResolver,
  }) : _now = now ?? DateTime.now,
       _contextResolver = contextResolver ?? const DailyAyahContextResolver();

  final QuranRepository _repository;
  final DateTime Function() _now;
  final String assetPath;
  final DailyAyahContextResolver _contextResolver;

  Future<AyahOfDay?> call({DateTime? date, String? userGoal}) async {
    final refs = await _loadRefs();
    if (refs.isEmpty) return null;
    final day = date ?? _now();
    var context = _contextResolver.resolve(date: day, userGoal: userGoal);
    var candidates = refs
        .where((ref) => ref.contexts.contains(context))
        .toList();
    if (candidates.isEmpty) {
      context = DailyAyahContext.general;
      candidates = refs.where((ref) => ref.contexts.isEmpty).toList();
    }
    if (candidates.isEmpty) candidates = refs;
    final ref = candidates[_indexFor(day, candidates.length)];
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
            context: context,
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
    final ordinal = DateTime(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime(1970)).inDays;
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
              contexts: _contextsFrom(item['tags']),
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

  Set<DailyAyahContext> _contextsFrom(Object? value) {
    if (value is! List<dynamic>) return const <DailyAyahContext>{};
    return {
      for (final item in value)
        if (item is String) ?DailyAyahContext.fromWireName(item),
    };
  }
}
