/// The Quran excerpt printed on every certificate.
///
/// Source: `assets/data/quran.json` (Tanzil, verbatim), surah 17 (Al-Isra),
/// ayah 9: the first seven words of the ayah, copied without any change.
/// `test/features/certificate/certificate_verse_test.dart` checks it still
/// matches the canonical record word for word.
library;

abstract final class CertificateVerse {
  static const surahId = 17;
  static const ayahNumber = 9;
  static const wordCount = 7;

  /// The canonical text, without verse brackets.
  static const text =
      'إِنَّ هَٰذَا ٱلْقُرْءَانَ يَهْدِى لِلَّتِى هِىَ أَقْوَمُ';
}
