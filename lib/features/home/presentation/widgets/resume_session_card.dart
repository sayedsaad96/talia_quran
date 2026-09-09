import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/journey/resume_session_presentation_input.dart';
import '../../../../core/journey/resume_session_presentation_mapper.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/home_cubit.dart';

class ResumeSessionCard extends StatelessWidget {
  const ResumeSessionCard({
    super.key,
    required this.location,
    required this.isDark,
    required this.isKids,
  });

  final String location;
  final bool isDark;
  final bool isKids;

  @override
  Widget build(BuildContext context) {
    final presentationData = const ResumeSessionPresentationMapper().map(
      ResumeSessionPresentationInput(
        route: location,
        isArabic: context.isArabic,
        l10n: context.l10n,
      ),
    );
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Semantics(
      button: true,
      label: presentationData.title,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: primary.withValues(alpha: 0.22)),
        ),
        // The title/icon row and the action row are kept separate (rather
        // than one long Row) so the "Resume"/close controls never compete
        // for width with the title on narrow phones or at large text-scale
        // factors — each row only ever has to fit its own, smaller content.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(presentationData.icon, color: primary, size: 34),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentationData.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: textColor,
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        presentationData.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: TextButton(
                    onPressed: () => unawaited(context.push(location)),
                    child: Text(
                      context.l10n.resumeAction,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await getIt<AppSessionService>()
                        .clearLastRestorableLocation();
                    if (context.mounted) {
                      unawaited(context.read<HomeCubit>().load());
                    }
                  },
                  icon: Icon(Icons.close_rounded, color: subTextColor),
                  tooltip: context.l10n.notNow,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
