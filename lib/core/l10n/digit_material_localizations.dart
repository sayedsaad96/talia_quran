import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import '../utils/locale_number_formatter.dart';

/// The generic Arabic intl locale uses Western digits. Override presentation
/// methods without changing the framework's language, calendar or time format.
class DigitMaterialLocalizations extends MaterialLocalizationAr {
  DigitMaterialLocalizations()
    : super(
        fullYearFormat: intl.DateFormat.y('ar'),
        compactDateFormat: intl.DateFormat.yMd('ar'),
        shortDateFormat: intl.DateFormat.yMMMd('ar'),
        mediumDateFormat: intl.DateFormat.MMMEd('ar'),
        longDateFormat: intl.DateFormat.yMMMMEEEEd('ar'),
        yearMonthFormat: intl.DateFormat.yMMMM('ar'),
        shortMonthDayFormat: intl.DateFormat.MMMd('ar'),
        decimalFormat: intl.NumberFormat.decimalPattern('ar'),
        twoDigitZeroPaddedFormat: intl.NumberFormat('00', 'ar'),
      );

  String _digits(String numericText) =>
      LocaleNumberFormatter.format(numericText, 'ar');

  @override
  String formatDecimal(int number) => _digits(super.formatDecimal(number));

  @override
  String formatHour(
    TimeOfDay timeOfDay, {
    bool alwaysUse24HourFormat = false,
  }) => _digits(
    super.formatHour(timeOfDay, alwaysUse24HourFormat: alwaysUse24HourFormat),
  );

  @override
  String formatMinute(TimeOfDay timeOfDay) =>
      _digits(super.formatMinute(timeOfDay));

  @override
  String formatYear(DateTime date) => _digits(super.formatYear(date));

  @override
  String formatCompactDate(DateTime date) =>
      _digits(super.formatCompactDate(date));

  @override
  String formatShortDate(DateTime date) => _digits(super.formatShortDate(date));

  @override
  String formatMediumDate(DateTime date) =>
      _digits(super.formatMediumDate(date));

  @override
  String formatFullDate(DateTime date) => _digits(super.formatFullDate(date));

  @override
  String formatMonthYear(DateTime date) => _digits(super.formatMonthYear(date));

  @override
  String formatShortMonthDay(DateTime date) =>
      _digits(super.formatShortMonthDay(date));

  @override
  DateTime? parseCompactDate(String? inputString) {
    if (inputString == null) return null;
    final directionMarks = RegExp('[\u200e\u200f\u061c]');
    final pattern = intl.DateFormat.yMd(
      'ar',
    ).pattern!.replaceAll(directionMarks, '');
    final digits = LocaleNumberFormatter.western(
      inputString,
    ).replaceAll(directionMarks, '');
    try {
      return intl.DateFormat(pattern, 'en').parseStrict(digits);
    } on FormatException {
      return null;
    }
  }

  static const delegate = _DigitMaterialLocalizationsDelegate();
}

class _DigitMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _DigitMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ar';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // Let Flutter initialize intl's date symbols using its existing loader.
    await GlobalMaterialLocalizations.delegate.load(locale);
    return DigitMaterialLocalizations();
  }

  @override
  bool shouldReload(_DigitMaterialLocalizationsDelegate old) => false;
}
