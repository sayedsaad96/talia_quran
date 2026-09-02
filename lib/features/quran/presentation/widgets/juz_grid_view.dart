import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

typedef JuzSelectedCallback = void Function(int juzNumber, int initialPage);

class JuzGridView extends StatelessWidget {
  const JuzGridView({super.key, this.onJuzSelected});

  final JuzSelectedCallback? onJuzSelected;

  static const List<int> _juzStartPages = [
    1,
    22,
    42,
    62,
    82,
    102,
    121,
    142,
    162,
    182,
    201,
    222,
    242,
    262,
    282,
    302,
    322,
    342,
    362,
    382,
    402,
    422,
    442,
    462,
    482,
    502,
    522,
    542,
    562,
    582,
  ];

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = constraints.maxWidth / textScale;
        final columnCount = switch (effectiveWidth) {
          >= 1100 => 4,
          >= 720 => 3,
          >= 360 => 2,
          _ => 1,
        };

        return GridView.builder(
          key: const ValueKey('juz_grid'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            120,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            mainAxisExtent: 138 + ((textScale - 1) * 48),
          ),
          itemCount: _juzStartPages.length,
          itemBuilder: (context, index) {
            final juzNumber = index + 1;
            final initialPage = _juzStartPages[index];

            return _JuzCard(
              key: ValueKey('juz_card_$juzNumber'),
              juzNumber: juzNumber,
              initialPage: initialPage,
              onTap: () {
                final callback = onJuzSelected;
                if (callback != null) {
                  callback(juzNumber, initialPage);
                  return;
                }
                context.push('/quran/page/$initialPage');
              },
            );
          },
        );
      },
    );
  }
}

class _JuzCard extends StatelessWidget {
  const _JuzCard({
    super.key,
    required this.juzNumber,
    required this.initialPage,
    required this.onTap,
  });

  final int juzNumber;
  final int initialPage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final title = '${context.l10n.juz} ${context.localizedJuzName(juzNumber)}';
    final pageLabel = '${context.l10n.page} $initialPage';
    final surface = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.lightSurfaceVariant;
    final primaryText = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '$title، $pageLabel',
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: primary.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.11),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$juzNumber',
                        style: AppTypography.labelMedium.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.menu_book_rounded, size: 21, color: primary),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 15,
                      color: secondaryText,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      pageLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
