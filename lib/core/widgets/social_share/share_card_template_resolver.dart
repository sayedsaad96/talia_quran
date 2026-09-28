import 'package:flutter/material.dart';

import 'heroes/award_hero.dart';
import 'heroes/stat_hero.dart';
import 'heroes/text_hero.dart';
import 'share_card_palette.dart';
import 'social_share_model.dart';
import 'talia_share_tokens.dart';

/// Picks the hero for a share category.
abstract final class ShareCardTemplateResolver {
  static Widget resolve({
    required SocialShareData data,
    required SharePalette palette,
    required SocialShareFormat format,
  }) {
    final metrics = TaliaShareMetrics.of(format);
    switch (data.category) {
      case SocialShareCategory.quranAyah:
      case SocialShareCategory.dua:
        return TextHero(data: data, palette: palette, metrics: metrics);
      case SocialShareCategory.azkar:
        return data.isAzkarWirdProgress
            ? StatHero(data: data, palette: palette, metrics: metrics)
            : TextHero(data: data, palette: palette, metrics: metrics);
      case SocialShareCategory.memorization:
      case SocialShareCategory.streak:
      case SocialShareCategory.progress:
        return StatHero(data: data, palette: palette, metrics: metrics);
      case SocialShareCategory.achievement:
      case SocialShareCategory.certificate:
      case SocialShareCategory.khatmah:
        return AwardHero(data: data, palette: palette, metrics: metrics);
    }
  }
}
