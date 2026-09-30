import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/theme/app_colors.dart';
import 'package:talia_quran/core/theme/app_theme.dart';
import 'package:talia_quran/core/theme/talia_tokens.dart';

void main() {
  group('dark vs pure-black (OLED) themes', () {
    test('OLED is true black, standard dark is visibly lifted off it', () {
      expect(AppTheme.oled.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(
        AppTheme.dark.scaffoldBackgroundColor,
        isNot(AppTheme.oled.scaffoldBackgroundColor),
      );
      // Lifted enough to read as a different theme, not just "almost black".
      expect(
        AppTheme.dark.scaffoldBackgroundColor.computeLuminance(),
        greaterThan(0.01),
      );
    });

    test('surfaces, cards and dividers differ between the two', () {
      const dark = TaliaTokens.dark;
      const oled = TaliaTokens.oled;
      expect(dark.surface, isNot(oled.surface));
      expect(dark.card, isNot(oled.card));
      expect(dark.surfaceVariant, isNot(oled.surfaceVariant));
      expect(dark.divider, isNot(oled.divider));
    });

    test('both stay dark and expose their own tokens', () {
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppTheme.oled.brightness, Brightness.dark);
      expect(AppTheme.dark.extension<TaliaTokens>(), TaliaTokens.dark);
      expect(AppTheme.oled.extension<TaliaTokens>(), TaliaTokens.oled);
    });

    test('dark palette constants feed the standard dark tokens', () {
      expect(TaliaTokens.dark.background, AppColors.darkBackground);
      expect(TaliaTokens.oled.background, AppColors.oledBackground);
    });
  });
}
