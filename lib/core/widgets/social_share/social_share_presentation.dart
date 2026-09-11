import 'social_share_model.dart';

/// Chooses how the official companion participates in a card composition.
///
/// This belongs to the share presentation layer so domain share data remains
/// unchanged while every template receives the same branding treatment.
enum SocialShareCharacterTreatment { none, subtle, prominent }

abstract final class SocialSharePresentation {
  static SocialShareCharacterTreatment characterTreatmentFor(
    SocialShareData data, [
    SocialShareFormat format = SocialShareFormat.portrait,
  ]) {
    if (!data.showCharacter || _prioritizesContent(data, format)) {
      return SocialShareCharacterTreatment.none;
    }
    if (data.audience == SocialShareAudience.kids) {
      return SocialShareCharacterTreatment.prominent;
    }
    return SocialShareCharacterTreatment.subtle;
  }

  static bool _prioritizesContent(
    SocialShareData data,
    SocialShareFormat format,
  ) {
    final primaryTextLength = data.content.length;
    final supportingTextLength =
        (data.title?.length ?? 0) +
        (data.subtitle?.length ?? 0) +
        (data.translation?.length ?? 0);
    final textLoad = primaryTextLength + supportingTextLength;
    final isTextHero =
        data.category == SocialShareCategory.quranAyah ||
        data.category == SocialShareCategory.dua ||
        data.category == SocialShareCategory.azkar;

    final threshold = switch ((data.audience, format, isTextHero)) {
      (SocialShareAudience.kids, SocialShareFormat.square, true) => 70,
      (SocialShareAudience.kids, SocialShareFormat.portrait, true) => 105,
      (SocialShareAudience.kids, SocialShareFormat.story, true) => 135,
      (SocialShareAudience.kids, SocialShareFormat.square, false) => 90,
      (SocialShareAudience.kids, SocialShareFormat.portrait, false) => 135,
      (SocialShareAudience.kids, SocialShareFormat.story, false) => 165,
      (SocialShareAudience.adult, SocialShareFormat.square, true) => 140,
      (SocialShareAudience.adult, SocialShareFormat.portrait, true) => 180,
      (SocialShareAudience.adult, SocialShareFormat.story, true) => 220,
      (SocialShareAudience.adult, SocialShareFormat.square, false) => 120,
      (SocialShareAudience.adult, SocialShareFormat.portrait, false) => 140,
      (SocialShareAudience.adult, SocialShareFormat.story, false) => 160,
    };
    return textLoad > threshold;
  }
}
