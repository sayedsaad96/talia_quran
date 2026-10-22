import 'package:characters/characters.dart';

import '../../../../core/constants/surah_names.dart';

abstract final class AyahNotePolicy {
  /// Longest note, in user-perceived characters (graphemes).
  static const maxBodyLength = 1000;

  static void checkReference(int surahId, int ayahNumber) {
    if (surahId < 1 ||
        surahId > 114 ||
        ayahNumber < 1 ||
        ayahNumber > SurahNames.ayahCount(surahId)) {
      throw const FormatException('Invalid ayah reference');
    }
  }

  static void checkBody(String body) {
    if (body.trim().isEmpty || body.characters.length > maxBodyLength) {
      throw const FormatException('Invalid note body');
    }
  }

  static void checkDates(DateTime createdAt, DateTime updatedAt) {
    if (updatedAt.isBefore(createdAt)) {
      throw const FormatException('Invalid note timestamps');
    }
  }
}
