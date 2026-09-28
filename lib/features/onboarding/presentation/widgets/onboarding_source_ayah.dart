import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/repositories/quran_repository.dart';

/// Renders an ayah loaded verbatim from the canonical Quran source
/// (`assets/data/quran.json` via [QuranRepository]).
///
/// Onboarding previews must never carry Quran text typed into the code
/// (docs/TALIA_ISLAMIC_CONTENT_SOURCES_POLICY.md). The text is passed to
/// [builder] unchanged apart from dropping a stray byte-order mark, so the
/// caller keeps full control of the typography. If the source can't be
/// read, nothing is rendered (fail closed) — never a hardcoded fallback.
class OnboardingSourceAyah extends StatelessWidget {
  const OnboardingSourceAyah({
    super.key,
    required this.surah,
    required this.ayah,
    required this.builder,
  });

  final int surah;
  final int ayah;
  final Widget Function(BuildContext context, String text) builder;

  static final Map<int, Future<List<Ayah>?>> _surahCache = {};

  /// Stable per-ayah futures so rebuilds don't restart the FutureBuilder.
  static final Map<(int, int), Future<String?>> _ayahCache = {};

  @visibleForTesting
  static void resetCacheForTest() {
    _surahCache.clear();
    _ayahCache.clear();
  }

  static Future<List<Ayah>?> _loadSurah(int surahId) {
    return _surahCache.putIfAbsent(surahId, () async {
      if (!getIt.isRegistered<QuranRepository>()) return null;
      final result = await getIt<QuranRepository>().getSurahDetail(surahId);
      return result.fold((_) => null, (detail) => detail.ayahs);
    });
  }

  /// The ayah text as stored in the source, without a leading BOM.
  static Future<String?> load(int surah, int ayah) {
    return _ayahCache.putIfAbsent((surah, ayah), () async {
      final ayahs = await _loadSurah(surah);
      final hit = ayahs?.where((a) => a.numberInSurah == ayah).firstOrNull;
      return hit?.text.replaceAll('﻿', '').trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: load(surah, ayah),
      builder: (context, snapshot) {
        final text = snapshot.data;
        if (text == null || text.isEmpty) return const SizedBox.shrink();
        // Quran text is right-to-left in every UI locale; otherwise the
        // end-of-ayah marker lands on the wrong side in English.
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(builder: (context) => builder(context, text)),
        );
      },
    );
  }
}
