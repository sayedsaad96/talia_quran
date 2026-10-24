import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/services/guardian_milestone_detector.dart';
import '../cubits/family_dashboard_cubit.dart';
import '../pages/child_detail_page.dart';
import 'family_child_name.dart';

/// «ما الجديد»: milestones of the children the guardian has not seen yet.
/// Tapping a line opens that child's details; «تم» marks everything seen.
class GuardianNewsSection extends StatelessWidget {
  const GuardianNewsSection({super.key, required this.news});

  final List<GuardianNewsItem> news;

  String _line(BuildContext context, GuardianNewsItem item) {
    final l10n = context.l10n;
    final name = item.child.shownName(l10n);
    return switch (item.milestone) {
      SurahCompletedMilestone(:final surahId) => l10n.guardianNewsSurah(
        name,
        context.localizedSurahName(surahId),
      ),
      CertificateEarnedMilestone(:final titleAr, :final titleEn) =>
        l10n.guardianNewsCertificate(
          name,
          l10n.localeName == 'ar' ? titleAr : (titleEn ?? titleAr),
        ),
      PromiseMetMilestone(:final title) => l10n.guardianNewsPromise(
        name,
        title,
      ),
      WeekCompletedMilestone() => l10n.guardianNewsWeek(name),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const ValueKey('guardian-news-section'),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(TaliaIcons.celebrate, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.guardianNewsTitle,
                  style: AppTypography.titleMedium,
                ),
              ),
              TextButton(
                key: const ValueKey('guardian-news-dismiss'),
                onPressed: () =>
                    context.read<FamilyDashboardCubit>().dismissNews(),
                child: Text(l10n.guardianNewsDismiss),
              ),
            ],
          ),
          for (final item in news)
            InkWell(
              onTap: () => context.push(
                AppRoutes.childDetail,
                extra: ChildDetailRouteArgs(
                  child: item.child,
                  cubit: context.read<FamilyDashboardCubit>(),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    _line(context, item),
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
