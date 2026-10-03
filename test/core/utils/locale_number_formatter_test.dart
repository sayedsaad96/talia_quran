import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/utils/locale_number_formatter.dart';
import 'package:talia_quran/core/utils/locale_numeric_input_formatter.dart';

void main() {
  test(
    'display digits follow locale without changing precision or separators',
    () {
      const samples = {
        '0': '٠',
        '-120': '-١٢٠',
        '001.50%': '٠٠١.٥٠%',
        '01:09 / 2026/10/03': '٠١:٠٩ / ٢٠٢٦/١٠/٠٣',
        '12 / ٣٤': '١٢ / ٣٤',
      };
      for (final sample in samples.entries) {
        final arabic = LocaleNumberFormatter.format(sample.key, 'ar');
        expect(arabic, sample.value);
        expect(LocaleNumberFormatter.format(arabic, 'ar'), arabic);
        expect(
          LocaleNumberFormatter.format(arabic, 'en'),
          LocaleNumberFormatter.western(sample.key),
        );
      }
      expect(LocaleNumberFormatter.number(-12.5, 'ar_EG'), '-١٢.٥');
      expect(LocaleNumberFormatter.format('١٢', 'en-US'), '12');
    },
  );

  test(
    'editable digits preserve selection and defer active IME composition',
    () {
      final formatter = LocaleNumericInputFormatter('ar');
      const edited = TextEditingValue(
        text: '12٣',
        selection: TextSelection.collapsed(offset: 2),
      );
      final shaped = formatter.formatEditUpdate(TextEditingValue.empty, edited);
      expect(shaped.text, '١٢٣');
      expect(shaped.selection, edited.selection);
      expect(int.parse(LocaleNumberFormatter.western(shaped.text)), 123);
      expect(
        LocaleNumericInputFormatter('en').formatEditUpdate(edited, shaped).text,
        '123',
      );
      final composing = edited.copyWith(
        composing: const TextRange(start: 0, end: 2),
      );
      expect(
        formatter.formatEditUpdate(TextEditingValue.empty, composing),
        composing,
      );
    },
  );
}
