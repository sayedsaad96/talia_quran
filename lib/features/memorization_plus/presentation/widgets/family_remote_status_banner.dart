import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';

/// Says the linked children could not be read: either an older saved copy
/// is shown, or they may be missing. Hidden while the read is fresh.
class FamilyRemoteStatusBanner extends StatelessWidget {
  const FamilyRemoteStatusBanner({
    super.key,
    required this.status,
    required this.fetchedAt,
    required this.onRetry,
  });

  final FamilyRemoteStatus status;
  final DateTime? fetchedAt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      FamilyRemoteStatus.cached when fetchedAt != null =>
        context.l10n.familyDashboardOfflineCached(_time(context, fetchedAt!)),
      FamilyRemoteStatus.cached || FamilyRemoteStatus.unavailable =>
        context.l10n.familyDashboardRemoteUnavailable,
      FamilyRemoteStatus.live || FamilyRemoteStatus.notConnected => null,
    };
    if (message == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('family-remote-banner'),
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.md,
          AppSpacing.pagePadding,
          0,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Row(
          children: [
            Icon(TaliaIcons.cloudOff, color: scheme.onErrorContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey('family-remote-retry'),
              onPressed: onRetry,
              child: Text(context.l10n.retryLabel),
            ),
          ],
        ),
      ),
    );
  }

  static String _time(BuildContext context, DateTime at) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return context.digitText(
      DateFormat.MMMd(locale).add_jm().format(at.toLocal()),
    );
  }
}
