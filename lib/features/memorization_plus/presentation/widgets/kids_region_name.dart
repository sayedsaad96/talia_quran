import '../../../../core/l10n/app_localizations.dart';
import '../../domain/services/kids_adventure_regions.dart';

/// Localized UI name of an Adventure region (non-religious copy).
String kidsRegionName(AppLocalizations l10n, KidsRegionId id) => switch (id) {
  KidsRegionId.beginning => l10n.kidsRegionBeginning,
  KidsRegionId.palmOasis => l10n.kidsRegionPalmOasis,
  KidsRegionId.flowerValley => l10n.kidsRegionFlowerValley,
  KidsRegionId.starMountain => l10n.kidsRegionStarMountain,
  KidsRegionId.pearlSea => l10n.kidsRegionPearlSea,
};
