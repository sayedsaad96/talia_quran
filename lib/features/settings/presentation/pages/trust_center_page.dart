import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/content/content_manifest_summary.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_subpage_scaffold.dart';

/// Plain-language account of where Talia's content comes from, what happens
/// to the user's voice, and how their data is kept.
class TrustCenterPage extends StatefulWidget {
  const TrustCenterPage({super.key, this.summaryFuture});

  /// Overrides the bundled manifest read (tests).
  final Future<ContentManifestSummary?>? summaryFuture;

  @override
  State<TrustCenterPage> createState() => _TrustCenterPageState();
}

class _TrustCenterPageState extends State<TrustCenterPage> {
  late final Future<ContentManifestSummary?> _summary =
      widget.summaryFuture ?? loadContentManifestSummary(rootBundle);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingsSubpageScaffold(
      title: l10n.trustCenterTitle,
      children: [
        FutureBuilder<ContentManifestSummary?>(
          future: _summary,
          builder: (context, snapshot) {
            final summary = snapshot.data;
            final version = summary?.datasetVersion;
            return _TrustCard(
              title: l10n.trustSourcesTitle,
              body: l10n.trustSourcesBody,
              meta: summary == null || version == null
                  ? null
                  : l10n.trustSourcesMeta(
                      version,
                      context.numText(summary.sourceCount),
                    ),
              actionLabel: l10n.trustViewSources,
              onAction: () => context.push(AppRoutes.sourcesLicenses),
            );
          },
        ),
        _TrustCard(title: l10n.trustVoiceTitle, body: l10n.trustVoiceBody),
        _TrustCard(
          title: l10n.trustDataTitle,
          body: l10n.trustDataBody,
          actionLabel: l10n.trustViewPrivacy,
          onAction: () => context.push(AppRoutes.privacyPolicy),
        ),
      ],
    );
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard({
    required this.title,
    required this.body,
    this.meta,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? meta;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SettingsGroup(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  body,
                  style: AppTypography.bodyMedium.copyWith(
                    color: tokens.textPrimary,
                    height: 1.5,
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    meta!,
                    style: AppTypography.labelMedium.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
                if (actionLabel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
