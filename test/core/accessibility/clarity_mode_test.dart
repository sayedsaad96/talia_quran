import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/accessibility/clarity_mode.dart';
import 'package:talia_quran/core/theme/app_theme.dart';
import 'package:talia_quran/core/theme/talia_tokens.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final la = _lum(a);
  final lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test(
    'clarityTextScaler: off keeps system; on lifts to 1.3 or keeps larger',
    () {
      expect(clarityTextScaler(TextScaler.noScaling, on: false).scale(1), 1.0);
      expect(
        clarityTextScaler(const TextScaler.linear(1.1), on: false).scale(1),
        1.1,
      );
      expect(
        clarityTextScaler(TextScaler.noScaling, on: true).scale(1),
        kClarityTextScale,
      );
      expect(
        clarityTextScaler(const TextScaler.linear(1.5), on: true).scale(1),
        1.5,
      );
    },
  );

  group('ClarityModeController', () {
    test('isOn false when flag off even if pref true', () async {
      SharedPreferences.setMockInitialValues({'clarity_mode_on': true});
      final prefs = await SharedPreferences.getInstance();
      final c = ClarityModeController(prefs, flagEnabled: () => false);
      expect(c.isOn, isFalse);
      expect(c.preference, isTrue);
    });

    test('setOn persists, notifies, and respects the flag', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ClarityModeController(prefs, flagEnabled: () => true);
      var notified = 0;
      c.addListener(() => notified++);
      expect(c.isOn, isFalse);
      await c.setOn(true);
      expect(c.isOn, isTrue);
      expect(prefs.getBool('clarity_mode_on'), isTrue);
      expect(notified, 1);
    });
  });

  group('high-contrast tokens', () {
    final variants = <String, (TaliaTokens, bool)>{
      'light': (TaliaTokens.light, false),
      'dark': (TaliaTokens.dark, true),
      'oled': (TaliaTokens.oled, true),
    };
    for (final entry in variants.entries) {
      test(
        '${entry.key}: secondary text >= 4.5:1 on surface and background',
        () {
          final base = entry.value.$1;
          final t = base.toHighContrast(dark: entry.value.$2);
          expect(
            _contrast(t.textSecondary, t.surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(t.textSecondary, t.background),
            greaterThanOrEqualTo(4.5),
          );
          expect(_contrast(t.textHint, t.surface), greaterThanOrEqualTo(4.5));
          expect(_contrast(t.textPrimary, t.surface), greaterThanOrEqualTo(7));
          expect(
            _contrast(t.textPrimary, t.surface),
            greaterThanOrEqualTo(_contrast(base.textPrimary, base.surface)),
          );
        },
      );
    }

    test('AppTheme high-contrast variants carry the high-contrast tokens', () {
      expect(
        AppTheme.lightFor(
          highContrast: true,
        ).extension<TaliaTokens>()!.textPrimary,
        const Color(0xFF000000),
      );
      expect(
        AppTheme.darkFor(highContrast: true).colorScheme.onSurface,
        const Color(0xFFFFFFFF),
      );
      expect(
        AppTheme.lightFor().extension<TaliaTokens>()!.textPrimary,
        TaliaTokens.light.textPrimary,
      );
    });
  });

  testWidgets('Mushaf SystemTextScale keeps system scale under clarity', (
    tester,
  ) async {
    double? app;
    double? mushaf;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.1)),
        child: ClarityTextScaleScope(
          on: true,
          child: Builder(
            builder: (context) {
              app = MediaQuery.textScalerOf(context).scale(1);
              return SystemTextScale(
                child: Builder(
                  builder: (context) {
                    mushaf = MediaQuery.textScalerOf(context).scale(1);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(app, kClarityTextScale);
    expect(mushaf, 1.1);
  });
}
