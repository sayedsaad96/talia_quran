import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/kids_encouragement.dart';

String encouragementMessageLabel(
  AppLocalizations l10n,
  KidsEncouragementMessage message,
) => switch (message) {
  KidsEncouragementMessage.proud => l10n.encouragementProud,
  KidsEncouragementMessage.wellDone => l10n.encouragementWellDone,
  KidsEncouragementMessage.keepGoing => l10n.encouragementKeepGoing,
  KidsEncouragementMessage.greatEffort => l10n.encouragementGreatEffort,
  KidsEncouragementMessage.seeYouTomorrow => l10n.encouragementSeeYouTomorrow,
};

String encouragementStickerLabel(
  AppLocalizations l10n,
  KidsEncouragementSticker sticker,
) => switch (sticker) {
  KidsEncouragementSticker.starReward => l10n.encouragementStarSticker,
  KidsEncouragementSticker.taliaEncourage => l10n.encouragementTaliaSticker,
};
