import 'social_share_model.dart';

/// Whether the official companion appears on a card. Only kids cards show
/// it, and only when the text leaves room so it never overlaps content.
enum SocialShareCharacterTreatment { none, prominent }

abstract final class SocialSharePresentation {
  static SocialShareCharacterTreatment characterTreatmentFor(
    SocialShareData data, [
    SocialShareFormat format = SocialShareFormat.portrait,
  ]) {
    if (!data.showCharacter ||
        data.audience != SocialShareAudience.kids ||
        _prioritizesContent(data, format)) {
      return SocialShareCharacterTreatment.none;
    }
    return SocialShareCharacterTreatment.prominent;
  }

  static bool _prioritizesContent(
    SocialShareData data,
    SocialShareFormat format,
  ) {
    final textLoad =
        data.content.length +
        (data.title?.length ?? 0) +
        (data.subtitle?.length ?? 0) +
        (data.translation?.length ?? 0);
    final isTextHero =
        data.category == SocialShareCategory.quranAyah ||
        data.category == SocialShareCategory.dua ||
        (data.category == SocialShareCategory.azkar &&
            !data.isAzkarWirdProgress);
    final threshold = switch ((format, isTextHero)) {
      (SocialShareFormat.square, true) => 70,
      (SocialShareFormat.portrait, true) => 105,
      (SocialShareFormat.story, true) => 135,
      (SocialShareFormat.square, false) => 90,
      (SocialShareFormat.portrait, false) => 135,
      (SocialShareFormat.story, false) => 165,
    };
    return textLoad > threshold;
  }
}
