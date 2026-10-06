import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_subpage_scaffold.dart';

/// Attribution for the content and code Talia ships, as the sources'
/// licenses require (Tanzil: name the source, keep its notice verbatim and
/// link to tanzil.net).
class SourcesLicensesPage extends StatelessWidget {
  const SourcesLicensesPage({super.key});

  /// Tanzil's copyright notice; its license requires it verbatim.
  static const tanzilNotice =
      'Tanzil Quran Text Copyright (C) 2007-2021 Tanzil Project\n'
      'License: Creative Commons Attribution 3.0';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = context.isDark;

    return SettingsSubpageScaffold(
      title: l10n.sourcesLicensesTitle,
      children: [
        SettingsGroup(
          children: [
            _SourceEntry(
              title: l10n.sourcesQuranTextTitle,
              body: l10n.sourcesQuranTextBody,
              notice: tanzilNotice,
              link: Uri.parse('https://tanzil.net'),
            ),
            SettingsDivider(isDark: isDark, indent: AppSpacing.md),
            _SourceEntry(
              title: l10n.sourcesMushafTitle,
              body: l10n.sourcesMushafBody,
              link: Uri.parse('https://github.com/hussein12347/qcf_quran_plus'),
            ),
            SettingsDivider(isDark: isDark, indent: AppSpacing.md),
            _SourceEntry(
              title: l10n.sourcesRecitationTitle,
              body: l10n.sourcesRecitationBody,
              link: Uri.parse('https://everyayah.com'),
            ),
            SettingsDivider(isDark: isDark, indent: AppSpacing.md),
            _SourceEntry(
              title: l10n.sourcesAdhanTitle,
              body: l10n.sourcesAdhanBody,
              link: Uri.parse(
                'https://archive.org/details/adhan.notifications',
              ),
            ),
            SettingsDivider(isDark: isDark, indent: AppSpacing.md),
            _SourceEntry(
              title: l10n.sourcesKhatmDuaTitle,
              body: l10n.sourcesKhatmDuaBody,
            ),
          ],
        ),
        SettingsGroup(
          children: [
            ListTile(
              key: const ValueKey('open-source-licenses'),
              title: Text(
                l10n.sourcesOpenSourceTitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                l10n.sourcesOpenSourceBody,
                style: AppTypography.labelMedium.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
              trailing: SettingsTrailingChevron(
                color: context.tokens.textSecondary,
              ),
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.settingsAppBrand,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SourceEntry extends StatelessWidget {
  const _SourceEntry({
    required this.title,
    required this.body,
    this.notice,
    this.link,
  });

  final String title;
  final String body;
  final String? notice;
  final Uri? link;

  @override
  Widget build(BuildContext context) {
    final textColor = context.tokens.textPrimary;
    final subtextColor = context.tokens.textSecondary;
    final link = this.link;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: AppTypography.bodySmall.copyWith(color: subtextColor),
          ),
          if (notice != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                notice!,
                style: AppTypography.labelMedium.copyWith(color: textColor),
              ),
            ),
          ],
          if (link != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () =>
                    launchUrl(link, mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(context.l10n.sourcesOpenLink(link.host)),
                style: TextButton.styleFrom(
                  foregroundColor: context.tokens.accent,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
