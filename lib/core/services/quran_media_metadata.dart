import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';

import '../../features/quran/domain/entities/quran_entities.dart';
import '../constants/surah_names.dart';
import '../l10n/app_localizations.dart';
import 'quran_reciter.dart';

/// Localized platform metadata for the existing continuous Quran audio queue.
class QuranMediaMetadata {
  QuranMediaMetadata({Locale Function()? locale, this.artworkUri})
    : _locale = locale ?? _arabicLocale;

  final Locale Function() _locale;

  /// The persistent local artwork URI, when available.
  Uri? artworkUri;

  String get channelName => lookupAppLocalizations(_locale()).quran;

  List<MediaItem> build(List<Ayah> ayahs, QuranReciter reciter) {
    final locale = _locale();
    final l10n = lookupAppLocalizations(locale);
    final arabic = locale.languageCode == 'ar';
    final artist = arabic ? reciter.nameAr : reciter.nameEn;
    return List<MediaItem>.unmodifiable(
      ayahs.map((ayah) {
        final surahName = arabic
            ? SurahNames.nameAr(ayah.surahId)
            : SurahNames.nameEn(ayah.surahId);
        return MediaItem(
          id: '${ayah.surahId}_${ayah.numberInSurah}',
          title: l10n.surahAyahFormat(surahName, ayah.numberInSurah),
          artist: artist,
          album: l10n.quran,
          artUri: artworkUri,
        );
      }),
    );
  }

  static Locale _arabicLocale() => const Locale('ar');
}
