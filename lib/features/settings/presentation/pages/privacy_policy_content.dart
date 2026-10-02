import '../../../../core/l10n/app_localizations.dart';

class PrivacySection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const PrivacySection({
    required this.title,
    required this.paragraphs,
    this.bullets = const [],
  });
}

abstract class PrivacyPolicyContent {
  static List<PrivacySection> sections(AppLocalizations l10n) => [
    PrivacySection(
      title: l10n.privacyControllerTitle,
      paragraphs: [l10n.privacyControllerBody],
    ),
    PrivacySection(
      title: l10n.privacyDataTitle,
      paragraphs: [
        l10n.privacyAccountData,
        l10n.privacyProgressData,
        l10n.privacyTechnicalData,
      ],
    ),
    PrivacySection(
      title: l10n.privacyPurposeTitle,
      paragraphs: [l10n.privacyPurposeBody],
    ),
    PrivacySection(
      title: l10n.privacyPermissionsTitle,
      paragraphs: [],
      bullets: [
        l10n.privacyMicrophone,
        l10n.privacyCamera,
        l10n.privacyNotifications,
        l10n.privacyPhotos,
        l10n.privacyLocation,
      ],
    ),
    PrivacySection(
      title: l10n.privacyChildrenTitle,
      paragraphs: [
        l10n.privacyChildrenBody,
        l10n.privacyGuardianSharing,
        l10n.privacyChildrenSpeech,
      ],
    ),
    PrivacySection(
      title: l10n.privacyProvidersTitle,
      paragraphs: [l10n.privacyProvidersBody, l10n.privacyProviderProtection],
    ),
    PrivacySection(
      title: l10n.privacySecurityTitle,
      paragraphs: [l10n.privacySecurityBody],
    ),
    PrivacySection(
      title: l10n.privacyRetentionTitle,
      paragraphs: [l10n.privacyRetentionBody],
    ),
    PrivacySection(
      title: l10n.privacyDeletionTitle,
      paragraphs: [
        l10n.privacyDeletionBody,
        l10n.privacyDeletionLimits,
        l10n.privacyExternalDeletion,
      ],
    ),
    PrivacySection(
      title: l10n.privacyRightsTitle,
      paragraphs: [l10n.privacyRightsBody],
    ),
    PrivacySection(
      title: l10n.privacyChangesTitle,
      paragraphs: [l10n.privacyChangesBody],
    ),
    PrivacySection(
      title: l10n.privacyContactTitle,
      paragraphs: [l10n.privacyContactBody],
    ),
  ];
}
