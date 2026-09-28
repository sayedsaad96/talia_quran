import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/extensions/context_extensions.dart';
import 'package:talia_quran/core/theme/app_colors.dart';
import 'package:talia_quran/core/theme/app_theme.dart';
import 'package:talia_quran/core/theme/talia_tokens.dart';

void main() {
  group('AppTheme registers TaliaTokens', () {
    test('light, dark and oled each carry their own tokens', () {
      expect(AppTheme.light.extension<TaliaTokens>(), same(TaliaTokens.light));
      expect(AppTheme.dark.extension<TaliaTokens>(), same(TaliaTokens.dark));
      expect(AppTheme.oled.extension<TaliaTokens>(), same(TaliaTokens.oled));
    });

    test('oled is pure black and dark-brightness', () {
      final oled = AppTheme.oled;
      expect(oled.brightness, Brightness.dark);
      expect(oled.scaffoldBackgroundColor, AppColors.oledBackground);
      expect(oled.colorScheme.surface, AppColors.oledSurface);
    });

    test('scaffold background and text colors come from the tokens', () {
      for (final theme in [AppTheme.light, AppTheme.dark, AppTheme.oled]) {
        final tokens = theme.extension<TaliaTokens>()!;
        expect(theme.scaffoldBackgroundColor, tokens.background);
        expect(theme.textTheme.bodyLarge!.color, tokens.textPrimary);
        expect(theme.textTheme.bodySmall!.color, tokens.textSecondary);
      }
    });

    test('every variant defines the shared component themes', () {
      for (final theme in [AppTheme.light, AppTheme.dark, AppTheme.oled]) {
        expect(theme.filledButtonTheme.style, isNotNull);
        expect(theme.outlinedButtonTheme.style, isNotNull);
        expect(theme.textButtonTheme.style, isNotNull);
        expect(theme.elevatedButtonTheme.style, isNotNull);
        expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
        expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
      }
    });

    test('buttons meet the 48dp minimum touch target', () {
      final size = AppTheme.light.filledButtonTheme.style!.minimumSize!.resolve(
        const <WidgetState>{},
      )!;
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('TaliaTokens', () {
    test('lerp at the ends returns the endpoints', () {
      const a = TaliaTokens.light;
      const b = TaliaTokens.dark;
      expect(a.lerp(b, 0).background, a.background);
      expect(a.lerp(b, 1).background, b.background);
      expect(a.lerp(null, 0.5), same(a));
    });

    test('copyWith overrides only the given fields', () {
      final t = TaliaTokens.light.copyWith(card: const Color(0xFF123456));
      expect(t.card, const Color(0xFF123456));
      expect(t.background, TaliaTokens.light.background);
    });

    testWidgets('context.tokens reads the active theme', (tester) async {
      late TaliaTokens seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.oled,
          home: Builder(
            builder: (context) {
              seen = context.tokens;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, same(TaliaTokens.oled));
    });

    testWidgets('context.tokens falls back by brightness without AppTheme', (
      tester,
    ) async {
      late TaliaTokens seen;
      late TextStyle verse;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              seen = context.tokens;
              verse = context.talia.quranVerse;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, same(TaliaTokens.dark));
      expect(verse.color, TaliaTokens.dark.textPrimary);
    });
  });
}
