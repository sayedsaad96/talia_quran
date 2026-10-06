import '../utils/arabic_normalizer.dart';

/// The two runtime parts of a canonical ayah text.
final class AyahTextParts {
  const AyahTextParts({required this.body, this.basmalah});

  /// The leading basmalah exactly as written in the canonical text, or null
  /// when this ayah has none to separate.
  final String? basmalah;

  /// The numbered ayah text, an exact substring of the canonical text.
  final String body;
}

/// Separates the basmalah that the Tanzil text carries at the start of
/// ayah 1 of every surah except Al-Fatihah and At-Tawbah.
///
/// `assets/data/quran.json` is the immutable canonical Tanzil text and is
/// never rewritten; this split happens at runtime only, so the UI adapts to
/// the Quran data rather than the data to the UI.
///
/// - Al-Fatihah (1): the basmalah IS ayah 1 in the counting used; untouched.
/// - At-Tawbah (9): has no basmalah.
/// - Basmalahs are not Unicode-identical across surahs, so the prefix is
///   recognised by comparing its normalized form with Al-Fatihah 1:1 from
///   the same corpus, and both parts are returned as verbatim substrings.
/// - Anything unexpected fails safe: nothing is hidden.
abstract final class QuranBasmalah {
  static const int fatihahSurahId = 1;
  static const int tawbahSurahId = 9;
  static const int _basmalahWordCount = 4;
  static final RegExp _word = RegExp(r'\S+');

  static AyahTextParts split({
    required int surahId,
    required int ayahNumber,
    required String canonicalText,
    required String? normalizedReference,
  }) {
    final unsplit = AyahTextParts(body: canonicalText);
    if (ayahNumber != 1 ||
        surahId == fatihahSurahId ||
        surahId == tawbahSurahId ||
        normalizedReference == null ||
        normalizedReference.isEmpty) {
      return unsplit;
    }

    final words = _word
        .allMatches(canonicalText)
        .take(_basmalahWordCount + 1)
        .toList();
    if (words.length <= _basmalahWordCount) return unsplit;

    final basmalah = canonicalText.substring(
      0,
      words[_basmalahWordCount - 1].end,
    );
    if (ArabicNormalizer.normalize(basmalah) != normalizedReference) {
      return unsplit;
    }
    return AyahTextParts(
      basmalah: basmalah,
      body: canonicalText.substring(words[_basmalahWordCount].start),
    );
  }
}
