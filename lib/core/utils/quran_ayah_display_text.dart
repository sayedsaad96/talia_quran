class QuranAyahDisplayText {
  static const _terminalSpacing = r'[\s\u200E\u200F\u061C]*';
  static const _ayahDecoration = r'[۝۞۩﴿﴾()\[\]{}\u06DD\u06DE\u06E9]+';

  static String withoutTrailingNumber(String text, {required int ayahNumber}) {
    final numberAlternatives = _numberScripts(
      ayahNumber,
    ).map(RegExp.escape).join('|');
    final terminalNumber = RegExp(
      '$_terminalSpacing(?:$_ayahDecoration$_terminalSpacing)*'
      '(?:$numberAlternatives)'
      '(?:$_terminalSpacing$_ayahDecoration)*$_terminalSpacing\$',
    );
    final match = terminalNumber.firstMatch(text);
    if (match == null) return text;

    return text.substring(0, match.start).trimRight();
  }

  static String withVerseBrackets(String text, {required int ayahNumber}) {
    final cleaned = withoutTrailingNumber(text, ayahNumber: ayahNumber).trim();
    if (cleaned.startsWith('﴿') && cleaned.endsWith('﴾')) return cleaned;

    return '﴿ $cleaned ﴾';
  }

  static List<String> _numberScripts(int number) => [
    number.toString(),
    _convertDigits(number, 0x0660),
    _convertDigits(number, 0x06F0),
  ];

  static String _convertDigits(int number, int zeroCodePoint) => number
      .toString()
      .codeUnits
      .map((digit) => String.fromCharCode(zeroCodePoint + digit - 0x30))
      .join();
}
