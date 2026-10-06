import 'package:equatable/equatable.dart';
import '../../../../core/services/quran_audio_service.dart';

class Surah extends Equatable {
  const Surah({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.ayahCount,
    required this.juz,
    required this.type,
    required this.page,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final int ayahCount;
  final int juz;
  final String type; // 'meccan' | 'medinan'
  final int page;

  bool get isMeccan => type == 'meccan';

  @override
  List<Object?> get props => [id, nameAr, nameEn, ayahCount, juz, type, page];
}

class Ayah extends Equatable {
  const Ayah({
    required this.number,
    required this.surahId,
    required this.text,
    required this.numberInSurah,
    this.juz,
    this.page,
    String? canonicalText,
    this.leadingBasmalah,
  }) : _canonicalText = canonicalText;

  final int number; // global ayah number
  final int surahId;

  /// The numbered ayah text shown and recited. For ayah 1 of every surah
  /// except Al-Fatihah and At-Tawbah, the runtime split removes the leading
  /// basmalah the canonical Tanzil text carries (see `QuranBasmalah`).
  final String text;

  final String? _canonicalText;

  /// The verbatim record from the canonical `quran.json`, never altered.
  String get canonicalText => _canonicalText ?? text;

  /// The basmalah separated from [canonicalText] at runtime, verbatim.
  final String? leadingBasmalah;

  final int numberInSurah;
  final int? juz;
  final int? page;

  String get audioUrl => QuranAudioService.buildUrl(surahId, numberInSurah);

  @override
  List<Object?> get props => [number, surahId, text, numberInSurah];
}

class SurahDetail extends Equatable {
  const SurahDetail({required this.surah, required this.ayahs});

  final Surah surah;
  final List<Ayah> ayahs;

  @override
  List<Object?> get props => [surah, ayahs];
}

class QuranPageDetail extends Equatable {
  const QuranPageDetail({
    required this.pageNumber,
    required this.ayahs,
    required this.surahs,
  });

  final int pageNumber;
  final List<Ayah> ayahs;
  final List<Surah> surahs;

  @override
  List<Object?> get props => [pageNumber, ayahs, surahs];
}
