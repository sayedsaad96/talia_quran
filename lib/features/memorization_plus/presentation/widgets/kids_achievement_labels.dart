import 'package:flutter/widgets.dart';

import '../../../../core/icons/talia_icons.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/services/kids_achievements.dart';

/// Display name of a kids milestone, shared by the kids page and the
/// guardian's view of the child.
String kidsAchievementTitle(AppLocalizations l10n, KidsAchievementId id) =>
    switch (id) {
      KidsAchievementId.firstAyah => l10n.kidsAchievementFirstAyah,
      KidsAchievementId.ayahs10 => l10n.kidsAchievementAyahs10,
      KidsAchievementId.ayahs50 => l10n.kidsAchievementAyahs50,
      KidsAchievementId.ayahs100 => l10n.kidsAchievementAyahs100,
      KidsAchievementId.firstSurah => l10n.kidsAchievementFirstSurah,
      KidsAchievementId.surahs3 => l10n.kidsAchievementSurahs3,
      KidsAchievementId.surahs10 => l10n.kidsAchievementSurahs10,
      KidsAchievementId.firstPage => l10n.kidsAchievementFirstPage,
      KidsAchievementId.pages10 => l10n.kidsAchievementPages10,
      KidsAchievementId.pages30 => l10n.kidsAchievementPages30,
      KidsAchievementId.streak3 => l10n.kidsAchievementStreak3,
      KidsAchievementId.streak7 => l10n.kidsAchievementStreak7,
      KidsAchievementId.streak30 => l10n.kidsAchievementStreak30,
      KidsAchievementId.firstStar => l10n.kidsAchievementFirstStar,
      KidsAchievementId.stars10 => l10n.kidsAchievementStars10,
      KidsAchievementId.stars50 => l10n.kidsAchievementStars50,
    };

/// Milestone icon: the kids glyphs on kids screens, the standard Talia
/// glyphs ([kids] false) on the guardian's screens.
IconData kidsAchievementIcon(
  KidsAchievementMetric metric, {
  bool kids = true,
}) => switch (metric) {
  KidsAchievementMetric.ayahs => kids ? TaliaKidsIcons.hifz : TaliaIcons.hifz,
  KidsAchievementMetric.surahs =>
    kids ? TaliaKidsIcons.trophy : TaliaIcons.trophy,
  KidsAchievementMetric.pages =>
    kids ? TaliaKidsIcons.mushaf : TaliaIcons.mushaf,
  KidsAchievementMetric.streak =>
    kids ? TaliaKidsIcons.flame : TaliaIcons.flame,
  KidsAchievementMetric.stars =>
    kids ? TaliaKidsIcons.starFilled : TaliaIcons.starFilled,
};
