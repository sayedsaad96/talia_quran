import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The signature bar sits over the brightest part of the mushaf light.
Color _signatureBackdrop(SharePalette p) => Color.alphaBlend(
  p.signatureSurface,
  Color.lerp(p.skyBase, p.glow, p.glowStrength.clamp(0.0, 1.0))!,
);

void main() {
  SocialShareData dataFor(
    SocialShareCategory category, {
    SocialShareAudience audience = SocialShareAudience.adult,
  }) => SocialShareData(content: 'x', category: category, audience: audience);

  test('auto mood maps every category to its time-of-day palette', () {
    const expected = {
      SocialShareCategory.quranAyah: SharePaletteId.mushafLight,
      SocialShareCategory.dua: SharePaletteId.suhoor,
      SocialShareCategory.azkar: SharePaletteId.dusk,
      SocialShareCategory.achievement: SharePaletteId.sunrise,
      SocialShareCategory.certificate: SharePaletteId.sunrise,
      SocialShareCategory.khatmah: SharePaletteId.sunrise,
      SocialShareCategory.memorization: SharePaletteId.forenoon,
      SocialShareCategory.progress: SharePaletteId.forenoon,
      SocialShareCategory.streak: SharePaletteId.forenoon,
    };
    for (final category in SocialShareCategory.values) {
      expect(
        SharePalettes.resolve(dataFor(category), SocialShareMood.auto).id,
        expected[category],
        reason: '$category',
      );
    }
  });

  test('kids audience uses the morning palette only in auto mood', () {
    final kids = dataFor(
      SocialShareCategory.streak,
      audience: SocialShareAudience.kids,
    );
    expect(
      SharePalettes.resolve(kids, SocialShareMood.auto).id,
      SharePaletteId.kidsMorning,
    );
    expect(
      SharePalettes.resolve(kids, SocialShareMood.night).id,
      SharePaletteId.night,
    );
    expect(
      SharePalettes.resolve(kids, SocialShareMood.day).id,
      SharePaletteId.day,
    );
  });

  test('night and day moods override every category', () {
    for (final category in SocialShareCategory.values) {
      expect(
        SharePalettes.resolve(dataFor(category), SocialShareMood.night).id,
        SharePaletteId.night,
      );
      expect(
        SharePalettes.resolve(dataFor(category), SocialShareMood.day).id,
        SharePaletteId.day,
      );
    }
  });

  group('contrast', () {
    for (final p in SharePalettes.all) {
      test('${p.id}: body text is readable on the sky', () {
        expect(_contrast(p.textPrimary, p.skyMid), greaterThanOrEqualTo(4.5));
      });
      test('${p.id}: accent (numerals, references) is readable', () {
        expect(_contrast(p.textAccent, p.skyMid), greaterThanOrEqualTo(3.0));
      });
      test('${p.id}: signature text survives the brightest glow', () {
        expect(
          _contrast(p.signatureText, _signatureBackdrop(p)),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('${p.id}: QR modules contrast with their quiet zone', () {
        expect(_contrast(p.qrForeground, p.qrBackground), greaterThan(7));
      });
    }
  });
}
