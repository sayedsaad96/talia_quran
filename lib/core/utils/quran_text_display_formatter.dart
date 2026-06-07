class QuranTextDisplayFormatter {
  static final RegExp _whitespaceRegex = RegExp(
    r'[\s\u200B\u200C\u200D\uFEFF]+',
  );

  static final RegExp _trailingAyahNumberRegex = RegExp(
    r'[\s\u200E\u200F\u061C]*(?:[۝۞۩﴿﴾()\[\]{}⟦⟧\u06DD\u06DE\u06E9]+[\s\u200E\u200F\u061C]*)*[0-9\u0660-\u0669\u06F0-\u06F9]+(?:[\s\u200E\u200F\u061C]*[۝۞۩﴿﴾()\[\]{}⟦⟧\u06DD\u06DE\u06E9]+)*\s*$',
  );

  static final RegExp _trailingAyahAdornmentRegex = RegExp(
    r'[\s\u200E\u200F\u061C]*[۝۞۩﴿﴾\u06DD\u06DE\u06E9]+\s*$',
  );

  static final RegExp _spaceBeforePunctuationRegex = RegExp(r'\s+([،؛:,.!?؟])');

  static final RegExp _spaceAfterPunctuationRegex = RegExp(
    r'([،؛:,.!?؟])(?=[^\s،؛:,.!?؟])',
  );

  static String cleanAyahForMemorization(
    String text, {
    String? trailingMarker,
  }) {
    if (text.isEmpty) return text;

    var cleaned = text.trim();
    if (cleaned.isEmpty) return cleaned;

    if (trailingMarker != null && trailingMarker.isNotEmpty) {
      cleaned = _removeTrailingMarker(cleaned, trailingMarker);
    }

    cleaned = cleaned.replaceAll('\n', ' ');
    cleaned = cleaned.replaceAll(_trailingAyahNumberRegex, '');
    cleaned = cleaned.replaceAll(_trailingAyahAdornmentRegex, '');
    cleaned = cleaned.replaceAll(_spaceBeforePunctuationRegex, r'$1');
    cleaned = cleaned.replaceAll(_spaceAfterPunctuationRegex, r'$1 ');
    cleaned = _normalizeMissingWordSpacing(cleaned);
    cleaned = cleaned.replaceAll(_whitespaceRegex, ' ').trim();

    return cleaned;
  }

  static String _removeTrailingMarker(String text, String trailingMarker) {
    final trimmed = text.trimRight();
    if (!trimmed.endsWith(trailingMarker)) return trimmed;

    return trimmed.substring(0, trimmed.length - trailingMarker.length).trim();
  }

  static String _normalizeMissingWordSpacing(String text) {
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (_startsWithDefiniteArticle(text, i) && i > 0) {
        final previousChar = text[i - 1];
        if (!_isWhitespace(previousChar)) {
          var scanIndex = i - 1;
          var hasTrailingDiacritic = false;

          while (scanIndex >= 0 && _isArabicDiacritic(text[scanIndex])) {
            hasTrailingDiacritic = true;
            scanIndex--;
          }

          if (hasTrailingDiacritic &&
              scanIndex >= 0 &&
              _isArabicLetter(text[scanIndex])) {
            buffer.write(' ');
          }
        }
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  static bool _startsWithDefiniteArticle(String text, int index) =>
      text.startsWith('ال', index) || text.startsWith('ٱل', index);

  static bool _isWhitespace(String char) => _whitespaceRegex.hasMatch(char);

  static bool _isArabicDiacritic(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 0x064B && code <= 0x065F) ||
        code == 0x0670 ||
        (code >= 0x06D6 && code <= 0x06ED);
  }

  static bool _isArabicLetter(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 0x0621 && code <= 0x063A) ||
        (code >= 0x0641 && code <= 0x064A);
  }
}
