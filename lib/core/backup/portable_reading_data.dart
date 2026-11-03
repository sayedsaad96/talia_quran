import '../constants/surah_names.dart';

/// Raised when portable reading data is invalid, unreadable, or requested for
/// an account that is not the active one. Export callers must treat it as a
/// failure, never as an empty result.
class PortableReadingDataException implements Exception {
  const PortableReadingDataException(this.message);

  final String message;

  @override
  String toString() => 'PortableReadingDataException: $message';
}

/// A bookmark reduced to a canonical Quran reference.
///
/// It deliberately carries no surah name, ayah text, sync flags, revision or
/// owner id: those are re-derived at display time, so a foreign file can never
/// inject Quran text or claim an account's data.
class PortableBookmark {
  PortableBookmark({
    required this.surahId,
    required this.ayahNumber,
    required DateTime savedAt,
  }) : savedAt = savedAt.toUtc() {
    if (surahId < 1 || surahId > 114) {
      throw PortableReadingDataException('surah $surahId out of range');
    }
    if (ayahNumber < 1 || ayahNumber > SurahNames.ayahCount(surahId)) {
      throw PortableReadingDataException(
        'ayah $surahId:$ayahNumber out of range',
      );
    }
  }

  factory PortableBookmark.fromJson(Map<String, dynamic> json) {
    final surahId = json['surahId'];
    final ayahNumber = json['ayahNumber'];
    final savedAt = json['savedAt'];
    if (surahId is! int || ayahNumber is! int || savedAt is! String) {
      throw const PortableReadingDataException('malformed bookmark entry');
    }
    final parsed = DateTime.tryParse(savedAt);
    if (parsed == null) {
      throw const PortableReadingDataException('malformed bookmark timestamp');
    }
    return PortableBookmark(
      surahId: surahId,
      ayahNumber: ayahNumber,
      savedAt: parsed,
    );
  }

  final int surahId;
  final int ayahNumber;
  final DateTime savedAt;

  /// Arabic surah name derived from the reference, never read from a file.
  String get surahNameAr => SurahNames.nameAr(surahId);

  Map<String, dynamic> toJson() => {
    'surahId': surahId,
    'ayahNumber': ayahNumber,
    'savedAt': savedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is PortableBookmark &&
      other.surahId == surahId &&
      other.ayahNumber == ayahNumber &&
      other.savedAt == savedAt;

  @override
  int get hashCode => Object.hash(surahId, ayahNumber, savedAt);
}

/// The ordinary Quran reader position: a mushaf page in 1..604.
///
/// Khatmah and memorization positions have their own authority and are never
/// represented here.
class QuranReadingCheckpoint {
  static const int firstPage = 1;
  static const int lastPage = 604;

  QuranReadingCheckpoint({required this.pageNumber}) {
    if (pageNumber < firstPage || pageNumber > lastPage) {
      throw PortableReadingDataException('page $pageNumber out of range');
    }
  }

  factory QuranReadingCheckpoint.fromJson(Map<String, dynamic> json) {
    final page = json['pageNumber'];
    if (page is! int) {
      throw const PortableReadingDataException('malformed reading checkpoint');
    }
    return QuranReadingCheckpoint(pageNumber: page);
  }

  final int pageNumber;

  Map<String, dynamic> toJson() => {'pageNumber': pageNumber};

  @override
  bool operator ==(Object other) =>
      other is QuranReadingCheckpoint && other.pageNumber == pageNumber;

  @override
  int get hashCode => pageNumber.hashCode;
}
