/// Shapes display digits without changing punctuation, precision or padding.
/// Apply only to numeric presentation values, never canonical content or IDs.
abstract final class LocaleNumberFormatter {
  static String format(String text, String languageCode) {
    final zero = languageCode.split(RegExp('[-_]')).first == 'ar'
        ? 0x0660
        : 0x0030;
    return String.fromCharCodes(
      text.runes.map((rune) {
        if (rune >= 0x0030 && rune <= 0x0039) return zero + rune - 0x0030;
        if (rune >= 0x0660 && rune <= 0x0669) return zero + rune - 0x0660;
        return rune;
      }),
    );
  }

  static String number(num number, String languageCode) =>
      format(number.toString(), languageCode);

  static String western(String text) => format(text, 'en');
}
