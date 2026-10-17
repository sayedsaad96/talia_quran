import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/memorization/kids_enrichment_feature_flags.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/family_dashboard.dart';
import '../../domain/services/kids_progress_snapshot.dart';

/// The certificates the guardian's child has earned, each opening the existing
/// certificate page (print / share) in the child's name. Certificates are only
/// ever read from recorded achievements: nothing here issues one.
class ChildCertificatesSection extends StatelessWidget {
  const ChildCertificatesSection({
    super.key,
    required this.child,
    required this.childName,
    this.localCertificates,
  });

  final FamilyChildEntry child;
  final String childName;

  /// Test seam for the local child's earned list; defaults to the kids path
  /// of [AchievementService].
  final List<CertificateAward> Function()? localCertificates;

  /// Off unless the rollout flag is on (and the flags are wired).
  static bool isEnabled() =>
      getIt.isRegistered<KidsEnrichmentFlags>() &&
      getIt<KidsEnrichmentFlags>().isEnabled(
        KidsEnrichmentFeature.guardianCertificates,
      );

  List<CertificateAward> _load() {
    if (child.isLocal) {
      try {
        final loader =
            localCertificates ??
            () =>
                getIt<AchievementService>().getEarnedCertificates(isKids: true);
        return loader();
      } catch (_) {
        return const [];
      }
    }
    final summary = child.remoteSummary;
    if (summary == null) return const [];
    return remoteKidsProgressSnapshot(
      summary,
      now: DateTime.now(),
    ).certificates;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final certificates = _load();
    return Material(
      key: const ValueKey('child-certificates-section'),
      color: context.tokens.card,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.childCertificatesTitle, style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            if (certificates.isEmpty)
              Text(
                l10n.childCertificatesEmpty,
                style: AppTypography.bodySmall.copyWith(
                  color: context.tokens.textSecondary,
                ),
              )
            else
              for (final award in certificates)
                _GuardianCertificateTile(award: award, childName: childName),
          ],
        ),
      ),
    );
  }
}

class _GuardianCertificateTile extends StatelessWidget {
  const _GuardianCertificateTile({
    required this.award,
    required this.childName,
  });

  final CertificateAward award;
  final String childName;

  @override
  Widget build(BuildContext context) {
    final title = context.isArabic
        ? award.titleAr
        : (award.titleEn ?? award.titleAr);
    final date = context.digitText(
      MaterialLocalizations.of(
        context,
      ).formatShortDate(award.earnedAt.toLocal()),
    );
    return ListTile(
      key: ValueKey('guardian-certificate-${award.id}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(TaliaIcons.certificate, color: AppColors.gold),
      title: Text(title, style: AppTypography.titleSmall),
      subtitle: Text(date, style: AppTypography.bodySmall),
      trailing: Icon(
        context.isArabic ? TaliaIcons.chevronBack : TaliaIcons.chevronForward,
        size: 18,
      ),
      onTap: () => context.push(
        AppRoutes.certificate,
        extra: <String, dynamic>{'award': award, 'userName': childName},
      ),
    );
  }
}
