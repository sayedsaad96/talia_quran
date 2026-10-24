import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/quran_media_metadata.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  const ayah = Ayah(number: 1, surahId: 1, text: '', numberInSurah: 1);

  test('uses canonical localized names and stable IDs', () {
    var locale = const Locale('ar');
    final metadata = QuranMediaMetadata(locale: () => locale);
    final art = Uri.file('/cover.png');
    metadata.artworkUri = art;
    final arabic = metadata.build([ayah], QuranReciter.alafasy).single;
    expect(arabic.id, '1_1');
    expect(
      arabic.title,
      lookupAppLocalizations(locale).surahAyahFormat('الفاتحة', 1),
    );
    expect(arabic.artist, QuranReciter.alafasy.nameAr);
    expect(arabic.album, lookupAppLocalizations(locale).quran);
    expect(arabic.artUri, art);
    expect(metadata.channelName, lookupAppLocalizations(locale).quran);

    locale = const Locale('en');
    final english = metadata.build([ayah], QuranReciter.alafasy).single;
    expect(
      english.title,
      lookupAppLocalizations(locale).surahAyahFormat('Al-Fatihah', 1),
    );
    expect(english.artist, QuranReciter.alafasy.nameEn);
    expect(metadata.channelName, lookupAppLocalizations(locale).quran);
  });

  test('defaults to Arabic and supports no artwork', () {
    final item = QuranMediaMetadata().build([
      ayah,
    ], QuranReciter.alafasy).single;
    expect(item.artist, QuranReciter.alafasy.nameAr);
    expect(item.artUri, isNull);
  });
}
