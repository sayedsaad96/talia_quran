import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../domain/entities/juz_summary.dart';

typedef JuzSelectedCallback = void Function(int juzNumber, int initialPage);

class JuzGridView extends StatelessWidget {
  const JuzGridView({
    super.key,
    this.onJuzSelected,
    this.summaries,
    this.query = '',
  });

  final JuzSelectedCallback? onJuzSelected;

  /// Precomputed per-juz metadata shared with the reader Quick Navigation
  /// sheet. When null, cards fall back to page-only display.
  final List<JuzSummary>? summaries;

  /// Active-tab search text. Empty means no filtering.
  final String query;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final visible = _visibleJuz(context);

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
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final juzNumber = visible[index];
            final initialPage = JuzSummaries.startPages[juzNumber - 1];

            return _JuzCard(
              key: ValueKey('juz_card_$juzNumber'),
              juzNumber: juzNumber,
              initialPage: initialPage,
              summary: _summaryFor(juzNumber),
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

  JuzSummary? _summaryFor(int juzNumber) {
    final list = summaries;
    if (list == null) return null;
    for (final summary in list) {
      if (summary.juzNumber == juzNumber) return summary;
    }
    return null;
  }

  /// Juz numbers matching [query] by juz number or surah-range names.
  List<int> _visibleJuz(BuildContext context) {
    final q = ArabicNormalizer.normalize(query.trim());
    final all = List<int>.generate(JuzSummaries.totalJuz, (i) => i + 1);
    if (q.isEmpty) return all;
    final isArabic = context.isArabic;
    return all.where((juzNumber) {
      if ('$juzNumber'.contains(query.trim())) return true;
      final summary = _summaryFor(juzNumber);
      if (summary == null || !summary.hasRange) return false;
      for (final surah in summary.surahs) {
        final name = isArabic ? surah.nameAr : surah.nameEn;
        if (ArabicNormalizer.normalize(name).contains(q)) return true;
        final other = isArabic ? surah.nameEn.toLowerCase() : surah.nameAr;
        if (other.toLowerCase().contains(query.trim().toLowerCase())) {
          return true;
        }
      }
      return false;
    }).toList();
  }
}

class _JuzCard extends StatelessWidget {
  const _JuzCard({
    super.key,
    required this.juzNumber,
    required this.initialPage,
    required this.onTap,
    this.summary,
  });

  final int juzNumber;
  final int initialPage;
  final VoidCallback onTap;
  final JuzSummary? summary;

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
                if (summary != null && summary!.hasRange)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _rangeLabel(context, summary!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: secondaryText,
                      ),
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

String _rangeLabel(BuildContext context, JuzSummary summary) {
  final first = context.isArabic
      ? summary.firstSurah.nameAr
      : summary.firstSurah.nameEn;
  if (summary.isSingleSurah) {
    return context.isArabic ? 'سورة $first' : first;
  }
  final last = context.isArabic
      ? summary.lastSurah.nameAr
      : summary.lastSurah.nameEn;
  return context.isArabic ? 'من $first إلى $last' : '$first – $last';
}
