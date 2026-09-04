import 'package:flutter/material.dart';
import 'social_share_model.dart';
import 'social_share_theme.dart';
import 'templates/achievement_template.dart';
import 'templates/certificate_template.dart';
import 'templates/dua_zikr_template.dart';
import 'templates/memorization_template.dart';
import 'templates/progress_template.dart';
import 'templates/quran_verse_template.dart';
import 'templates/streak_template.dart';

/// Resolves and builds the appropriate specialized template widget
abstract class ShareCardTemplateResolver {
  static Widget resolve({
    required SocialShareData data,
    required SocialShareTheme theme,
    required SocialShareFormat format,
  }) {
    switch (data.category) {
      case SocialShareCategory.quranAyah:
        return QuranVerseTemplate(data: data, theme: theme, format: format);

      case SocialShareCategory.achievement:
      case SocialShareCategory.khatmah:
        return AchievementTemplate(data: data, theme: theme, format: format);

      case SocialShareCategory.dua:
      case SocialShareCategory.azkar:
        return DuaZikrTemplate(data: data, theme: theme, format: format);

      case SocialShareCategory.memorization:
        return MemorizationTemplate(data: data, theme: theme, format: format);

      case SocialShareCategory.streak:
        return StreakTemplate(data: data, theme: theme, format: format);

      case SocialShareCategory.progress:
        return ProgressTemplate(data: data, theme: theme, format: format);

      case SocialShareCategory.certificate:
        return CertificateTemplate(data: data, theme: theme, format: format);
    }
  }
}
