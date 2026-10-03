import 'package:flutter/services.dart';

import 'locale_number_formatter.dart';

/// Keeps editable digit shaping length-preserving, including the selection.
class LocaleNumericInputFormatter extends TextInputFormatter {
  LocaleNumericInputFormatter(this.languageCode);

  final String languageCode;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    return newValue.copyWith(
      text: LocaleNumberFormatter.format(newValue.text, languageCode),
    );
  }
}
